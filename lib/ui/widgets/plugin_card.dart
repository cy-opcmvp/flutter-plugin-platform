import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';

/// Widget that displays a plugin in a card format with actions
class PluginCard extends StatelessWidget {
  final PluginInfo pluginInfo;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleEnabled;
  final VoidCallback? onUninstall;

  const PluginCard({
    super.key,
    required this.pluginInfo,
    this.onTap,
    this.onToggleEnabled,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final descriptor = pluginInfo.descriptor;
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                  // Plugin icon based on type
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getPluginTypeColor(descriptor.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPluginTypeIcon(descriptor.type),
                      color: _getPluginTypeColor(descriptor.type),
                      size: 24,
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
                            _buildStatusChip(context),
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
              const SizedBox(height: 12),
              // Plugin actions
              Row(
                children: [
                  // Enable/Disable toggle
                  Switch(
                    value: pluginInfo.isEnabled,
                    onChanged: onToggleEnabled,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pluginInfo.isEnabled ? 'Enabled' : 'Disabled',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onTap,
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'Plugin Details',
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: onUninstall,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Uninstall',
                        iconSize: 20,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
              // Additional info row
              if (pluginInfo.lastUsed != null || descriptor.requiredPermissions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (pluginInfo.lastUsed != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last used: ${_formatDate(pluginInfo.lastUsed!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    if (pluginInfo.lastUsed != null && descriptor.requiredPermissions.isNotEmpty)
                      const SizedBox(width: 16),
                    if (descriptor.requiredPermissions.isNotEmpty) ...[
                      Icon(
                        Icons.security,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${descriptor.requiredPermissions.length} permission${descriptor.requiredPermissions.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    Color chipColor;
    String statusText;
    
    switch (pluginInfo.state) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}