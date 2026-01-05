import 'dart:io';
import '../models/external_plugin_models.dart';
import '../models/plugin_models.dart';

/// Service for validating plugin requirements against system capabilities
class RequirementValidator {
  static RequirementValidator? _instance;
  
  /// Singleton instance
  static RequirementValidator get instance {
    _instance ??= RequirementValidator._();
    return _instance!;
  }
  
  RequirementValidator._();
  
  /// System capabilities cache
  final Map<String, dynamic> _systemCapabilities = {};
  
  /// Platform information cache
  final Map<String, String> _platformInfo = {};
  
  /// Initialize system capability detection
  Future<void> initialize() async {
    await _detectSystemCapabilities();
    await _detectPlatformInfo();
  }
  
  /// Validate plugin requirements against system capabilities
  Future<ValidationResult> validatePluginRequirements(PluginManifest manifest) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Validate platform support
    final platformResult = await _validatePlatformSupport(manifest);
    errors.addAll(platformResult.errors);
    warnings.addAll(platformResult.warnings);
    
    // Validate system requirements
    final systemResult = await _validateSystemRequirements(manifest);
    errors.addAll(systemResult.errors);
    warnings.addAll(systemResult.warnings);
    
    // Validate permissions
    final permissionResult = await _validatePermissions(manifest);
    errors.addAll(permissionResult.errors);
    warnings.addAll(permissionResult.warnings);
    
    // Validate dependencies
    final dependencyResult = await _validateDependencies(manifest);
    errors.addAll(dependencyResult.errors);
    warnings.addAll(dependencyResult.warnings);
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate external plugin package requirements
  Future<ValidationResult> validatePackageRequirements(PluginPackage package) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Validate manifest requirements
    final manifestResult = await validatePluginRequirements(package.manifest);
    errors.addAll(manifestResult.errors);
    warnings.addAll(manifestResult.warnings);
    
    // Validate platform assets
    final assetResult = await _validatePlatformAssets(package);
    errors.addAll(assetResult.errors);
    warnings.addAll(assetResult.warnings);
    
    // Validate security signature
    final securityResult = await _validateSecuritySignature(package);
    errors.addAll(securityResult.errors);
    warnings.addAll(securityResult.warnings);
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Get current system capabilities
  Map<String, dynamic> getSystemCapabilities() {
    return Map.unmodifiable(_systemCapabilities);
  }
  
  /// Get current platform information
  Map<String, String> getPlatformInfo() {
    return Map.unmodifiable(_platformInfo);
  }
  
  /// Check if system supports specific capability
  bool hasCapability(String capability) {
    return _systemCapabilities.containsKey(capability) && 
           _systemCapabilities[capability] == true;
  }
  
  /// Get capability value
  T? getCapabilityValue<T>(String capability) {
    return _systemCapabilities[capability] as T?;
  }
  
  /// Detect system capabilities
  Future<void> _detectSystemCapabilities() async {
    _systemCapabilities.clear();
    
    // Detect file system capabilities
    await _detectFileSystemCapabilities();
    
    // Detect network capabilities
    await _detectNetworkCapabilities();
    
    // Detect hardware capabilities
    await _detectHardwareCapabilities();
    
    // Detect runtime capabilities
    await _detectRuntimeCapabilities();
  }
  
  /// Detect platform information
  Future<void> _detectPlatformInfo() async {
    _platformInfo.clear();
    
    // Operating system
    _platformInfo['os'] = Platform.operatingSystem;
    _platformInfo['osVersion'] = Platform.operatingSystemVersion;
    
    // Architecture
    _platformInfo['architecture'] = _detectArchitecture();
    
    // Platform type
    _platformInfo['platformType'] = _detectPlatformType();
    
    // Runtime environment
    _platformInfo['runtime'] = 'dart';
    _platformInfo['runtimeVersion'] = Platform.version;
  }
  
  /// Detect file system capabilities
  Future<void> _detectFileSystemCapabilities() async {
    try {
      // Test read capability
      final tempDir = Directory.systemTemp;
      _systemCapabilities['fileSystemRead'] = await tempDir.exists();
      
      // Test write capability
      try {
        final testFile = File('${tempDir.path}/test_write_${DateTime.now().millisecondsSinceEpoch}');
        await testFile.writeAsString('test');
        await testFile.delete();
        _systemCapabilities['fileSystemWrite'] = true;
      } catch (e) {
        _systemCapabilities['fileSystemWrite'] = false;
      }
      
      // Test execute capability (platform dependent)
      _systemCapabilities['fileSystemExecute'] = Platform.isWindows || 
                                                Platform.isLinux || 
                                                Platform.isMacOS;
    } catch (e) {
      _systemCapabilities['fileSystemRead'] = false;
      _systemCapabilities['fileSystemWrite'] = false;
      _systemCapabilities['fileSystemExecute'] = false;
    }
  }
  
  /// Detect network capabilities
  Future<void> _detectNetworkCapabilities() async {
    try {
      // Test basic network access
      final result = await InternetAddress.lookup('google.com');
      _systemCapabilities['networkAccess'] = result.isNotEmpty;
    } catch (e) {
      _systemCapabilities['networkAccess'] = false;
    }
    
    // Server and client capabilities depend on platform
    _systemCapabilities['networkServer'] = !Platform.isIOS && !Platform.isAndroid;
    _systemCapabilities['networkClient'] = true;
  }
  
  /// Detect hardware capabilities
  Future<void> _detectHardwareCapabilities() async {
    // Camera capability (mobile platforms typically have cameras)
    _systemCapabilities['camera'] = Platform.isAndroid || Platform.isIOS;
    
    // Microphone capability (most platforms have microphones)
    _systemCapabilities['microphone'] = true;
    
    // Clipboard capability (desktop platforms)
    _systemCapabilities['clipboard'] = Platform.isWindows || 
                                      Platform.isLinux || 
                                      Platform.isMacOS;
    
    // Notifications capability
    _systemCapabilities['notifications'] = true;
  }
  
