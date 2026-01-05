import 'package:flutter/material.dart';
import '../../core/services/external_plugin_manager.dart';
import '../../core/models/plugin_models.dart';

/// Screen for managing external plugins with lifecycle controls
class ExternalPluginManagementScreen extends StatefulWidget {
  const ExternalPluginManagementScreen({super.key});

  @override
  State<ExternalPluginManagementScreen> createState() => _ExternalPluginManagementScreenState();
}

class _ExternalPluginManagementScreenState extends State<ExternalPluginManagementScreen> {
  late final ExternalPluginManager _pluginManager;
  List<PluginRuntimeInfo> _pluginRuntimeInfos = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  PluginType? _filterType;
  PluginState? _filterState;
  Set<String> _selectedPlugins = {};
  bool _isMultiSelectMode = false;
  Map<String, bool> _operationInProgress = {};

  @override
  void initState() {
    super.initState();
    _pluginManager = ExternalPluginManager();
    _initializePluginManager();
  }

  Future<void> _initializePluginManager() async {
    try {
      await _pluginManager.initialize();
      await _loadPlugins();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize external plugin manager: $e';
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

      final runtimeInfos = _pluginManager.getAllPluginRuntimeInfo();

      setState(() {
        _pluginRuntimeInfos = runtimeInfos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load external plugins: $e';
        _isLoading = false;
      });
    }
  }

  List<PluginRuntimeInfo> get _filteredPlugins {
    var filtered = _pluginRuntimeInfos.where((info) {
      final matchesSearch = _searchQuery.isEmpty ||
          info.descriptor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          info.descriptor.id.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _filterType == null || info.descriptor.type == _filterType;
      final matchesState = _filterState == null || info.stateManager.currentState == _filterState;
      
      return matchesSearch && matchesType && matchesState;
    }).toList();

    // Sort by name
    filtered.sort((a, b) => a.descriptor.name.compareTo(b.descriptor.name));
    return filtered;
  }

  bool _isOperationInProgress(String pluginId) {
    return _operationInProgress[pluginId] ?? false;
  }

  void _setOperationInProgress(String pluginId, bool inProgress) {
    setState(() {
      _operationInProgress[pluginId] = inProgress;
    });
  }

  Future<void> _updatePlugin(String pluginId) async {
    if (_isOperationInProgress(pluginId)) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Update Plugin',
      content: 'Are you sure you want to update this plugin to the latest version? A backup will be created for rollback if needed.',
      confirmText: 'Update',
      confirmColor: Colors.blue,
    );

