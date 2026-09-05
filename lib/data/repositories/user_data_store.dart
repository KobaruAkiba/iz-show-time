import '../models/catalogue_item.dart';
import '../models/new_episode_alert.dart';
import '../models/watch_record.dart';

/// Persists catalogue items and watch history on device.
abstract class UserDataStore {
  Future<void> open();

  Future<List<CatalogueItem>> loadCatalogue();

  Future<void> saveCatalogueItem(CatalogueItem item);

  Future<void> removeCatalogueItem(int mediaId);

  Future<List<WatchRecord>> loadWatchHistory();

  Future<void> saveWatchRecord(WatchRecord record);

  /// Persists many watch records in one box write (no per-item disk flush).
  Future<void> saveWatchRecords(Iterable<WatchRecord> records);

  Future<void> removeWatchRecord(String watchKey);

  /// Removes many watch records in one box write (no per-item disk flush).
  Future<void> removeWatchRecords(Iterable<String> watchKeys);

  Future<List<NewEpisodeAlert>> loadNewEpisodeAlerts();

  Future<void> saveNewEpisodeAlerts(List<NewEpisodeAlert> alerts);

  Future<DateTime?> loadLastEpisodeCheckAt();

  Future<void> saveLastEpisodeCheckAt(DateTime checkedAt);

  Future<bool> loadAppInForeground();

  Future<void> saveAppInForeground(bool isInForeground);

  /// Episode IDs that already triggered a system notification.
  Future<Set<int>> loadNotifiedEpisodeIds();

  Future<void> saveNotifiedEpisodeIds(Set<int> episodeIds);

  /// Forces durable write of pending box changes to disk.
  Future<void> flush();

  Future<void> clearAll();

  Future<void> close();
}
