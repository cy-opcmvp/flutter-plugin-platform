import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/external_plugin_models.dart';
import '../models/plugin_models.dart';
import 'permission_manager.dart';
import 'security_monitor.dart';

/// Comprehensive sandbox for external plugin security and resource management
class PluginSandbox {
  final String pluginId;
  final SecurityLevel securityLevel;
  final ResourceLimits resourceLimits;
  final List<Permission> allowedPermissions;
  final NetworkPolicy _networkPolicy;
  final PermissionManager _permissionManager;
  final SecurityMonitor _securityMonitor;

  // Internal state
  bool _isActive = false;
  DateTime? _createdAt;
  String? _sandboxPath;
  ResourceMonitor? _resourceMonitor;

  PluginSandbox({
    required this.pluginId,
    required this.securityLevel,
    required this.resourceLimits,
    required this.allowedPermissions,
    NetworkPolicy? networkPolicy,
    PermissionManager? permissionManager,
    SecurityMonitor? securityMonitor,
  }) : _networkPolicy =
           networkPolicy ?? NetworkPolicy.fromSecurityLevel(securityLevel),
       _permissionManager = permissionManager ?? PermissionManager(),
       _securityMonitor = securityMonitor ?? SecurityMonitor() {
    // Grant initial permissions to the plugin
    _permissionManager.grantPermissions(pluginId, allowedPermissions);

    // Start security monitoring
    _securityMonitor.startMonitoring(pluginId, securityLevel);
  }

  /// Check if sandbox is currently active
  bool get isActive => _isActive;

  /// Get sandbox creation time
  DateTime? get createdAt => _createdAt;

  /// Get sandbox file system path
  String? get sandboxPath => _sandboxPath;

  /// Get security monitor for this sandbox
  SecurityMonitor get securityMonitor => _securityMonitor;

  /// Create isolated sandbox environment with comprehensive security controls
  Future<void> createSandbox() async {
    if (_isActive) {
      throw SandboxException('Sandbox already active for plugin $pluginId');
    }

    try {
      _createdAt = DateTime.now();

      // Create isolated file system
      await _createIsolatedFileSystem();

      // Configure network policies
      await _configureNetworkPolicy();

      // Apply resource limits
      await _applyResourceLimits();

      // Setup permission enforcement
      await _setupPermissionEnforcement();

      // Initialize resource monitoring
      await _initializeResourceMonitoring();

      _isActive = true;
    } catch (e) {
      await _cleanup();
      throw SandboxException(
        'Failed to create sandbox for plugin $pluginId: $e',
      );
    }
  }

  /// Validate access request against permissions and security policies
  Future<bool> validateAccess(AccessRequest request) async {
    if (!_isActive) {
      return false;
    }

    try {
      // Use permission manager for comprehensive validation
      if (!await _permissionManager.validateAccess(pluginId, request)) {
        _logSecurityViolation('Permission denied', request);
        _securityMonitor.logAccessViolation(
          pluginId,
          request.permission,
          request.resource,
          'Permission denied',
        );
        return false;
      }

      // Validate resource usage
      if (!await _withinResourceLimits(request)) {
        _logSecurityViolation('Resource limit exceeded', request);
        _securityMonitor.logAccessViolation(
          pluginId,
          request.permission,
          request.resource,
          'Resource limit exceeded',
        );
        return false;
      }

      // Apply security policies
      if (!await _applySecurityPolicies(request)) {
        _logSecurityViolation('Security policy violation', request);
        _securityMonitor.logPolicyViolation(
          pluginId,
          'Security policy',
          'Access to ${request.resource} denied by security policy',
        );
        return false;
      }

      // Apply network policies if applicable
      if (_isNetworkRequest(request) && !await _applyNetworkPolicies(request)) {
        _logSecurityViolation('Network policy violation', request);
        _securityMonitor.logPolicyViolation(
          pluginId,
          'Network policy',
          'Network access to ${request.resource} denied by network policy',
        );
        return false;
      }

      return true;
    } catch (e) {
      _logSecurityViolation('Access validation error: $e', request);
      return false;
    }
  }

  /// Monitor current resource usage
  Future<ResourceUsage> getResourceUsage() async {
    if (!_isActive || _resourceMonitor == null) {
      throw const SandboxException(
        'Sandbox not active or resource monitor not initialized',
      );
    }

    return await _resourceMonitor!.getCurrentUsage();
  }

