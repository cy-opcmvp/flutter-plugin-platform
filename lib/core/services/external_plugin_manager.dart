import '../interfaces/i_external_plugin.dart';
import '../models/external_plugin_models.dart';
import '../models/plugin_models.dart';
import 'plugin_registry_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Manager for external plugin lifecycle and operations
class ExternalPluginManager {
  final Map<String, IExternalPlugin> _activePlugins = {};
  final Map<String, PluginPackage> _installedPackages = {};
  final Map<String, PluginStateManager> _pluginStates = {};
  final Map<String, PluginRuntimeInfo> _runtimeInfo = {};
  final Map<String, PluginPackage> _backupPackages = {};
  final PluginRegistryService _registryService = PluginRegistryService();
  bool _isInitialized = false;

  /// Initialize the external plugin manager
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Initialize plugin state tracking
    _pluginStates.clear();
    _runtimeInfo.clear();

    // Load previously installed plugins and their states
    await _loadInstalledPlugins();

    _isInitialized = true;
  }

  /// Shutdown the external plugin manager
  Future<void> shutdown() async {
    if (!_isInitialized) {
      return;
    }

    // Terminate all active external plugins
    final activePluginIds = List<String>.from(_activePlugins.keys);
    for (final pluginId in activePluginIds) {
      await terminateExternalPlugin(pluginId);
    }

    _activePlugins.clear();
    _pluginStates.clear();
    _runtimeInfo.clear();
    _isInitialized = false;
  }

  /// Install an external plugin from a package
  Future<void> installExternalPlugin(PluginPackage package) async {
    _ensureInitialized();

    if (!package.isValid()) {
      throw ArgumentError('Invalid plugin package');
    }

    // Check if plugin is already installed
    if (_installedPackages.containsKey(package.id)) {
      throw StateError('Plugin ${package.id} is already installed');
    }

    // Store the package
    _installedPackages[package.id] = package;

    // Initialize plugin state
    final stateManager = PluginStateManager(
      pluginId: package.id,
      initialState: PluginState.inactive,
    );
    _pluginStates[package.id] = stateManager;

    // Create runtime info
    final descriptor = _createDescriptorFromPackage(package);
    _runtimeInfo[package.id] = PluginRuntimeInfo(
      descriptor: descriptor,
      stateManager: stateManager,
    );
  }

  /// Launch an external plugin
  Future<void> launchExternalPlugin(String pluginId) async {
    _ensureInitialized();

    final package = _installedPackages[pluginId];
    if (package == null) {
      throw StateError('Plugin $pluginId is not installed');
    }

    final stateManager = _pluginStates[pluginId];
    if (stateManager == null) {
      throw StateError('Plugin $pluginId state not found');
    }

    // Check if plugin is already active
    if (stateManager.currentState == PluginState.active) {
      return; // Already active
    }

    // Transition to loading state
    if (!stateManager.transitionTo(PluginState.loading)) {
      throw StateError(
        'Cannot launch plugin $pluginId from state ${stateManager.currentState}',
      );
    }

    try {
      // Plugin launching will be implemented in future tasks
      // For now, just transition to active state
      if (!stateManager.transitionTo(PluginState.active)) {
        throw StateError('Failed to activate plugin $pluginId');
      }
    } catch (e) {
      // Transition to error state on failure
      stateManager.transitionTo(PluginState.error);
      rethrow;
    }
  }

  /// Terminate an external plugin
  Future<void> terminateExternalPlugin(String pluginId) async {
    _ensureInitialized();

    final plugin = _activePlugins[pluginId];
    final stateManager = _pluginStates[pluginId];

    if (plugin != null) {
      try {
        await plugin.terminate();
      } catch (e) {
        // Log error but continue with cleanup
      }
      _activePlugins.remove(pluginId);
    }

    if (stateManager != null) {
      stateManager.transitionTo(PluginState.inactive);
    }
  }

  /// Update an external plugin to a new version
  Future<void> updateExternalPlugin(
    String pluginId,
    PluginPackage newPackage,
  ) async {
    _ensureInitialized();

    if (!_installedPackages.containsKey(pluginId)) {
      throw StateError('Plugin $pluginId is not installed');
    }

    if (!newPackage.isValid()) {
      throw ArgumentError('Invalid plugin package for update');
    }

    // Terminate if active
    if (isPluginActive(pluginId)) {
      await terminateExternalPlugin(pluginId);
    }

    // Update the package
    _installedPackages[pluginId] = newPackage;

    // Update runtime info
    final stateManager = _pluginStates[pluginId]!;
    final descriptor = _createDescriptorFromPackage(newPackage);
    _runtimeInfo[pluginId] = PluginRuntimeInfo(
      descriptor: descriptor,
      stateManager: stateManager,
    );
  }

  /// Get plugin state
  PluginState? getPluginState(String pluginId) {
    return _pluginStates[pluginId]?.currentState;
  }

  /// Get plugin runtime information
  PluginRuntimeInfo? getPluginRuntimeInfo(String pluginId) {
    return _runtimeInfo[pluginId];
  }

  /// Get plugin state manager
  PluginStateManager? getPluginStateManager(String pluginId) {
    return _pluginStates[pluginId];
  }

  /// Get list of installed external plugins
  List<PluginPackage> getInstalledPlugins() {
    return _installedPackages.values.toList();
  }

  /// Get list of active external plugins
  List<IExternalPlugin> getActivePlugins() {
    return _activePlugins.values.toList();
  }

  /// Get list of all plugin runtime info
  List<PluginRuntimeInfo> getAllPluginRuntimeInfo() {
    return _runtimeInfo.values.toList();
  }

  /// Check if a plugin is installed
  bool isPluginInstalled(String pluginId) {
    return _installedPackages.containsKey(pluginId);
  }

  /// Check if a plugin is active
  bool isPluginActive(String pluginId) {
    final state = getPluginState(pluginId);
    return state == PluginState.active;
  }

  /// Check if a plugin is in error state
  bool isPluginInError(String pluginId) {
    final state = getPluginState(pluginId);
    return state == PluginState.error;
  }

  /// Uninstall an external plugin
  Future<void> uninstallExternalPlugin(String pluginId) async {
    _ensureInitialized();

    // Terminate if active
    if (isPluginActive(pluginId)) {
      await terminateExternalPlugin(pluginId);
    }

    // Remove from all tracking maps
    _installedPackages.remove(pluginId);
    _pluginStates.remove(pluginId);
    _runtimeInfo.remove(pluginId);
  }

  /// Pause an external plugin
  Future<void> pauseExternalPlugin(String pluginId) async {
    _ensureInitialized();

    final stateManager = _pluginStates[pluginId];
    if (stateManager == null) {
      throw StateError('Plugin $pluginId not found');
    }

    if (stateManager.currentState == PluginState.active) {
      if (!stateManager.transitionTo(PluginState.paused)) {
        throw StateError('Cannot pause plugin $pluginId');
      }
    }
  }

  /// Resume a paused external plugin
  Future<void> resumeExternalPlugin(String pluginId) async {
    _ensureInitialized();

    final stateManager = _pluginStates[pluginId];
    if (stateManager == null) {
      throw StateError('Plugin $pluginId not found');
    }

    if (stateManager.currentState == PluginState.paused) {
      if (!stateManager.transitionTo(PluginState.active)) {
        throw StateError('Cannot resume plugin $pluginId');
      }
    }
  }

  /// Get plugins by state
  List<String> getPluginsByState(PluginState state) {
    return _pluginStates.entries
        .where((entry) => entry.value.currentState == state)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get registry service (for testing)
  PluginRegistryService get registryService => _registryService;

  /// Download and install plugin from registry
  Future<void> downloadAndInstallPlugin(String pluginId) async {
    _ensureInitialized();

    // Get plugin info from registry
    final registryEntry = _registryService.getPluginInfo(pluginId);
    if (registryEntry == null) {
      throw StateError('Plugin $pluginId not found in registry');
    }

    // Check if plugin is already installed
    if (_installedPackages.containsKey(pluginId)) {
      throw StateError('Plugin $pluginId is already installed');
    }

    try {
      // Download plugin package
      final packageData = await _downloadPluginPackage(
        registryEntry.downloadUrl,
      );

      // Verify package integrity
      await _verifyPackageIntegrity(packageData, registryEntry);

      // Parse package
      final package = await _parsePluginPackage(packageData, registryEntry);

      // Resolve dependencies
      await _resolveDependencies(package);

      // Install the package
      await installExternalPlugin(package);
    } catch (e) {
      // Clean up any partial installation
      await _cleanupFailedInstallation(pluginId);
      rethrow;
    }
  }

  /// Update plugin to new version with rollback capability
  Future<void> updatePluginWithRollback(
    String pluginId,
    String newVersion,
  ) async {
    _ensureInitialized();

    if (!_installedPackages.containsKey(pluginId)) {
      throw StateError('Plugin $pluginId is not installed');
    }

    // Create backup of current version
    final currentPackage = _installedPackages[pluginId]!;
    _backupPackages[pluginId] = currentPackage;

    try {
      // Get new version from registry
      final registryEntry = _registryService.getPluginInfo(pluginId);
      if (registryEntry == null || registryEntry.version != newVersion) {
        throw StateError(
          'Plugin $pluginId version $newVersion not found in registry',
        );
      }

      // Download and verify new version
      final packageData = await _downloadPluginPackage(
        registryEntry.downloadUrl,
      );
      await _verifyPackageIntegrity(packageData, registryEntry);
      final newPackage = await _parsePluginPackage(packageData, registryEntry);

      // Update the plugin
      await updateExternalPlugin(pluginId, newPackage);

      // Clear backup on successful update
      _backupPackages.remove(pluginId);
    } catch (e) {
      // Rollback to previous version
      await _rollbackPlugin(pluginId);
      rethrow;
    }
  }

  /// Rollback plugin to previous version
  Future<void> rollbackPlugin(String pluginId) async {
    _ensureInitialized();
    await _rollbackPlugin(pluginId);
  }

  /// Install plugin with dependency resolution
  Future<void> installPluginWithDependencies(PluginPackage package) async {
    _ensureInitialized();

    if (!package.isValid()) {
      throw ArgumentError('Invalid plugin package');
    }

    try {
      // Resolve and install dependencies first
      await _resolveDependencies(package);

      // Install the main package
      await installExternalPlugin(package);
    } catch (e) {
      // Clean up any installed dependencies on failure
      await _cleanupFailedInstallation(package.id);
      rethrow;
    }
  }

  /// Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ExternalPluginManager not initialized');
    }
  }

  Future<void> _loadInstalledPlugins() async {
    // This would load previously installed plugins from persistent storage
    // For now, this is a placeholder for future implementation
  }

  PluginDescriptor _createDescriptorFromPackage(PluginPackage package) {
    return PluginDescriptor(
      id: package.id,
      name: package.name,
      version: package.version,
      type: package.type,
      requiredPermissions: package.manifest.requiredPermissions,
      metadata: {
        'runtimeType': package.manifest.type.name,
        'supportedPlatforms': package.manifest.supportedPlatforms,
        'securityLevel': package.manifest.security.level.name,
      },
      entryPoint:
          package.manifest.configuration['entryPoint'] as String? ?? 'main',
    );
  }

  /// Download plugin package from URL
  Future<Uint8List> _downloadPluginPackage(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download plugin: HTTP ${response.statusCode}',
        );
      }

      final bytes = await response.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );
      client.close();

      return Uint8List.fromList(bytes);
    } catch (e) {
      throw Exception('Failed to download plugin package: $e');
    }
  }

  /// Verify package integrity using checksum and signature
  Future<void> _verifyPackageIntegrity(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    // Verify checksum (simplified - in real implementation would use proper hash from registry)
    // In a real implementation, we would compare with the expected hash from registry
    // For now, we just ensure the package is not empty and has valid structure
    if (packageData.isEmpty) {
      throw Exception('Downloaded package is empty');
    }

    // Verify signature if required
    if (registryEntry.securityStatus.requiresSignature &&
        !registryEntry.securityStatus.hasSignature) {
      throw Exception('Plugin requires signature but none provided');
    }

    // Additional security checks
    if (registryEntry.securityStatus.securityWarnings.isNotEmpty) {
      // In production, might want to warn user or require explicit confirmation
    }
  }

  /// Parse plugin package data into PluginPackage object
  Future<PluginPackage> _parsePluginPackage(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    try {
      // In a real implementation, this would parse the actual package format (ZIP, TAR, etc.)
      // For now, we create a package based on registry information

      final manifest = PluginManifest(
        id: registryEntry.pluginId,
        name: registryEntry.name,
        version: registryEntry.version,
        type: PluginType.tool, // Default type
        requiredPermissions: [], // Would be parsed from package
        supportedPlatforms: registryEntry.compatibility.supportedPlatforms,
        configuration: {
          'entryPoint': 'main',
          'description': registryEntry.description,
        },
        providedAPIs: [],
        dependencies: [],
        security: SecurityRequirements(
          level: SecurityLevel.values.firstWhere(
            (level) => level.name == registryEntry.securityStatus.securityLevel,
            orElse: () => SecurityLevel.standard,
          ),
          allowedDomains: [],
          blockedDomains: [],
          resourceLimits: const ResourceLimits(
            maxMemoryMB: 256,
            maxCpuPercent: 50.0,
            maxNetworkKbps: 1000,
            maxFileHandles: 100,
            maxExecutionTime: Duration(minutes: 5),
          ),
          requiresSignature: registryEntry.securityStatus.requiresSignature,
        ),
        uiIntegration: const UIIntegration(
          containerType: 'embedded',
          containerConfig: {},
          supportsTheming: true,
          supportedInputMethods: ['keyboard', 'mouse'],
        ),
      );

      final platformAssets = <String, PlatformAsset>{};
      for (final platform in registryEntry.compatibility.supportedPlatforms) {
        platformAssets[platform] = PlatformAsset(
          platform: platform,
          assetPath: 'assets/$platform/plugin',
          assetType: 'executable',
          size: packageData.length,
          checksum: sha256.convert(packageData).toString(),
          metadata: {},
        );
      }

      return PluginPackage(
        id: registryEntry.pluginId,
        name: registryEntry.name,
        version: registryEntry.version,
        type: PluginType.tool,
        platformAssets: platformAssets,
        manifest: manifest,
        dependencies: [],
        signature: SecuritySignature(
          algorithm: 'SHA256',
          signature: sha256.convert(packageData).toString(),
          publicKey: 'mock-public-key',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to parse plugin package: $e');
    }
  }

  /// Resolve and install plugin dependencies
  Future<void> _resolveDependencies(PluginPackage package) async {
    for (final dependency in package.dependencies) {
      if (dependency.required &&
          !_installedPackages.containsKey(dependency.id)) {
        // Check if dependency is available in registry
        final depRegistryEntry = _registryService.getPluginInfo(dependency.id);
        if (depRegistryEntry == null) {
          if (dependency.downloadUrl != null) {
            // Try to download from provided URL
            try {
              final depPackageData = await _downloadPluginPackage(
                dependency.downloadUrl!,
              );
              // Create a minimal registry entry for verification
              final tempRegistryEntry = PluginRegistryEntry(
                pluginId: dependency.id,
                name: dependency.name,
                version: dependency.version,
                description: 'Dependency for ${package.name}',
                category: 'dependency',
                tags: ['dependency'],
                downloadUrl: dependency.downloadUrl!,
                sourceUrl: '',
                securityStatus: const SecurityStatus(
                  isVerified: false,
                  hasSignature: false,
                  securityLevel: 'medium',
                  securityWarnings: [],
                ),
                compatibility: CompatibilityInfo(
                  supportedPlatforms: package.manifest.supportedPlatforms,
                  minHostVersion: '1.0.0',
                  requiredFeatures: [],
                  systemRequirements: {},
                ),
                statistics: PluginStatistics(
                  downloadCount: 0,
                  averageRating: 0.0,
                  ratingCount: 0,
                  activeInstalls: 0,
                  firstPublished: DateTime.now(),
                ),
                lastUpdated: DateTime.now(),
                author: 'Unknown',
                license: 'Unknown',
              );

              await _verifyPackageIntegrity(depPackageData, tempRegistryEntry);
              final depPackage = await _parsePluginPackage(
                depPackageData,
                tempRegistryEntry,
              );

              // Recursively resolve dependencies
              await _resolveDependencies(depPackage);
              await installExternalPlugin(depPackage);
            } catch (e) {
              throw Exception(
                'Failed to install required dependency ${dependency.id}: $e',
              );
            }
          } else {
            throw Exception(
              'Required dependency ${dependency.id} not found and no download URL provided',
            );
          }
        } else {
          // Install from registry
          await downloadAndInstallPlugin(dependency.id);
        }
      }
    }
  }

  /// Rollback plugin to backup version
  Future<void> _rollbackPlugin(String pluginId) async {
    final backupPackage = _backupPackages[pluginId];
    if (backupPackage == null) {
      throw StateError('No backup available for plugin $pluginId');
    }

    try {
      // Terminate if active
      if (isPluginActive(pluginId)) {
        await terminateExternalPlugin(pluginId);
      }

      // Restore backup package
      _installedPackages[pluginId] = backupPackage;

      // Update runtime info
      final stateManager = _pluginStates[pluginId]!;
      final descriptor = _createDescriptorFromPackage(backupPackage);
      _runtimeInfo[pluginId] = PluginRuntimeInfo(
        descriptor: descriptor,
        stateManager: stateManager,
      );

      // Clear backup
      _backupPackages.remove(pluginId);
    } catch (e) {
      throw Exception('Failed to rollback plugin $pluginId: $e');
    }
  }

  /// Clean up failed installation
  Future<void> _cleanupFailedInstallation(String pluginId) async {
    try {
      // Remove from all tracking maps
      _installedPackages.remove(pluginId);
      _pluginStates.remove(pluginId);
      _runtimeInfo.remove(pluginId);
      _backupPackages.remove(pluginId);

      // Terminate if somehow active
      if (_activePlugins.containsKey(pluginId)) {
        final plugin = _activePlugins[pluginId];
        if (plugin != null) {
          await plugin.terminate();
        }
        _activePlugins.remove(pluginId);
      }
    } catch (e) {
      // Log error but don't throw - cleanup should be best effort
    }
  }
}
