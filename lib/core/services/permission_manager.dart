import '../models/plugin_models.dart';
import '../models/external_plugin_models.dart';
import 'external_plugin_sandbox.dart' show AccessRequest;

/// Manages permissions for external plugins with granular access control
class PermissionManager {
  final Map<String, List<Permission>> _grantedPermissions = {};
  final Map<String, List<PermissionRequest>> _pendingRequests = {};
  final Map<Permission, PermissionPolicy> _permissionPolicies = {};

  PermissionManager() {
    _initializeDefaultPolicies();
  }

  /// Grant permissions to a plugin
  void grantPermissions(String pluginId, List<Permission> permissions) {
    _grantedPermissions[pluginId] = List.from(permissions);
  }

  /// Revoke specific permissions from a plugin
  void revokePermissions(String pluginId, List<Permission> permissions) {
    final granted = _grantedPermissions[pluginId];
    if (granted != null) {
      granted.removeWhere((p) => permissions.contains(p));
    }
  }

  /// Revoke all permissions from a plugin
  void revokeAllPermissions(String pluginId) {
    _grantedPermissions.remove(pluginId);
    _pendingRequests.remove(pluginId);
  }

  /// Check if plugin has specific permission
  bool hasPermission(String pluginId, Permission permission) {
    final granted = _grantedPermissions[pluginId];
    return granted?.contains(permission) ?? false;
  }

  /// Get all permissions granted to a plugin
  List<Permission> getGrantedPermissions(String pluginId) {
    return List.from(_grantedPermissions[pluginId] ?? []);
  }

  /// Request permission for a plugin (runtime permission checking)
  Future<PermissionResult> requestPermission(
    String pluginId,
    Permission permission, {
    String? justification,
  }) async {
    // Check if already granted
    if (hasPermission(pluginId, permission)) {
      return PermissionResult.granted;
    }

    // Check permission policy
    final policy = _permissionPolicies[permission];
    if (policy == null) {
      return PermissionResult.denied;
    }

    // Apply policy rules
    final policyResult = await _applyPermissionPolicy(
      pluginId,
      permission,
      policy,
    );
    if (policyResult != PermissionResult.granted) {
      return policyResult;
    }

    // For sensitive permissions, require explicit user consent
    if (_isSensitivePermission(permission)) {
      return await _requestUserConsent(pluginId, permission, justification);
    }

    // Auto-grant non-sensitive permissions
    _grantPermissions(pluginId, [permission]);
    return PermissionResult.granted;
  }

  /// Validate access request with comprehensive permission checking
  Future<bool> validateAccess(String pluginId, AccessRequest request) async {
    // Basic permission check
    if (!hasPermission(pluginId, request.permission)) {
      return false;
    }

    // Apply permission-specific validation
    return await _validatePermissionSpecificAccess(pluginId, request);
  }

  /// Get permission policy for a specific permission
  PermissionPolicy? getPermissionPolicy(Permission permission) {
    return _permissionPolicies[permission];
  }

  /// Set permission policy for a specific permission
  void setPermissionPolicy(Permission permission, PermissionPolicy policy) {
    _permissionPolicies[permission] = policy;
  }

  /// Get all pending permission requests for a plugin
  List<PermissionRequest> getPendingRequests(String pluginId) {
    return List.from(_pendingRequests[pluginId] ?? []);
  }

  /// Approve a pending permission request
  Future<void> approvePendingRequest(String pluginId, String requestId) async {
    final requests = _pendingRequests[pluginId];
    if (requests != null) {
      final request = requests.where((r) => r.id == requestId).firstOrNull;
      if (request != null) {
        _grantPermissions(pluginId, [request.permission]);
        requests.remove(request);
      }
    }
  }

  /// Deny a pending permission request
  Future<void> denyPendingRequest(String pluginId, String requestId) async {
    final requests = _pendingRequests[pluginId];
    if (requests != null) {
      requests.removeWhere((r) => r.id == requestId);
    }
  }

  /// Check if permission group is granted
  bool hasPermissionGroup(String pluginId, PermissionGroup group) {
    final requiredPermissions = _getPermissionsForGroup(group);
    return requiredPermissions.every((p) => hasPermission(pluginId, p));
  }

  /// Grant permission group to plugin
  void grantPermissionGroup(String pluginId, PermissionGroup group) {
    final permissions = _getPermissionsForGroup(group);
    _grantPermissions(pluginId, permissions);
  }

  // Private helper methods

  /// Initialize default permission policies
  void _initializeDefaultPolicies() {
    // File system permissions
    _permissionPolicies[Permission.fileSystemRead] = const PermissionPolicy(
      requiresUserConsent: false,
      allowedSecurityLevels: SecurityLevel.values,
      restrictions: ['sandbox/*', 'temp/*', 'data/*'],
    );

    _permissionPolicies[Permission.fileSystemWrite] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: ['sandbox/*', 'temp/*', 'data/*'],
    );

