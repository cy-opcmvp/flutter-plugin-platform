import 'dart:async';
import 'dart:math';
import '../models/plugin_models.dart';
import 'plugin_manager.dart';

/// Resource limits for plugin execution
class ResourceLimits {
  final int maxMemoryMB;
  final int maxCpuTimeMs;
  final int maxNetworkRequests;
  final int maxFileOperations;
  final Duration maxExecutionTime;

  const ResourceLimits({
    this.maxMemoryMB = 100,
    this.maxCpuTimeMs = 5000,
    this.maxNetworkRequests = 50,
    this.maxFileOperations = 20,
    this.maxExecutionTime = const Duration(seconds: 30),
  });

  /// Create resource limits based on security level
  factory ResourceLimits.fromSecurityLevel(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return const ResourceLimits(
          maxMemoryMB: 200,
          maxCpuTimeMs: 10000,
          maxNetworkRequests: 100,
          maxFileOperations: 50,
          maxExecutionTime: Duration(minutes: 1),
        );
      case SecurityLevel.medium:
        return const ResourceLimits(
          maxMemoryMB: 100,
          maxCpuTimeMs: 5000,
          maxNetworkRequests: 50,
          maxFileOperations: 20,
          maxExecutionTime: Duration(seconds: 30),
        );
      case SecurityLevel.high:
        return const ResourceLimits(
          maxMemoryMB: 50,
          maxCpuTimeMs: 2000,
          maxNetworkRequests: 20,
          maxFileOperations: 10,
          maxExecutionTime: Duration(seconds: 15),
        );
      case SecurityLevel.critical:
        return const ResourceLimits(
          maxMemoryMB: 25,
          maxCpuTimeMs: 1000,
          maxNetworkRequests: 5,
          maxFileOperations: 5,
          maxExecutionTime: Duration(seconds: 5),
        );
    }
  }
}

/// Resource usage tracking
class ResourceUsage {
  int memoryUsageMB = 0;
  int cpuTimeMs = 0;
  int networkRequests = 0;
  int fileOperations = 0;
  DateTime startTime = DateTime.now();

  /// Check if usage exceeds limits
  bool exceedsLimits(ResourceLimits limits) {
    final executionTime = DateTime.now().difference(startTime);
    
    return memoryUsageMB > limits.maxMemoryMB ||
           cpuTimeMs > limits.maxCpuTimeMs ||
           networkRequests > limits.maxNetworkRequests ||
           fileOperations > limits.maxFileOperations ||
           executionTime > limits.maxExecutionTime;
  }

  /// Get usage as percentage of limits
  Map<String, double> getUsagePercentages(ResourceLimits limits) {
    final executionTime = DateTime.now().difference(startTime);
    
    return {
      'memory': (memoryUsageMB / limits.maxMemoryMB) * 100,
      'cpu': (cpuTimeMs / limits.maxCpuTimeMs) * 100,
      'network': (networkRequests / limits.maxNetworkRequests) * 100,
      'fileOps': (fileOperations / limits.maxFileOperations) * 100,
      'time': (executionTime.inMilliseconds / limits.maxExecutionTime.inMilliseconds) * 100,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'memoryUsageMB': memoryUsageMB,
      'cpuTimeMs': cpuTimeMs,
      'networkRequests': networkRequests,
      'fileOperations': fileOperations,
      'startTime': startTime.toIso8601String(),
    };
  }
}

/// Security violation types
enum SecurityViolationType {
  unauthorizedPermission,
  resourceLimitExceeded,
  maliciousActivity,
  invalidOperation,
  sandboxEscape
}

/// Security violation record
class SecurityViolation {
  final SecurityViolationType type;
  final String description;
  final DateTime timestamp;
  final String pluginId;
  final Map<String, dynamic> details;

  const SecurityViolation({
    required this.type,
    required this.description,
    required this.timestamp,
    required this.pluginId,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'pluginId': pluginId,
      'details': details,
    };
  }
}

/// Plugin sandbox for secure execution
class PluginSandbox {
  final String pluginId;
  final Set<Permission> allowedPermissions;
  final ResourceLimits limits;
  final ResourceUsage _usage = ResourceUsage();
  final List<SecurityViolation> _violations = [];
  final StreamController<SecurityViolation> _violationController = StreamController<SecurityViolation>.broadcast();
  
  bool _isActive = false;
  Timer? _resourceMonitor;

  PluginSandbox({
    required this.pluginId,
    required this.allowedPermissions,
    required this.limits,
  });

  /// Stream of security violations
  Stream<SecurityViolation> get violationStream => _violationController.stream;

  /// Get current resource usage
  ResourceUsage get resourceUsage => _usage;

  /// Get security violations
  List<SecurityViolation> get violations => List.unmodifiable(_violations);

