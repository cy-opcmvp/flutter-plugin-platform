import 'plugin_models.dart';

/// External Plugin Descriptor extending base PluginDescriptor
class ExternalPluginDescriptor extends PluginDescriptor {
  final PluginRuntimeType pluginRuntimeType;
  final String packageUrl;
  final String packageHash;
  final PlatformRequirements platformRequirements;
  final SecurityLevel securityLevel;
  final List<String> distributionChannels;

  const ExternalPluginDescriptor({
    required super.id,
    required super.name,
    required super.version,
    required super.type,
    required super.requiredPermissions,
    required super.metadata,
    required super.entryPoint,
    required this.pluginRuntimeType,
    required this.packageUrl,
    required this.packageHash,
    required this.platformRequirements,
    required this.securityLevel,
    required this.distributionChannels,
  });

  @override
  bool isValid() {
    if (!super.isValid()) {
      return false;
    }
    
    // Package URL must be valid
    final uri = Uri.tryParse(packageUrl);
    if (packageUrl.isEmpty || uri == null || !uri.hasAbsolutePath) {
      return false;
    }
    
    // Package hash must be non-empty
    if (packageHash.isEmpty) {
      return false;
    }
    
    // Must have at least one distribution channel
    if (distributionChannels.isEmpty) {
      return false;
    }
    
    return true;
  }

  factory ExternalPluginDescriptor.fromJson(Map<String, dynamic> json) {
    final baseDescriptor = PluginDescriptor.fromJson(json);
    
    return ExternalPluginDescriptor(
      id: baseDescriptor.id,
      name: baseDescriptor.name,
      version: baseDescriptor.version,
      type: baseDescriptor.type,
      requiredPermissions: baseDescriptor.requiredPermissions,
      metadata: baseDescriptor.metadata,
      entryPoint: baseDescriptor.entryPoint,
      pluginRuntimeType: PluginRuntimeType.values.firstWhere(
        (e) => e.name == json['pluginRuntimeType'],
      ),
      packageUrl: json['packageUrl'] as String,
      packageHash: json['packageHash'] as String,
      platformRequirements: PlatformRequirements.fromJson(
        json['platformRequirements'] as Map<String, dynamic>,
      ),
      securityLevel: SecurityLevel.values.firstWhere(
        (e) => e.name == json['securityLevel'],
      ),
      distributionChannels: (json['distributionChannels'] as List<dynamic>)
          .cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'pluginRuntimeType': pluginRuntimeType.name,
      'packageUrl': packageUrl,
      'packageHash': packageHash,
      'platformRequirements': platformRequirements.toJson(),
      'securityLevel': securityLevel.name,
      'distributionChannels': distributionChannels,
    });
    return baseJson;
  }
}

/// Plugin Package containing all necessary files and metadata
class PluginPackage {
  final String id;
  final String name;
  final String version;
  final PluginType type;
  final Map<String, PlatformAsset> platformAssets;
  final PluginManifest manifest;
  final List<Dependency> dependencies;
  final SecuritySignature signature;

  const PluginPackage({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.platformAssets,
    required this.manifest,
    required this.dependencies,
    required this.signature,
  });

  /// Validate package integrity and completeness
  bool isValid() {
    // Basic validation
    if (id.isEmpty || name.isEmpty || version.isEmpty) {
      return false;
    }
    
    // Must have at least one platform asset
    if (platformAssets.isEmpty) {
      return false;
    }
    
    // Manifest must be valid
    if (!manifest.isValid()) {
      return false;
    }
    
    // Signature must be valid
    if (!signature.isValid()) {
      return false;
    }
    
    return true;
  }

  /// Get platform asset for specific platform
  PlatformAsset? getAssetForPlatform(String platform) {
    return platformAssets[platform];
  }

  /// Check if package supports platform
  bool supportsPlatform(String platform) {
    return platformAssets.containsKey(platform);
  }

  /// Get all supported platforms
  List<String> getSupportedPlatforms() {
    return platformAssets.keys.toList();
  }

  factory PluginPackage.fromJson(Map<String, dynamic> json) {
    return PluginPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      type: PluginType.values.firstWhere((e) => e.name == json['type']),
      platformAssets: (json['platformAssets'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                key,
                PlatformAsset.fromJson(value as Map<String, dynamic>),
              )),
      manifest: PluginManifest.fromJson(json['manifest'] as Map<String, dynamic>),
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => Dependency.fromJson(e as Map<String, dynamic>))
          .toList(),
      signature: SecuritySignature.fromJson(json['signature'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type.name,
      'platformAssets': platformAssets.map((key, value) => MapEntry(key, value.toJson())),
      'manifest': manifest.toJson(),
      'dependencies': dependencies.map((e) => e.toJson()).toList(),
      'signature': signature.toJson(),
    };
  }
}

