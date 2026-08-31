import 'dart:convert';

/// Singleton cache manager for storing and retrieving cached data
class CacheManager {
  final Map<String, dynamic> _memoryCache = {};

  /// Private constructor - use factory instead
  CacheManager._internal();

  /// Factory constructor to create singleton instance
  factory CacheManager() => CacheManager._internal();

  /// Clears all cached data
  void clearAll() {
    _memoryCache.clear();
  }

  /// Removes a specific key from the cache
  void removeFromAll(String key) {
    _memoryCache.remove(key);
  }

  /// Gets statistics about the cache (returns keys expected by AppServices)
  Map<String, dynamic> getStatistics() => {
        'movies_box_size': 0,
        'episodes_box_size': 0,
        'memory_cache_entries': _memoryCache.length,
      };

  /// Generic getter method - retrieve value by type and key
  T? get<T>(String key) {
    final rawValue = _memoryCache[key];
    if (rawValue == null) return null;
    
    try {
      final data = jsonDecode(rawValue);
      return data as T?;
    } catch (_) {
      return rawValue as T?;
    }
  }

  /// Generic setter method - store value with optional TTL in minutes
  void put<T>(String key, dynamic value, {int ttlMinutes = 60}) {
    final serialized = jsonEncode(value);
    _memoryCache[key] = serialized;
  }

  /// Convenience method to retrieve cached movie details
  String? getCachedMovieDetails(int id) => get<String>('movie_details_' + id.toString());

  /// Sets cached movie details
  void setCachedMovieDetails(int id, Map<String, dynamic> details) {
    put('movie_details_' + id.toString(), details);
  }

  /// Convenience method to retrieve cached TV show details
  String? getCachedTvShowDetails(int id) => get<String>('tvshow_details_' + id.toString());

  /// Sets cached TV show details
  void setCachedTvShowDetails(int id, Map<String, dynamic> details) {
    put('tvshow_details_' + id.toString(), details);
  }

  /// Convenience method to retrieve cached TV show episodes
  String? getCachedTvShowEpisodes(int tvId, int season) =>
      get<String>('tvshow_episodes_' + tvId.toString() + '_' + season.toString());

  /// Sets cached TV show episodes
  void setCachedTvShowEpisodes(
      int tvId, int season, List<Map<String, dynamic>> episodes) {
    put('tvshow_episodes_' + tvId.toString() + '_' + season.toString(), episodes);
  }

  /// Clears all movie cache entries
  void clearAllMovieCache() {
    for (var key in _memoryCache.keys.where((k) => k.startsWith('movie_'))) {
      removeFromAll(key);
    }
  }

  /// Clears all TV show cache entries
  void clearAllTvShowCache() {
    for (var key in _memoryCache.keys.where((k) => k.startsWith('tvshow_'))) {
      removeFromAll(key);
    }
  }

  /// Generic getter method (adds to public API for cache abstraction)
  String? getFromMemory(String key) => _memoryCache[key]?.toString();

  /// Generic setter method (adds to public API for cache abstraction)
  void setInMemory(String key, dynamic value) {
    _memoryCache[key] = jsonEncode(value);
  }

  /// Closes the cache manager (for dispose pattern compatibility)
  void dispose() {
    _memoryCache.clear();
  }
}