  /// Check if sandbox is active
  bool get isActive => _isActive;

  /// Start the sandbox
  void start() {
    if (_isActive) return;
    
    _isActive = true;
    _usage.startTime = DateTime.now();
    
    // Start resource monitoring
    _resourceMonitor = Timer.periodic(const Duration(seconds: 1), _monitorResources);
  }

  /// Stop the sandbox
  void stop() {
    if (!_isActive) return;
    
    _isActive = false;
    _resourceMonitor?.cancel();
    _resourceMonitor = null;
  }

  /// Execute operation within sandbox with permission and resource checks
  Future<T> executeInSandbox<T>(Future<T> Function() operation, {
    Permission? requiredPermission,
    String? operationDescription,
  }) async {
    if (!_isActive) {
      throw SandboxException('Sandbox is not active', pluginId);
    }

    // Check permission if required
    if (requiredPermission != null && !hasPermission(requiredPermission)) {
      final violation = SecurityViolation(
        type: SecurityViolationType.unauthorizedPermission,
        description: 'Plugin attempted to use ${requiredPermission.name} without permission',
        timestamp: DateTime.now(),
        pluginId: pluginId,
        details: {
          'permission': requiredPermission.name,
          'operation': operationDescription ?? 'unknown',
        },
      );
      _recordViolation(violation);
      throw SandboxException('Permission ${requiredPermission.name} not granted', pluginId);
    }

    // Check resource limits before execution
    if (_usage.exceedsLimits(limits)) {
      final violation = SecurityViolation(
        type: SecurityViolationType.resourceLimitExceeded,
        description: 'Plugin exceeded resource limits',
        timestamp: DateTime.now(),
        pluginId: pluginId,
        details: {
          'usage': _usage.toJson(),
          'limits': {
            'maxMemoryMB': limits.maxMemoryMB,
            'maxCpuTimeMs': limits.maxCpuTimeMs,
            'maxNetworkRequests': limits.maxNetworkRequests,
            'maxFileOperations': limits.maxFileOperations,
            'maxExecutionTime': limits.maxExecutionTime.inMilliseconds,
          },
        },
      );
      _recordViolation(violation);
      throw SandboxException('Resource limits exceeded', pluginId);
    }

    try {
      final startTime = DateTime.now();
      final result = await operation();
      final executionTime = DateTime.now().difference(startTime);
      
      // Update resource usage
      _usage.cpuTimeMs += executionTime.inMilliseconds;
      
      // Track specific operation types
      if (requiredPermission == Permission.networkAccess) {
        _usage.networkRequests++;
      } else if (requiredPermission == Permission.fileAccess) {
        _usage.fileOperations++;
      }
      
      return result;
    } catch (e) {
      // Log potential security issues
      if (e.toString().contains('security') || e.toString().contains('unauthorized')) {
        final violation = SecurityViolation(
          type: SecurityViolationType.maliciousActivity,
          description: 'Potential security violation during operation execution',
          timestamp: DateTime.now(),
          pluginId: pluginId,
          details: {
            'error': e.toString(),
            'operation': operationDescription ?? 'unknown',
          },
        );
        _recordViolation(violation);
      }
      rethrow;
    }
  }

  /// Check if plugin has a specific permission
  bool hasPermission(Permission permission) {
    return allowedPermissions.contains(permission);
  }

  /// Validate plugin operation
  bool validateOperation(String operation, Map<String, dynamic> parameters) {
    // Basic operation validation
    if (operation.isEmpty) return false;
    
    // Check for potentially dangerous operations
    final dangerousOperations = [
      'eval',
      'exec',
      'system',
      'shell',
      'process',
      'file_write_system',
      'network_raw_socket',
    ];
    
    if (dangerousOperations.any((dangerous) => operation.toLowerCase().contains(dangerous))) {
      final violation = SecurityViolation(
        type: SecurityViolationType.maliciousActivity,
        description: 'Plugin attempted dangerous operation: $operation',
        timestamp: DateTime.now(),
        pluginId: pluginId,
        details: {
          'operation': operation,
          'parameters': parameters,
        },
      );
      _recordViolation(violation);
      return false;
    }
    
    return true;
  }

  /// Monitor resource usage
  void _monitorResources(Timer timer) {
    if (!_isActive) {
      timer.cancel();
      return;
    }

    // Simulate memory usage tracking (in a real implementation, this would use actual metrics)
    _usage.memoryUsageMB = _simulateMemoryUsage();
    
    // Check if limits are exceeded
    if (_usage.exceedsLimits(limits)) {
      final violation = SecurityViolation(
        type: SecurityViolationType.resourceLimitExceeded,
        description: 'Plugin exceeded resource limits during monitoring',
        timestamp: DateTime.now(),
        pluginId: pluginId,
        details: {
          'usage': _usage.toJson(),
          'usagePercentages': _usage.getUsagePercentages(limits),
        },
      );
      _recordViolation(violation);
      
      // Force stop the sandbox
      stop();
    }
  }

