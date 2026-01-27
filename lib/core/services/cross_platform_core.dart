import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../interfaces/i_synchronization_engine.dart';
import '../interfaces/i_network_manager.dart';
import '../interfaces/i_state_manager.dart';

/// Abstract storage interface for testing
abstract class ISyncStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Set<String> getKeys();
}

/// Production storage implementation for sync
class SyncStorage implements ISyncStorage {
  final IStateManager _stateManager;

  SyncStorage(this._stateManager);

  @override
  Future<String?> getString(String key) async {
    return await _stateManager.loadState<String>(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _stateManager.saveState(key, value);
  }

  @override
  Future<bool> containsKey(String key) async {
    final value = await getString(key);
    return value != null;
  }

  @override
  Future<void> remove(String key) async {
    await _stateManager.saveState(key, null);
  }

  @override
  Set<String> getKeys() {
    // This is a simplified implementation
    // In a real scenario, we'd need to track all sync keys
    return <String>{};
  }
}

/// Mock storage for testing
class MockSyncStorage implements ISyncStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Set<String> getKeys() => _data.keys.toSet();
}

/// Cross-platform synchronization engine implementation
class CrossPlatformCore implements ISynchronizationEngine {
  static const String _syncMetadataPrefix = 'sync_meta_';
  static const String _conflictPrefix = 'sync_conflict_';
  static const String _dirtyKeysKey = 'sync_dirty_keys';
  static const String _lastSyncKey = 'last_sync_time';

  final INetworkManager _networkManager;
  late final ISyncStorage _storage;

  SyncStatus _status = SyncStatus.idle;
  final List<SyncConflict> _pendingConflicts = [];
  final Set<String> _dirtyKeys = {};
  DateTime? _lastSyncTime;

  final StreamController<SyncResult> _syncController =
      StreamController<SyncResult>.broadcast();
  Timer? _recoveryTimer;
  bool _isInitialized = false;

  CrossPlatformCore(
    this._networkManager, {
    IStateManager? stateManager,
    ISyncStorage? storage,
  }) {
    _storage =
        storage ??
        (stateManager != null ? SyncStorage(stateManager) : MockSyncStorage());
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load dirty keys from storage
    await _loadDirtyKeys();

    // Load pending conflicts
    await _loadPendingConflicts();

    // Load last sync time
    await _loadLastSyncTime();

    // Set up network recovery monitoring
    _networkManager.connectivityStream.listen(_onConnectivityChanged);

    _isInitialized = true;
  }

  @override
  Future<SyncResult> synchronizeData() async {
    if (!_isInitialized) {
      throw StateError('Synchronization engine not initialized');
    }

    if (!_networkManager.isOnline) {
      _status = SyncStatus.offline;
      return SyncResult(
        success: false,
        conflicts: [],
        syncedKeys: [],
        failedKeys: _dirtyKeys.toList(),
        timestamp: DateTime.now(),
        error: 'No network connectivity',
      );
    }

    _status = SyncStatus.syncing;

    final syncedKeys = <String>[];
    final failedKeys = <String>[];
    final conflicts = <SyncConflict>[];

    try {
      // Sync all dirty keys
      for (final key in _dirtyKeys.toList()) {
        try {
          final result = await synchronizeKey(key);
          if (result.success) {
            syncedKeys.addAll(result.syncedKeys);
            _dirtyKeys.remove(key);
          } else {
            failedKeys.add(key);
          }
          conflicts.addAll(result.conflicts);
        } catch (e) {
          failedKeys.add(key);
        }
      }

      // Update last sync time if any keys were synced
      if (syncedKeys.isNotEmpty) {
        _lastSyncTime = DateTime.now();
        await _saveLastSyncTime();
      }

      // Save updated dirty keys
      await _saveDirtyKeys();

      _status = conflicts.isNotEmpty ? SyncStatus.conflict : SyncStatus.idle;

      final result = SyncResult(
        success: failedKeys.isEmpty && conflicts.isEmpty,
        conflicts: conflicts,
        syncedKeys: syncedKeys,
        failedKeys: failedKeys,
        timestamp: DateTime.now(),
      );

      _syncController.add(result);
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      final result = SyncResult(
        success: false,
        conflicts: [],
        syncedKeys: syncedKeys,
        failedKeys: _dirtyKeys.toList(),
        timestamp: DateTime.now(),
        error: e.toString(),
      );

      _syncController.add(result);
      return result;
    }
  }

