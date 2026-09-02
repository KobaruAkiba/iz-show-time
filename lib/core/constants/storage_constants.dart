/// Constants for local Hive storage of user data.
class StorageConstants {
  static const String catalogueBoxName = 'catalogue';
  static const String watchHistoryBoxName = 'watch_history';
  static const String metaBoxName = 'meta';

  static const String schemaVersionKey = 'schema_version';
  static const int storageSchemaVersion = 1;

  static const String newEpisodeAlertsKey = 'new_episode_alerts';
  static const String lastEpisodeCheckKey = 'last_episode_check_at';
}
