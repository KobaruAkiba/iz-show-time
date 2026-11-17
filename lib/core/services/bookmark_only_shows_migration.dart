import '../../data/models/catalogue_item.dart';
import '../../data/models/watchlist_entry.dart';
import '../../data/repositories/user_data_store.dart';
import '../utils/catalogue_activity.dart';
import 'catalogue_index.dart';
import 'watch_history_index.dart';

/// One-off move of catalogue shows with no watched episode to the watchlist.
/// Migrated shows lose their followed/favorite tags (the watchlist has none).
class BookmarkOnlyShowsMigration {
  BookmarkOnlyShowsMigration({
    required UserDataStore store,
    required CatalogueIndex catalogue,
    required WatchHistoryIndex history,
    DateTime Function() clock = DateTime.now,
  })  : _store = store,
        _catalogue = catalogue,
        _history = history,
        _clock = clock;

  final UserDataStore _store;
  final CatalogueIndex _catalogue;
  final WatchHistoryIndex _history;
  final DateTime Function() _clock;

  /// Returns how many shows moved; 0 when the flag is already set.
  Future<int> run() async {
    if (await _store.loadWatchlistMigrationDone()) return 0;

    final lastActivity = lastCatalogueActivityByMediaId(_history.records);
    final shows = _catalogue.tvShows
        .where((show) => _history.episodeCountFor(show.id) == 0)
        .toList(growable: false);
    for (final show in shows) {
      // Watchlist first: a crash here leaves the show in both places, which
      // the next launch fixes (flag unset, watchlist load drops catalogued).
      await _store.saveWatchlistEntry(
        WatchlistEntry(
          item: show.copyWithTags(const []),
          addedAt: lastActivity[show.mediaKey] ?? _clock(),
        ),
      );
      await _store.removeCatalogueItem(show);
      _catalogue.remove(show);
    }

    await _store.saveWatchlistMigrationDone();
    await _store.flush();
    return shows.length;
  }
}
