/// Constants for local Hive storage of user data.
class StorageConstants {
  static const String catalogueBoxName = 'catalogue';
  static const String watchHistoryBoxName = 'watch_history';
  static const String metaBoxName = 'meta';

  static const String schemaVersionKey = 'schema_version';

  /// v2: catalogue without overview; watch records without media_title.
  /// v3: catalogue keyed by media key (film/TV + id) instead of bare TMDB id.
  static const int storageSchemaVersion = 3;

  static const String newEpisodeAlertsKey = 'new_episode_alerts';
  static const String lastEpisodeCheckKey = 'last_episode_check_at';
  static const String appInForegroundKey = 'app_in_foreground';

  /// Last time the app left the foreground: episodes notified before then
  /// count as seen.
  static const String appLeftForegroundAtKey = 'app_left_foreground_at';
  static const String notifiedEpisodeIdsKey = 'notified_episode_ids';
  static const String notificationPermissionPrePromptShownKey =
      'notification_permission_pre_prompt_shown';
  static const String themeModeKey = 'theme_mode';

  /// Catalogue header shows a catalogue summary instead of total watch time.
  static const String hideWatchTimeKey = 'hide_watch_time';

  /// Last time non-catalogue TMDB caches were purged (API Terms ≤6 months).
  static const String lastTmdbCachePurgeKey = 'last_tmdb_cache_purge_at';

  /// Max age for cached TMDB information before a compliance purge.
  static const Duration tmdbCacheMaxAge = Duration(days: 183);
}
