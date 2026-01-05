import 'dart:io';
import '../models/external_plugin_models.dart';
import 'distribution_channels.dart';
import 'plugin_registry_service.dart';

/// Manager for plugin distribution across multiple channels
class DistributionManager {
  final Map<String, DistributionChannel> _channels = {};
  bool _isInitialized = false;

  /// Initialize the distribution manager
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Initialize default channels
    await _initializeDefaultChannels();
    
    _isInitialized = true;
  }

  /// Shutdown the distribution manager
  Future<void> shutdown() async {
    if (!_isInitialized) {
      return;
    }

    // Dispose all channels
    for (final channel in _channels.values) {
      if (channel is DirectDownloadChannel) {
        channel.dispose();
      } else if (channel is PluginStoreChannel) {
        channel.dispose();
      }
    }

    _channels.clear();
    _isInitialized = false;
  }

  /// Add a distribution channel
  void addChannel(DistributionChannel channel) {
    _ensureInitialized();
    
    if (!channel.isValid()) {
      throw ArgumentError('Invalid distribution channel');
    }

    _channels[channel.channelId] = channel;
  }

  /// Remove a distribution channel
  void removeChannel(String channelId) {
    _ensureInitialized();
    
    final channel = _channels.remove(channelId);
    if (channel != null) {
      if (channel is DirectDownloadChannel) {
        channel.dispose();
      } else if (channel is PluginStoreChannel) {
        channel.dispose();
      }
    }
  }

  /// Get a distribution channel by ID
  DistributionChannel? getChannel(String channelId) {
    _ensureInitialized();
    return _channels[channelId];
  }

  /// Get all available distribution channels
  List<DistributionChannel> getAllChannels() {
    _ensureInitialized();
    return _channels.values.where((channel) => channel.isEnabled).toList();
  }

  /// Get enabled distribution channels
  List<DistributionChannel> getEnabledChannels() {
    _ensureInitialized();
    return _channels.values.where((channel) => channel.isEnabled).toList();
  }

  /// Search for plugins across all enabled channels
  Future<List<PluginRegistryEntry>> searchPlugins(String query, {
    String? category,
    List<String>? tags,
    String? author,
    List<String>? channelIds,
  }) async {
    _ensureInitialized();
    
    final channels = channelIds != null 
        ? channelIds.map((id) => _channels[id]).where((c) => c != null).cast<DistributionChannel>()
        : getEnabledChannels();

    final allResults = <PluginRegistryEntry>[];
    
    for (final channel in channels) {
      try {
        final results = await channel.searchPlugins(
          query,
          category: category,
          tags: tags,
          author: author,
        );
        allResults.addAll(results);
      } catch (e) {
        // Log error but continue with other channels
        print('Error searching in channel ${channel.channelId}: $e');
      }
    }

    // Remove duplicates based on plugin ID
    final uniqueResults = <String, PluginRegistryEntry>{};
    for (final result in allResults) {
      if (!uniqueResults.containsKey(result.pluginId) ||
          _isNewerVersion(result.version, uniqueResults[result.pluginId]!.version)) {
        uniqueResults[result.pluginId] = result;
      }
    }

    return uniqueResults.values.toList();
  }

  /// Download plugin from the best available channel
  Future<PluginPackage> downloadPlugin(String pluginId, String version, {
    String? preferredChannelId,
  }) async {
    _ensureInitialized();
    
    final channels = preferredChannelId != null 
        ? [_channels[preferredChannelId]].where((c) => c != null).cast<DistributionChannel>()
        : getEnabledChannels();

    Exception? lastException;
    
    for (final channel in channels) {
      try {
        if (await channel.isPluginAvailable(pluginId, version)) {
          return await channel.downloadPlugin(pluginId, version);
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        // Continue to next channel
      }
    }

    throw lastException ?? Exception('Plugin $pluginId version $version not found in any channel');
  }

  /// Get plugin information from all channels
  Future<PluginRegistryEntry?> getPluginInfo(String pluginId, {
    String? preferredChannelId,
  }) async {
    _ensureInitialized();
    
    final channels = preferredChannelId != null 
        ? [_channels[preferredChannelId]].where((c) => c != null).cast<DistributionChannel>()
        : getEnabledChannels();

    for (final channel in channels) {
      try {
        final info = await channel.getPluginInfo(pluginId);
        if (info != null) {
          return info;
        }
      } catch (e) {
        // Continue to next channel
      }
    }

    return null;
  }

  /// Get statistics for all channels
  Future<Map<String, ChannelStatistics>> getAllChannelStatistics() async {
    _ensureInitialized();
    
    final statistics = <String, ChannelStatistics>{};
    
    for (final channel in _channels.values) {
      try {
        statistics[channel.channelId] = await channel.getStatistics();
      } catch (e) {
        // Log error but continue
        print('Error getting statistics for channel ${channel.channelId}: $e');
      }
    }

    return statistics;
  }

  /// Check if plugin is available in any channel
  Future<bool> isPluginAvailable(String pluginId, String version) async {
    _ensureInitialized();
    
    for (final channel in getEnabledChannels()) {
      try {
        if (await channel.isPluginAvailable(pluginId, version)) {
          return true;
        }
      } catch (e) {
        // Continue checking other channels
      }
    }

    return false;
  }

  /// Get available versions of a plugin across all channels
  Future<List<String>> getAvailableVersions(String pluginId) async {
    _ensureInitialized();
    
    final versions = <String>{};
    
    for (final channel in getEnabledChannels()) {
      try {
        final info = await channel.getPluginInfo(pluginId);
        if (info != null) {
          versions.add(info.version);
        }
      } catch (e) {
        // Continue checking other channels
      }
    }

    final versionList = versions.toList();
    versionList.sort(_compareVersions);
    return versionList.reversed.toList(); // Latest first
  }

  /// Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('DistributionManager not initialized. Call initialize() first.');
    }
  }

  Future<void> _initializeDefaultChannels() async {
    // Initialize direct download channel
    final directDownload = DirectDownloadChannel();
    _channels[directDownload.channelId] = directDownload;

    // Initialize package manager channel (if available)
    try {
      final packageManager = PackageManagerChannel(
        packageManagerType: _detectPackageManager(),
        packageManagerConfig: {},
      );
      _channels[packageManager.channelId] = packageManager;
    } catch (e) {
      // Package manager not available, skip
    }

    // Initialize plugin store channel (if configured)
    try {
      final pluginStore = PluginStoreChannel(
        storeUrl: 'https://plugins.example.com',
        apiKey: 'demo-key',
        storeConfig: {},
      );
      _channels[pluginStore.channelId] = pluginStore;
    } catch (e) {
      // Plugin store not configured, skip
    }
  }

  String _detectPackageManager() {
    // Simple detection logic - in real implementation would be more sophisticated
    if (Platform.isWindows) {
      return 'winget'; // or 'chocolatey'
    } else if (Platform.isMacOS) {
      return 'brew';
    } else if (Platform.isLinux) {
      return 'apt'; // or detect specific distro package manager
    }
    return 'npm'; // fallback
  }

  bool _isNewerVersion(String version1, String version2) {
    return _compareVersions(version1, version2) > 0;
  }

  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part != v2Part) {
        return v1Part.compareTo(v2Part);
      }
    }
    
    return 0;
  }
}