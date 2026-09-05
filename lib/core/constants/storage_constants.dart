/// Constants for local Hive storage of user data.
class StorageConstants {
  static const String catalogueBoxName = 'catalogue';
  static const String watchHistoryBoxName = 'watch_history';
  static const String metaBoxName = 'meta';

  static const String schemaVersionKey = 'schema_version';
  /// v2: catalogue without overview; watch records without media_title.
  static const int storageSchemaVersion = 2;

  static const String newEpisodeAlertsKey = 'new_episode_alerts';
  static const String lastEpisodeCheckKey = 'last_episode_check_at';
  static const String appInForegroundKey = 'app_in_foreground';
  static const String notifiedEpisodeIdsKey = 'notified_episode_ids';
}
