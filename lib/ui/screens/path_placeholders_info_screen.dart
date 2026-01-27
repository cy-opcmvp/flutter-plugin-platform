library;

import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 路径占位符说明页面
class PathPlaceholdersInfoScreen extends StatelessWidget {
  const PathPlaceholdersInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.path_placeholders_title)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 说明文本
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.path_placeholders_description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 占位符列表
          Text(
            l10n.path_placeholders_available,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          _buildPlaceholderCard(
            context,
            name: '{documents}',
            description: l10n.path_placeholder_documents_desc,
            example: l10n.path_placeholder_documents_example,
            icon: Icons.folder_outlined,
          ),

          const SizedBox(height: 8),

          _buildPlaceholderCard(
            context,
            name: '{home}',
            description: l10n.path_placeholder_home_desc,
            example: l10n.path_placeholder_home_example,
            icon: Icons.home_outlined,
          ),

          const SizedBox(height: 8),

          _buildPlaceholderCard(
            context,
            name: '{temp}',
            description: l10n.path_placeholder_temp_desc,
            example: l10n.path_placeholder_temp_example,
            icon: Icons.folder_outlined,
          ),

          const SizedBox(height: 8),

          _buildPlaceholderCard(
            context,
            name: '{appdata}',
            description: l10n.path_placeholder_appdata_desc,
            example: l10n.path_placeholder_appdata_example,
            icon: Icons.storage_outlined,
          ),

          const SizedBox(height: 24),

          // 使用说明
          Text(
            l10n.path_placeholders_usage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUsageStep(
                    context,
                    number: '1',
                    text: l10n.path_placeholders_usage_step1,
                  ),
                  _buildUsageStep(
                    context,
                    number: '2',
                    text: l10n.path_placeholders_usage_step2,
                  ),
                  _buildUsageStep(
                    context,
                    number: '3',
                    text: l10n.path_placeholders_usage_step3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 示例
          Text(
            l10n.path_placeholders_example_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.path_placeholders_example_input,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('{documents}/Screenshots'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.path_placeholders_example_output,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'C:/Users/Username/Documents/Screenshots',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context, {
    required String name,
    required String description,
    required String example,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 4),
            Text(
              '$example: ${name.substring(1, name.length - 1)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStep(
    BuildContext context, {
    required String number,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
