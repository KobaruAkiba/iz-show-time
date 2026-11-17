import '../models/watchlist_entry.dart';

/// Persistence for the watchlist, keyed by media key.
abstract interface class WatchlistStore {
  Future<List<WatchlistEntry>> loadWatchlist();

  Future<void> saveWatchlistEntry(WatchlistEntry e);

  Future<void> removeWatchlistEntry(String mediaKey);
}