  /// Simulate memory usage (in a real implementation, this would use actual metrics)
  int _simulateMemoryUsage() {
    // Simulate gradual memory increase with some randomness
    final random = Random();
    final baseUsage = DateTime.now().difference(_usage.startTime).inSeconds;
    final randomFactor = random.nextDouble() * 10;
    return (baseUsage + randomFactor).round().clamp(0, limits.maxMemoryMB + 50);
  }

  /// Record a security violation
  void _recordViolation(SecurityViolation violation) {
    _violations.add(violation);
    _violationController.add(violation);
  }

  /// Dispose the sandbox
  Future<void> dispose() async {
    stop();
    await _violationController.close();
  }
}

/// Permission-based access control system
class PermissionManager {
  final Map<String, Set<Permission>> _pluginPermissions = {};
  final Map<Permission, List<String>> _permissionRequests = {};
  final StreamController<PermissionEvent> _eventController = StreamController<PermissionEvent>.broadcast();

  /// Stream of permission events
  Stream<PermissionEvent> get eventStream => _eventController.stream;

  /// Grant permissions to a plugin
  void grantPermissions(String pluginId, Set<Permission> permissions) {
    _pluginPermissions.putIfAbsent(pluginId, () => <Permission>{});
    _pluginPermissions[pluginId]!.addAll(permissions);
    
    for (final permission in permissions) {
      _eventController.add(PermissionEvent(
        pluginId: pluginId,
        permission: permission,
        granted: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Revoke permissions from a plugin
  void revokePermissions(String pluginId, Set<Permission> permissions) {
    final currentPermissions = _pluginPermissions[pluginId];
    if (currentPermissions != null) {
      currentPermissions.removeAll(permissions);
      
      for (final permission in permissions) {
        _eventController.add(PermissionEvent(
          pluginId: pluginId,
          permission: permission,
          granted: false,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// Check if plugin has permission
  bool hasPermission(String pluginId, Permission permission) {
    return _pluginPermissions[pluginId]?.contains(permission) ?? false;
  }

  /// Get all permissions for a plugin
  Set<Permission> getPermissions(String pluginId) {
    return Set.from(_pluginPermissions[pluginId] ?? {});
  }

  /// Request permission for a plugin
  Future<bool> requestPermission(String pluginId, Permission permission) async {
    // Add to request queue
    _permissionRequests.putIfAbsent(permission, () => []).add(pluginId);
    
    // In a real implementation, this would show a user dialog
    // For now, we'll auto-grant based on permission type
    final shouldGrant = _shouldAutoGrant(permission);
    
    if (shouldGrant) {
      grantPermissions(pluginId, {permission});
    }
    
    return shouldGrant;
  }

  /// Auto-grant logic for permissions
  bool _shouldAutoGrant(Permission permission) {
    switch (permission) {
      case Permission.notifications:
      case Permission.systemNotifications:
      case Permission.storage:
      case Permission.platformStorage:
        return true; // Generally safe permissions
      case Permission.networkAccess:
      case Permission.networkClient:
      case Permission.networkServer:
        return true; // Common requirement
      case Permission.platformServices:
      case Permission.platformUI:
      case Permission.systemClipboard:
      case Permission.pluginCommunication:
      case Permission.pluginDataSharing:
        return true; // Generally safe platform permissions
      case Permission.fileAccess:
      case Permission.fileSystemRead:
      case Permission.fileSystemWrite:
      case Permission.fileSystemExecute:
      case Permission.camera:
      case Permission.systemCamera:
      case Permission.microphone:
      case Permission.systemMicrophone:
      case Permission.location:
        return false; // Require explicit user consent
    }
  }

  /// Remove all permissions for a plugin
  void removePlugin(String pluginId) {
    _pluginPermissions.remove(pluginId);
    
    // Remove from request queues
    for (final requests in _permissionRequests.values) {
      requests.removeWhere((id) => id == pluginId);
    }
  }

  /// Dispose the permission manager
  Future<void> dispose() async {
    await _eventController.close();
  }
}

/// Exception thrown by sandbox operations
class SandboxException implements Exception {
  final String message;
  final String pluginId;

  const SandboxException(this.message, this.pluginId);

  @override
  String toString() => 'SandboxException: $message (Plugin: $pluginId)';
}

/// Permission event for tracking permission changes
class PermissionEvent {
  final String pluginId;
  final Permission permission;
  final bool granted;
  final DateTime timestamp;

  const PermissionEvent({
    required this.pluginId,
    required this.permission,
    required this.granted,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'permission': permission.name,
      'granted': granted,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}