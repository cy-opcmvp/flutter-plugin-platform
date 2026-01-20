/// Descriptor containing plugin metadata
class PluginDescriptor {
  final String id;
  final String name;
  final String version;
  final PluginType type;
  final List<Permission> requiredPermissions;
  final Map<String, dynamic> metadata;
  final String entryPoint;
  final Set<String> tags; // 插件标签ID集合

  const PluginDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.requiredPermissions,
    required this.metadata,
    required this.entryPoint,
    this.tags = const {},
  });

  /// Validates the plugin descriptor for data integrity
  bool isValid() {
    // ID must be non-empty and follow reverse domain notation
    if (id.isEmpty || !RegExp(r'^[a-z0-9]+(\.[a-z0-9]+)*$').hasMatch(id)) {
      return false;
    }

    // Name must be non-empty
    if (name.trim().isEmpty) {
      return false;
    }

    // Version must follow semantic versioning pattern
    if (!RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$').hasMatch(version)) {
      return false;
    }

    // Entry point must be non-empty
    if (entryPoint.trim().isEmpty) {
      return false;
    }

    return true;
  }

  factory PluginDescriptor.fromJson(Map<String, dynamic> json) {
    final descriptor = PluginDescriptor(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      type: PluginType.values.firstWhere((e) => e.name == json['type']),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((e) => Permission.values.firstWhere((p) => p.name == e))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>,
      entryPoint: json['entryPoint'] as String,
      tags: json['tags'] != null
          ? (json['tags'] as List).cast<String>().toSet()
          : const {},
    );

    if (!descriptor.isValid()) {
      throw ArgumentError('Invalid plugin descriptor data');
    }

    return descriptor;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type.name,
      'requiredPermissions': requiredPermissions.map((e) => e.name).toList(),
      'metadata': metadata,
      'entryPoint': entryPoint,
      'tags': tags.toList(),
    };
  }
}

/// Current state of a plugin
enum PluginState { inactive, loading, active, paused, error }

/// Type of plugin
enum PluginType { tool, game }

/// Permissions that plugins can request
enum Permission {
  // File system permissions
  fileSystemRead,
  fileSystemWrite,
  fileSystemExecute,

  // Network permissions
  networkAccess,
  networkServer,
  networkClient,

  // System permissions
  systemNotifications,
  systemClipboard,
  systemCamera,
  systemMicrophone,

  // Platform permissions
  platformServices,
  platformUI,
  platformStorage,

  // Inter-plugin permissions
  pluginCommunication,
  pluginDataSharing,

  // Legacy permissions for backward compatibility
  fileAccess,
  notifications,
  camera,
  microphone,
  location,
  storage,
}

/// Plugin state management class that tracks plugin lifecycle and state transitions
class PluginStateManager {
  final String pluginId;
  PluginState _currentState;
  final Map<String, dynamic> _stateData;
  final List<PluginStateTransition> _stateHistory;
  DateTime _lastStateChange;

  PluginStateManager({
    required this.pluginId,
    PluginState initialState = PluginState.inactive,
    Map<String, dynamic>? initialStateData,
  }) : _currentState = initialState,
       _stateData = initialStateData ?? {},
       _stateHistory = [],
       _lastStateChange = DateTime.now();

  /// Current state of the plugin
  PluginState get currentState => _currentState;

  /// Current state data
  Map<String, dynamic> get stateData => Map.unmodifiable(_stateData);

  /// State transition history
  List<PluginStateTransition> get stateHistory =>
      List.unmodifiable(_stateHistory);

  /// Last time the state was changed
  DateTime get lastStateChange => _lastStateChange;

  /// Validates if a state transition is allowed
  bool canTransitionTo(PluginState newState) {
    switch (_currentState) {
      case PluginState.inactive:
        return newState == PluginState.loading;
      case PluginState.loading:
        return newState == PluginState.active ||
            newState == PluginState.error ||
            newState == PluginState.inactive;
      case PluginState.active:
        return newState == PluginState.paused ||
            newState == PluginState.inactive ||
            newState == PluginState.error;
      case PluginState.paused:
        return newState == PluginState.active ||
            newState == PluginState.inactive ||
            newState == PluginState.error;
      case PluginState.error:
        return newState == PluginState.inactive ||
            newState == PluginState.loading;
    }
  }

