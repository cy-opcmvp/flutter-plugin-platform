import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';
import '../../core/services/plugin_manager.dart';
import '../../core/services/platform_services.dart';
import '../../core/extensions/context_extensions.dart';
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
        _error = e.toString();
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
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PluginInfo> get _filteredPlugins {
    var filtered = _pluginInfos.where((info) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          info.descriptor.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          info.descriptor.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType =
          _filterType == null || info.descriptor.type == _filterType;

      return matchesSearch && matchesType;
    }).toList();

    // Sort by name
    filtered.sort((a, b) => a.descriptor.name.compareTo(b.descriptor.name));
    return filtered;
  }

  Future<void> _uninstallPlugin(String pluginId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.button_uninstall),
        content: Text(l10n.dialog_uninstallPlugin),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.button_uninstall),
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
            SnackBar(
              content: Text(l10n.plugin_uninstallSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.plugin_operationFailed(e.toString())),
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
        type: _availablePlugins.length % 2 == 0
            ? PluginType.tool
            : PluginType.game,
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
          SnackBar(
            content: Text(context.l10n.plugin_installSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.plugin_operationFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plugin_title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadPlugins,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.common_refresh,
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
                  decoration: InputDecoration(
                    hintText: l10n.hint_searchPlugins,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
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
                    Text(l10n.plugin_filterByType),
                    const SizedBox(width: 8),
                    DropdownButton<PluginType?>(
                      value: _filterType,
                      onChanged: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.common_all),
                        ),
                        DropdownMenuItem(
                          value: PluginType.tool,
                          child: Text(l10n.plugin_typeTool),
                        ),
                        DropdownMenuItem(
                          value: PluginType.game,
                          child: Text(l10n.plugin_typeGame),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Plugin list
          Expanded(child: _buildPluginList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _installSamplePlugin,
        tooltip: context.l10n.pluginManagement_installSample,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPluginList() {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              l10n.common_error,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.error_loadFailed(_error!),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlugins,
              child: Text(l10n.common_retry),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? l10n.plugin_noMatch
                  : l10n.plugin_noPlugins,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != null
                  ? l10n.hint_tryAdjustSearch
                  : l10n.plugin_installFirst,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75, // 4:3 比例
      ),
      itemCount: filteredPlugins.length,
      itemBuilder: (context, index) {
        final pluginInfo = filteredPlugins[index];
        return PluginCard(
          pluginInfo: pluginInfo,
          onTap: () => _showPluginDetails(pluginInfo),
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