  @override
  Future<SyncResult> synchronizeKey(String key) async {
    if (!_networkManager.isOnline) {
      return SyncResult(
        success: false,
        conflicts: [],
        syncedKeys: [],
        failedKeys: [key],
        timestamp: DateTime.now(),
        error: 'No network connectivity',
      );
    }

    try {
      // Get local data and metadata
      final localData = await _storage.getString(key);
      final localMeta = await _getMetadata(key);

      // Get remote data
      final remoteData = await _networkManager.downloadData(key);

      if (localData == null && remoteData == null) {
        // No data exists locally or remotely
        return SyncResult(
          success: true,
          conflicts: [],
          syncedKeys: [],
          failedKeys: [],
          timestamp: DateTime.now(),
        );
      }

      if (localData != null && remoteData == null) {
        // Local data exists, upload to remote
        await _networkManager.uploadData(key, jsonDecode(localData));
        await _updateMetadata(key, DateTime.now());

        return SyncResult(
          success: true,
          conflicts: [],
          syncedKeys: [key],
          failedKeys: [],
          timestamp: DateTime.now(),
        );
      }

      if (localData == null && remoteData != null) {
        // Remote data exists, download to local
        await _storage.setString(key, jsonEncode(remoteData));
        await _updateMetadata(key, DateTime.now());

        return SyncResult(
          success: true,
          conflicts: [],
          syncedKeys: [key],
          failedKeys: [],
          timestamp: DateTime.now(),
        );
      }

      // Both local and remote data exist, check for conflicts
      final remoteTimestamp =
          DateTime.tryParse(remoteData!['_timestamp'] ?? '') ?? DateTime.now();
      final localTimestamp = localMeta?.lastModified ?? DateTime.now();

      if (_hasConflict(
        localData!,
        remoteData,
        localTimestamp,
        remoteTimestamp,
      )) {
        // Create conflict for resolution
        final conflict = SyncConflict(
          key: key,
          type: ConflictType.dataModified,
          localData: jsonDecode(localData),
          remoteData: remoteData,
          localTimestamp: localTimestamp,
          remoteTimestamp: remoteTimestamp,
        );

        _pendingConflicts.add(conflict);
        await _saveConflict(conflict);

        return SyncResult(
          success: false,
          conflicts: [conflict],
          syncedKeys: [],
          failedKeys: [],
          timestamp: DateTime.now(),
        );
      } else {
        // No conflict, use most recent data
        if (remoteTimestamp.isAfter(localTimestamp)) {
          await _storage.setString(key, jsonEncode(remoteData));
        } else {
          await _networkManager.uploadData(key, jsonDecode(localData));
        }

        await _updateMetadata(key, DateTime.now());

        return SyncResult(
          success: true,
          conflicts: [],
          syncedKeys: [key],
          failedKeys: [],
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        conflicts: [],
        syncedKeys: [],
        failedKeys: [key],
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> resolveConflict(
    SyncConflict conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.useLocal:
        if (conflict.localData != null) {
          await _networkManager.uploadData(conflict.key, conflict.localData!);
          await _updateMetadata(conflict.key, DateTime.now());
        }
        break;

      case ConflictResolution.useRemote:
        if (conflict.remoteData != null) {
          await _storage.setString(
            conflict.key,
            jsonEncode(conflict.remoteData!),
          );
          await _updateMetadata(conflict.key, DateTime.now());
        }
        break;

      case ConflictResolution.merge:
        // Simple merge strategy - combine non-conflicting fields
        final merged = _mergeData(conflict.localData, conflict.remoteData);
        await _storage.setString(conflict.key, jsonEncode(merged));
        await _networkManager.uploadData(conflict.key, merged);
        await _updateMetadata(conflict.key, DateTime.now());
        break;

      case ConflictResolution.userChoice:
        // This would typically involve showing UI to user
        // For now, default to using local data
        if (conflict.localData != null) {
          await _networkManager.uploadData(conflict.key, conflict.localData!);
          await _updateMetadata(conflict.key, DateTime.now());
        }
        break;
    }

    // Remove conflict from pending list
    _pendingConflicts.removeWhere((c) => c.key == conflict.key);
    await _removeConflict(conflict.key);

    // Remove from dirty keys
    _dirtyKeys.remove(conflict.key);
    await _saveDirtyKeys();
  }

  @override
  Future<void> handleNetworkRecovery() async {
    if (!_networkManager.isOnline) {
      return;
    }

    // Update status immediately when network is available
    if (_status == SyncStatus.offline) {
      _status = SyncStatus.idle;
    }

    // Cancel any existing recovery timer
    _recoveryTimer?.cancel();

    // Start recovery process after a short delay
    _recoveryTimer = Timer(const Duration(seconds: 2), () async {
      if (_dirtyKeys.isNotEmpty) {
        await synchronizeData();
      }
    });
  }

  @override
  SyncStatus get status => _status;

  @override
  Stream<SyncResult> get syncEvents => _syncController.stream;

  @override
  List<SyncConflict> get pendingConflicts =>
      List.unmodifiable(_pendingConflicts);

  @override
  Future<bool> needsSync(String key) async {
    return _dirtyKeys.contains(key);
  }

  @override
  Future<void> markDirty(String key) async {
    _dirtyKeys.add(key);
    await _saveDirtyKeys();
  }

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  Future<void> shutdown() async {
    _recoveryTimer?.cancel();
    _syncController.close();
    _isInitialized = false;
  }

  /// Check if there's a conflict between local and remote data
  bool _hasConflict(
    String localData,
    Map<String, dynamic> remoteData,
    DateTime localTimestamp,
    DateTime remoteTimestamp,
  ) {
    try {
      final localMap = jsonDecode(localData) as Map<String, dynamic>;

      // Remove timestamp fields for comparison
      final localCopy = Map<String, dynamic>.from(localMap);
      final remoteCopy = Map<String, dynamic>.from(remoteData);
      localCopy.remove('_timestamp');
      remoteCopy.remove('_timestamp');

      // If data is identical, no conflict
      if (_deepEquals(localCopy, remoteCopy)) {
        return false;
      }

      // If timestamps are very close (within 1 second), consider it the same update
      if ((localTimestamp.difference(remoteTimestamp).abs().inSeconds) < 1) {
        return false;
      }

      return true;
    } catch (e) {
      // If we can't parse, assume conflict
      return true;
    }
  }

  /// Deep equality check for maps
  bool _deepEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;

      final aValue = a[key];
      final bValue = b[key];

      if (aValue is Map && bValue is Map) {
        if (!_deepEquals(
          Map<String, dynamic>.from(aValue),
          Map<String, dynamic>.from(bValue),
        )) {
          return false;
        }
      } else if (aValue is List && bValue is List) {
        if (aValue.length != bValue.length) return false;
        for (int i = 0; i < aValue.length; i++) {
          if (aValue[i] != bValue[i]) return false;
        }
      } else if (aValue != bValue) {
        return false;
      }
    }

    return true;
  }

  /// Merge two data maps
  Map<String, dynamic> _mergeData(
    Map<String, dynamic>? local,
    Map<String, dynamic>? remote,
  ) {
    if (local == null) return remote ?? {};
    if (remote == null) return local;

    final merged = Map<String, dynamic>.from(local);

    for (final entry in remote.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      } else {
        // For conflicts, prefer remote data (last writer wins)
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  /// Get metadata for a key
  Future<SyncMetadata?> _getMetadata(String key) async {
    final metaJson = await _storage.getString('$_syncMetadataPrefix$key');
    if (metaJson == null) return null;

    try {
      final metaData = jsonDecode(metaJson) as Map<String, dynamic>;
      return SyncMetadata(
        key: key,
        lastModified: DateTime.parse(metaData['lastModified']),
        version: metaData['version'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Update metadata for a key
  Future<void> _updateMetadata(String key, DateTime timestamp) async {
    final metadata = SyncMetadata(
      key: key,
      lastModified: timestamp,
      version: _generateVersion(),
    );

    await _storage.setString(
      '$_syncMetadataPrefix$key',
      jsonEncode({
        'lastModified': metadata.lastModified.toIso8601String(),
        'version': metadata.version,
      }),
    );
  }

  /// Generate a version string
  String _generateVersion() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Load dirty keys from storage
  Future<void> _loadDirtyKeys() async {
    final dirtyJson = await _storage.getString(_dirtyKeysKey);
    if (dirtyJson != null) {
      try {
        final dirtyList = jsonDecode(dirtyJson) as List<dynamic>;
        _dirtyKeys.addAll(dirtyList.cast<String>());
      } catch (e) {
        // Ignore invalid data
      }
    }
  }

  /// Save dirty keys to storage
  Future<void> _saveDirtyKeys() async {
    await _storage.setString(_dirtyKeysKey, jsonEncode(_dirtyKeys.toList()));
  }

  /// Load pending conflicts from storage
  Future<void> _loadPendingConflicts() async {
    // This is a simplified implementation
    // In practice, we'd iterate through all conflict keys
  }

  /// Save a conflict to storage
  Future<void> _saveConflict(SyncConflict conflict) async {
    final conflictData = {
      'key': conflict.key,
      'type': conflict.type.name,
      'localData': conflict.localData,
      'remoteData': conflict.remoteData,
      'localTimestamp': conflict.localTimestamp.toIso8601String(),
      'remoteTimestamp': conflict.remoteTimestamp.toIso8601String(),
      'localVersion': conflict.localVersion,
      'remoteVersion': conflict.remoteVersion,
    };

    await _storage.setString(
      '$_conflictPrefix${conflict.key}',
      jsonEncode(conflictData),
    );
  }

  /// Remove a conflict from storage
  Future<void> _removeConflict(String key) async {
    await _storage.remove('$_conflictPrefix$key');
  }

  /// Load last sync time from storage
  Future<void> _loadLastSyncTime() async {
    final lastSyncJson = await _storage.getString(_lastSyncKey);
    if (lastSyncJson != null) {
      try {
        _lastSyncTime = DateTime.parse(lastSyncJson);
      } catch (e) {
        // Ignore invalid data
      }
    }
  }

  /// Save last sync time to storage
  Future<void> _saveLastSyncTime() async {
    if (_lastSyncTime != null) {
      await _storage.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isConnected) {
    if (isConnected && _status == SyncStatus.offline) {
      _status = SyncStatus.idle;
      handleNetworkRecovery();
    } else if (!isConnected) {
      _status = SyncStatus.offline;
    }
  }
}

/// Metadata for synchronized data
class SyncMetadata {
  final String key;
  final DateTime lastModified;
  final String version;

  const SyncMetadata({
    required this.key,
    required this.lastModified,
    required this.version,
  });
}