/// Plugin Manifest with comprehensive metadata and configuration
class PluginManifest {
  final String id;
  final String name;
  final String version;
  final PluginType type;
  final List<Permission> requiredPermissions;
  final List<String> supportedPlatforms;
  final Map<String, dynamic> configuration;
  final List<APIEndpoint> providedAPIs;
  final List<Dependency> dependencies;
  final SecurityRequirements security;
  final UIIntegration uiIntegration;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.type,
    required this.requiredPermissions,
    required this.supportedPlatforms,
    required this.configuration,
    required this.providedAPIs,
    required this.dependencies,
    required this.security,
    required this.uiIntegration,
  });

  /// Validate manifest data
  bool isValid() {
    // Basic validation
    if (id.isEmpty || name.isEmpty || version.isEmpty) {
      return false;
    }
    
    // Must support at least one platform
    if (supportedPlatforms.isEmpty) {
      return false;
    }
    
    // Security requirements must be valid
    if (!security.isValid()) {
      return false;
    }
    
    return true;
  }

  /// Check if manifest supports platform
  bool supportsPlatform(String platform) {
    return supportedPlatforms.contains(platform);
  }

  /// Get configuration for specific key
  T? getConfig<T>(String key) {
    return configuration[key] as T?;
  }

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      type: PluginType.values.firstWhere((e) => e.name == json['type']),
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>)
          .map((e) => Permission.values.firstWhere((p) => p.name == e))
          .toList(),
      supportedPlatforms: (json['supportedPlatforms'] as List<dynamic>).cast<String>(),
      configuration: json['configuration'] as Map<String, dynamic>,
      providedAPIs: (json['providedAPIs'] as List<dynamic>)
          .map((e) => APIEndpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => Dependency.fromJson(e as Map<String, dynamic>))
          .toList(),
      security: SecurityRequirements.fromJson(json['security'] as Map<String, dynamic>),
      uiIntegration: UIIntegration.fromJson(json['uiIntegration'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type.name,
      'requiredPermissions': requiredPermissions.map((e) => e.name).toList(),
      'supportedPlatforms': supportedPlatforms,
      'configuration': configuration,
      'providedAPIs': providedAPIs.map((e) => e.toJson()).toList(),
      'dependencies': dependencies.map((e) => e.toJson()).toList(),
      'security': security.toJson(),
      'uiIntegration': uiIntegration.toJson(),
    };
  }
}

/// Runtime type for external plugins
enum PluginRuntimeType {
  executable,
  webApp,
  container,
  native,
  script
}

/// Security level for external plugins
enum SecurityLevel {
  minimal,    // Basic sandboxing
  standard,   // Standard security controls
  strict,     // Enhanced security with limited access
  isolated    // Maximum isolation with minimal permissions
}

/// Platform requirements for external plugins
class PlatformRequirements {
  final String minVersion;
  final String? maxVersion;
  final List<String> requiredFeatures;
  final Map<String, String> systemRequirements;

  const PlatformRequirements({
    required this.minVersion,
    this.maxVersion,
    required this.requiredFeatures,
    required this.systemRequirements,
  });

  factory PlatformRequirements.fromJson(Map<String, dynamic> json) {
    return PlatformRequirements(
      minVersion: json['minVersion'] as String,
      maxVersion: json['maxVersion'] as String?,
      requiredFeatures: (json['requiredFeatures'] as List<dynamic>).cast<String>(),
      systemRequirements: (json['systemRequirements'] as Map<String, dynamic>).cast<String, String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minVersion': minVersion,
      'maxVersion': maxVersion,
      'requiredFeatures': requiredFeatures,
      'systemRequirements': systemRequirements,
    };
  }
}

/// Platform-specific asset information
class PlatformAsset {
  final String platform;
  final String assetPath;
  final String assetType;
  final int size;
  final String checksum;
  final Map<String, dynamic> metadata;

  const PlatformAsset({
    required this.platform,
    required this.assetPath,
    required this.assetType,
    required this.size,
    required this.checksum,
    required this.metadata,
  });

  factory PlatformAsset.fromJson(Map<String, dynamic> json) {
    return PlatformAsset(
      platform: json['platform'] as String,
      assetPath: json['assetPath'] as String,
      assetType: json['assetType'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'assetPath': assetPath,
      'assetType': assetType,
      'size': size,
      'checksum': checksum,
      'metadata': metadata,
    };
  }
}

/// Security signature for plugin packages
class SecuritySignature {
  final String algorithm;
  final String signature;
  final String publicKey;
  final DateTime timestamp;

  const SecuritySignature({
    required this.algorithm,
    required this.signature,
    required this.publicKey,
    required this.timestamp,
  });

  /// Validate signature format
  bool isValid() {
    return algorithm.isNotEmpty && 
           signature.isNotEmpty && 
           publicKey.isNotEmpty;
  }

