import 'package:flutter/foundation.dart';

import '../../data/models/catalogue_item.dart';
import '../../data/models/watchlist_entry.dart';
import '../../data/repositories/watchlist_store.dart';
import 'watchlist_index.dart';

enum WatchlistAddResult { added, alreadyPresent, alreadyInCatalogue }

/// Titles saved to watch later, kept outside the catalogue.
///
/// Rules and persistence live here; the only link with the catalogue is the
/// [isInCatalogue] callback. Checks and index changes happen before any
/// `await`, so concurrent calls for the same title cannot both succeed.
class WatchlistService {
  WatchlistService({
    required WatchlistStore Function() store,
    required Future<void> Function() flushIfIdle,
    required bool Function(CatalogueItem) isInCatalogue,
    DateTime Function() clock = DateTime.now,
  })  : _store = store,
        _flushIfIdle = flushIfIdle,
        _isInCatalogue = isInCatalogue,
        _clock = clock;

  final WatchlistStore Function() _store;
  final Future<void> Function() _flushIfIdle;
  final bool Function(CatalogueItem) _isInCatalogue;
  final DateTime Function() _clock;

  final WatchlistIndex _index = WatchlistIndex();
  final ValueNotifier<List<WatchlistEntry>> _notifier =
      ValueNotifier<List<WatchlistEntry>>(const []);

  ValueListenable<List<WatchlistEntry>> get listenable => _notifier;

  List<WatchlistEntry> get entries => _index.entries;

  Map<String, DateTime> get addedAtByMediaKey => _index.addedAtByMediaKey;

  bool contains(CatalogueItem item) => _index.contains(item);

  WatchlistEntry? entryFor(CatalogueItem item) => _index.find(item);

  Future<WatchlistAddResult> add(CatalogueItem item) async {
    if (_isInCatalogue(item)) return WatchlistAddResult.alreadyInCatalogue;
    if (_index.contains(item)) return WatchlistAddResult.alreadyPresent;

    final entry = WatchlistEntry(
      item: catalogueItemForLocalStore(item).copyWithTags(const []),
      addedAt: _clock(),
    );
    _index.add(entry);
    _publish();
    await _persist(() => _store().saveWatchlistEntry(entry), entry.mediaKey);
    return WatchlistAddResult.added;
  }

  /// Returns false when [item] was not on the watchlist.
  Future<bool> remove(CatalogueItem item) async {
    if (!_index.contains(item)) return false;

    _index.remove(item);
    _publish();
    await _persist(
      () => _store().removeWatchlistEntry(item.mediaKey),
      item.mediaKey,
    );
    return true;
  }

  /// Undo of [remove]: ignored if the title entered the catalogue meanwhile.
  Future<void> restore(WatchlistEntry entry) async {
    if (_isInCatalogue(entry.item) || _index.contains(entry.item)) return;

    _index.add(entry);
    _publish();
    await _persist(() => _store().saveWatchlistEntry(entry), entry.mediaKey);
  }

  /// Loads [store] into memory, dropping entries already in the catalogue.
  Future<void> loadFrom(WatchlistStore store) async {
    final loaded = await store.loadWatchlist();
    final kept = <WatchlistEntry>[];
    var dropped = false;
    for (final entry in loaded) {
      if (_isInCatalogue(entry.item)) {
        dropped = true;
        await _persist(
          () => store.removeWatchlistEntry(entry.mediaKey),
          entry.mediaKey,
          flush: false,
        );
      } else {
        kept.add(entry);
      }
    }
    _index.replaceAll(kept);
    _publish();
    if (dropped) await _flushIfIdle();
  }

  /// Empties the in-memory watchlist only; the store is left untouched.
  void clear() {
    _index.clear();
    _publish();
  }

  void _publish() => _notifier.value = _index.entries;

  Future<void> _persist(
    Future<void> Function() write,
    String mediaKey, {
    bool flush = true,
  }) async {
    try {
      await write();
      if (flush) await _flushIfIdle();
    } catch (error, stackTrace) {
      debugPrint(
          'Failed to persist watchlist entry $mediaKey: $error\n$stackTrace');
    }
  }
}
