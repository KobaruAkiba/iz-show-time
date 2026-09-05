import 'dart:convert';

/// Singleton cache manager for storing and retrieving cached data
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  final Map<String, String> _memoryCache = {};

  CacheManager._internal();

  factory CacheManager() => _instance;

  void clearAll() {
    _memoryCache.clear();
  }

  void removeFromAll(String key) {
    _memoryCache.remove(key);
  }

  Map<String, dynamic> getStatistics() => {
        'movies_box_size': 0,
        'episodes_box_size': 0,
        'memory_cache_entries': _memoryCache.length,
      };

  T? get<T>(String key) {
    final rawValue = _memoryCache[key];
    if (rawValue == null) return null;

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic> && decoded.containsKey('value')) {
        final expiresAtStr = decoded['expiresAt'] as String?;
        if (expiresAtStr != null) {
          final expiresAt = DateTime.parse(expiresAtStr);
          if (DateTime.now().isAfter(expiresAt)) {
            _memoryCache.remove(key);
            return null;
          }
        }
        final value = decoded['value'];
        if (value is T) return value;
        if (value is List) {
          return List<dynamic>.from(value) as T;
        }
        if (value is Map) {
          try {
            return Map<String, dynamic>.from(value) as T;
          } catch (_) {
            return null;
          }
        }
        try {
          return value as T?;
        } catch (_) {
          return null;
        }
      }
      try {
        return decoded as T?;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  void put<T>(String key, dynamic value, {int ttlMinutes = 60}) {
    final expiresAtTime = ttlMinutes <= 0
        ? DateTime.now().subtract(const Duration(seconds: 1))
        : DateTime.now().add(Duration(minutes: ttlMinutes));
    _memoryCache[key] = jsonEncode({
      'value': value,
      'expiresAt': expiresAtTime.toIso8601String(),
    });
  }

  Iterable<String> get keys => _memoryCache.keys;

  void dispose() {
    _memoryCache.clear();
  }
}
