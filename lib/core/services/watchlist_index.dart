import '../../data/models/catalogue_item.dart';
import '../../data/models/watchlist_entry.dart';

/// In-memory watchlist, in insertion order, with lookup by media key.
///
/// Films and TV shows share TMDB id values, so entries are always identified
/// by [CatalogueItemExtension.mediaKey]. Holds state only: persistence stays
/// with the caller.
class WatchlistIndex {
  final List<WatchlistEntry> _entries = [];
  final Map<String, WatchlistEntry> _byKey = {};

  List<WatchlistEntry> get entries => List.unmodifiable(_entries);

  List<CatalogueItem> get items =>
      _entries.map((entry) => entry.item).toList(growable: false);

  bool contains(CatalogueItem item) => _byKey.containsKey(item.mediaKey);

  WatchlistEntry? find(CatalogueItem item) => _byKey[item.mediaKey];

  Map<String, DateTime> get addedAtByMediaKey => {
        for (final entry in _entries) entry.mediaKey: entry.addedAt,
      };

  /// Adds [entry], or replaces the stored one with the same media key.
  void add(WatchlistEntry entry) {
    final key = entry.mediaKey;
    if (_byKey.containsKey(key)) {
      final index = _entries.indexWhere((e) => e.mediaKey == key);
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    _byKey[key] = entry;
  }

  void remove(CatalogueItem item) {
    final key = item.mediaKey;
    _entries.removeWhere((entry) => entry.mediaKey == key);
    _byKey.remove(key);
  }

  void replaceAll(Iterable<WatchlistEntry> entries) {
    clear();
    entries.forEach(add);
  }

  void clear() {
    _entries.clear();
    _byKey.clear();
  }
}
