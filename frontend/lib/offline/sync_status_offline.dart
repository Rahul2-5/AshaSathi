class SyncStatusOffline {
  /// Successfully synced with backend
  static const int synced = 1;

  /// Created/updated locally, not yet synced
  static const int pending = 0;

  /// Deleted locally, needs backend delete
  static const int deleted = -1;

  /// Sync was blocked because server and local versions diverged
  static const int conflict = -2;
}