  /// Transitions to a new state if the transition is valid
  bool transitionTo(
    PluginState newState, {
    Map<String, dynamic>? newStateData,
  }) {
    if (!canTransitionTo(newState)) {
      return false;
    }

    final transition = PluginStateTransition(
      fromState: _currentState,
      toState: newState,
      timestamp: DateTime.now(),
      pluginId: pluginId,
    );

    _stateHistory.add(transition);
    _currentState = newState;
    _lastStateChange = transition.timestamp;

    if (newStateData != null) {
      _stateData.clear();
      _stateData.addAll(newStateData);
    }

    return true;
  }

  /// Updates state data without changing the state
  void updateStateData(Map<String, dynamic> data) {
    _stateData.clear();
    _stateData.addAll(data);
  }

  /// Serializes the state manager to JSON
  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'currentState': _currentState.name,
      'stateData': _stateData,
      'lastStateChange': _lastStateChange.toIso8601String(),
      'stateHistory': _stateHistory.map((t) => t.toJson()).toList(),
    };
  }

  /// Creates a state manager from JSON
  factory PluginStateManager.fromJson(Map<String, dynamic> json) {
    final manager = PluginStateManager(
      pluginId: json['pluginId'] as String,
      initialState: PluginState.values.firstWhere(
        (e) => e.name == json['currentState'],
      ),
      initialStateData: json['stateData'] as Map<String, dynamic>?,
    );

    manager._lastStateChange = DateTime.parse(
      json['lastStateChange'] as String,
    );

    final historyList = json['stateHistory'] as List<dynamic>;
    for (final historyJson in historyList) {
      manager._stateHistory.add(
        PluginStateTransition.fromJson(historyJson as Map<String, dynamic>),
      );
    }

    return manager;
  }
}

/// Represents a state transition event
class PluginStateTransition {
  final PluginState fromState;
  final PluginState toState;
  final DateTime timestamp;
  final String pluginId;
  final String? reason;

  const PluginStateTransition({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    required this.pluginId,
    this.reason,
  });

  /// Serializes the transition to JSON
  Map<String, dynamic> toJson() {
    return {
      'fromState': fromState.name,
      'toState': toState.name,
      'timestamp': timestamp.toIso8601String(),
      'pluginId': pluginId,
      'reason': reason,
    };
  }

  /// Creates a transition from JSON
  factory PluginStateTransition.fromJson(Map<String, dynamic> json) {
    return PluginStateTransition(
      fromState: PluginState.values.firstWhere(
        (e) => e.name == json['fromState'],
      ),
      toState: PluginState.values.firstWhere((e) => e.name == json['toState']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      pluginId: json['pluginId'] as String,
      reason: json['reason'] as String?,
    );
  }
}

/// Plugin runtime information combining descriptor and state
class PluginRuntimeInfo {
  final PluginDescriptor descriptor;
  final PluginStateManager stateManager;
  final DateTime loadTime;
  final Map<String, dynamic> runtimeMetadata;

  PluginRuntimeInfo({
    required this.descriptor,
    required this.stateManager,
    DateTime? loadTime,
    Map<String, dynamic>? runtimeMetadata,
  }) : loadTime = loadTime ?? DateTime.now(),
       runtimeMetadata = runtimeMetadata ?? {};

  /// Current state of the plugin
  PluginState get currentState => stateManager.currentState;

  /// Plugin ID
  String get pluginId => descriptor.id;

  /// Plugin name
  String get pluginName => descriptor.name;

  /// Plugin type
  PluginType get pluginType => descriptor.type;

  /// Checks if the plugin is currently active
  bool get isActive => currentState == PluginState.active;

  /// Checks if the plugin is in an error state
  bool get hasError => currentState == PluginState.error;

  /// Serializes the runtime info to JSON
  Map<String, dynamic> toJson() {
    return {
      'descriptor': descriptor.toJson(),
      'stateManager': stateManager.toJson(),
      'loadTime': loadTime.toIso8601String(),
      'runtimeMetadata': runtimeMetadata,
    };
  }

  /// Creates runtime info from JSON
  factory PluginRuntimeInfo.fromJson(Map<String, dynamic> json) {
    return PluginRuntimeInfo(
      descriptor: PluginDescriptor.fromJson(
        json['descriptor'] as Map<String, dynamic>,
      ),
      stateManager: PluginStateManager.fromJson(
        json['stateManager'] as Map<String, dynamic>,
      ),
      loadTime: DateTime.parse(json['loadTime'] as String),
      runtimeMetadata: json['runtimeMetadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
