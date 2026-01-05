import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';

/// Dialog that shows detailed information about a plugin
class PluginDetailsDialog extends StatelessWidget {
  final PluginInfo pluginInfo;
  final ValueChanged<bool>? onToggleEnabled;
  final VoidCallback? onUninstall;

  const PluginDetailsDialog({
    super.key,
    required this.pluginInfo,
    this.onToggleEnabled,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final descriptor = pluginInfo.descriptor;
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getPluginTypeColor(descriptor.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPluginTypeIcon(descriptor.type),
                      color: _getPluginTypeColor(descriptor.type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descriptor.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${descriptor.version}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and basic info
                    _buildInfoSection(
                      context,
                      'Status',
                      [
                        _InfoItem('State', _getStateDisplayName(pluginInfo.state)),
                        _InfoItem('Enabled', pluginInfo.isEnabled ? 'Yes' : 'No'),
                        _InfoItem('Type', descriptor.type.name.toUpperCase()),
                        _InfoItem('Plugin ID', descriptor.id),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    if (descriptor.metadata.containsKey('description')) ...[
                      _buildInfoSection(
                        context,
                        'Description',
                        [_InfoItem('', descriptor.metadata['description'] as String)],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Installation info
                    _buildInfoSection(
                      context,
                      'Installation',
                      [
                        _InfoItem('Installed', _formatDateTime(pluginInfo.installedAt)),
                        if (pluginInfo.lastUsed != null)
                          _InfoItem('Last Used', _formatDateTime(pluginInfo.lastUsed!)),
                        _InfoItem('Entry Point', descriptor.entryPoint),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Permissions
                    if (descriptor.requiredPermissions.isNotEmpty) ...[
                      _buildPermissionsSection(context),
                      const SizedBox(height: 24),
                    ],
                    
                    // Metadata
                    if (descriptor.metadata.isNotEmpty) ...[
                      _buildMetadataSection(context),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Enable/Disable toggle
                  Switch(
                    value: pluginInfo.isEnabled,
                    onChanged: onToggleEnabled,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pluginInfo.isEnabled ? 'Enabled' : 'Disabled',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  // Action buttons
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onUninstall?.call();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Uninstall'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<_InfoItem> items) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: item.label.isEmpty
              ? Text(
                  item.value,
                  style: theme.textTheme.bodyMedium,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${item.label}:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
        )),
      ],
    );
  }

  Widget _buildPermissionsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pluginInfo.descriptor.requiredPermissions.map((permission) {
            return Chip(
              label: Text(
                _getPermissionDisplayName(permission),
                style: theme.textTheme.bodySmall,
              ),
              backgroundColor: theme.colorScheme.secondaryContainer,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = pluginInfo.descriptor.metadata;
    
    // Filter out description as it's shown separately
    final filteredMetadata = Map<String, dynamic>.from(metadata);
    filteredMetadata.remove('description');
    
    if (filteredMetadata.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...filteredMetadata.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '${_capitalizeFirst(entry.key)}:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
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

  String _getStateDisplayName(PluginState state) {
    switch (state) {
      case PluginState.active:
        return 'Active';
      case PluginState.inactive:
        return 'Inactive';
      case PluginState.loading:
        return 'Loading';
      case PluginState.paused:
        return 'Paused';
      case PluginState.error:
        return 'Error';
    }
  }

  String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.fileAccess:
        return 'File Access';
      case Permission.fileSystemRead:
        return 'File System Read';
      case Permission.fileSystemWrite:
        return 'File System Write';
      case Permission.fileSystemExecute:
        return 'File System Execute';
      case Permission.networkAccess:
        return 'Network Access';
      case Permission.networkServer:
        return 'Network Server';
      case Permission.networkClient:
        return 'Network Client';
      case Permission.notifications:
        return 'Notifications';
      case Permission.systemNotifications:
        return 'System Notifications';
      case Permission.camera:
        return 'Camera';
      case Permission.systemCamera:
        return 'System Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.systemMicrophone:
        return 'System Microphone';
      case Permission.location:
        return 'Location';
      case Permission.storage:
        return 'Storage';
      case Permission.platformStorage:
        return 'Platform Storage';
      case Permission.systemClipboard:
        return 'System Clipboard';
      case Permission.platformServices:
        return 'Platform Services';
      case Permission.platformUI:
        return 'Platform UI';
      case Permission.pluginCommunication:
        return 'Plugin Communication';
      case Permission.pluginDataSharing:
        return 'Plugin Data Sharing';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}