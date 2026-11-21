import 'package:iz_show_time_tracker/data/models/catalogue_item.dart';
import 'package:iz_show_time_tracker/data/models/new_episode_alert.dart';
import 'package:iz_show_time_tracker/data/models/watch_record.dart';
import 'package:iz_show_time_tracker/data/models/watchlist_entry.dart';
import 'package:iz_show_time_tracker/data/repositories/background_check_outbox.dart';
import 'package:iz_show_time_tracker/data/repositories/user_data_store.dart';

class FakeUserDataStore implements UserDataStore {
  final List<CatalogueItem> catalogue = [];
  final List<WatchRecord> history = [];
  final List<CatalogueItem> savedCatalogueItems = [];
  final List<int> removedCatalogueIds = [];
  final List<WatchRecord> savedWatchRecords = [];
  final List<String> removedWatchKeys = [];
  List<NewEpisodeAlert> alerts = [];
  DateTime? lastEpisodeCheckAt;
  bool appInForeground = false;
  final List<WatchlistEntry> watchlist = [];
  bool watchlistMigrationDone = false;
  bool cleared = false;

  @override
  Future<void> open() async {}

  @override
  Future<Map<String, dynamic>> exportBackupData() async => {
        'catalogue': catalogue
            .map(
              (item) => item is Film
                  ? {'type': 'film', ...item.toJson()}
                  : {'type': 'tv', ...(item as TvShow).toJson()},
            )
            .toList(),
        'watchHistory': history.map((record) => record.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'themeMode': themeMode,
        'hideWatchTime': hideWatchTime,
        'watchlist': watchlist.map((entry) => entry.toStorageJson()).toList(),
      };

  @override
  Future<void> importBackupData(Map<String, dynamic> data) async {
    catalogue
      ..clear()
      ..addAll(
        (data['catalogue'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(
              (json) => json['type'] == 'film'
                  ? Film.fromJson(json)
                  : TvShow.fromJson(json),
            ),
      );
    history
      ..clear()
      ..addAll(
        (data['watchHistory'] as List<dynamic>? ?? const []).map((entry) =>
            WatchRecord.fromJson(Map<String, dynamic>.from(entry as Map))),
      );
    alerts = (data['alerts'] as List<dynamic>? ?? const [])
        .map((entry) =>
            NewEpisodeAlert.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    themeMode = data['themeMode'] as String?;
    hideWatchTime = data['hideWatchTime'] == true;
    watchlist
      ..clear()
      ..addAll(
        (data['watchlist'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map(WatchlistEntry.fromStorageJson)
            .nonNulls,
      );
    // Importing a backup makes the migration run again.
    watchlistMigrationDone = false;
  }

  @override
  Future<List<CatalogueItem>> loadCatalogue() async =>
      List<CatalogueItem>.from(catalogue);

  @override
  Future<void> saveCatalogueItem(CatalogueItem item) async {
    savedCatalogueItems.add(item);
    final index =
        catalogue.indexWhere((entry) => entry.mediaKey == item.mediaKey);
    if (index >= 0) {
      catalogue[index] = item;
    } else {
      catalogue.add(item);
    }
  }

  @override
  Future<void> removeCatalogueItem(CatalogueItem item) async {
    removedCatalogueIds.add(item.id);
    catalogue.removeWhere((entry) => entry.mediaKey == item.mediaKey);
  }

  @override
  Future<List<WatchRecord>> loadWatchHistory() async =>
      List<WatchRecord>.from(history);

  int flushCount = 0;
  int saveWatchRecordsCalls = 0;
  int removeWatchRecordsCalls = 0;

  @override
  Future<void> saveWatchRecord(WatchRecord record) async {
    await saveWatchRecords([record]);
  }

  @override
  Future<void> saveWatchRecords(Iterable<WatchRecord> records) async {
    saveWatchRecordsCalls++;
    for (final record in records) {
      history.removeWhere((entry) => entry.watchKey == record.watchKey);
      history.add(record);
      savedWatchRecords.add(record);
    }
  }

  @override
  Future<void> removeWatchRecord(String watchKey) async {
    await removeWatchRecords([watchKey]);
  }

  @override
  Future<void> removeWatchRecords(Iterable<String> watchKeys) async {
    removeWatchRecordsCalls++;
    final keys = watchKeys.toSet();
    removedWatchKeys.addAll(keys);
    history.removeWhere((record) => keys.contains(record.watchKey));
  }

  @override
  Future<List<WatchlistEntry>> loadWatchlist() async =>
      List<WatchlistEntry>.from(watchlist);

  @override
  Future<void> saveWatchlistEntry(WatchlistEntry e) async {
    final index = watchlist.indexWhere((entry) => entry.mediaKey == e.mediaKey);
    if (index >= 0) {
      watchlist[index] = e;
    } else {
      watchlist.add(e);
    }
  }

  @override
  Future<void> removeWatchlistEntry(String mediaKey) async {
    watchlist.removeWhere((entry) => entry.mediaKey == mediaKey);
  }

  @override
  Future<bool> loadWatchlistMigrationDone() async => watchlistMigrationDone;

  @override
  Future<void> saveWatchlistMigrationDone() async {
    watchlistMigrationDone = true;
  }

  @override
  Future<void> flush() async {
    flushCount++;
  }

  @override
  Future<List<NewEpisodeAlert>> loadNewEpisodeAlerts() async =>
      List<NewEpisodeAlert>.from(alerts);

  @override
  Future<void> saveNewEpisodeAlerts(List<NewEpisodeAlert> alerts) async {
    this.alerts = List<NewEpisodeAlert>.from(alerts);
  }

  @override
  Future<DateTime?> loadLastEpisodeCheckAt() async => lastEpisodeCheckAt;

  @override
  Future<void> saveLastEpisodeCheckAt(DateTime checkedAt) async {
    lastEpisodeCheckAt = checkedAt;
  }

  @override
  Future<bool> loadAppInForeground() async => appInForeground;

  /// Every value passed to [saveAppInForeground], in order.
  final List<bool> foregroundWrites = [];

  @override
  Future<void> saveAppInForeground(bool isInForeground) async {
    foregroundWrites.add(isInForeground);
    appInForeground = isInForeground;
  }

  Set<int> notifiedEpisodeIds = {};

  @override
  Future<Set<int>> loadNotifiedEpisodeIds() async =>
      Set<int>.from(notifiedEpisodeIds);

  @override
  Future<void> saveNotifiedEpisodeIds(Set<int> episodeIds) async {
    notifiedEpisodeIds = Set<int>.from(episodeIds);
  }

  BackgroundCheckResult? backgroundCheckResult;

  @override
  Future<BackgroundCheckResult?> loadBackgroundCheckResult() async =>
      backgroundCheckResult;

  bool notificationPermissionPrePromptShown = false;

  @override
  Future<bool> loadNotificationPermissionPrePromptShown() async =>
      notificationPermissionPrePromptShown;

  @override
  Future<void> saveNotificationPermissionPrePromptShown(bool shown) async {
    notificationPermissionPrePromptShown = shown;
  }

  String? themeMode;

  @override
  Future<String?> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(String themeMode) async {
    this.themeMode = themeMode;
  }

  bool hideWatchTime = false;

  @override
  Future<bool> loadHideWatchTime() async => hideWatchTime;

  @override
  Future<void> saveHideWatchTime(bool hidden) async {
    hideWatchTime = hidden;
  }

  DateTime? lastTmdbCachePurgeAt;

  @override
  Future<DateTime?> loadLastTmdbCachePurgeAt() async => lastTmdbCachePurgeAt;

  @override
  Future<void> saveLastTmdbCachePurgeAt(DateTime purgedAt) async {
    lastTmdbCachePurgeAt = purgedAt;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
    catalogue.clear();
    history.clear();
    watchlist.clear();
    alerts = [];
    lastEpisodeCheckAt = null;
    notifiedEpisodeIds = {};
    notificationPermissionPrePromptShown = false;
    lastTmdbCachePurgeAt = null;
  }

  @override
  Future<void> close() async {}
}
