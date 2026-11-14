import 'dart:collection';

class _CacheEntry {
  const _CacheEntry(this.value, this.expiresAt);

  final Object? value;
  final DateTime expiresAt;
}

/// Singleton in-memory cache with per-entry TTL and a size cap.
///
/// Values are kept as stored (no JSON round trip): callers must treat what
/// they read as immutable.
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  /// Entries beyond this are evicted, least recently used first.
  static const int maxEntries = 300;

  // Insertion order doubles as recency order: reads re-insert the entry.
  final LinkedHashMap<String, _CacheEntry> _memoryCache =
      LinkedHashMap<String, _CacheEntry>();

  CacheManager._internal();

  factory CacheManager() => _instance;

  void clearAll() {
    _memoryCache.clear();
  }

  void removeFromAll(String key) {
    _memoryCache.remove(key);
  }

  T? get<T>(String key) {
    final entry = _memoryCache.remove(key);
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) return null;
    _memoryCache[key] = entry;

    final value = entry.value;
    if (value is T) return value;
    try {
      if (value is List) return List<dynamic>.from(value) as T;
      if (value is Map) return Map<String, dynamic>.from(value) as T;
    } catch (_) {
      // Stored under a different shape than the one requested.
    }
    return null;
  }

  void put<T>(String key, dynamic value, {int ttlMinutes = 60}) {
    final expiresAt = ttlMinutes <= 0
        ? DateTime.now().subtract(const Duration(seconds: 1))
        : DateTime.now().add(Duration(minutes: ttlMinutes));
    _memoryCache.remove(key);
    _memoryCache[key] = _CacheEntry(value, expiresAt);
    while (_memoryCache.length > maxEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  /// Snapshot of the keys: reading entries reorders the underlying map.
  Iterable<String> get keys => List<String>.of(_memoryCache.keys);

  void dispose() {
    _memoryCache.clear();
  }
}
