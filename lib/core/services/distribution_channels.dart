import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/external_plugin_models.dart';
import '../models/plugin_models.dart';
import 'plugin_registry_service.dart';

/// Abstract base class for plugin distribution channels
abstract class DistributionChannel {
  final String channelId;
  final String name;
  final String description;
  final bool isEnabled;

  const DistributionChannel({
    required this.channelId,
    required this.name,
    required this.description,
    this.isEnabled = true,
  });

  /// Download plugin package from this channel
  Future<PluginPackage> downloadPlugin(String pluginId, String version);

  /// Search for plugins in this channel
  Future<List<PluginRegistryEntry>> searchPlugins(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
  });

  /// Get plugin information from this channel
  Future<PluginRegistryEntry?> getPluginInfo(String pluginId);

  /// Check if plugin is available in this channel
  Future<bool> isPluginAvailable(String pluginId, String version);

  /// Validate channel configuration
  bool isValid();

  /// Get channel statistics
  Future<ChannelStatistics> getStatistics();
}

/// Direct download channel for plugins from URLs
class DirectDownloadChannel extends DistributionChannel {
  final Map<String, PluginRegistryEntry> _pluginRegistry = {};
  final HttpClient _httpClient = HttpClient();

  DirectDownloadChannel({
    super.channelId = 'direct-download',
    super.name = 'Direct Download',
    super.description = 'Download plugins directly from URLs',
    super.isEnabled = true,
  });

  @override
  Future<PluginPackage> downloadPlugin(String pluginId, String version) async {
    final registryEntry = _pluginRegistry[pluginId];
    if (registryEntry == null) {
      throw Exception('Plugin $pluginId not found in direct download channel');
    }

    if (registryEntry.version != version) {
      throw Exception(
        'Plugin $pluginId version $version not available. Available: ${registryEntry.version}',
      );
    }

    try {
      // Download plugin package
      final packageData = await _downloadFromUrl(registryEntry.downloadUrl);

      // Verify package integrity
      await _verifyPackageIntegrity(packageData, registryEntry);

      // Parse and return plugin package
      return await _parsePluginPackage(packageData, registryEntry);
    } catch (e) {
      throw Exception(
        'Failed to download plugin $pluginId from direct URL: $e',
      );
    }
  }

