import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/storage_constants.dart';
import '../models/catalogue_item.dart';
import '../models/new_episode_alert.dart';
import '../models/watch_record.dart';
import 'user_data_store.dart';

/// Hive-backed persistence for catalogue and watch history.
///
/// Writes update the in-memory box immediately; durable disk sync is deferred
/// to [flush] so bulk catalogue/watch mutations stay O(batch) instead of
/// O(items × fsync).
class HiveUserDataStore implements UserDataStore {
  Box? _catalogueBox;
  Box? _watchHistoryBox;
  Box? _metaBox;

  Box get catalogueBox => _catalogueBox!;
  Box get watchHistoryBox => _watchHistoryBox!;
  Box get metaBox => _metaBox!;

  @override
  Future<void> open() async {
    _catalogueBox ??= await Hive.openBox(StorageConstants.catalogueBoxName);
    _watchHistoryBox ??=
        await Hive.openBox(StorageConstants.watchHistoryBoxName);
    _metaBox ??= await Hive.openBox(StorageConstants.metaBoxName);

    await metaBox.put(
      StorageConstants.schemaVersionKey,
      StorageConstants.storageSchemaVersion,
    );
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
      item.id,
      catalogueItemToStorageJson(item),
    );
  }

  @override
  Future<void> removeCatalogueItem(int mediaId) async {
    await open();
    await catalogueBox.delete(mediaId);
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

  Future<void> _putEncodedMap(
    Box box,
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
