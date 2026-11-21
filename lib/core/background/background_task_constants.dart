/// Identifiers for native background episode checks.
class BackgroundTaskConstants {
  static const String episodeCheckUniqueName =
      'com.izshowtime.tracker.episode_check';
  static const String episodeCheckTaskName = 'episodeCheckTask';

  /// iOS BGProcessingTask; must match Info.plist and AppDelegate.swift.
  static const String nightlyCheckUniqueName =
      'com.izshowtime.tracker.episode_check_nightly';
  static const String nightlyCheckTaskName = 'episodeCheckNightlyTask';

  /// Earliest start of the nightly check after it is scheduled. Short enough
  /// that a launch in the evening still lands in the night window, long
  /// enough to keep it from running several times a night.
  static const Duration nightlyCheckInitialDelay = Duration(hours: 3);
}
