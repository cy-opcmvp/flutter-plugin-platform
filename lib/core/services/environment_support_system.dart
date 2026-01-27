import 'package:flutter/foundation.dart';
import '../models/external_plugin_models.dart';
import '../models/plugin_models.dart';
import 'platform_environment.dart';

/// Environment support system for managing development and production environments
class EnvironmentSupportSystem {
  static EnvironmentSupportSystem? _instance;

  /// Singleton instance
  static EnvironmentSupportSystem get instance {
    _instance ??= EnvironmentSupportSystem._();
    return _instance!;
  }

  EnvironmentSupportSystem._();

  /// Current environment
  PluginEnvironment _currentEnvironment = PluginEnvironment.production;

  /// Environment configurations
  final Map<PluginEnvironment, EnvironmentConfig> _environmentConfigs = {};

  /// Environment-specific plugin configurations
  final Map<String, Map<PluginEnvironment, PluginEnvironmentConfig>>
  _pluginConfigs = {};

  /// Initialize environment support system
  Future<void> initialize() async {
    await _detectEnvironment();
    await _loadEnvironmentConfigurations();
  }

  /// Get current environment
  PluginEnvironment get currentEnvironment => _currentEnvironment;

  /// Set current environment
  Future<void> setEnvironment(PluginEnvironment environment) async {
    if (_currentEnvironment != environment) {
      final oldEnvironment = _currentEnvironment;
      _currentEnvironment = environment;

      // Apply environment-specific configurations
      await _applyEnvironmentConfiguration(environment);

      // Notify about environment change
      await _notifyEnvironmentChange(oldEnvironment, environment);
    }
  }

  /// Get environment configuration
  EnvironmentConfig? getEnvironmentConfig(PluginEnvironment environment) {
    return _environmentConfigs[environment];
  }

  /// Set environment configuration
  void setEnvironmentConfig(
    PluginEnvironment environment,
    EnvironmentConfig config,
  ) {
    _environmentConfigs[environment] = config;
  }

  /// Get plugin environment configuration
  PluginEnvironmentConfig? getPluginEnvironmentConfig(
    String pluginId,
    PluginEnvironment environment,
  ) {
    return _pluginConfigs[pluginId]?[environment];
  }

  /// Set plugin environment configuration
  void setPluginEnvironmentConfig(
    String pluginId,
    PluginEnvironment environment,
    PluginEnvironmentConfig config,
  ) {
    _pluginConfigs.putIfAbsent(pluginId, () => {});
    _pluginConfigs[pluginId]![environment] = config;
  }

