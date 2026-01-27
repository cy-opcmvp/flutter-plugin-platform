import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin_manager.dart';
import '../../core/models/plugin_models.dart';
import '../../core/extensions/context_extensions.dart';

/// Widget that displays a plugin in a card format with actions
class PluginCard extends StatelessWidget {
  final PluginInfo pluginInfo;
  final VoidCallback? onTap;
  final VoidCallback? onUninstall;

  const PluginCard({
    super.key,
    required this.pluginInfo,
    this.onTap,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final descriptor = pluginInfo.descriptor;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部：图标 + 名称 + 状态
              Row(
                children: [
                  // Plugin icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPluginTypeColor(
                        descriptor.type,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPluginTypeIcon(descriptor.type),
                      color: _getPluginTypeColor(descriptor.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Plugin name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          descriptor.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${descriptor.version}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 8),
              // 描述（如果有）
              if (descriptor.metadata.containsKey('description')) ...[
                Expanded(
                  child: Text(
                    descriptor.metadata['description'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 底部操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.info_outline),
                    tooltip: context.l10n.plugin_detailsTitle,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onUninstall,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.l10n.button_uninstall,
                    iconSize: 18,
                    color: theme.colorScheme.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
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
        statusText = context.l10n.plugin_stateActive;
        break;
      case PluginState.inactive:
        chipColor = Colors.grey;
        statusText = context.l10n.plugin_stateInactive;
        break;
      case PluginState.loading:
        chipColor = Colors.orange;
        statusText = context.l10n.plugin_stateLoading;
        break;
      case PluginState.paused:
        chipColor = Colors.blue;
        statusText = context.l10n.plugin_statePaused;
        break;
      case PluginState.error:
        chipColor = Colors.red;
        statusText = context.l10n.plugin_stateError;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
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