  /// Detect runtime capabilities
  Future<void> _detectRuntimeCapabilities() async {
    // Platform services
    _systemCapabilities['platformServices'] = true;
    
    // Platform UI
    _systemCapabilities['platformUI'] = true;
    
    // Platform storage
    _systemCapabilities['platformStorage'] = true;
    
    // Plugin communication
    _systemCapabilities['pluginCommunication'] = true;
    
    // Plugin data sharing
    _systemCapabilities['pluginDataSharing'] = true;
  }
  
  /// Detect system architecture
  String _detectArchitecture() {
    // This is a simplified detection - in a real implementation,
    // you might use platform channels or other methods
    if (Platform.isAndroid || Platform.isIOS) {
      return 'arm64';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'x64';
    }
    return 'unknown';
  }
  
  /// Detect platform type
  String _detectPlatformType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
  
  /// Validate platform support
  Future<ValidationResult> _validatePlatformSupport(PluginManifest manifest) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    final currentPlatform = _platformInfo['platformType'] ?? 'unknown';
    
    if (!manifest.supportedPlatforms.contains(currentPlatform)) {
      errors.add('Plugin does not support current platform: $currentPlatform');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate system requirements
  Future<ValidationResult> _validateSystemRequirements(PluginManifest manifest) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Check each required feature
    for (final feature in manifest.security.resourceLimits.maxMemoryMB > 0 ? ['memory'] : <String>[]) {
      if (!hasCapability(feature)) {
        errors.add('Required system feature not available: $feature');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate permissions
  Future<ValidationResult> _validatePermissions(PluginManifest manifest) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    for (final permission in manifest.requiredPermissions) {
      final capabilityName = _mapPermissionToCapability(permission);
      if (capabilityName != null && !hasCapability(capabilityName)) {
        errors.add('Required permission not supported: ${permission.name}');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate dependencies
  Future<ValidationResult> _validateDependencies(PluginManifest manifest) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    for (final dependency in manifest.dependencies) {
      if (dependency.required) {
        // In a real implementation, you would check if the dependency is available
        // For now, we'll just validate the dependency format
        if (dependency.id.isEmpty || dependency.version.isEmpty) {
          errors.add('Invalid dependency: ${dependency.name}');
        }
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate platform assets
  Future<ValidationResult> _validatePlatformAssets(PluginPackage package) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    final currentPlatform = _platformInfo['platformType'] ?? 'unknown';
    
    if (!package.supportsPlatform(currentPlatform)) {
      errors.add('Plugin package does not include assets for current platform: $currentPlatform');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate security signature
  Future<ValidationResult> _validateSecuritySignature(PluginPackage package) async {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (!package.signature.isValid()) {
      errors.add('Invalid security signature');
    }
    
    // In a real implementation, you would verify the signature cryptographically
    if (package.manifest.security.requiresSignature && package.signature.signature.isEmpty) {
      errors.add('Plugin requires signature but none provided');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Map permission to system capability
  String? _mapPermissionToCapability(Permission permission) {
    switch (permission) {
      case Permission.fileSystemRead:
      case Permission.fileAccess:
        return 'fileSystemRead';
      case Permission.fileSystemWrite:
        return 'fileSystemWrite';
      case Permission.fileSystemExecute:
        return 'fileSystemExecute';
      case Permission.networkAccess:
      case Permission.networkClient:
        return 'networkAccess';
      case Permission.networkServer:
        return 'networkServer';
      case Permission.systemCamera:
      case Permission.camera:
        return 'camera';
      case Permission.systemMicrophone:
      case Permission.microphone:
        return 'microphone';
      case Permission.systemClipboard:
        return 'clipboard';
      case Permission.systemNotifications:
      case Permission.notifications:
        return 'notifications';
      case Permission.platformServices:
        return 'platformServices';
      case Permission.platformUI:
        return 'platformUI';
      case Permission.platformStorage:
      case Permission.storage:
        return 'platformStorage';
      case Permission.pluginCommunication:
        return 'pluginCommunication';
      case Permission.pluginDataSharing:
        return 'pluginDataSharing';
      case Permission.location:
        return null; // Location not implemented in this basic version
    }
  }
}

/// Result of requirement validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  /// Check if validation passed without errors
  bool get hasErrors => errors.isNotEmpty;
  
  /// Check if validation has warnings
  bool get hasWarnings => warnings.isNotEmpty;
  
  /// Get all issues (errors and warnings)
  List<String> get allIssues => [...errors, ...warnings];
  
  /// Create a successful validation result
  factory ValidationResult.success({List<String>? warnings}) {
    return ValidationResult(
      isValid: true,
      errors: const [],
      warnings: warnings ?? const [],
    );
  }
  
  /// Create a failed validation result
  factory ValidationResult.failure({
    required List<String> errors,
    List<String>? warnings,
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings ?? const [],
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult(isValid: $isValid)');
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    return buffer.toString();
  }
}

/// System capability information
class SystemCapability {
  final String name;
  final bool available;
  final String? version;
  final Map<String, dynamic> metadata;
  
  const SystemCapability({
    required this.name,
    required this.available,
    this.version,
    this.metadata = const {},
  });
  
  factory SystemCapability.fromJson(Map<String, dynamic> json) {
    return SystemCapability(
      name: json['name'] as String,
      available: json['available'] as bool,
      version: json['version'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'available': available,
      'version': version,
      'metadata': metadata,
    };
  }
}