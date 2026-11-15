import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../core/constants/storage_constants.dart';
import '../models/catalogue_item.dart';
import '../models/new_episode_alert.dart';
import '../models/watch_record.dart';
import 'background_check_outbox.dart';
import 'user_data_store.dart';

/// Point-in-time copy of the user data, see [HiveUserDataStore.readSnapshot].
class UserDataSnapshot {
  final List<CatalogueItem> catalogue;
  final List<WatchRecord> watchHistory;
  final List<NewEpisodeAlert> newEpisodeAlerts;
  final bool appInForeground;
  final Set<int> notifiedEpisodeIds;
  final DateTime? lastEpisodeCheckAt;

  const UserDataSnapshot({
    required this.catalogue,
    required this.watchHistory,
    required this.newEpisodeAlerts,
    required this.appInForeground,
    required this.notifiedEpisodeIds,
    this.lastEpisodeCheckAt,
  });
}

/// Hive-backed persistence for catalogue and watch history.
///
/// Writes update the in-memory box immediately; durable disk sync is deferred
/// to [flush] so bulk catalogue/watch mutations stay O(batch) instead of
/// O(items × fsync).
class HiveUserDataStore implements UserDataStore {
  static const String _backupFormat = 'iz_show_time_backup';
  /// v2: catalogue keyed by media key; older app versions must reject it.
  static const int _backupVersion = 2;
  static const Set<String> _backupMetaKeys = {
    StorageConstants.newEpisodeAlertsKey,
    StorageConstants.lastEpisodeCheckKey,
    StorageConstants.notifiedEpisodeIdsKey,
    StorageConstants.notificationPermissionPrePromptShownKey,
    StorageConstants.themeModeKey,
  };

  HiveUserDataStore() : _readOnly = false;

  HiveUserDataStore._readOnly() : _readOnly = true;

  /// Read-only instances never migrate, never recover and never write.
  final bool _readOnly;

  Box<dynamic>? _catalogueBox;
  Box<dynamic>? _watchHistoryBox;
  Box<dynamic>? _metaBox;

  Box<dynamic> get catalogueBox => _catalogueBox!;
  Box<dynamic> get watchHistoryBox => _watchHistoryBox!;
  Box<dynamic> get metaBox => _metaBox!;

  @override
  Future<void> open() async {
    final wasClosed = _metaBox == null;
    _catalogueBox ??= await _openBox(StorageConstants.catalogueBoxName);
    _watchHistoryBox ??= await _openBox(StorageConstants.watchHistoryBoxName);
    _metaBox ??= await _openBox(StorageConstants.metaBoxName);

    if (!wasClosed || _readOnly) return;
    await _ensureSchema();
  }

  // Crash recovery truncates the file: only the owning isolate may do it.
  Future<Box<dynamic>> _openBox(String name) =>
      Hive.openBox<dynamic>(name, crashRecovery: !_readOnly);

  /// Reads user data from an isolate that does not own the boxes.
  ///
  /// Hive 2 boxes are single-isolate: the UI isolate owns them, so this opens
  /// them without crash recovery or migrations and closes them right away.
  /// Returns null when the schema still has to be migrated by the UI isolate;
  /// throws when a file is caught mid-write.
  static Future<UserDataSnapshot?> readSnapshot() async {
    final store = HiveUserDataStore._readOnly();
    try {
      await store.open();
      final version = store.metaBox.get(StorageConstants.schemaVersionKey);
      if (version != StorageConstants.storageSchemaVersion) return null;
      return UserDataSnapshot(
        catalogue: await store.loadCatalogue(),
        watchHistory: await store.loadWatchHistory(),
        newEpisodeAlerts: await store.loadNewEpisodeAlerts(),
        appInForeground: await store.loadAppInForeground(),
        notifiedEpisodeIds: await store.loadNotifiedEpisodeIds(),
        lastEpisodeCheckAt: await store.loadLastEpisodeCheckAt(),
      );
    } finally {
      await store.close();
    }
  }

  @override
  Future<Map<String, dynamic>> exportBackupData() async {
    await open();
    return {
      'format': _backupFormat,
      'version': _backupVersion,
      'schemaVersion': StorageConstants.storageSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'catalogue': _stringifyMapEntries(catalogueBox.toMap()),
      'watchHistory': _stringifyMapEntries(watchHistoryBox.toMap()),
      'meta': _stringifyMapEntries(_filteredBackupMetaMap()),
    };
  }