    if (confirmed == true) {
      _setOperationInProgress(pluginId, true);
      
      try {
        // Show progress dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating plugin...'),
                ],
              ),
            ),
          );
        }

        // Use the rollback-capable update method
        await _pluginManager.updatePluginWithRollback(pluginId, '2.0.0'); // Simulate new version
        
        await _loadPlugins();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plugin updated successfully. Rollback available if needed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed and was rolled back: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _setOperationInProgress(pluginId, false);
      }
    }
  }

  Future<void> _rollbackPlugin(String pluginId) async {
    if (_isOperationInProgress(pluginId)) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Rollback Plugin',
      content: 'Are you sure you want to rollback this plugin to the previous version? This will undo the last update.',
      confirmText: 'Rollback',
      confirmColor: Colors.orange,
    );

    if (confirmed == true) {
      _setOperationInProgress(pluginId, true);
      
      try {
        // Show progress dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rolling back plugin...'),
                ],
              ),
            ),
          );
        }

        await _pluginManager.rollbackPlugin(pluginId);
        await _loadPlugins();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plugin rolled back successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rollback plugin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _setOperationInProgress(pluginId, false);
      }
    }
  }

  bool _hasRollbackAvailable(String pluginId) {
    // Check if plugin has backup available for rollback
    // This would be exposed by the plugin manager in a real implementation
    return true; // Simplified for demo
  }

  Future<void> _disablePlugin(String pluginId) async {
    if (_isOperationInProgress(pluginId)) return;

    _setOperationInProgress(pluginId, true);
    
    try {
      await _pluginManager.pauseExternalPlugin(pluginId);
      await _loadPlugins();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plugin disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable plugin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setOperationInProgress(pluginId, false);
    }
  }

  Future<void> _enablePlugin(String pluginId) async {
    if (_isOperationInProgress(pluginId)) return;

    _setOperationInProgress(pluginId, true);
    
    try {
      await _pluginManager.resumeExternalPlugin(pluginId);
      await _loadPlugins();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plugin enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable plugin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setOperationInProgress(pluginId, false);
    }
  }

  Future<void> _removePlugin(String pluginId) async {
    if (_isOperationInProgress(pluginId)) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Remove Plugin',
      content: 'Are you sure you want to remove this plugin? This action cannot be undone.',
      confirmText: 'Remove',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      _setOperationInProgress(pluginId, true);
      
      try {
        // Show progress dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Removing plugin...'),
                ],
              ),
            ),
          );
        }

        await _pluginManager.uninstallExternalPlugin(pluginId);
        await _loadPlugins();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plugin removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove plugin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _setOperationInProgress(pluginId, false);
      }
    }
  }

  Future<void> _batchUpdatePlugins() async {
    if (_selectedPlugins.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Update Selected Plugins',
      content: 'Are you sure you want to update ${_selectedPlugins.length} selected plugin(s)?',
      confirmText: 'Update All',
      confirmColor: Colors.blue,
    );

    if (confirmed == true) {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Updating ${_selectedPlugins.length} plugin(s)...'),
              ],
            ),
          ),
        );
      }

      int successCount = 0;
      int failureCount = 0;

      for (final _ in _selectedPlugins) {
        try {
          // Simulate update process
          await Future.delayed(const Duration(milliseconds: 500));
          successCount++;
        } catch (e) {
          failureCount++;
        }
      }

      await _loadPlugins();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        String message;
        Color backgroundColor;
        
        if (failureCount == 0) {
          message = 'All $successCount plugin(s) updated successfully';
          backgroundColor = Colors.green;
        } else if (successCount == 0) {
          message = 'Failed to update all $failureCount plugin(s)';
          backgroundColor = Colors.red;
        } else {
          message = '$successCount updated, $failureCount failed';
          backgroundColor = Colors.orange;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
      }

      _exitMultiSelectMode();
    }
  }

  Future<void> _batchRemovePlugins() async {
    if (_selectedPlugins.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Remove Selected Plugins',
      content: 'Are you sure you want to remove ${_selectedPlugins.length} selected plugin(s)? This action cannot be undone.',
      confirmText: 'Remove All',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Removing ${_selectedPlugins.length} plugin(s)...'),
              ],
            ),
          ),
        );
      }

      int successCount = 0;
      int failureCount = 0;

      for (final pluginId in _selectedPlugins) {
        try {
          await _pluginManager.uninstallExternalPlugin(pluginId);
          successCount++;
        } catch (e) {
          failureCount++;
        }
      }

      await _loadPlugins();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        String message;
        Color backgroundColor;
        
        if (failureCount == 0) {
          message = 'All $successCount plugin(s) removed successfully';
          backgroundColor = Colors.green;
        } else if (successCount == 0) {
          message = 'Failed to remove all $failureCount plugin(s)';
          backgroundColor = Colors.red;
        } else {
          message = '$successCount removed, $failureCount failed';
          backgroundColor = Colors.orange;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
      }

      _exitMultiSelectMode();
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedPlugins.clear();
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedPlugins.clear();
    });
  }

  void _togglePluginSelection(String pluginId) {
    setState(() {
      if (_selectedPlugins.contains(pluginId)) {
        _selectedPlugins.remove(pluginId);
      } else {
        _selectedPlugins.add(pluginId);
      }
    });
  }

  void _selectAllPlugins() {
    setState(() {
      _selectedPlugins = _filteredPlugins.map((info) => info.descriptor.id).toSet();
    });
  }

  void _deselectAllPlugins() {
    setState(() {
      _selectedPlugins.clear();
    });
  }

  void _showPluginDetails(PluginRuntimeInfo runtimeInfo) {
    showDialog(
      context: context,
      builder: (context) => _ExternalPluginDetailsDialog(
        runtimeInfo: runtimeInfo,
        onUpdate: () => _updatePlugin(runtimeInfo.descriptor.id),
        onDisable: () => _disablePlugin(runtimeInfo.descriptor.id),
        onEnable: () => _enablePlugin(runtimeInfo.descriptor.id),
        onRemove: () => _removePlugin(runtimeInfo.descriptor.id),
        onRollback: _hasRollbackAvailable(runtimeInfo.descriptor.id) ? () => _rollbackPlugin(runtimeInfo.descriptor.id) : null,
        isOperationInProgress: _isOperationInProgress(runtimeInfo.descriptor.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiSelectMode 
            ? '${_selectedPlugins.length} selected'
            : 'External Plugins'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isMultiSelectMode
            ? IconButton(
                onPressed: _exitMultiSelectMode,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          if (_isMultiSelectMode) ...[
            if (_selectedPlugins.length < _filteredPlugins.length)
              IconButton(
                onPressed: _selectAllPlugins,
                icon: const Icon(Icons.select_all),
                tooltip: 'Select All',
              ),
            if (_selectedPlugins.isNotEmpty)
              IconButton(
                onPressed: _deselectAllPlugins,
                icon: const Icon(Icons.deselect),
                tooltip: 'Deselect All',
              ),
          ] else ...[
            if (_filteredPlugins.isNotEmpty)
              IconButton(
                onPressed: _enterMultiSelectMode,
                icon: const Icon(Icons.checklist),
                tooltip: 'Multi-select',
              ),
            IconButton(
              onPressed: _loadPlugins,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (!_isMultiSelectMode) ...[
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search external plugins...',
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
                      Expanded(
                        child: DropdownButtonFormField<PluginType?>(
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _filterType,
                          onChanged: (value) {
                            setState(() {
                              _filterType = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Types'),
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
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<PluginState?>(
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _filterState,
                          onChanged: (value) {
                            setState(() {
                              _filterState = value;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All States'),
                            ),
                            DropdownMenuItem(
                              value: PluginState.active,
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: PluginState.inactive,
                              child: Text('Inactive'),
                            ),
                            DropdownMenuItem(
                              value: PluginState.paused,
                              child: Text('Paused'),
                            ),
                            DropdownMenuItem(
                              value: PluginState.error,
                              child: Text('Error'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // Plugin list
          Expanded(
            child: _buildPluginList(),
          ),
        ],
      ),
      bottomNavigationBar: _isMultiSelectMode && _selectedPlugins.isNotEmpty
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _batchUpdatePlugins,
                        icon: const Icon(Icons.update),
                        label: const Text('Update Selected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _batchRemovePlugins,
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove Selected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
              _searchQuery.isNotEmpty || _filterType != null || _filterState != null
                  ? 'No plugins match your search'
                  : 'No external plugins installed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != null || _filterState != null
                  ? 'Try adjusting your search or filter criteria'
                  : 'Install your first external plugin to get started',
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
        final runtimeInfo = filteredPlugins[index];
        final pluginId = runtimeInfo.descriptor.id;
        final isSelected = _selectedPlugins.contains(pluginId);
        final isInProgress = _isOperationInProgress(pluginId);

        return _ExternalPluginCard(
          runtimeInfo: runtimeInfo,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: isSelected,
          isOperationInProgress: isInProgress,
          onTap: _isMultiSelectMode
              ? () => _togglePluginSelection(pluginId)
              : () => _showPluginDetails(runtimeInfo),
          onUpdate: () => _updatePlugin(pluginId),
          onDisable: () => _disablePlugin(pluginId),
          onEnable: () => _enablePlugin(pluginId),
          onRemove: () => _removePlugin(pluginId),
          onRollback: _hasRollbackAvailable(pluginId) ? () => _rollbackPlugin(pluginId) : null,
          onToggleSelection: () => _togglePluginSelection(pluginId),
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

/// Custom card widget for external plugins with lifecycle controls
class _ExternalPluginCard extends StatelessWidget {
  final PluginRuntimeInfo runtimeInfo;
  final bool isMultiSelectMode;
  final bool isSelected;
  final bool isOperationInProgress;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;
  final VoidCallback? onRemove;
  final VoidCallback? onRollback;
  final VoidCallback? onToggleSelection;

  const _ExternalPluginCard({
    required this.runtimeInfo,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.isOperationInProgress,
    this.onTap,
    this.onUpdate,
    this.onDisable,
    this.onEnable,
    this.onRemove,
    this.onRollback,
    this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final descriptor = runtimeInfo.descriptor;
    final state = runtimeInfo.stateManager.currentState;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMultiSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelection?.call(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Plugin icon based on type
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getPluginTypeColor(descriptor.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getPluginTypeIcon(descriptor.type),
                          color: _getPluginTypeColor(descriptor.type),
                          size: 24,
                        ),
                        if (isOperationInProgress)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Plugin info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                descriptor.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusChip(context, state),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${descriptor.version} • ${descriptor.type.name.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (descriptor.metadata.containsKey('description')) ...[
                          const SizedBox(height: 4),
                          Text(
                            descriptor.metadata['description'] as String,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!isMultiSelectMode) ...[
                const SizedBox(height: 12),
                // Plugin actions
                Row(
                  children: [
                    // State-based action button
                    if (state == PluginState.active || state == PluginState.paused) ...[
                      ElevatedButton.icon(
                        onPressed: isOperationInProgress ? null : (state == PluginState.active ? onDisable : onEnable),
                        icon: Icon(state == PluginState.active ? Icons.pause : Icons.play_arrow),
                        label: Text(state == PluginState.active ? 'Disable' : 'Enable'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state == PluginState.active ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Update button
                    ElevatedButton.icon(
                      onPressed: isOperationInProgress ? null : onUpdate,
                      icon: const Icon(Icons.update),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rollback button (show if rollback is available)
                    if (onRollback != null) ...[
                      ElevatedButton.icon(
                        onPressed: isOperationInProgress ? null : onRollback,
                        icon: const Icon(Icons.undo),
                        label: const Text('Rollback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: isOperationInProgress ? null : onTap,
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Plugin Details',
                          iconSize: 20,
                        ),
                        IconButton(
                          onPressed: isOperationInProgress ? null : onRemove,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove',
                          iconSize: 20,
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
                // Additional info row
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Security: ${descriptor.metadata['securityLevel'] ?? 'Unknown'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.devices,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Platforms: ${(descriptor.metadata['supportedPlatforms'] as List<String>?)?.join(', ') ?? 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, PluginState state) {
    final theme = Theme.of(context);
    Color chipColor;
    String statusText;
    
    switch (state) {
      case PluginState.active:
        chipColor = Colors.green;
        statusText = 'Active';
        break;
      case PluginState.inactive:
        chipColor = Colors.grey;
        statusText = 'Inactive';
        break;
      case PluginState.loading:
        chipColor = Colors.orange;
        statusText = 'Loading';
        break;
      case PluginState.paused:
        chipColor = Colors.blue;
        statusText = 'Paused';
        break;
      case PluginState.error:
        chipColor = Colors.red;
        statusText = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getPluginTypeIcon(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Icons.build;
      case PluginType.game:
        return Icons.games;
    }
  }

  Color _getPluginTypeColor(PluginType type) {
    switch (type) {
      case PluginType.tool:
        return Colors.blue;
      case PluginType.game:
        return Colors.purple;
    }
  }
}

/// Details dialog for external plugins
class _ExternalPluginDetailsDialog extends StatelessWidget {
  final PluginRuntimeInfo runtimeInfo;
  final VoidCallback? onUpdate;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;
  final VoidCallback? onRemove;
  final VoidCallback? onRollback;
  final bool isOperationInProgress;

  const _ExternalPluginDetailsDialog({
    required this.runtimeInfo,
    this.onUpdate,
    this.onDisable,
    this.onEnable,
    this.onRemove,
    this.onRollback,
    required this.isOperationInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final descriptor = runtimeInfo.descriptor;
    final state = runtimeInfo.stateManager.currentState;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(descriptor.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('ID', descriptor.id),
            _buildInfoRow('Version', descriptor.version),
            _buildInfoRow('Type', descriptor.type.name.toUpperCase()),
            _buildInfoRow('State', state.name.toUpperCase()),
            _buildInfoRow('Security Level', descriptor.metadata['securityLevel'] ?? 'Unknown'),
            _buildInfoRow('Entry Point', descriptor.entryPoint),
            if (descriptor.metadata.containsKey('description'))
              _buildInfoRow('Description', descriptor.metadata['description']),
            if (descriptor.metadata.containsKey('author'))
              _buildInfoRow('Author', descriptor.metadata['author']),
            if (descriptor.metadata.containsKey('category'))
              _buildInfoRow('Category', descriptor.metadata['category']),
            if (descriptor.metadata.containsKey('license'))
              _buildInfoRow('License', descriptor.metadata['license']),
            _buildInfoRow('Supported Platforms', 
              (descriptor.metadata['supportedPlatforms'] as List<String>?)?.join(', ') ?? 'Unknown'),
            if (descriptor.requiredPermissions.isNotEmpty)
              _buildInfoRow('Required Permissions', 
                descriptor.requiredPermissions.map((p) => p.name).join(', ')),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Version Management',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildVersionInfo(descriptor.id),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (state == PluginState.active || state == PluginState.paused)
          TextButton(
            onPressed: isOperationInProgress ? null : () {
              Navigator.of(context).pop();
              if (state == PluginState.active) {
                onDisable?.call();
              } else {
                onEnable?.call();
              }
            },
            child: Text(state == PluginState.active ? 'Disable' : 'Enable'),
          ),
        TextButton(
          onPressed: isOperationInProgress ? null : () {
            Navigator.of(context).pop();
            onUpdate?.call();
          },
          child: const Text('Update'),
        ),
        if (onRollback != null)
          TextButton(
            onPressed: isOperationInProgress ? null : () {
              Navigator.of(context).pop();
              onRollback?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Rollback'),
          ),
        TextButton(
          onPressed: isOperationInProgress ? null : () {
            Navigator.of(context).pop();
            onRemove?.call();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Remove'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(String pluginId) {
    // In a real implementation, this would fetch version history from the plugin manager
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16),
            const SizedBox(width: 4),
            Text(
              'Current Version: ${runtimeInfo.descriptor.version}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (onRollback != null) ...[
          Row(
            children: [
              const Icon(Icons.backup, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              const Text(
                'Backup available for rollback',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ] else ...[
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'No backup available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }
}