  /// Validate deployment for environment
  Future<DeploymentValidationResult> validateDeployment(
    PluginPackage package,
    PluginEnvironment targetEnvironment,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate environment configuration exists
    final envConfig = getEnvironmentConfig(targetEnvironment);
    if (envConfig == null) {
      errors.add(
        'No configuration found for environment: ${targetEnvironment.name}',
      );
      return DeploymentValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Validate plugin requirements against environment
    final requirementResult = await _validateEnvironmentRequirements(
      package,
      envConfig,
    );
    errors.addAll(requirementResult.errors);
    warnings.addAll(requirementResult.warnings);

    // Validate security requirements
    final securityResult = await _validateEnvironmentSecurity(
      package,
      envConfig,
    );
    errors.addAll(securityResult.errors);
    warnings.addAll(securityResult.warnings);

    // Validate resource requirements
    final resourceResult = await _validateEnvironmentResources(
      package,
      envConfig,
    );
    errors.addAll(resourceResult.errors);
    warnings.addAll(resourceResult.warnings);

    // Validate dependencies
    final dependencyResult = await _validateEnvironmentDependencies(
      package,
      envConfig,
    );
    errors.addAll(dependencyResult.errors);
    warnings.addAll(dependencyResult.warnings);

    return DeploymentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get environment-specific plugin configuration
  Map<String, dynamic> getEnvironmentPluginConfig(String pluginId) {
    final pluginConfig = getPluginEnvironmentConfig(
      pluginId,
      _currentEnvironment,
    );
    final envConfig = getEnvironmentConfig(_currentEnvironment);

    final config = <String, dynamic>{};

    // Add environment-specific settings
    if (envConfig != null) {
      config.addAll(envConfig.defaultPluginSettings);
    }

    // Add plugin-specific environment settings
    if (pluginConfig != null) {
      config.addAll(pluginConfig.settings);
    }

    return config;
  }

  /// Check if feature is enabled in current environment
  bool isFeatureEnabled(String feature) {
    final envConfig = getEnvironmentConfig(_currentEnvironment);
    return envConfig?.enabledFeatures.contains(feature) ?? false;
  }

  /// Get environment-specific resource limits
  ResourceLimits getEnvironmentResourceLimits() {
    final envConfig = getEnvironmentConfig(_currentEnvironment);
    return envConfig?.defaultResourceLimits ?? _getDefaultResourceLimits();
  }

  /// Get environment-specific security level
  SecurityLevel getEnvironmentSecurityLevel() {
    final envConfig = getEnvironmentConfig(_currentEnvironment);
    return envConfig?.defaultSecurityLevel ?? SecurityLevel.standard;
  }

  /// Create environment-specific plugin instance configuration
  Map<String, dynamic> createPluginInstanceConfig(PluginManifest manifest) {
    final config = <String, dynamic>{};

    // Add environment type
    config['environment'] = _currentEnvironment.name;

    // Add environment-specific settings
    config.addAll(getEnvironmentPluginConfig(manifest.id));

    // Add environment-specific resource limits
    final resourceLimits = getEnvironmentResourceLimits();
    config['resourceLimits'] = resourceLimits.toJson();

    // Add environment-specific security settings
    config['securityLevel'] = getEnvironmentSecurityLevel().name;

    // Add environment-specific features
    final envConfig = getEnvironmentConfig(_currentEnvironment);
    if (envConfig != null) {
      config['enabledFeatures'] = envConfig.enabledFeatures;
      config['debugMode'] = envConfig.debugMode;
      config['loggingLevel'] = envConfig.loggingLevel.name;
    }

    return config;
  }

  /// Detect current environment
  Future<void> _detectEnvironment() async {
    final platformEnv = PlatformEnvironment.instance;

    // Check environment variables using PlatformEnvironment
    final envVar = platformEnv.getVariable('PLUGIN_ENVIRONMENT');
    if (envVar != null) {
      try {
        _currentEnvironment = PluginEnvironment.values.firstWhere(
          (e) => e.name.toLowerCase() == envVar.toLowerCase(),
        );
        return;
      } catch (e) {
        // Invalid environment variable, continue with detection
      }
    }

    // Check for development indicators using PlatformEnvironment
    if (platformEnv.containsKey('FLUTTER_TEST') ||
        platformEnv.containsKey('DEBUG') ||
        platformEnv.containsKey('DEVELOPMENT')) {
      _currentEnvironment = PluginEnvironment.development;
      return;
    }

    // Alternative detection for web platform: use Flutter's kDebugMode
    if (platformEnv.isWeb && kDebugMode) {
      _currentEnvironment = PluginEnvironment.development;
      return;
    }

    // Check for staging indicators using PlatformEnvironment
    if (platformEnv.containsKey('STAGING') || platformEnv.containsKey('TEST')) {
      _currentEnvironment = PluginEnvironment.staging;
      return;
    }

    // Default to production (fallback when detection fails)
    _currentEnvironment = PluginEnvironment.production;
  }

  /// Load environment configurations
  Future<void> _loadEnvironmentConfigurations() async {
    // Load default configurations for each environment
    _environmentConfigs[PluginEnvironment.development] =
        _createDevelopmentConfig();
    _environmentConfigs[PluginEnvironment.staging] = _createStagingConfig();
    _environmentConfigs[PluginEnvironment.production] =
        _createProductionConfig();
  }

  /// Create development environment configuration
  EnvironmentConfig _createDevelopmentConfig() {
    return const EnvironmentConfig(
      name: 'Development',
      debugMode: true,
      loggingLevel: LoggingLevel.debug,
      enabledFeatures: [
        'hot_reload',
        'debug_tools',
        'development_apis',
        'mock_services',
        'test_data',
      ],
      defaultSecurityLevel: SecurityLevel.minimal,
      defaultResourceLimits: ResourceLimits(
        maxMemoryMB: 1024,
        maxCpuPercent: 80.0,
        maxNetworkKbps: 10000,
        maxFileHandles: 1000,
        maxExecutionTime: Duration(minutes: 30),
      ),
      defaultPluginSettings: {
        'debug': true,
        'verbose_logging': true,
        'mock_external_services': true,
        'enable_test_endpoints': true,
      },
      allowedPluginTypes: PluginType.values,
      requireSignedPlugins: false,
      allowExternalPlugins: true,
    );
  }

  /// Create staging environment configuration
  EnvironmentConfig _createStagingConfig() {
    return const EnvironmentConfig(
      name: 'Staging',
      debugMode: false,
      loggingLevel: LoggingLevel.info,
      enabledFeatures: [
        'performance_monitoring',
        'error_reporting',
        'analytics',
      ],
      defaultSecurityLevel: SecurityLevel.standard,
      defaultResourceLimits: ResourceLimits(
        maxMemoryMB: 512,
        maxCpuPercent: 60.0,
        maxNetworkKbps: 5000,
        maxFileHandles: 500,
        maxExecutionTime: Duration(minutes: 15),
      ),
      defaultPluginSettings: {
        'debug': false,
        'verbose_logging': false,
        'mock_external_services': false,
        'enable_test_endpoints': false,
      },
      allowedPluginTypes: PluginType.values,
      requireSignedPlugins: true,
      allowExternalPlugins: true,
    );
  }

  /// Create production environment configuration
  EnvironmentConfig _createProductionConfig() {
    return const EnvironmentConfig(
      name: 'Production',
      debugMode: false,
      loggingLevel: LoggingLevel.warning,
      enabledFeatures: [
        'performance_monitoring',
        'error_reporting',
        'analytics',
        'security_monitoring',
      ],
      defaultSecurityLevel: SecurityLevel.strict,
      defaultResourceLimits: ResourceLimits(
        maxMemoryMB: 256,
        maxCpuPercent: 40.0,
        maxNetworkKbps: 2000,
        maxFileHandles: 200,
        maxExecutionTime: Duration(minutes: 10),
      ),
      defaultPluginSettings: {
        'debug': false,
        'verbose_logging': false,
        'mock_external_services': false,
        'enable_test_endpoints': false,
      },
      allowedPluginTypes: PluginType.values,
      requireSignedPlugins: true,
      allowExternalPlugins: false,
    );
  }

  /// Apply environment configuration
  Future<void> _applyEnvironmentConfiguration(
    PluginEnvironment environment,
  ) async {
    final config = getEnvironmentConfig(environment);
    if (config == null) return;

    // Apply logging level
    // In a real implementation, you would configure your logging system here

    // Apply security settings
    // In a real implementation, you would configure security policies here

    // Apply feature flags
    // In a real implementation, you would enable/disable features here
  }

  /// Notify about environment change
  Future<void> _notifyEnvironmentChange(
    PluginEnvironment oldEnvironment,
    PluginEnvironment newEnvironment,
  ) async {
    // In a real implementation, you would notify plugins and services about the environment change
    debugPrint(
      'Environment changed from ${oldEnvironment.name} to ${newEnvironment.name}',
    );
  }

  /// Validate environment requirements
  Future<DeploymentValidationResult> _validateEnvironmentRequirements(
    PluginPackage package,
    EnvironmentConfig envConfig,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if plugin type is allowed in this environment
    if (!envConfig.allowedPluginTypes.contains(package.type)) {
      errors.add(
        'Plugin type ${package.type.name} not allowed in ${envConfig.name} environment',
      );
    }

    // Check if external plugins are allowed
    if (!envConfig.allowExternalPlugins) {
      errors.add(
        'External plugins not allowed in ${envConfig.name} environment',
      );
    }

    // Check signature requirements
    if (envConfig.requireSignedPlugins && !package.signature.isValid()) {
      errors.add('Plugin signature required in ${envConfig.name} environment');
    }

    return DeploymentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate environment security
  Future<DeploymentValidationResult> _validateEnvironmentSecurity(
    PluginPackage package,
    EnvironmentConfig envConfig,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check security level compatibility
    if (package.manifest.security.level.index <
        envConfig.defaultSecurityLevel.index) {
      warnings.add('Plugin security level lower than environment requirement');
    }

    return DeploymentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate environment resources
  Future<DeploymentValidationResult> _validateEnvironmentResources(
    PluginPackage package,
    EnvironmentConfig envConfig,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    final pluginLimits = package.manifest.security.resourceLimits;
    final envLimits = envConfig.defaultResourceLimits;

    // Check if plugin resource requirements exceed environment limits
    if (pluginLimits.maxMemoryMB > envLimits.maxMemoryMB) {
      errors.add(
        'Plugin memory requirement (${pluginLimits.maxMemoryMB}MB) exceeds environment limit (${envLimits.maxMemoryMB}MB)',
      );
    }

    if (pluginLimits.maxCpuPercent > envLimits.maxCpuPercent) {
      errors.add(
        'Plugin CPU requirement (${pluginLimits.maxCpuPercent}%) exceeds environment limit (${envLimits.maxCpuPercent}%)',
      );
    }

    return DeploymentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate environment dependencies
  Future<DeploymentValidationResult> _validateEnvironmentDependencies(
    PluginPackage package,
    EnvironmentConfig envConfig,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    // In a real implementation, you would check if dependencies are available in the target environment
    for (final dependency in package.dependencies) {
      if (dependency.required) {
        // Check if dependency is available in environment
        // This is a simplified check
        if (dependency.id.isEmpty) {
          errors.add('Invalid dependency: ${dependency.name}');
        }
      }
    }

    return DeploymentValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get default resource limits
  ResourceLimits _getDefaultResourceLimits() {
    return const ResourceLimits(
      maxMemoryMB: 128,
      maxCpuPercent: 25.0,
      maxNetworkKbps: 1000,
      maxFileHandles: 100,
      maxExecutionTime: Duration(minutes: 5),
    );
  }
}

/// Plugin environment types
enum PluginEnvironment { development, staging, production }

/// Logging levels
enum LoggingLevel { debug, info, warning, error }

/// Environment configuration
class EnvironmentConfig {
  final String name;
  final bool debugMode;
  final LoggingLevel loggingLevel;
  final List<String> enabledFeatures;
  final SecurityLevel defaultSecurityLevel;
  final ResourceLimits defaultResourceLimits;
  final Map<String, dynamic> defaultPluginSettings;
  final List<PluginType> allowedPluginTypes;
  final bool requireSignedPlugins;
  final bool allowExternalPlugins;

  const EnvironmentConfig({
    required this.name,
    required this.debugMode,
    required this.loggingLevel,
    required this.enabledFeatures,
    required this.defaultSecurityLevel,
    required this.defaultResourceLimits,
    required this.defaultPluginSettings,
    required this.allowedPluginTypes,
    required this.requireSignedPlugins,
    required this.allowExternalPlugins,
  });

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) {
    return EnvironmentConfig(
      name: json['name'] as String,
      debugMode: json['debugMode'] as bool,
      loggingLevel: LoggingLevel.values.firstWhere(
        (e) => e.name == json['loggingLevel'],
      ),
      enabledFeatures: (json['enabledFeatures'] as List<dynamic>)
          .cast<String>(),
      defaultSecurityLevel: SecurityLevel.values.firstWhere(
        (e) => e.name == json['defaultSecurityLevel'],
      ),
      defaultResourceLimits: ResourceLimits.fromJson(
        json['defaultResourceLimits'] as Map<String, dynamic>,
      ),
      defaultPluginSettings:
          json['defaultPluginSettings'] as Map<String, dynamic>,
      allowedPluginTypes: (json['allowedPluginTypes'] as List<dynamic>)
          .map((e) => PluginType.values.firstWhere((t) => t.name == e))
          .toList(),
      requireSignedPlugins: json['requireSignedPlugins'] as bool,
      allowExternalPlugins: json['allowExternalPlugins'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'debugMode': debugMode,
      'loggingLevel': loggingLevel.name,
      'enabledFeatures': enabledFeatures,
      'defaultSecurityLevel': defaultSecurityLevel.name,
      'defaultResourceLimits': defaultResourceLimits.toJson(),
      'defaultPluginSettings': defaultPluginSettings,
      'allowedPluginTypes': allowedPluginTypes.map((e) => e.name).toList(),
      'requireSignedPlugins': requireSignedPlugins,
      'allowExternalPlugins': allowExternalPlugins,
    };
  }
}

/// Plugin environment-specific configuration
class PluginEnvironmentConfig {
  final String pluginId;
  final PluginEnvironment environment;
  final Map<String, dynamic> settings;
  final ResourceLimits? resourceLimits;
  final SecurityLevel? securityLevel;
  final List<String> enabledFeatures;

  const PluginEnvironmentConfig({
    required this.pluginId,
    required this.environment,
    required this.settings,
    this.resourceLimits,
    this.securityLevel,
    this.enabledFeatures = const [],
  });

  factory PluginEnvironmentConfig.fromJson(Map<String, dynamic> json) {
    return PluginEnvironmentConfig(
      pluginId: json['pluginId'] as String,
      environment: PluginEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
      ),
      settings: json['settings'] as Map<String, dynamic>,
      resourceLimits: json['resourceLimits'] != null
          ? ResourceLimits.fromJson(
              json['resourceLimits'] as Map<String, dynamic>,
            )
          : null,
      securityLevel: json['securityLevel'] != null
          ? SecurityLevel.values.firstWhere(
              (e) => e.name == json['securityLevel'],
            )
          : null,
      enabledFeatures:
          (json['enabledFeatures'] as List<dynamic>?)?.cast<String>() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'environment': environment.name,
      'settings': settings,
      'resourceLimits': resourceLimits?.toJson(),
      'securityLevel': securityLevel?.name,
      'enabledFeatures': enabledFeatures,
    };
  }
}

/// Deployment validation result
class DeploymentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const DeploymentValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Check if validation has errors
  bool get hasErrors => errors.isNotEmpty;

  /// Check if validation has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get all issues (errors and warnings)
  List<String> get allIssues => [...errors, ...warnings];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('DeploymentValidationResult(isValid: $isValid)');

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
