/// App Info Screen
///
/// 应用信息页面
library;

import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/services/desktop_pet_manager.dart';
import 'package:plugin_platform/core/services/tag_manager.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'package:plugin_platform/core/models/tag_model.dart';
import 'package:plugin_platform/core/services/platform_service_manager.dart';
import 'desktop_pet_settings_screen.dart';
import 'service_test_screen.dart';
import 'tag_management_screen.dart';

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

  /// 桌面宠物管理器
  late DesktopPetManager _desktopPetManager;

  /// 标签列表
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _desktopPetManager = DesktopPetManager();
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
        appBar: AppBar(
          title: Text(l10n.settings_app),
        ),
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

          // 平台信息
          _buildSectionHeader(l10n.platform_platformInfo),
          const SizedBox(height: 8),
          _buildPlatformInfoTile(l10n),

          const SizedBox(height: 24),

          // 功能状态
          _buildSectionHeader(l10n.appInfo_section_features),
          const SizedBox(height: 8),
          _buildDesktopPetStatusTile(l10n),

          const SizedBox(height: 24),

          // 功能设置
          _buildSectionHeader(l10n.settings_features),
          const SizedBox(height: 8),
          _buildFeatureSettingsTile(l10n),

          const SizedBox(height: 24),

          // 高级设置
          _buildSectionHeader(l10n.settings_advanced),
          const SizedBox(height: 8),
          _buildAdvancedSettingsTile(l10n),

          const SizedBox(height: 24),

          // 标签配置
          _buildSectionHeader(l10n.tag_title),
          const SizedBox(height: 8),
          _buildTagsTile(l10n),

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

  /// 桌面宠物状态卡片
  Widget _buildDesktopPetStatusTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.pets,
          color: _globalConfig!.features.showDesktopPet
              ? Colors.green
              : Colors.black87,
        ),
        title: Text(l10n.desktopPet_settings_title),
        subtitle: _globalConfig!.features.showDesktopPet
            ? Text(l10n.common_enabled)
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DesktopPetSettingsScreen(),
            ),
          );
        },
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
            MaterialPageRoute(
              builder: (context) => const ServiceTestScreen(),
            ),
          );
        },
      ),
    );
  }

  /// 平台信息卡片
  Widget _buildPlatformInfoTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.computer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.info_platformType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(_getPlatformType()),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.info_currentMode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(_getCurrentModeText(l10n)),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取平台类型显示文本
  String _getPlatformType() {
    // 从实际运行的操作系统获取平台类型
    if (io.Platform.isWindows) {
      return 'Windows';
    } else if (io.Platform.isMacOS) {
      return 'macOS';
    } else if (io.Platform.isLinux) {
      return 'Linux';
    } else if (io.Platform.isAndroid) {
      return 'Android';
    } else if (io.Platform.isIOS) {
      return 'iOS';
    } else {
      return io.Platform.operatingSystem; // Web 或其他平台
    }
  }

  /// 获取当前运行模式显示文本
  String _getCurrentModeText(AppLocalizations l10n) {
    // 检查桌面宠物的实际运行状态，而不是配置中的开关
    final isPetMode = _desktopPetManager.isDesktopPetMode;

    // 如果桌面宠物正在运行，显示"在线模式"，否则显示"本地模式"
    return isPetMode ? l10n.mode_online : l10n.mode_local;
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
                  final color = _getTagColor(tag.color);
                  return Chip(
                    label: Text(tag.name),
                    backgroundColor: color.withOpacity(0.2),
                    side: BorderSide(color: color),
                  );
                }).toList(),
              ),
              if (_tags.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... ${l10n.tag_and_more} ${_tags.length - 5} ${l10n.tag_items}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                l10n.tag_no_tags,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
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

  /// 将 TagColor 转换为 Color
  Color _getTagColor(TagColor color) {
    switch (color) {
      case TagColor.blue:
        return Colors.blue;
      case TagColor.green:
        return Colors.green;
      case TagColor.orange:
        return Colors.orange;
      case TagColor.purple:
        return Colors.purple;
      case TagColor.red:
        return Colors.red;
      case TagColor.teal:
        return Colors.teal;
      case TagColor.indigo:
        return Colors.indigo;
      case TagColor.pink:
        return Colors.pink;
    }
  }

  /// 功能设置卡片
  Widget _buildFeatureSettingsTile(AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          // 开机自启
          SwitchListTile(
            secondary: const Icon(Icons.start),
            title: Text(l10n.settings_autoStart),
            subtitle: Text(
              '当前状态: ${PlatformServiceManager.autoStart.isEnabled ? "已启用" : "已禁用"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: PlatformServiceManager.autoStart.isEnabled,
            onChanged: (value) => _showAutoStartConfirmDialog(value),
          ),
          // TODO: 实现最小化到托盘功能
          // SwitchListTile(
          //   secondary: const Icon(Icons.web_asset),
          //   title: Text(l10n.settings_minimizeToTray),
          //   value: _globalConfig!.features.minimizeToTray,
          //   onChanged: (value) => _updateFeature('minimizeToTray', value),
          // ),
          // 通知模式选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, size: 20),
                    const SizedBox(width: 16),
                    Text(
                      l10n.settings_notificationMode,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<NotificationMode>(
                  segments: [
                    ButtonSegment(
                      value: NotificationMode.app,
                      label: Text(l10n.settings_notificationMode_app),
                    ),
                    ButtonSegment(
                      value: NotificationMode.system,
                      label: Text(l10n.settings_notificationMode_system),
                    ),
                  ],
                  selected: {_globalConfig!.services.notification.mode},
                  onSelectionChanged: (Set<NotificationMode> selection) async {
                    final newMode = selection.first;
                    await _updateNotificationMode(newMode);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settings_notificationMode_desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  /// 更新功能配置
  Future<void> _updateFeature(String key, bool value) async {
    if (_globalConfig == null) return;

    final newFeatures = _globalConfig!.features.copyWith(
      autoStart: key == 'autoStart' ? value : null,
      minimizeToTray: key == 'minimizeToTray' ? value : null,
      enableNotifications: key == 'enableNotifications' ? value : null,
    );

    final newConfig = _globalConfig!.copyWith(features: newFeatures);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      if (mounted) {
        setState(() => _globalConfig = newConfig);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to update feature: $e');
      _showErrorMessage();
    }
  }

  /// 更新通知模式
  Future<void> _updateNotificationMode(NotificationMode mode) async {
    if (_globalConfig == null) return;

    final newNotificationConfig = _globalConfig!.services.notification.copyWith(
      mode: mode,
    );

    final newServices = _globalConfig!.services.copyWith(
      notification: newNotificationConfig,
    );

    final newConfig = _globalConfig!.copyWith(services: newServices);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      if (mounted) {
        setState(() => _globalConfig = newConfig);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to update notification mode: $e');
      _showErrorMessage();
    }
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

  /// 显示开机自启确认对话框
  void _showAutoStartConfirmDialog(bool enabled) {
    final l10n = AppLocalizations.of(context)!;

    // 检查是否为开发模式
    final isDebugMode = _isRunningInDebugMode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? '启用开机自启' : '禁用开机自启'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enabled
                ? '将允许 Plugin Platform 在 Windows 启动时自动运行。'
                : '将禁止 Plugin Platform 在 Windows 启动时自动运行。'),
            const SizedBox(height: 12),
            if (enabled && isDebugMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '⚠️ 开发模式警告',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前运行的是开发版本，重启后无法正常启动！\n\n'
                      '原因：开发版本依赖 Flutter 开发服务器，重启后服务器已关闭。\n\n'
                      '正确测试方法：\n'
                      '1. 运行：flutter build windows --release\n'
                      '2. 直接运行：build\\windows\\x64\\runner\\Release\\plugin_platform.exe\n'
                      '3. 在发布版本中启用开机自启',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (enabled) ...[
              Text(
                '注意：每次重新编译后需要重新设置，因为可执行文件路径会变化。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _setAutoStart(enabled);
            },
            style: isDebugMode && enabled
                ? FilledButton.styleFrom(backgroundColor: Colors.orange)
                : null,
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );
  }

  /// 检查是否运行在开发模式
  bool _isRunningInDebugMode() {
    try {
      // 检查可执行文件路径
      final exePath = io.Platform.resolvedExecutable;
      // Debug 版本通常在 Debug 目录
      return exePath.contains('Debug') || exePath.contains('debug');
    } catch (e) {
      // 如果检测失败，假设是开发模式（更安全）
      return true;
    }
  }

  /// 设置开机自启
  Future<void> _setAutoStart(bool enabled) async {
    try {
      final success = await PlatformServiceManager.autoStart.setEnabled(enabled);
      if (success) {
        // 更新配置中的 autoStart 状态
        final newFeatures = _globalConfig!.features.copyWith(
          autoStart: enabled,
        );
        final newConfig = _globalConfig!.copyWith(features: newFeatures);
        await ConfigManager.instance.updateGlobalConfig(newConfig);

        if (mounted) {
          setState(() => _globalConfig = newConfig);
          _showSuccessMessage();
        }
      } else {
        _showErrorMessage();
      }
    } catch (e) {
      debugPrint('Failed to set auto start: $e');
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