  /// Enforce resource limits and terminate if exceeded
  Future<void> enforceResourceLimits() async {
    if (!_isActive) {
      return;
    }

    try {
      final usage = await getResourceUsage();

      if (usage.memoryMB > resourceLimits.maxMemoryMB) {
        _securityMonitor.logResourceViolation(
          pluginId,
          'memory',
          usage.memoryMB,
          resourceLimits.maxMemoryMB.toDouble(),
        );
        throw SecurityViolationException(
          'Memory limit exceeded: ${usage.memoryMB}MB > ${resourceLimits.maxMemoryMB}MB',
        );
      }

      if (usage.cpuPercent > resourceLimits.maxCpuPercent) {
        _securityMonitor.logResourceViolation(
          pluginId,
          'cpu',
          usage.cpuPercent,
          resourceLimits.maxCpuPercent,
        );
        throw SecurityViolationException(
          'CPU limit exceeded: ${usage.cpuPercent}% > ${resourceLimits.maxCpuPercent}%',
        );
      }

      if (usage.networkKbps > resourceLimits.maxNetworkKbps) {
        _securityMonitor.logResourceViolation(
          pluginId,
          'network',
          usage.networkKbps,
          resourceLimits.maxNetworkKbps.toDouble(),
        );
        throw SecurityViolationException(
          'Network limit exceeded: ${usage.networkKbps}Kbps > ${resourceLimits.maxNetworkKbps}Kbps',
        );
      }

      if (usage.fileHandles > resourceLimits.maxFileHandles) {
        _securityMonitor.logResourceViolation(
          pluginId,
          'fileHandles',
          usage.fileHandles.toDouble(),
          resourceLimits.maxFileHandles.toDouble(),
        );
        throw SecurityViolationException(
          'File handle limit exceeded: ${usage.fileHandles} > ${resourceLimits.maxFileHandles}',
        );
      }

      if (usage.uptime > resourceLimits.maxExecutionTime) {
        _securityMonitor.logResourceViolation(
          pluginId,
          'executionTime',
          usage.uptime.inSeconds.toDouble(),
          resourceLimits.maxExecutionTime.inSeconds.toDouble(),
        );
        throw SecurityViolationException(
          'Execution time limit exceeded: ${usage.uptime} > ${resourceLimits.maxExecutionTime}',
        );
      }
    } catch (e) {
      await terminate();
      rethrow;
    }
  }

  /// Terminate sandbox and clean up all resources
  Future<void> terminate() async {
    if (!_isActive) {
      return;
    }

    try {
      // Stop resource monitoring
      await _resourceMonitor?.stop();

      // Stop security monitoring
      _securityMonitor.stopMonitoring(pluginId);

      // Revoke all permissions
      _permissionManager.revokeAllPermissions(pluginId);

      // Clean up sandbox resources
      await _cleanup();

      _isActive = false;
    } catch (e) {
      throw SandboxException(
        'Failed to terminate sandbox for plugin $pluginId: $e',
      );
    }
  }

  // Private implementation methods

  /// Create isolated file system for the plugin
  Future<void> _createIsolatedFileSystem() async {
    final sandboxDir = Directory('sandbox/$pluginId');

    if (await sandboxDir.exists()) {
      await sandboxDir.delete(recursive: true);
    }

    await sandboxDir.create(recursive: true);
    _sandboxPath = sandboxDir.path;

    // Create standard directories based on security level
    switch (securityLevel) {
      case SecurityLevel.minimal:
        await Directory('${sandboxDir.path}/temp').create();
        await Directory('${sandboxDir.path}/data').create();
        break;
      case SecurityLevel.standard:
        await Directory('${sandboxDir.path}/temp').create();
        await Directory('${sandboxDir.path}/data').create();
        await Directory('${sandboxDir.path}/cache').create();
        break;
      case SecurityLevel.strict:
        await Directory('${sandboxDir.path}/temp').create();
        break;
      case SecurityLevel.isolated:
        // No additional directories for maximum isolation
        break;
    }
  }

