

/// Synchronization conflict types
enum ConflictType {
  dataModified,
  dataDeleted,
  versionMismatch,
  timestampConflict
}

/// Synchronization conflict resolution strategies
enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
  userChoice
}

/// Represents a synchronization conflict
class SyncConflict {
  final String key;
  final ConflictType type;
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final String? localVersion;
  final String? remoteVersion;

  const SyncConflict({
    required this.key,
    required this.type,
    this.localData,
    this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    this.localVersion,
    this.remoteVersion,
  });
}

/// Synchronization result
class SyncResult {
  final bool success;
  final List<SyncConflict> conflicts;
  final List<String> syncedKeys;
  final List<String> failedKeys;
  final DateTime timestamp;
  final String? error;

  const SyncResult({
    required this.success,
    required this.conflicts,
    required this.syncedKeys,
    required this.failedKeys,
    required this.timestamp,
    this.error,
  });
}

/// Synchronization status
enum SyncStatus {
  idle,
  syncing,
  conflict,
  error,
  offline
}

/// Interface for the synchronization engine
abstract class ISynchronizationEngine {
  /// Initialize the synchronization engine
  Future<void> initialize();

  /// Synchronize all data across devices
  Future<SyncResult> synchronizeData();

  /// Synchronize specific data by key
  Future<SyncResult> synchronizeKey(String key);

  /// Resolve a synchronization conflict
  Future<void> resolveConflict(SyncConflict conflict, ConflictResolution resolution);

  /// Handle network interruption recovery
  Future<void> handleNetworkRecovery();

  /// Get current synchronization status
  SyncStatus get status;

  /// Stream of synchronization events
  Stream<SyncResult> get syncEvents;

  /// Get pending conflicts
  List<SyncConflict> get pendingConflicts;

  /// Check if data needs synchronization
  Future<bool> needsSync(String key);

  /// Mark data as dirty (needs sync)
  Future<void> markDirty(String key);

  /// Get last sync timestamp
  DateTime? get lastSyncTime;

  /// Shutdown the synchronization engine
  Future<void> shutdown();
}