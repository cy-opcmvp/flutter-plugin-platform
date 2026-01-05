/// Interface for application state management
abstract class IStateManager {
  /// Initialize the state manager
  Future<void> initialize();
  
  /// Save application state
  Future<void> saveState(String key, dynamic value);
  
  /// Load application state
  Future<T?> loadState<T>(String key);
  
  /// Clear all application state
  Future<void> clearState();
  
  /// Synchronize state across devices
  Future<void> syncState();
  
  /// Save plugin-specific state
  Future<void> savePluginState(String pluginId, Map<String, dynamic> state);
  
  /// Load plugin-specific state
  Future<Map<String, dynamic>?> loadPluginState(String pluginId);
  
  /// Clear plugin-specific state
  Future<void> clearPluginState(String pluginId);
  
  /// Get all plugin states
  Future<Map<String, Map<String, dynamic>>> getAllPluginStates();
  
  /// Stream of state changes
  Stream<StateChangeEvent> get stateChanges;
}

/// Event fired when state changes
class StateChangeEvent {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  const StateChangeEvent({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });
}