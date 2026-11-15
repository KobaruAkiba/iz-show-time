/// Application-wide constants for configuration
class AppConstants {
  // API and Network settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// After this delay while a request is still in flight, show slow-connection UI
  /// (banner / inline hint) so slow networks feel intentional rather than frozen.
  static const Duration slowConnectionThreshold = Duration(seconds: 4);

  /// Max shows checked in parallel by the new-episode check.
  static const int episodeCheckConcurrency = 4;

  /// Shows checked between two saves of the background episode check: a run
  /// cut short by the OS keeps what the completed blocks found.
  static const int episodeCheckBlockSize = 8;

  /// Retries after the first HTTP 429 before returning [ApiErrorType.rateLimit].
  static const int tmdbMaxRateLimitRetries = 5;

  /// Upper bound for Retry-After / backoff delay between 429 retries.
  static const Duration tmdbRateLimitRetryMaxDelay = Duration(seconds: 30);

  static const int defaultCacheTTLMinutes = 60;

  // Cache TTL settings for different data types (in minutes)
  static const int movieDetailsCacheTTL = 1440 * 30; // 30 days
  static const int tvCacheTTL = 720; // 12 hours
  static const int tvDetailsCacheTTL = 1440 * 30; // 30 days
  static const int searchCacheTTL = 120; // 2 hours
  static const int episodeCacheTTL = 1440; // 24 hours

  // Notification / background episode-check settings
  static const int notificationCheckIntervalHours = 2;

  /// System notifications are raised only for episodes aired within this
  /// many days; older ones stay in Continue Watching without notifying.
  static const int notificationRecentAirDays = 7;

  /// First WorkManager run after registration (Android minimum ~15 minutes).
  static const int notificationCheckInitialDelayMinutes = 15;

  /// Initial / incremental page size for lazy-loaded lists.
  static const int listPageSize = 15;

  /// Delay after typing stops before calling the search API.
  static const int searchDebounceDelayMs = 1000;

  /// Minimum gap between Home pull-to-refresh network calls.
  static const Duration homeRefreshCooldown = Duration(seconds: 2);

  /// Public PayPal.Me donation link (not a secret — safe to ship in the app).
  static const String paypalDonateUrl = 'https://paypal.me/MirkoCorba';

  /// Official TMDB site (attribution / logos & branding).
  static const String tmdbHomeUrl = 'https://www.themoviedb.org';
}
