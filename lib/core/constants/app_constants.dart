/// Application-wide constants for configuration
class AppConstants {
  // API and Network settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int defaultCacheTTLMinutes = 60;

  // Cache TTL settings for different data types (in minutes)
  static const int movieDetailsCacheTTL = 1440 * 30; // 30 days
  static const int tvCacheTTL = 720; // 12 hours
  static const int tvDetailsCacheTTL = 1440 * 30; // 30 days
  static const int searchCacheTTL = 120; // 2 hours
  static const int episodeCacheTTL = 1440; // 24 hours

  // Notification / background episode-check settings
  static const int notificationCheckIntervalHours = 4;

  /// First WorkManager run after registration (Android minimum ~15 minutes).
  static const int notificationCheckInitialDelayMinutes = 15;

  /// Initial / incremental page size for lazy-loaded lists.
  static const int listPageSize = 15;
}
