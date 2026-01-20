import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';
import '../../core/extensions/context_extensions.dart';

/// Dialog that shows detailed information about a plugin
class PluginDetailsDialog extends StatelessWidget {
  final PluginInfo pluginInfo;
  final VoidCallback? onUninstall;

  const PluginDetailsDialog({
    super.key,
    required this.pluginInfo,
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
                      color: _getPluginTypeColor(descriptor.type).withValues(alpha: 0.2),
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
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
                      context.l10n.plugin_detailsStatus,
                      [
                        _InfoItem(context.l10n.plugin_detailsState, _getStateDisplayName(context, pluginInfo.state)),
                        _InfoItem(context.l10n.plugin_detailsType, descriptor.type.name.toUpperCase()),
                        _InfoItem(context.l10n.plugin_detailsPluginId, descriptor.id),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    if (descriptor.metadata.containsKey('description')) ...[
                      _buildInfoSection(
                        context,
                        context.l10n.plugin_detailsDescription,
                        [_InfoItem('', descriptor.metadata['description'] as String)],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Installation info
                    _buildInfoSection(
                      context,
                      context.l10n.plugin_detailsInstallation,
                      [
                        _InfoItem(context.l10n.plugin_detailsInstalled, _formatDateTime(pluginInfo.installedAt)),
                        if (pluginInfo.lastUsed != null)
                          _InfoItem(context.l10n.plugin_detailsLastUsed, _formatDateTime(pluginInfo.lastUsed!)),
                        _InfoItem(context.l10n.plugin_detailsEntryPoint, descriptor.entryPoint),
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
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Action buttons
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.common_close),
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
                    child: Text(context.l10n.button_uninstall),
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
          context.l10n.plugin_detailsPermissions,
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
                _getPermissionDisplayName(context, permission),
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
          context.l10n.plugin_detailsAdditionalInfo,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  String _getStateDisplayName(BuildContext context, PluginState state) {
    switch (state) {
      case PluginState.active:
        return context.l10n.plugin_stateActive;
      case PluginState.inactive:
        return context.l10n.plugin_stateInactive;
      case PluginState.loading:
        return context.l10n.plugin_stateLoading;
      case PluginState.paused:
        return context.l10n.plugin_statePaused;
      case PluginState.error:
        return context.l10n.plugin_stateError;
    }
  }

  String _getPermissionDisplayName(BuildContext context, Permission permission) {
    switch (permission) {
      case Permission.fileAccess:
        return context.l10n.plugin_permissionFileAccess;
      case Permission.fileSystemRead:
        return context.l10n.plugin_permissionFileSystemRead;
      case Permission.fileSystemWrite:
        return context.l10n.plugin_permissionFileSystemWrite;
      case Permission.fileSystemExecute:
        return context.l10n.plugin_permissionFileSystemExecute;
      case Permission.networkAccess:
        return context.l10n.plugin_permissionNetworkAccess;
      case Permission.networkServer:
        return context.l10n.plugin_permissionNetworkServer;
      case Permission.networkClient:
        return context.l10n.plugin_permissionNetworkClient;
      case Permission.notifications:
        return context.l10n.plugin_permissionNotifications;
      case Permission.systemNotifications:
        return context.l10n.plugin_permissionSystemNotifications;
      case Permission.camera:
        return context.l10n.plugin_permissionCamera;
      case Permission.systemCamera:
        return context.l10n.plugin_permissionSystemCamera;
      case Permission.microphone:
        return context.l10n.plugin_permissionMicrophone;
      case Permission.systemMicrophone:
        return context.l10n.plugin_permissionSystemMicrophone;
      case Permission.location:
        return context.l10n.plugin_permissionLocation;
      case Permission.storage:
        return context.l10n.plugin_permissionStorage;
      case Permission.platformStorage:
        return context.l10n.plugin_permissionPlatformStorage;
      case Permission.systemClipboard:
        return context.l10n.plugin_permissionSystemClipboard;
      case Permission.platformServices:
        return context.l10n.plugin_permissionPlatformServices;
      case Permission.platformUI:
        return context.l10n.plugin_permissionPlatformUI;
      case Permission.pluginCommunication:
        return context.l10n.plugin_permissionPluginCommunication;
      case Permission.pluginDataSharing:
        return context.l10n.plugin_permissionPluginDataSharing;
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