  @override
  Future<void> importBackupData(Map<String, dynamic> data) async {
    await open();

    final format = data['format'];
    final version = data['version'];
    if (format != _backupFormat ||
        version is! int ||
        version > _backupVersion) {
      throw const FormatException('Unsupported backup file');
    }

    final catalogue = _decodeBackupSection(data['catalogue']);
    final watchHistory = _decodeBackupSection(data['watchHistory']);
    final meta = _decodeBackupSection(data['meta']);
    // Reject the file before touching current data.
    _validateBackupEntries(catalogue, watchHistory);

    final previous = (
      catalogue: Map<dynamic, dynamic>.of(catalogueBox.toMap()),
      watchHistory: Map<dynamic, dynamic>.of(watchHistoryBox.toMap()),
      meta: Map<dynamic, dynamic>.of(metaBox.toMap()),
    );

    try {
      await _replaceBoxContents(
        catalogue: catalogue,
        watchHistory: watchHistory,
        meta: _filteredBackupMetaEntries(meta),
      );
      // Version 1 backups key the catalogue by bare TMDB id.
      await _migrateCatalogueKeysV3();
      await metaBox.put(
        StorageConstants.schemaVersionKey,
        StorageConstants.storageSchemaVersion,
      );
    } catch (_) {
      await _replaceBoxContents(
        catalogue: previous.catalogue,
        watchHistory: previous.watchHistory,
        meta: previous.meta,
      );
      await flush();
      rethrow;
    }

    await _deleteBackgroundCheckResult();
    await flush();
  }

  Future<void> _replaceBoxContents({
    required Map<dynamic, dynamic> catalogue,
    required Map<dynamic, dynamic> watchHistory,
    required Map<dynamic, dynamic> meta,
  }) async {
    await catalogueBox.clear();
    await watchHistoryBox.clear();
    await metaBox.clear();
    if (catalogue.isNotEmpty) await catalogueBox.putAll(catalogue);
    if (watchHistory.isNotEmpty) await watchHistoryBox.putAll(watchHistory);
    if (meta.isNotEmpty) await metaBox.putAll(meta);
  }

