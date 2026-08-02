class DatabaseChangeTracker {
  static final DatabaseChangeTracker _instance = DatabaseChangeTracker._();

  factory DatabaseChangeTracker() => _instance;

  DatabaseChangeTracker._();

  bool _hasPendingBackup = false;

  bool get hasPendingBackup => _hasPendingBackup;

  void markChanged() {
    _hasPendingBackup = true;
  }

  void clearPendingBackup() {
    _hasPendingBackup = false;
  }
}