  /// Configure network access policies
  Future<void> _configureNetworkPolicy() async {
    // Network policy configuration based on security level and permissions
    switch (securityLevel) {
      case SecurityLevel.isolated:
        _networkPolicy.allowOutbound = false;
        _networkPolicy.allowInbound = false;
        break;
      case SecurityLevel.strict:
        _networkPolicy.allowOutbound = allowedPermissions.contains(
          Permission.networkClient,
        );
        _networkPolicy.allowInbound = false;
        break;
      case SecurityLevel.standard:
        _networkPolicy.allowOutbound =
            allowedPermissions.contains(Permission.networkAccess) ||
            allowedPermissions.contains(Permission.networkClient);
        _networkPolicy.allowInbound = allowedPermissions.contains(
          Permission.networkServer,
        );
        break;
      case SecurityLevel.minimal:
        _networkPolicy.allowOutbound = true;
        _networkPolicy.allowInbound = allowedPermissions.contains(
          Permission.networkServer,
        );
        break;
    }
  }

  /// Apply resource limits to the sandbox
  Future<void> _applyResourceLimits() async {
    // Resource limits are enforced through monitoring rather than hard limits
    // This allows for graceful handling of limit violations
  }

  /// Setup permission enforcement mechanisms
  Future<void> _setupPermissionEnforcement() async {
    // Permission enforcement is handled through validateAccess method
    // This method can be extended to setup additional enforcement mechanisms
  }

  /// Initialize resource monitoring
  Future<void> _initializeResourceMonitoring() async {
    _resourceMonitor = ResourceMonitor(pluginId: pluginId);
    await _resourceMonitor!.start();
  }

