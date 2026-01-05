import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';
import '../../core/services/plugin_manager.dart';
import '../../core/services/platform_services.dart';
import '../widgets/plugin_card.dart';
import '../widgets/plugin_details_dialog.dart';

/// Screen for managing plugins - installation, uninstallation, enable/disable
class PluginManagementScreen extends StatefulWidget {
  const PluginManagementScreen({super.key});

  @override
  State<PluginManagementScreen> createState() => _PluginManagementScreenState();
}

class _PluginManagementScreenState extends State<PluginManagementScreen> {
  late final IPluginManager _pluginManager;
  List<PluginDescriptor> _availablePlugins = [];
  List<PluginInfo> _pluginInfos = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  PluginType? _filterType;

  @override
  void initState() {
    super.initState();
    _pluginManager = PluginManager(PlatformServices());
    _initializePluginManager();
  }

  Future<void> _initializePluginManager() async {
    try {
      await _pluginManager.initialize();
      await _loadPlugins();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize plugin manager: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlugins() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final plugins = await _pluginManager.getAvailablePlugins();
      final pluginInfos = <PluginInfo>[];

      for (final plugin in plugins) {
        final info = await _pluginManager.getPluginInfo(plugin.id);
        if (info != null) {
          pluginInfos.add(info);
        }
      }

      setState(() {
        _availablePlugins = plugins;
        _pluginInfos = pluginInfos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plugins: $e';
        _isLoading = false;
      });
    }
  }

  List<PluginInfo> get _filteredPlugins {
    var filtered = _pluginInfos.where((info) {
      final matchesSearch = _searchQuery.isEmpty ||
          info.descriptor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          info.descriptor.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _filterType == null || info.descriptor.type == _filterType;
      
      return matchesSearch && matchesType;
    }).toList();

    // Sort by name
    filtered.sort((a, b) => a.descriptor.name.compareTo(b.descriptor.name));
    return filtered;
  }

  Future<void> _togglePluginEnabled(String pluginId, bool enabled) async {
    try {
      if (enabled) {
        await _pluginManager.enablePlugin(pluginId);
      } else {
        await _pluginManager.disablePlugin(pluginId);
      }
      await _loadPlugins();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Plugin enabled' : 'Plugin disabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${enabled ? 'enable' : 'disable'} plugin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uninstallPlugin(String pluginId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Plugin'),
        content: const Text('Are you sure you want to uninstall this plugin? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pluginManager.uninstallPlugin(pluginId);
        await _loadPlugins();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plugin uninstalled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to uninstall plugin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPluginDetails(PluginInfo pluginInfo) {
    showDialog(
      context: context,
      builder: (context) => PluginDetailsDialog(
        pluginInfo: pluginInfo,
        onToggleEnabled: (enabled) => _togglePluginEnabled(pluginInfo.descriptor.id, enabled),
        onUninstall: () => _uninstallPlugin(pluginInfo.descriptor.id),
      ),
    );
  }

  Future<void> _installSamplePlugin() async {
    try {
      // Create a sample plugin for demonstration
      final sampleDescriptor = PluginDescriptor(
        id: 'com.example.sample_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Sample Plugin ${_availablePlugins.length + 1}',
        version: '1.0.0',
        type: _availablePlugins.length % 2 == 0 ? PluginType.tool : PluginType.game,
        requiredPermissions: [Permission.storage],
        metadata: {
          'description': 'A sample plugin for demonstration purposes',
          'author': 'Plugin Platform Team',
        },
        entryPoint: 'lib/main.dart',
      );

      final samplePackage = PluginPackage(
        descriptor: sampleDescriptor,
        packageData: [1, 2, 3, 4, 5], // Mock package data
        checksum: 'mock_checksum_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _pluginManager.installPlugin(samplePackage);
      await _loadPlugins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample plugin installed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install sample plugin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadPlugins,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search plugins...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Filter by type: '),
                    const SizedBox(width: 8),
                    DropdownButton<PluginType?>(
                      value: _filterType,
                      onChanged: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: PluginType.tool,
                          child: Text('Tools'),
                        ),
                        DropdownMenuItem(
                          value: PluginType.game,
                          child: Text('Games'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Plugin list
          Expanded(
            child: _buildPluginList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _installSamplePlugin,
        tooltip: 'Install Sample Plugin',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPluginList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlugins,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredPlugins = _filteredPlugins;

    if (filteredPlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? 'No plugins match your search'
                  : 'No plugins installed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? 'Try adjusting your search or filter criteria'
                  : 'Install your first plugin to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredPlugins.length,
      itemBuilder: (context, index) {
        final pluginInfo = filteredPlugins[index];
        return PluginCard(
          pluginInfo: pluginInfo,
          onTap: () => _showPluginDetails(pluginInfo),
          onToggleEnabled: (enabled) => _togglePluginEnabled(pluginInfo.descriptor.id, enabled),
          onUninstall: () => _uninstallPlugin(pluginInfo.descriptor.id),
        );
      },
    );
  }

  @override
  void dispose() {
    _pluginManager.shutdown();
    super.dispose();
  }
}