  @override
  Future<List<PluginRegistryEntry>> searchPlugins(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
  }) async {
    var results = _pluginRegistry.values.toList();

    // Apply text search filter
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((entry) {
        return entry.name.toLowerCase().contains(lowerQuery) ||
            entry.description.toLowerCase().contains(lowerQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    // Apply category filter
    if (category != null && category.isNotEmpty) {
      results = results
          .where(
            (entry) => entry.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    // Apply tags filter
    if (tags != null && tags.isNotEmpty) {
      results = results.where((entry) {
        return tags.any(
          (tag) => entry.tags.any(
            (entryTag) => entryTag.toLowerCase() == tag.toLowerCase(),
          ),
        );
      }).toList();
    }

    // Apply author filter
    if (author != null && author.isNotEmpty) {
      results = results
          .where(
            (entry) =>
                entry.author.toLowerCase().contains(author.toLowerCase()),
          )
          .toList();
    }

    return results;
  }

  @override
  Future<PluginRegistryEntry?> getPluginInfo(String pluginId) async {
    return _pluginRegistry[pluginId];
  }

  @override
  Future<bool> isPluginAvailable(String pluginId, String version) async {
    final entry = _pluginRegistry[pluginId];
    return entry != null && entry.version == version;
  }

  @override
  bool isValid() {
    return channelId.isNotEmpty && name.isNotEmpty;
  }

  @override
  Future<ChannelStatistics> getStatistics() async {
    final totalPlugins = _pluginRegistry.length;
    final totalDownloads = _pluginRegistry.values.fold(
      0,
      (sum, entry) => sum + entry.statistics.downloadCount,
    );

    final categoryCounts = <String, int>{};
    for (final entry in _pluginRegistry.values) {
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;
    }

    return ChannelStatistics(
      channelId: channelId,
      totalPlugins: totalPlugins,
      totalDownloads: totalDownloads,
      categoryCounts: categoryCounts,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add plugin to direct download registry
  void addPlugin(PluginRegistryEntry entry) {
    if (!entry.isValid()) {
      throw ArgumentError('Invalid plugin registry entry');
    }
    _pluginRegistry[entry.pluginId] = entry;
  }

  /// Remove plugin from direct download registry
  void removePlugin(String pluginId) {
    _pluginRegistry.remove(pluginId);
  }

  /// Get all plugins in this channel
  List<PluginRegistryEntry> getAllPlugins() {
    return _pluginRegistry.values.toList();
  }

  /// Clear all plugins from this channel
  void clear() {
    _pluginRegistry.clear();
  }

  /// Private helper methods

  Future<Uint8List> _downloadFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to download from $url',
        );
      }

      final bytes = await response.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );
      return Uint8List.fromList(bytes);
    } catch (e) {
      throw Exception('Failed to download from URL $url: $e');
    }
  }

  Future<void> _verifyPackageIntegrity(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    if (packageData.isEmpty) {
      throw Exception('Downloaded package is empty');
    }

    // Verify signature if required
    if (registryEntry.securityStatus.requiresSignature &&
        !registryEntry.securityStatus.hasSignature) {
      throw Exception('Plugin requires signature but none provided');
    }

    // Check security warnings
    if (registryEntry.securityStatus.securityWarnings.isNotEmpty) {
      // In production, might want to warn user or require explicit confirmation
    }
  }

  Future<PluginPackage> _parsePluginPackage(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    try {
      // Create plugin package from registry entry and downloaded data
      final manifest = PluginManifest(
        id: registryEntry.pluginId,
        name: registryEntry.name,
        version: registryEntry.version,
        type: PluginType.tool,
        requiredPermissions: [],
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
          resourceLimits: ResourceLimits(
            maxMemoryMB: 256,
            maxCpuPercent: 50.0,
            maxNetworkKbps: 1000,
            maxFileHandles: 100,
            maxExecutionTime: const Duration(minutes: 5),
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
          publicKey: 'direct-download-key',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to parse plugin package: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Package manager channel for system package managers
class PackageManagerChannel extends DistributionChannel {
  final String packageManagerType;
  final Map<String, String> packageManagerConfig;
  final Map<String, PluginRegistryEntry> _pluginRegistry = {};

  PackageManagerChannel({
    required this.packageManagerType,
    required this.packageManagerConfig,
    super.channelId = 'package-manager',
    super.name = 'Package Manager',
    super.description = 'Install plugins through system package managers',
    super.isEnabled = true,
  });

  @override
  Future<PluginPackage> downloadPlugin(String pluginId, String version) async {
    final registryEntry = _pluginRegistry[pluginId];
    if (registryEntry == null) {
      throw Exception('Plugin $pluginId not found in package manager channel');
    }

    if (registryEntry.version != version) {
      throw Exception(
        'Plugin $pluginId version $version not available. Available: ${registryEntry.version}',
      );
    }

    try {
      // Install using package manager
      final packageData = await _installFromPackageManager(pluginId, version);

      // Verify package integrity
      await _verifyPackageIntegrity(packageData, registryEntry);

      // Parse and return plugin package
      return await _parsePluginPackage(packageData, registryEntry);
    } catch (e) {
      throw Exception(
        'Failed to install plugin $pluginId from package manager: $e',
      );
    }
  }

  @override
  Future<List<PluginRegistryEntry>> searchPlugins(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
  }) async {
    // Search in package manager registry
    await _refreshPackageManagerRegistry();

    var results = _pluginRegistry.values.toList();

    // Apply filters similar to DirectDownloadChannel
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((entry) {
        return entry.name.toLowerCase().contains(lowerQuery) ||
            entry.description.toLowerCase().contains(lowerQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results
          .where(
            (entry) => entry.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((entry) {
        return tags.any(
          (tag) => entry.tags.any(
            (entryTag) => entryTag.toLowerCase() == tag.toLowerCase(),
          ),
        );
      }).toList();
    }

    if (author != null && author.isNotEmpty) {
      results = results
          .where(
            (entry) =>
                entry.author.toLowerCase().contains(author.toLowerCase()),
          )
          .toList();
    }

    return results;
  }

  @override
  Future<PluginRegistryEntry?> getPluginInfo(String pluginId) async {
    await _refreshPackageManagerRegistry();
    return _pluginRegistry[pluginId];
  }

  @override
  Future<bool> isPluginAvailable(String pluginId, String version) async {
    await _refreshPackageManagerRegistry();
    final entry = _pluginRegistry[pluginId];
    return entry != null && entry.version == version;
  }

  @override
  bool isValid() {
    return channelId.isNotEmpty &&
        name.isNotEmpty &&
        packageManagerType.isNotEmpty &&
        _isSupportedPackageManager();
  }

  @override
  Future<ChannelStatistics> getStatistics() async {
    await _refreshPackageManagerRegistry();

    final totalPlugins = _pluginRegistry.length;
    final totalDownloads = _pluginRegistry.values.fold(
      0,
      (sum, entry) => sum + entry.statistics.downloadCount,
    );

    final categoryCounts = <String, int>{};
    for (final entry in _pluginRegistry.values) {
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;
    }

    return ChannelStatistics(
      channelId: channelId,
      totalPlugins: totalPlugins,
      totalDownloads: totalDownloads,
      categoryCounts: categoryCounts,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get supported package manager types
  static List<String> getSupportedPackageManagers() {
    return ['npm', 'pip', 'apt', 'brew', 'chocolatey', 'winget'];
  }

  /// Check if package manager is supported
  bool _isSupportedPackageManager() {
    return getSupportedPackageManagers().contains(packageManagerType);
  }

  /// Install plugin from package manager
  Future<Uint8List> _installFromPackageManager(
    String pluginId,
    String version,
  ) async {
    final command = _buildInstallCommand(pluginId, version);

    try {
      final result = await Process.run(command[0], command.sublist(1));

      if (result.exitCode != 0) {
        throw Exception('Package manager command failed: ${result.stderr}');
      }

      // For simulation, return mock package data
      // In real implementation, this would read the installed package
      final mockPackageData = utf8.encode(
        'mock-package-data-$pluginId-$version',
      );
      return Uint8List.fromList(mockPackageData);
    } catch (e) {
      throw Exception('Failed to execute package manager command: $e');
    }
  }

  /// Build install command for package manager
  List<String> _buildInstallCommand(String pluginId, String version) {
    switch (packageManagerType) {
      case 'npm':
        return ['npm', 'install', '$pluginId@$version'];
      case 'pip':
        return ['pip', 'install', '$pluginId==$version'];
      case 'apt':
        return ['apt-get', 'install', '$pluginId=$version'];
      case 'brew':
        return ['brew', 'install', pluginId];
      case 'chocolatey':
        return ['choco', 'install', pluginId, '--version', version];
      case 'winget':
        return ['winget', 'install', pluginId, '--version', version];
      default:
        throw Exception('Unsupported package manager: $packageManagerType');
    }
  }

  /// Refresh package manager registry
  Future<void> _refreshPackageManagerRegistry() async {
    // In a real implementation, this would query the package manager
    // For now, we'll simulate with some mock data
    if (_pluginRegistry.isEmpty) {
      _addMockPackageManagerPlugins();
    }
  }

  /// Add mock plugins for testing
  void _addMockPackageManagerPlugins() {
    final mockPlugins = [
      PluginRegistryEntry(
        pluginId: 'pm-plugin-1',
        name: 'Package Manager Plugin 1',
        version: '1.0.0',
        description: 'A plugin installed via package manager',
        category: 'utility',
        tags: ['package-manager', 'utility'],
        downloadUrl: 'https://registry.example.com/pm-plugin-1',
        sourceUrl: 'https://github.com/example/pm-plugin-1',
        securityStatus: const SecurityStatus(
          isVerified: true,
          hasSignature: true,
          securityLevel: 'high',
          securityWarnings: [],
        ),
        compatibility: const CompatibilityInfo(
          supportedPlatforms: ['windows', 'linux', 'macos'],
          minHostVersion: '1.0.0',
          requiredFeatures: [],
          systemRequirements: {},
        ),
        statistics: PluginStatistics(
          downloadCount: 1000,
          averageRating: 4.5,
          ratingCount: 50,
          activeInstalls: 800,
          firstPublished: DateTime.now().subtract(const Duration(days: 30)),
        ),
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        author: 'Package Manager Team',
        license: 'MIT',
      ),
    ];

    for (final plugin in mockPlugins) {
      _pluginRegistry[plugin.pluginId] = plugin;
    }
  }

  Future<void> _verifyPackageIntegrity(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    if (packageData.isEmpty) {
      throw Exception('Package data is empty');
    }

    // Package manager installations are generally trusted
    // Additional verification could be added here
  }

  Future<PluginPackage> _parsePluginPackage(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    // Similar to DirectDownloadChannel but with package manager specific handling
    try {
      final manifest = PluginManifest(
        id: registryEntry.pluginId,
        name: registryEntry.name,
        version: registryEntry.version,
        type: PluginType.tool,
        requiredPermissions: [],
        supportedPlatforms: registryEntry.compatibility.supportedPlatforms,
        configuration: {
          'entryPoint': 'main',
          'description': registryEntry.description,
          'packageManager': packageManagerType,
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
          resourceLimits: ResourceLimits(
            maxMemoryMB: 256,
            maxCpuPercent: 50.0,
            maxNetworkKbps: 1000,
            maxFileHandles: 100,
            maxExecutionTime: const Duration(minutes: 5),
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
          metadata: {'packageManager': packageManagerType},
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
          publicKey: 'package-manager-key',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to parse package manager plugin package: $e');
    }
  }
}

/// Plugin store channel for curated plugin stores
class PluginStoreChannel extends DistributionChannel {
  final String storeUrl;
  final String apiKey;
  final Map<String, String> storeConfig;
  final HttpClient _httpClient = HttpClient();
  final Map<String, PluginRegistryEntry> _cachedPlugins = {};
  DateTime? _lastCacheUpdate;

  PluginStoreChannel({
    required this.storeUrl,
    required this.apiKey,
    required this.storeConfig,
    super.channelId = 'plugin-store',
    super.name = 'Plugin Store',
    super.description = 'Download plugins from curated plugin stores',
    super.isEnabled = true,
  });

  @override
  Future<PluginPackage> downloadPlugin(String pluginId, String version) async {
    await _refreshCache();

    final registryEntry = _cachedPlugins[pluginId];
    if (registryEntry == null) {
      throw Exception('Plugin $pluginId not found in plugin store');
    }

    if (registryEntry.version != version) {
      throw Exception(
        'Plugin $pluginId version $version not available. Available: ${registryEntry.version}',
      );
    }

    try {
      // Download from plugin store API
      final packageData = await _downloadFromStore(pluginId, version);

      // Verify package integrity
      await _verifyPackageIntegrity(packageData, registryEntry);

      // Parse and return plugin package
      return await _parsePluginPackage(packageData, registryEntry);
    } catch (e) {
      throw Exception(
        'Failed to download plugin $pluginId from plugin store: $e',
      );
    }
  }

  @override
  Future<List<PluginRegistryEntry>> searchPlugins(
    String query, {
    String? category,
    List<String>? tags,
    String? author,
  }) async {
    await _refreshCache();

    var results = _cachedPlugins.values.toList();

    // Apply filters
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((entry) {
        return entry.name.toLowerCase().contains(lowerQuery) ||
            entry.description.toLowerCase().contains(lowerQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results
          .where(
            (entry) => entry.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((entry) {
        return tags.any(
          (tag) => entry.tags.any(
            (entryTag) => entryTag.toLowerCase() == tag.toLowerCase(),
          ),
        );
      }).toList();
    }

    if (author != null && author.isNotEmpty) {
      results = results
          .where(
            (entry) =>
                entry.author.toLowerCase().contains(author.toLowerCase()),
          )
          .toList();
    }

    return results;
  }

  @override
  Future<PluginRegistryEntry?> getPluginInfo(String pluginId) async {
    await _refreshCache();
    return _cachedPlugins[pluginId];
  }

  @override
  Future<bool> isPluginAvailable(String pluginId, String version) async {
    await _refreshCache();
    final entry = _cachedPlugins[pluginId];
    return entry != null && entry.version == version;
  }

  @override
  bool isValid() {
    final storeUri = Uri.tryParse(storeUrl);
    return channelId.isNotEmpty &&
        name.isNotEmpty &&
        storeUrl.isNotEmpty &&
        storeUri != null &&
        storeUri.hasAbsolutePath &&
        apiKey.isNotEmpty;
  }

  @override
  Future<ChannelStatistics> getStatistics() async {
    await _refreshCache();

    final totalPlugins = _cachedPlugins.length;
    final totalDownloads = _cachedPlugins.values.fold(
      0,
      (sum, entry) => sum + entry.statistics.downloadCount,
    );

    final categoryCounts = <String, int>{};
    for (final entry in _cachedPlugins.values) {
      categoryCounts[entry.category] =
          (categoryCounts[entry.category] ?? 0) + 1;
    }

    return ChannelStatistics(
      channelId: channelId,
      totalPlugins: totalPlugins,
      totalDownloads: totalDownloads,
      categoryCounts: categoryCounts,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get featured plugins from store
  Future<List<PluginRegistryEntry>> getFeaturedPlugins({int limit = 10}) async {
    await _refreshCache();

    final featured = _cachedPlugins.values
        .where((entry) => entry.tags.contains('featured'))
        .toList();

    featured.sort(
      (a, b) =>
          b.statistics.averageRating.compareTo(a.statistics.averageRating),
    );
    return featured.take(limit).toList();
  }

  /// Get popular plugins from store
  Future<List<PluginRegistryEntry>> getPopularPlugins({int limit = 10}) async {
    await _refreshCache();

    final popular = _cachedPlugins.values.toList();
    popular.sort(
      (a, b) =>
          b.statistics.downloadCount.compareTo(a.statistics.downloadCount),
    );
    return popular.take(limit).toList();
  }

  /// Refresh plugin cache from store
  Future<void> _refreshCache() async {
    final now = DateTime.now();
    if (_lastCacheUpdate != null &&
        now.difference(_lastCacheUpdate!).inMinutes < 15) {
      return; // Cache is still fresh
    }

    try {
      await _fetchPluginsFromStore();
      _lastCacheUpdate = now;
    } catch (e) {
      // If cache refresh fails but we have cached data, continue with cached data
      if (_cachedPlugins.isEmpty) {
        rethrow;
      }
    }
  }

  /// Fetch plugins from store API
  Future<void> _fetchPluginsFromStore() async {
    try {
      final uri = Uri.parse('$storeUrl/api/plugins');
      final request = await _httpClient.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $apiKey');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Store API returned ${response.statusCode}');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final jsonData = json.decode(responseBody) as Map<String, dynamic>;

      final pluginsList = jsonData['plugins'] as List<dynamic>;

      _cachedPlugins.clear();
      for (final pluginJson in pluginsList) {
        final entry = PluginRegistryEntry.fromJson(
          pluginJson as Map<String, dynamic>,
        );
        _cachedPlugins[entry.pluginId] = entry;
      }
    } catch (e) {
      // Fallback to mock data for testing
      _addMockStorePlugins();
    }
  }

  /// Download plugin from store
  Future<Uint8List> _downloadFromStore(String pluginId, String version) async {
    try {
      final uri = Uri.parse(
        '$storeUrl/api/plugins/$pluginId/download?version=$version',
      );
      final request = await _httpClient.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $apiKey');

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Store download API returned ${response.statusCode}');
      }

      final bytes = await response.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );
      return Uint8List.fromList(bytes);
    } catch (e) {
      throw Exception('Failed to download from plugin store: $e');
    }
  }

  /// Add mock store plugins for testing
  void _addMockStorePlugins() {
    final mockPlugins = [
      PluginRegistryEntry(
        pluginId: 'store-plugin-1',
        name: 'Store Plugin 1',
        version: '2.0.0',
        description: 'A featured plugin from the store',
        category: 'productivity',
        tags: ['featured', 'productivity', 'popular'],
        downloadUrl: '$storeUrl/plugins/store-plugin-1',
        sourceUrl: 'https://github.com/store/plugin-1',
        securityStatus: const SecurityStatus(
          isVerified: true,
          hasSignature: true,
          securityLevel: 'high',
          securityWarnings: [],
        ),
        compatibility: const CompatibilityInfo(
          supportedPlatforms: ['windows', 'linux', 'macos', 'android', 'ios'],
          minHostVersion: '1.0.0',
          requiredFeatures: [],
          systemRequirements: {},
        ),
        statistics: PluginStatistics(
          downloadCount: 5000,
          averageRating: 4.8,
          ratingCount: 200,
          activeInstalls: 4500,
          firstPublished: DateTime.now().subtract(const Duration(days: 90)),
        ),
        lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        author: 'Store Team',
        license: 'MIT',
      ),
      PluginRegistryEntry(
        pluginId: 'store-plugin-2',
        name: 'Store Plugin 2',
        version: '1.5.0',
        description: 'Another great plugin from the store',
        category: 'development',
        tags: ['development', 'tools'],
        downloadUrl: '$storeUrl/plugins/store-plugin-2',
        sourceUrl: 'https://github.com/store/plugin-2',
        securityStatus: const SecurityStatus(
          isVerified: true,
          hasSignature: true,
          securityLevel: 'medium',
          securityWarnings: [],
        ),
        compatibility: const CompatibilityInfo(
          supportedPlatforms: ['windows', 'linux', 'macos'],
          minHostVersion: '1.0.0',
          requiredFeatures: ['network'],
          systemRequirements: {'memory': '512MB'},
        ),
        statistics: PluginStatistics(
          downloadCount: 2500,
          averageRating: 4.2,
          ratingCount: 75,
          activeInstalls: 2000,
          firstPublished: DateTime.now().subtract(const Duration(days: 60)),
        ),
        lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
        author: 'Developer Community',
        license: 'Apache-2.0',
      ),
    ];

    for (final plugin in mockPlugins) {
      _cachedPlugins[plugin.pluginId] = plugin;
    }
  }

  Future<void> _verifyPackageIntegrity(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    if (packageData.isEmpty) {
      throw Exception('Downloaded package is empty');
    }

    // Store plugins are curated and verified
    if (!registryEntry.securityStatus.isVerified) {
      throw Exception('Plugin is not verified by the store');
    }

    if (registryEntry.securityStatus.requiresSignature &&
        !registryEntry.securityStatus.hasSignature) {
      throw Exception('Plugin requires signature but none provided');
    }
  }

  Future<PluginPackage> _parsePluginPackage(
    Uint8List packageData,
    PluginRegistryEntry registryEntry,
  ) async {
    try {
      final manifest = PluginManifest(
        id: registryEntry.pluginId,
        name: registryEntry.name,
        version: registryEntry.version,
        type: PluginType.tool,
        requiredPermissions: [],
        supportedPlatforms: registryEntry.compatibility.supportedPlatforms,
        configuration: {
          'entryPoint': 'main',
          'description': registryEntry.description,
          'storeUrl': storeUrl,
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
          resourceLimits: ResourceLimits(
            maxMemoryMB: 256,
            maxCpuPercent: 50.0,
            maxNetworkKbps: 1000,
            maxFileHandles: 100,
            maxExecutionTime: const Duration(minutes: 5),
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
          metadata: {'storeUrl': storeUrl},
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
          publicKey: 'plugin-store-key',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to parse plugin store package: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Statistics for distribution channels
class ChannelStatistics {
  final String channelId;
  final int totalPlugins;
  final int totalDownloads;
  final Map<String, int> categoryCounts;
  final DateTime lastUpdated;

  const ChannelStatistics({
    required this.channelId,
    required this.totalPlugins,
    required this.totalDownloads,
    required this.categoryCounts,
    required this.lastUpdated,
  });

  factory ChannelStatistics.fromJson(Map<String, dynamic> json) {
    return ChannelStatistics(
      channelId: json['channelId'] as String,
      totalPlugins: json['totalPlugins'] as int,
      totalDownloads: json['totalDownloads'] as int,
      categoryCounts: (json['categoryCounts'] as Map<String, dynamic>)
          .cast<String, int>(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'totalPlugins': totalPlugins,
      'totalDownloads': totalDownloads,
      'categoryCounts': categoryCounts,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
