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

  String? getCachedMovieDetails(int id) =>
      get<String>('movie_details_$id');

  void setCachedMovieDetails(int id, Map<String, dynamic> details) {
    put('movie_details_$id', details);
  }

  String? getCachedTvShowDetails(int id) =>
      get<String>('tvshow_details_$id');

  void setCachedTvShowDetails(int id, Map<String, dynamic> details) {
    put('tvshow_details_$id', details);
  }

  String? getCachedTvShowEpisodes(int tvId, int season) =>
      get<String>('tvshow_episodes_${tvId}_$season');

  void setCachedTvShowEpisodes(
    int tvId,
    int season,
    List<Map<String, dynamic>> episodes,
  ) {
    put('tvshow_episodes_${tvId}_$season', episodes);
  }

  void clearAllMovieCache() {
    for (final key in _memoryCache.keys.where((k) => k.startsWith('movie_'))) {
      removeFromAll(key);
    }
  }

  void clearAllTvShowCache() {
    for (final key
        in _memoryCache.keys.where((k) => k.startsWith('tvshow_'))) {
      removeFromAll(key);
    }
  }

  Iterable<String> get keys => _memoryCache.keys;

  String? getFromMemory(String key) => _memoryCache[key];

  void setInMemory(String key, dynamic value) {
    put(key, value);
  }

  void dispose() {
    _memoryCache.clear();
  }
}
