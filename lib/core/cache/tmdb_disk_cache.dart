import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// A TMDB payload read back from disk.
class DiskCacheEntry {
  const DiskCacheEntry(this.value, this.expiresAt);

  final Map<String, dynamic> value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// On-disk cache of TMDB detail and season payloads.
///
/// Survives restarts, so titles already opened can be shown offline and the
/// app makes fewer requests. Expired entries are kept as an offline fallback
/// until the size cap or the periodic TMDB purge removes them.
///
/// Opened by the UI isolate only: Hive boxes cannot be shared across isolates.
class TmdbDiskCache {
  TmdbDiskCache._(this._box);

  static const String boxName = 'tmdb_cache';

  /// Entries kept after [trim]; payloads can be a few hundred KB each.
  static const int maxEntries = 150;

  // Values are "<expiry millis>|<json>": the expiry is readable without
  // decoding the payload, which keeps [trim] cheap.
  final LazyBox<String> _box;

  static Future<TmdbDiskCache> open() async {
    return TmdbDiskCache._(await Hive.openLazyBox<String>(boxName));
  }

  int get length => _box.length;

  Future<DiskCacheEntry?> read(String key) async {
    try {
      final raw = await _box.get(key);
      if (raw == null) return null;
      final separator = raw.indexOf('|');
      final expiresAt = _expiryOf(raw);
      final decoded = jsonDecode(raw.substring(separator + 1));
      if (expiresAt == null || decoded is! Map) return null;
      return DiskCacheEntry(Map<String, dynamic>.from(decoded), expiresAt);
    } catch (error, stackTrace) {
      debugPrint('TMDB disk cache read failed for $key: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> write(
    String key,
    Map<String, dynamic> value, {
    required int ttlMinutes,
  }) async {
    try {
      final expiresAt = DateTime.now().add(Duration(minutes: ttlMinutes));
      await _box.put(
        key,
        '${expiresAt.millisecondsSinceEpoch}|${jsonEncode(value)}',
      );
    } catch (error, stackTrace) {
      debugPrint('TMDB disk cache write failed for $key: $error\n$stackTrace');
    }
  }

  /// Keeps the [maxEntries] entries that expire last.
  Future<void> trim({int maxEntries = TmdbDiskCache.maxEntries}) async {
    try {
      if (_box.length <= maxEntries) return;
      final expiries = <String, int>{};
      for (final key in _box.keys.cast<String>()) {
        final raw = await _box.get(key);
        expiries[key] =
            (raw == null ? null : _expiryOf(raw))?.millisecondsSinceEpoch ?? 0;
      }
      final oldestFirst = expiries.keys.toList()
        ..sort((a, b) => expiries[a]!.compareTo(expiries[b]!));
      await _box.deleteAll(oldestFirst.take(_box.length - maxEntries));
      await _box.compact();
    } catch (error, stackTrace) {
      debugPrint('TMDB disk cache trim failed: $error\n$stackTrace');
    }
  }

  Future<void> clear() async {
    await _box.clear();
    await _box.compact();
  }

  Future<void> close() => _box.close();

  static DateTime? _expiryOf(String raw) {
    final separator = raw.indexOf('|');
    if (separator <= 0) return null;
    final millis = int.tryParse(raw.substring(0, separator));
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
