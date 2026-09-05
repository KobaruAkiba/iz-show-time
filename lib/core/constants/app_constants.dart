/// Application-wide constants for configuration
class AppConstants {
  // API and Network settings
  static const Duration connectionTimeout = Duration(seconds: 30); // 30 seconds
  static const Duration receiveTimeout = Duration(seconds: 30); // 30 seconds

  // TMDB API rate limiting
  static const int tmdbMaxRequestsPerMinute = 40;
  static const int defaultCacheTTLMinutes = 60;

  // Cache TTL settings for different data types (in minutes)
  static const int movieCacheTTL = 1440; // 24 hours - movies don't change often
  static const int movieDetailsCacheTTL =
      1440 * 30; // 30 days - details rarely update
  static const int tvCacheTTL = 720; // 12 hours - shows update frequently
  static const int tvDetailsCacheTTL = 1440 * 30; // 30 days
  static const int searchCacheTTL =
      120; // 2 hours - searches change based on trends
  static const int episodeCacheTTL = 1440; // 24 hours - new episodes daily
  static const int airingScheduleCacheTTL =
      1440; // Daily for new episode checks

  // Notification / background episode-check settings
  static const int notificationCheckIntervalHours = 4;

  /// First WorkManager run after registration (Android minimum ~15 minutes).
  static const int notificationCheckInitialDelayMinutes = 15;

  // Search debounce delay (milliseconds)
  static const int searchDebounceDelayMs = 500;

  // Cache statistics debug logging
  static const bool logCacheStats = false;

  // Cache expiration cleanup interval (seconds)
  static const int cacheCleanupIntervalSeconds = 3600; // Hourly

  // UI-related constants
  static const double cardHeight = 200.0;
  static const double cardWidthRatio = 0.75;

  /// Initial / incremental page size for lazy-loaded lists.
  static const int listPageSize = 15;
}
