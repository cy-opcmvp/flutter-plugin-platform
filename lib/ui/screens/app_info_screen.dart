/// App Info Screen
///
/// 应用信息与配置页面
library;

import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/services/tag_manager.dart';
import 'package:plugin_platform/core/services/tag_color_helper.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'package:plugin_platform/core/models/tag_model.dart';
import 'service_test_screen.dart';
import 'tag_management_screen.dart';
import 'plugin_tag_assignment_screen.dart';

/// App Info Screen
///
/// 显示应用的基本信息和状态
class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  /// 全局配置
  GlobalConfig? _globalConfig;

  /// 加载状态
  bool _isLoading = true;

  /// 标签管理器
  final TagManager _tagManager = TagManager.instance;

  /// 标签列表
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      _globalConfig = ConfigManager.instance.globalConfig;
      await _tagManager.initialize();
      _tags = _tagManager.getAllTags();
    } catch (e) {
      debugPrint('Failed to load config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _globalConfig == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings_app)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appInfo_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 应用信息
          _buildSectionHeader(l10n.appInfo_section_app),
          const SizedBox(height: 8),
          _buildAppInfoTile(l10n),

          const SizedBox(height: 24),

          // 标签配置
          _buildSectionHeader(l10n.tag_title),
          const SizedBox(height: 8),
          _buildTagsTile(l10n),
          _buildPluginTagAssignmentTile(l10n),

          const SizedBox(height: 24),

          // 高级设置
          _buildSectionHeader(l10n.settings_advanced),
          const SizedBox(height: 8),
          _buildAdvancedSettingsTile(l10n),

          const SizedBox(height: 24),

          // 开发者工具
          _buildSectionHeader(l10n.appInfo_section_developerTools),
          const SizedBox(height: 8),
          _buildServiceTestTile(l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 应用信息卡片
  Widget _buildAppInfoTile(AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.app_settings_alt),
            title: Text(l10n.settings_appName),
            subtitle: Text(_globalConfig!.app.name),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.settings_appVersion),
            subtitle: Text(_globalConfig!.app.version),
          ),
        ],
      ),
    );
  }

  /// 平台服务测试卡片
  Widget _buildServiceTestTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.science,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.serviceTest_title),
        subtitle: Text(l10n.appInfo_serviceTest_desc),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServiceTestScreen()),
          );
        },
      ),
    );
  }

  /// 标签配置卡片
  Widget _buildTagsTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.tag_title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('${_tags.length} ${l10n.tag_total}'),
                const SizedBox(width: 8),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.take(5).map((tag) {
                  final color = TagColorHelper.getTagColor(tag.color);
                  return Chip(
                    label: Text(tag.name),
                    backgroundColor: color.withValues(alpha: 0.2),
                    side: BorderSide(color: color),
                  );
                }).toList(),
              ),
              if (_tags.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... ${l10n.tag_and_more} ${_tags.length - 5} ${l10n.tag_items}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                l10n.tag_no_tags,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TagManagementScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: Text(l10n.tag_manage),
            ),
          ],
        ),
      ),
    );
  }

  /// 插件标签关联卡片
  Widget _buildPluginTagAssignmentTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.label_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.tag_plugin_assignment_title),
        subtitle: const Text('为每个插件设置标签分类'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PluginTagAssignmentScreen(),
            ),
          );
        },
      ),
    );
  }

  /// 高级设置卡片
  Widget _buildAdvancedSettingsTile(AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.bug_report),
            title: Text(l10n.settings_debugMode),
            value: _globalConfig!.advanced.debugMode,
            onChanged: (value) => _updateAdvanced('debugMode', value),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: Text(l10n.settings_logLevel),
            subtitle: Text(_globalConfig!.advanced.logLevel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogLevelDialog(context),
          ),
        ],
      ),
    );
  }

  /// 更新高级配置
  Future<void> _updateAdvanced(String key, bool value) async {
    if (_globalConfig == null) return;

    final newAdvanced = _globalConfig!.advanced.copyWith(
      debugMode: key == 'debugMode' ? value : null,
    );

    final newConfig = _globalConfig!.copyWith(advanced: newAdvanced);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      if (mounted) {
        setState(() => _globalConfig = newConfig);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to update advanced setting: $e');
      _showErrorMessage();
    }
  }

  /// 显示日志级别选择对话框
  void _showLogLevelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levels = ['debug', 'info', 'warning', 'error'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_logLevel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            final isSelected = _globalConfig!.advanced.logLevel == level;
            return ListTile(
              title: Text(level.toUpperCase()),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                Navigator.of(context).pop();
                await _updateLogLevel(level);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 更新日志级别
  Future<void> _updateLogLevel(String level) async {
    if (_globalConfig == null) return;

    final newAdvanced = _globalConfig!.advanced.copyWith(logLevel: level);
    final newConfig = _globalConfig!.copyWith(advanced: newAdvanced);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      if (mounted) {
        setState(() => _globalConfig = newConfig);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to update log level: $e');
      _showErrorMessage();
    }
  }

  /// 显示成功消息
  void _showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_configSaved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误消息
  void _showErrorMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_configSaveFailed),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
