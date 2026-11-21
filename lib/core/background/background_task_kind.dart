/// Which native background task ran the episode check.
enum BackgroundTaskKind {
  /// Android WorkManager periodic work, iOS BGAppRefreshTask or legacy fetch.
  periodic('periodic'),

  /// iOS BGProcessingTask, usually run at night while the device is idle.
  nightly('nightly');

  const BackgroundTaskKind(this.storageKey);

  /// Persisted value: never rename.
  final String storageKey;

  /// Null for missing or unknown values (older versions did not store it).
  static BackgroundTaskKind? fromStorageKey(Object? value) {
    for (final kind in values) {
      if (kind.storageKey == value) return kind;
    }
    return null;
  }
}