  /// Check if request is within resource limits
  Future<bool> _withinResourceLimits(AccessRequest request) async {
    try {
      final usage = await getResourceUsage();

      // Check if the request would exceed limits
      switch (request.permission) {
        case Permission.fileSystemRead:
        case Permission.fileSystemWrite:
          return usage.fileHandles < resourceLimits.maxFileHandles;
        case Permission.networkAccess:
        case Permission.networkClient:
        case Permission.networkServer:
          return usage.networkKbps < resourceLimits.maxNetworkKbps;
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Apply security policies to access request
  Future<bool> _applySecurityPolicies(AccessRequest request) async {
    // Apply security policies based on security level
    switch (securityLevel) {
      case SecurityLevel.isolated:
        return _applyIsolatedPolicies(request);
      case SecurityLevel.strict:
        return _applyStrictPolicies(request);
      case SecurityLevel.standard:
        return _applyStandardPolicies(request);
      case SecurityLevel.minimal:
        return _applyMinimalPolicies(request);
    }
  }

  /// Check if request is network-related
  bool _isNetworkRequest(AccessRequest request) {
    return [
      Permission.networkAccess,
      Permission.networkClient,
      Permission.networkServer,
    ].contains(request.permission);
  }

  /// Apply network policies to network requests
  Future<bool> _applyNetworkPolicies(AccessRequest request) async {
    final url = request.parameters['url'] as String?;

    if (url != null) {
      // Check against allowed/blocked domains
      final uri = Uri.tryParse(url);
      if (uri != null) {
        return _networkPolicy.isAllowed(uri);
      }
    }

    return _networkPolicy.allowOutbound;
  }

  /// Apply isolated security policies (maximum restriction)
  bool _applyIsolatedPolicies(AccessRequest request) {
    // Only allow minimal system access
    final allowedPermissions = [Permission.platformUI];
    return allowedPermissions.contains(request.permission);
  }

  /// Apply strict security policies
  bool _applyStrictPolicies(AccessRequest request) {
    // Allow limited system access
    final restrictedResources = ['system', 'kernel', 'registry', 'config'];

    final resource = request.resource.toLowerCase();
    return !restrictedResources.any(
      (restricted) => resource.contains(restricted),
    );
  }

  /// Apply standard security policies
  bool _applyStandardPolicies(AccessRequest request) {
    // Allow most access with some restrictions
    final blockedResources = [
      'system/kernel',
      'system/registry/critical',
      '/etc/passwd',
      '/etc/shadow',
    ];

    return !blockedResources.contains(request.resource);
  }

  /// Apply minimal security policies (least restriction)
  bool _applyMinimalPolicies(AccessRequest request) {
    // Allow almost all access
    return true;
  }

  /// Log security violations for audit purposes
  void _logSecurityViolation(String reason, AccessRequest request) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint(
      'SECURITY_VIOLATION [$timestamp] Plugin: $pluginId, Reason: $reason, '
      'Permission: ${request.permission}, Resource: ${request.resource}',
    );
  }

  /// Clean up sandbox resources
  Future<void> _cleanup() async {
    if (_sandboxPath != null) {
      final sandboxDir = Directory(_sandboxPath!);
      if (await sandboxDir.exists()) {
        await sandboxDir.delete(recursive: true);
      }
    }

    _sandboxPath = null;
    _resourceMonitor = null;
  }
}

/// Request for accessing system resources
class AccessRequest {
  final Permission permission;
  final String resource;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AccessRequest({
    required this.permission,
    required this.resource,
    required this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a file access request
  factory AccessRequest.fileAccess({
    required Permission permission,
    required String filePath,
    String? mode,
  }) {
    return AccessRequest(
      permission: permission,
      resource: filePath,
      parameters: {'mode': mode ?? 'read'},
    );
  }

  /// Create a network access request
  factory AccessRequest.networkAccess({
    required Permission permission,
    required String url,
    String? method,
  }) {
    return AccessRequest(
      permission: permission,
      resource: url,
      parameters: {'method': method ?? 'GET'},
    );
  }
}

/// Current resource usage of a plugin
class ResourceUsage {
  final double memoryMB;
  final double cpuPercent;
  final double networkKbps;
  final int fileHandles;
  final Duration uptime;
  final DateTime timestamp;

  ResourceUsage({
    required this.memoryMB,
    required this.cpuPercent,
    required this.networkKbps,
    required this.fileHandles,
    required this.uptime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if usage exceeds limits
  bool exceedsLimits(ResourceLimits limits) {
    return memoryMB > limits.maxMemoryMB ||
        cpuPercent > limits.maxCpuPercent ||
        networkKbps > limits.maxNetworkKbps ||
        fileHandles > limits.maxFileHandles ||
        uptime > limits.maxExecutionTime;
  }

  /// Get usage as percentage of limits
  Map<String, double> getUsagePercentages(ResourceLimits limits) {
    return {
      'memory': (memoryMB / limits.maxMemoryMB) * 100,
      'cpu': (cpuPercent / limits.maxCpuPercent) * 100,
      'network': (networkKbps / limits.maxNetworkKbps) * 100,
      'fileHandles': (fileHandles / limits.maxFileHandles) * 100,
      'executionTime':
          (uptime.inSeconds / limits.maxExecutionTime.inSeconds) * 100,
    };
  }
}

/// Security policy configuration
class SecurityPolicy {
  final SecurityLevel level;
  final List<String> allowedPaths;
  final List<String> blockedPaths;
  final List<String> allowedCommands;
  final bool allowSystemCalls;
  final bool allowNetworkAccess;
  final bool allowFileSystemAccess;

  const SecurityPolicy({
    required this.level,
    required this.allowedPaths,
    required this.blockedPaths,
    required this.allowedCommands,
    required this.allowSystemCalls,
    required this.allowNetworkAccess,
    required this.allowFileSystemAccess,
  });

  /// Create security policy from security level
  factory SecurityPolicy.fromSecurityLevel(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.isolated:
        return const SecurityPolicy(
          level: SecurityLevel.isolated,
          allowedPaths: [],
          blockedPaths: ['*'],
          allowedCommands: [],
          allowSystemCalls: false,
          allowNetworkAccess: false,
          allowFileSystemAccess: false,
        );
      case SecurityLevel.strict:
        return const SecurityPolicy(
          level: SecurityLevel.strict,
          allowedPaths: ['sandbox/*', 'temp/*'],
          blockedPaths: ['system/*', 'etc/*', 'root/*'],
          allowedCommands: ['echo', 'cat', 'ls'],
          allowSystemCalls: false,
          allowNetworkAccess: false,
          allowFileSystemAccess: true,
        );
      case SecurityLevel.standard:
        return const SecurityPolicy(
          level: SecurityLevel.standard,
          allowedPaths: ['sandbox/*', 'temp/*', 'data/*'],
          blockedPaths: ['system/critical/*', 'etc/passwd', 'etc/shadow'],
          allowedCommands: ['echo', 'cat', 'ls', 'grep', 'find'],
          allowSystemCalls: false,
          allowNetworkAccess: true,
          allowFileSystemAccess: true,
        );
      case SecurityLevel.minimal:
        return const SecurityPolicy(
          level: SecurityLevel.minimal,
          allowedPaths: ['*'],
          blockedPaths: [],
          allowedCommands: ['*'],
          allowSystemCalls: true,
          allowNetworkAccess: true,
          allowFileSystemAccess: true,
        );
    }
  }
}

/// Network policy configuration
class NetworkPolicy {
  bool allowOutbound;
  bool allowInbound;
  final List<String> allowedDomains;
  final List<String> blockedDomains;
  final List<int> allowedPorts;
  final List<int> blockedPorts;

  NetworkPolicy({
    required this.allowOutbound,
    required this.allowInbound,
    required this.allowedDomains,
    required this.blockedDomains,
    required this.allowedPorts,
    required this.blockedPorts,
  });

  /// Create network policy from security level
  factory NetworkPolicy.fromSecurityLevel(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.isolated:
        return NetworkPolicy(
          allowOutbound: false,
          allowInbound: false,
          allowedDomains: [],
          blockedDomains: ['*'],
          allowedPorts: [],
          blockedPorts: [1, 65535], // Block all ports
        );
      case SecurityLevel.strict:
        return NetworkPolicy(
          allowOutbound: false,
          allowInbound: false,
          allowedDomains: [],
          blockedDomains: ['localhost', '127.0.0.1', '0.0.0.0'],
          allowedPorts: [80, 443],
          blockedPorts: [22, 23, 3389], // Block SSH, Telnet, RDP
        );
      case SecurityLevel.standard:
        return NetworkPolicy(
          allowOutbound: true,
          allowInbound: false,
          allowedDomains: [],
          blockedDomains: ['localhost', '127.0.0.1'],
          allowedPorts: [80, 443, 8080, 8443],
          blockedPorts: [22, 23, 3389],
        );
      case SecurityLevel.minimal:
        return NetworkPolicy(
          allowOutbound: true,
          allowInbound: true,
          allowedDomains: ['*'],
          blockedDomains: [],
          allowedPorts: [],
          blockedPorts: [],
        );
    }
  }

  /// Check if URL is allowed by policy
  bool isAllowed(Uri uri) {
    // Check blocked domains first
    if (blockedDomains.contains('*') || blockedDomains.contains(uri.host)) {
      return false;
    }

    // Check allowed domains
    if (allowedDomains.isNotEmpty &&
        !allowedDomains.contains('*') &&
        !allowedDomains.contains(uri.host)) {
      return false;
    }

    // Check ports
    final port = uri.port;
    if (blockedPorts.contains(port)) {
      return false;
    }

    if (allowedPorts.isNotEmpty && !allowedPorts.contains(port)) {
      return false;
    }

    return true;
  }
}

/// Resource monitoring for plugins
class ResourceMonitor {
  final String pluginId;
  bool _isRunning = false;
  DateTime? _startTime;

  ResourceMonitor({required this.pluginId});

  /// Start resource monitoring
  Future<void> start() async {
    if (_isRunning) return;

    _startTime = DateTime.now();
    _isRunning = true;
  }

  /// Stop resource monitoring
  Future<void> stop() async {
    _isRunning = false;
    _startTime = null;
  }

  /// Get current resource usage
  Future<ResourceUsage> getCurrentUsage() async {
    if (!_isRunning || _startTime == null) {
      throw Exception('Resource monitor not running');
    }

    // Simulate resource usage monitoring
    // In a real implementation, this would query actual system resources
    return ResourceUsage(
      memoryMB: 50.0, // Simulated memory usage
      cpuPercent: 10.0, // Simulated CPU usage
      networkKbps: 100.0, // Simulated network usage
      fileHandles: 5, // Simulated file handle count
      uptime: DateTime.now().difference(_startTime!),
    );
  }
}

/// Exception thrown when sandbox operations fail
class SandboxException implements Exception {
  final String message;

  const SandboxException(this.message);

  @override
  String toString() => 'SandboxException: $message';
}

/// Exception thrown when security policies are violated
class SecurityViolationException implements Exception {
  final String message;

  const SecurityViolationException(this.message);

  @override
  String toString() => 'SecurityViolationException: $message';
}