  /// Throws [FormatException] when any entry would be dropped on load.
  void _validateBackupEntries(
    Map<dynamic, dynamic> catalogue,
    Map<dynamic, dynamic> watchHistory,
  ) {
    try {
      for (final raw in catalogue.values) {
        final json = _decodeStoredMap(raw);
        if (json == null || catalogueItemFromStorageJson(json) == null) {
          throw const FormatException('Invalid catalogue entry');
        }
      }
      for (final raw in watchHistory.values) {
        final json = _decodeStoredMap(raw);
        if (json == null) {
          throw const FormatException('Invalid watch history entry');
        }
        WatchRecord.fromJson(json);
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      // Type errors from the model factories: wrong field types.
      throw const FormatException('Invalid backup entry');
    }
  }

  Future<void> _ensureSchema() async {
    final rawVersion = metaBox.get(StorageConstants.schemaVersionKey);
    final version = rawVersion is int ? rawVersion : 0;

    if (version < 2) {
      await _migrateCompactPayloadsV2();
    }
    if (version < 3) {
      await _migrateCatalogueKeysV3();
    }

    if (version != StorageConstants.storageSchemaVersion) {
      await metaBox.put(
        StorageConstants.schemaVersionKey,
        StorageConstants.storageSchemaVersion,
      );
      await flush();
    }
  }

  /// Rewrites catalogue/watch payloads without overview / media_title.
  Future<void> _migrateCompactPayloadsV2() async {
    final catalogueEntries = <dynamic, String>{};
    for (final key in catalogueBox.keys) {
      try {
        final json = _decodeStoredMap(catalogueBox.get(key));
        if (json == null) continue;
        final item = catalogueItemFromStorageJson(json);
        if (item == null) continue;
        catalogueEntries[key] = jsonEncode(catalogueItemToStorageJson(item));
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping catalogue migration for $key: $error\n$stackTrace',
        );
      }
    }
    if (catalogueEntries.isNotEmpty) {
      await catalogueBox.putAll(catalogueEntries);
    }

    final watchEntries = <dynamic, String>{};
    for (final key in watchHistoryBox.keys) {
      try {
        final json = _decodeStoredMap(watchHistoryBox.get(key));
        if (json == null) continue;
        final record = WatchRecord.fromJson(json);
        watchEntries[key] = jsonEncode(record.toJson());
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping watch migration for $key: $error\n$stackTrace',
        );
      }
    }
    if (watchEntries.isNotEmpty) {
      await watchHistoryBox.putAll(watchEntries);
    }
  }

  /// Moves catalogue entries from the bare TMDB id to
  /// [CatalogueItemExtension.mediaKey]. Safe to run more than once.
  Future<void> _migrateCatalogueKeysV3() async {
    final rekeyed = <String, dynamic>{};
    final legacyKeys = <dynamic>[];
    for (final key in catalogueBox.keys.toList(growable: false)) {
      try {
        final raw = catalogueBox.get(key);
        final json = _decodeStoredMap(raw);
        if (json == null) continue;
        final item = catalogueItemFromStorageJson(json);
        if (item == null) continue;
        final mediaKey = item.mediaKey;
        if (key == mediaKey) continue;
        legacyKeys.add(key);
        // An entry already stored under the new key is the newer one.
        if (!catalogueBox.containsKey(mediaKey)) {
          rekeyed.putIfAbsent(mediaKey, () => raw);
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping catalogue key migration for $key: $error\n$stackTrace',
        );
      }
    }
    if (rekeyed.isNotEmpty) {
      await catalogueBox.putAll(rekeyed);
    }
    if (legacyKeys.isNotEmpty) {
      await catalogueBox.deleteAll(legacyKeys);
    }
  }

  @override
  Future<List<CatalogueItem>> loadCatalogue() async {
    await open();
    final items = <CatalogueItem>[];

    for (final key in catalogueBox.keys) {
      try {
        final json = _decodeStoredMap(catalogueBox.get(key));
        if (json == null) continue;
        final item = catalogueItemFromStorageJson(json);
        if (item != null) items.add(item);
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping corrupted catalogue entry $key: $error\n$stackTrace',
        );
      }
    }

    return items;
  }

  @override
  Future<void> saveCatalogueItem(CatalogueItem item) async {
    await open();
    await _putEncodedMap(
      catalogueBox,
      item.mediaKey,
      catalogueItemToStorageJson(item),
    );
  }

  @override
  Future<void> removeCatalogueItem(CatalogueItem item) async {
    await open();
    await catalogueBox.delete(item.mediaKey);
  }

  @override
  Future<List<WatchRecord>> loadWatchHistory() async {
    await open();
    final records = <WatchRecord>[];

    for (final key in watchHistoryBox.keys) {
      try {
        final json = _decodeStoredMap(watchHistoryBox.get(key));
        if (json == null) continue;
        records.add(WatchRecord.fromJson(json));
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping corrupted watch record $key: $error\n$stackTrace',
        );
      }
    }

    return records;
  }

  @override
  Future<void> saveWatchRecord(WatchRecord record) async {
    await saveWatchRecords([record]);
  }

  @override
  Future<void> saveWatchRecords(Iterable<WatchRecord> records) async {
    await open();
    final encoded = <dynamic, String>{
      for (final record in records)
        record.watchKey: jsonEncode(record.toJson()),
    };
    if (encoded.isEmpty) return;
    await watchHistoryBox.putAll(encoded);
  }

  @override
  Future<void> removeWatchRecord(String watchKey) async {
    await removeWatchRecords([watchKey]);
  }

  @override
  Future<void> removeWatchRecords(Iterable<String> watchKeys) async {
    await open();
    final keys = watchKeys.toList(growable: false);
    if (keys.isEmpty) return;
    await watchHistoryBox.deleteAll(keys);
  }

  @override
  Future<List<NewEpisodeAlert>> loadNewEpisodeAlerts() async {
    await open();
    final raw = metaBox.get(StorageConstants.newEpisodeAlertsKey);
    if (raw == null) return [];

    final List<dynamic> entries;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      entries = decoded;
    } else if (raw is List) {
      entries = raw;
    } else {
      return [];
    }

    final alerts = <NewEpisodeAlert>[];
    for (final entry in entries) {
      final json = _decodeStoredMap(entry);
      if (json == null) continue;
      try {
        alerts.add(NewEpisodeAlert.fromJson(json));
      } catch (error, stackTrace) {
        debugPrint(
          'Skipping corrupted new episode alert: $error\n$stackTrace',
        );
      }
    }
    return alerts;
  }

  @override
  Future<void> saveNewEpisodeAlerts(List<NewEpisodeAlert> alerts) async {
    await open();
    await metaBox.put(
      StorageConstants.newEpisodeAlertsKey,
      jsonEncode(alerts.map((alert) => alert.toJson()).toList()),
    );
  }

  @override
  Future<DateTime?> loadLastEpisodeCheckAt() async {
    await open();
    final raw = metaBox.get(StorageConstants.lastEpisodeCheckKey);
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> saveLastEpisodeCheckAt(DateTime checkedAt) async {
    await open();
    await metaBox.put(
      StorageConstants.lastEpisodeCheckKey,
      checkedAt.toIso8601String(),
    );
  }

  @override
  Future<bool> loadAppInForeground() async {
    await open();
    final raw = metaBox.get(StorageConstants.appInForegroundKey);
    if (raw is bool) return raw;
    return false;
  }

  @override
  Future<void> saveAppInForeground(bool isInForeground) async {
    await open();
    await metaBox.put(StorageConstants.appInForegroundKey, isInForeground);
  }

  @override
  Future<Set<int>> loadNotifiedEpisodeIds() async {
    await open();
    final raw = metaBox.get(StorageConstants.notifiedEpisodeIdsKey);
    if (raw is! String || raw.isEmpty) return <int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>{};
      return {
        for (final value in decoded)
          if (value is int) value else if (value is num) value.toInt(),
      };
    } catch (_) {
      return <int>{};
    }
  }

  @override
  Future<void> saveNotifiedEpisodeIds(Set<int> episodeIds) async {
    await open();
    final sorted = episodeIds.toList()..sort();
    await metaBox.put(
      StorageConstants.notifiedEpisodeIdsKey,
      jsonEncode(sorted),
    );
  }

  @override
  Future<BackgroundCheckResult?> loadBackgroundCheckResult() =>
      BackgroundCheckOutbox.read();

  /// A stale background result must not outlive the data it was built from.
  Future<void> _deleteBackgroundCheckResult() async {
    try {
      await BackgroundCheckOutbox.delete();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to delete background check result: $error\n$stackTrace',
      );
    }
  }

  @override
  Future<bool> loadNotificationPermissionPrePromptShown() async {
    await open();
    final raw = metaBox.get(
      StorageConstants.notificationPermissionPrePromptShownKey,
    );
    return raw == true;
  }

  @override
  Future<void> saveNotificationPermissionPrePromptShown(bool shown) async {
    await open();
    await metaBox.put(
      StorageConstants.notificationPermissionPrePromptShownKey,
      shown,
    );
  }

  @override
  Future<String?> loadThemeMode() async {
    await open();
    final raw = metaBox.get(StorageConstants.themeModeKey);
    if (raw is! String || raw.isEmpty) return null;
    return raw;
  }

  @override
  Future<void> saveThemeMode(String themeMode) async {
    await open();
    await metaBox.put(StorageConstants.themeModeKey, themeMode);
  }

  @override
  Future<DateTime?> loadLastTmdbCachePurgeAt() async {
    await open();
    final raw = metaBox.get(StorageConstants.lastTmdbCachePurgeKey);
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> saveLastTmdbCachePurgeAt(DateTime purgedAt) async {
    await open();
    await metaBox.put(
      StorageConstants.lastTmdbCachePurgeKey,
      purgedAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> flush() async {
    await open();
    await Future.wait([
      catalogueBox.flush(),
      watchHistoryBox.flush(),
      metaBox.flush(),
    ]);
  }

  @override
  Future<void> clearAll() async {
    await open();
    await catalogueBox.clear();
    await watchHistoryBox.clear();
    await metaBox.delete(StorageConstants.newEpisodeAlertsKey);
    await metaBox.delete(StorageConstants.lastEpisodeCheckKey);
    await metaBox.delete(StorageConstants.appInForegroundKey);
    await metaBox.delete(StorageConstants.notifiedEpisodeIdsKey);
    await metaBox.delete(
      StorageConstants.notificationPermissionPrePromptShownKey,
    );
    await metaBox.delete(StorageConstants.lastTmdbCachePurgeKey);
    await _deleteBackgroundCheckResult();
    await metaBox.put(
      StorageConstants.schemaVersionKey,
      StorageConstants.storageSchemaVersion,
    );
    await flush();
  }

  Map<String, dynamic>? _decodeStoredMap(Object? raw) {
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return null;
  }

  Map<String, dynamic> _stringifyMapEntries(Map<dynamic, dynamic> source) {
    return {
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };
  }

  Map<dynamic, dynamic> _decodeBackupSection(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid backup structure');
    }

    return {
      for (final entry in raw.entries)
        _restoreBackupKey(entry.key.toString()): entry.value,
    };
  }

  Object _restoreBackupKey(String key) {
    final asInt = int.tryParse(key);
    return asInt ?? key;
  }

  Map<dynamic, dynamic> _filteredBackupMetaMap() {
    final meta = metaBox.toMap();
    return _filteredBackupMetaEntries(meta);
  }

  Map<dynamic, dynamic> _filteredBackupMetaEntries(
      Map<dynamic, dynamic> source) {
    return {
      for (final entry in source.entries)
        if (_backupMetaKeys.contains(entry.key)) entry.key: entry.value,
    };
  }

  Future<void> _putEncodedMap(
    Box<dynamic> box,
    Object key,
    Map<String, dynamic> json,
  ) async {
    await box.put(key, jsonEncode(json));
  }

  @override
  Future<void> close() async {
    await _catalogueBox?.close();
    await _watchHistoryBox?.close();
    await _metaBox?.close();
    _catalogueBox = null;
    _watchHistoryBox = null;
    _metaBox = null;
  }
}