    _permissionPolicies[Permission.fileSystemExecute] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal],
      restrictions: ['sandbox/*'],
    );

    // Network permissions
    _permissionPolicies[Permission.networkAccess] = const PermissionPolicy(
      requiresUserConsent: false,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    _permissionPolicies[Permission.networkServer] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    _permissionPolicies[Permission.networkClient] = const PermissionPolicy(
      requiresUserConsent: false,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    // System permissions
    _permissionPolicies[Permission.systemNotifications] =
        const PermissionPolicy(
          requiresUserConsent: true,
          allowedSecurityLevels: SecurityLevel.values,
          restrictions: [],
        );

    _permissionPolicies[Permission.systemClipboard] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    _permissionPolicies[Permission.systemCamera] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    _permissionPolicies[Permission.systemMicrophone] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    // Platform permissions
    _permissionPolicies[Permission.platformServices] = const PermissionPolicy(
      requiresUserConsent: false,
      allowedSecurityLevels: SecurityLevel.values,
      restrictions: [],
    );

    _permissionPolicies[Permission.platformUI] = const PermissionPolicy(
      requiresUserConsent: false,
      allowedSecurityLevels: SecurityLevel.values,
      restrictions: [],
    );

    _permissionPolicies[Permission.platformStorage] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );

    // Inter-plugin permissions
    _permissionPolicies[Permission.pluginCommunication] =
        const PermissionPolicy(
          requiresUserConsent: false,
          allowedSecurityLevels: SecurityLevel.values,
          restrictions: [],
        );

    _permissionPolicies[Permission.pluginDataSharing] = const PermissionPolicy(
      requiresUserConsent: true,
      allowedSecurityLevels: [SecurityLevel.minimal, SecurityLevel.standard],
      restrictions: [],
    );
  }

  /// Apply permission policy rules
  Future<PermissionResult> _applyPermissionPolicy(
    String pluginId,
    Permission permission,
    PermissionPolicy policy,
  ) async {
    // This would integrate with plugin security level checking
    // For now, return granted if policy allows it
    return PermissionResult.granted;
  }

  /// Check if permission is sensitive and requires user consent
  bool _isSensitivePermission(Permission permission) {
    final policy = _permissionPolicies[permission];
    return policy?.requiresUserConsent ?? true;
  }

  /// Request user consent for sensitive permissions
  Future<PermissionResult> _requestUserConsent(
    String pluginId,
    Permission permission,
    String? justification,
  ) async {
    // Create pending request
    final request = PermissionRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pluginId: pluginId,
      permission: permission,
      justification: justification,
      timestamp: DateTime.now(),
    );

    _pendingRequests.putIfAbsent(pluginId, () => []).add(request);

    // In a real implementation, this would show a user dialog
    // For now, return pending
    return PermissionResult.pending;
  }

  /// Grant permissions internally
  void _grantPermissions(String pluginId, List<Permission> permissions) {
    _grantedPermissions.putIfAbsent(pluginId, () => []).addAll(permissions);
  }

  /// Validate permission-specific access rules
  Future<bool> _validatePermissionSpecificAccess(
    String pluginId,
    AccessRequest request,
  ) async {
    final policy = _permissionPolicies[request.permission];
    if (policy == null) return true;

    // Check resource restrictions
    if (policy.restrictions.isNotEmpty) {
      final resource = request.resource;
      final allowed = policy.restrictions.any((restriction) {
        if (restriction.endsWith('*')) {
          return resource.startsWith(
            restriction.substring(0, restriction.length - 1),
          );
        }
        return resource == restriction;
      });

      if (!allowed) return false;
    }

    return true;
  }

  /// Get permissions for a permission group
  List<Permission> _getPermissionsForGroup(PermissionGroup group) {
    switch (group) {
      case PermissionGroup.fileSystem:
        return [
          Permission.fileSystemRead,
          Permission.fileSystemWrite,
          Permission.fileSystemExecute,
        ];
      case PermissionGroup.network:
        return [
          Permission.networkAccess,
          Permission.networkClient,
          Permission.networkServer,
        ];
      case PermissionGroup.system:
        return [
          Permission.systemNotifications,
          Permission.systemClipboard,
          Permission.systemCamera,
          Permission.systemMicrophone,
        ];
      case PermissionGroup.platform:
        return [
          Permission.platformServices,
          Permission.platformUI,
          Permission.platformStorage,
        ];
      case PermissionGroup.interPlugin:
        return [Permission.pluginCommunication, Permission.pluginDataSharing];
    }
  }
}

/// Permission request for user consent
class PermissionRequest {
  final String id;
  final String pluginId;
  final Permission permission;
  final String? justification;
  final DateTime timestamp;

  const PermissionRequest({
    required this.id,
    required this.pluginId,
    required this.permission,
    this.justification,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pluginId': pluginId,
      'permission': permission.name,
      'justification': justification,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'] as String,
      pluginId: json['pluginId'] as String,
      permission: Permission.values.firstWhere(
        (e) => e.name == json['permission'],
      ),
      justification: json['justification'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Permission policy configuration
class PermissionPolicy {
  final bool requiresUserConsent;
  final List<SecurityLevel> allowedSecurityLevels;
  final List<String> restrictions;
  final Duration? timeLimit;
  final int? usageLimit;

  const PermissionPolicy({
    required this.requiresUserConsent,
    required this.allowedSecurityLevels,
    required this.restrictions,
    this.timeLimit,
    this.usageLimit,
  });

  /// Check if policy allows permission for security level
  bool allowsSecurityLevel(SecurityLevel level) {
    return allowedSecurityLevels.contains(level);
  }

  /// Check if resource is allowed by policy
  bool allowsResource(String resource) {
    if (restrictions.isEmpty) return true;

    return restrictions.any((restriction) {
      if (restriction.endsWith('*')) {
        return resource.startsWith(
          restriction.substring(0, restriction.length - 1),
        );
      }
      return resource == restriction;
    });
  }
}

/// Result of permission request
enum PermissionResult { granted, denied, pending, restricted }

/// Permission groups for easier management
enum PermissionGroup { fileSystem, network, system, platform, interPlugin }