  factory SecuritySignature.fromJson(Map<String, dynamic> json) {
    return SecuritySignature(
      algorithm: json['algorithm'] as String,
      signature: json['signature'] as String,
      publicKey: json['publicKey'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm,
      'signature': signature,
      'publicKey': publicKey,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Plugin dependency information
class Dependency {
  final String id;
  final String name;
  final String version;
  final bool required;
  final String? downloadUrl;

  const Dependency({
    required this.id,
    required this.name,
    required this.version,
    required this.required,
    this.downloadUrl,
  });

  factory Dependency.fromJson(Map<String, dynamic> json) {
    return Dependency(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      required: json['required'] as bool,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'required': required,
      'downloadUrl': downloadUrl,
    };
  }
}

/// API endpoint provided by plugin
class APIEndpoint {
  final String name;
  final String method;
  final String path;
  final Map<String, String> parameters;
  final String description;

  const APIEndpoint({
    required this.name,
    required this.method,
    required this.path,
    required this.parameters,
    required this.description,
  });

  factory APIEndpoint.fromJson(Map<String, dynamic> json) {
    return APIEndpoint(
      name: json['name'] as String,
      method: json['method'] as String,
      path: json['path'] as String,
      parameters: (json['parameters'] as Map<String, dynamic>).cast<String, String>(),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'method': method,
      'path': path,
      'parameters': parameters,
      'description': description,
    };
  }
}

/// Security requirements for plugin
class SecurityRequirements {
  final SecurityLevel level;
  final List<String> allowedDomains;
  final List<String> blockedDomains;
  final ResourceLimits resourceLimits;
  final bool requiresSignature;

  const SecurityRequirements({
    required this.level,
    required this.allowedDomains,
    required this.blockedDomains,
    required this.resourceLimits,
    required this.requiresSignature,
  });

  /// Validate security requirements
  bool isValid() {
    return resourceLimits.isValid();
  }

  factory SecurityRequirements.fromJson(Map<String, dynamic> json) {
    return SecurityRequirements(
      level: SecurityLevel.values.firstWhere((e) => e.name == json['level']),
      allowedDomains: (json['allowedDomains'] as List<dynamic>).cast<String>(),
      blockedDomains: (json['blockedDomains'] as List<dynamic>).cast<String>(),
      resourceLimits: ResourceLimits.fromJson(json['resourceLimits'] as Map<String, dynamic>),
      requiresSignature: json['requiresSignature'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'allowedDomains': allowedDomains,
      'blockedDomains': blockedDomains,
      'resourceLimits': resourceLimits.toJson(),
      'requiresSignature': requiresSignature,
    };
  }
}

/// Resource limits for plugin execution
class ResourceLimits {
  final int maxMemoryMB;
  final double maxCpuPercent;
  final int maxNetworkKbps;
  final int maxFileHandles;
  final Duration maxExecutionTime;

  const ResourceLimits({
    required this.maxMemoryMB,
    required this.maxCpuPercent,
    required this.maxNetworkKbps,
    required this.maxFileHandles,
    required this.maxExecutionTime,
  });

  /// Validate resource limits
  bool isValid() {
    return maxMemoryMB > 0 && 
           maxCpuPercent > 0 && 
           maxNetworkKbps >= 0 && 
           maxFileHandles > 0 &&
           maxExecutionTime.inSeconds > 0;
  }

  factory ResourceLimits.fromJson(Map<String, dynamic> json) {
    return ResourceLimits(
      maxMemoryMB: json['maxMemoryMB'] as int,
      maxCpuPercent: (json['maxCpuPercent'] as num).toDouble(),
      maxNetworkKbps: json['maxNetworkKbps'] as int,
      maxFileHandles: json['maxFileHandles'] as int,
      maxExecutionTime: Duration(seconds: json['maxExecutionTimeSeconds'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxMemoryMB': maxMemoryMB,
      'maxCpuPercent': maxCpuPercent,
      'maxNetworkKbps': maxNetworkKbps,
      'maxFileHandles': maxFileHandles,
      'maxExecutionTimeSeconds': maxExecutionTime.inSeconds,
    };
  }
}

/// UI integration configuration
class UIIntegration {
  final String containerType;
  final Map<String, dynamic> containerConfig;
  final bool supportsTheming;
  final List<String> supportedInputMethods;

  const UIIntegration({
    required this.containerType,
    required this.containerConfig,
    required this.supportsTheming,
    required this.supportedInputMethods,
  });

  factory UIIntegration.fromJson(Map<String, dynamic> json) {
    return UIIntegration(
      containerType: json['containerType'] as String,
      containerConfig: json['containerConfig'] as Map<String, dynamic>,
      supportsTheming: json['supportsTheming'] as bool,
      supportedInputMethods: (json['supportedInputMethods'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerType': containerType,
      'containerConfig': containerConfig,
      'supportsTheming': supportsTheming,
      'supportedInputMethods': supportedInputMethods,
    };
  }
}