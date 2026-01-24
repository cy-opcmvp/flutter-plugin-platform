/// Settings Screen
///
/// Provides comprehensive application and plugin configuration management.
library;

import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/main.dart' show PluginPlatformApp;
import 'package:plugin_platform/core/services/locale_provider.dart';
import 'package:plugin_platform/core/services/theme_provider.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/services/platform_core.dart';
import 'package:plugin_platform/core/services/platform_service_manager.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'package:plugin_platform/plugins/plugin_registry.dart';
import 'app_info_screen.dart';
import 'desktop_pet_settings_screen.dart';

/// Settings Screen
///
/// Allows users to configure application settings including:
/// - Global configuration (app, features, services, advanced)
/// - Plugin-specific configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Platform core
  late final PlatformCore _platformCore;

  /// Global configuration
  GlobalConfig? _globalConfig;

  /// Loading state
  bool _isLoading = true;

  /// Theme provider reference
  ThemeProvider? _themeProvider;

  @override
  void initState() {
    super.initState();
    _platformCore = PlatformCore();
    _loadConfigs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听 ThemeProvider 变化
    final newThemeProvider = PluginPlatformApp.themeOf(context);

    // 如果是不同的 provider，移除旧的监听器并添加新的
    if (_themeProvider != newThemeProvider) {
      _themeProvider?.removeListener(_onThemeChanged);
      _themeProvider = newThemeProvider;
      _themeProvider!.addListener(_onThemeChanged);
    }
  }

  @override
  void dispose() {
    _themeProvider?.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    // 主题变化时重建页面
    if (mounted) {
      setState(() {});
    }
  }

  /// Load all configurations
  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);

    try {
      // Initialize platform core
      await _platformCore.initialize();

      // Load global config
      _globalConfig = ConfigManager.instance.globalConfig;
    } catch (e) {
      debugPrint('Failed to load configs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = PluginPlatformApp.of(context);
    final themeProvider = PluginPlatformApp.themeOf(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context),
            tooltip: l10n.settings_resetToDefaults,
          ),
        ],
      ),
      body: ListView(
        children: [
          // 应用设置
          if (_globalConfig != null) ...[
            _buildSection(
              context,
              title: l10n.settings_app,
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(l10n.appInfo_title),
                  subtitle: Text(l10n.appInfo_viewDetails),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppInfoScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
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
                SwitchListTile(
                  secondary: const Icon(Icons.start),
                  title: Text(l10n.settings_autoStart),
                  subtitle: Text(l10n.settings_autoStart_description),
                  value: PlatformServiceManager.autoStart.isEnabled,
                  onChanged: (value) => _showAutoStartConfirmDialog(context, value),
                ),
              ],
            ),
          ],

          // 通用设置
          _buildSection(
            context,
            title: l10n.settings_general,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.settings_currentLanguage),
                subtitle: Text(
                  localeProvider.getLocaleDisplayName(localeProvider.locale),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, localeProvider),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.settings_theme),
                subtitle: Text(
                  themeProvider.getThemeModeDisplayName(
                    themeProvider.themeMode,
                    isChinese: localeProvider.isChinese,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModeDialog(
                  context,
                  themeProvider,
                  localeProvider.isChinese,
                ),
              ),
              if (_globalConfig != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // 插件管理
          _buildSection(
            context,
            title: l10n.settings_plugins,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l10n.plugin_worldclock_name),
                subtitle: Text(l10n.plugin_worldclock_description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPluginSettings('com.example.worldclock'),
              ),
              ListTile(
                leading: const Icon(Icons.calculate),
                title: Text(l10n.plugin_calculator_name),
                subtitle: Text(l10n.plugin_calculator_description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPluginSettings('com.example.calculator'),
              ),
              ListTile(
                leading: const Icon(Icons.screenshot),
                title: Text(l10n.plugin_screenshot_name),
                subtitle: Text(l10n.plugin_screenshot_description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openPluginSettings('com.example.screenshot'),
              ),
            ],
          ),

          // 底部留白
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Open plugin settings screen
  void _openPluginSettings(String pluginId) async {
    debugPrint('Opening plugin settings for: $pluginId');

    // First, ensure plugin is loaded
    final pluginManager = _platformCore.pluginManager;
    var plugin = pluginManager.getPlugin(pluginId);

    if (plugin == null) {
      debugPrint('Plugin not found: $pluginId');
      debugPrint(
        'Available plugins: ${pluginManager.getActivePlugins().map((p) => p.id).toList()}',
      );

      // Try to load the plugin
      try {
        debugPrint('Attempting to load plugin: $pluginId');

        // Get the plugin descriptor
        final descriptor = ExamplePluginRegistry.getDescriptor(pluginId);
        if (descriptor == null) {
          debugPrint('Plugin descriptor not found: $pluginId');
          _showErrorMessage();
          return;
        }

        await pluginManager.loadPlugin(descriptor);
        plugin = pluginManager.getPlugin(pluginId);

        if (plugin == null) {
          debugPrint('Failed to load plugin after loadPlugin call: $pluginId');
          _showErrorMessage();
          return;
        }

        debugPrint('Plugin loaded successfully: $pluginId');
        await _navigateToSettings(plugin);
      } catch (e) {
        debugPrint('Failed to load plugin: $e');
        _showErrorMessage();
        return;
      }
    } else {
      await _navigateToSettings(plugin);
    }
  }

  /// Navigate to plugin settings screen
  Future<void> _navigateToSettings(dynamic plugin) async {
    try {
      final settingsScreen = plugin.buildSettingsScreen();
      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => settingsScreen));
      }
    } catch (e) {
      debugPrint('Failed to build settings screen: $e');
      _showErrorMessage();
    }
  }

  /// Show reset confirmation dialog
  void _showResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_resetToDefaults),
        content: Text(l10n.settings_resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetToDefaults();
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );
  }

  /// Reset all configurations to defaults
  Future<void> _resetToDefaults() async {
    try {
      await ConfigManager.instance.resetToDefaults();
      await _loadConfigs();
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  /// Show success message
  void _showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_configSaved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_configSaveFailed),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Build a settings section with title and children
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Show language selection dialog
  void _showLanguageDialog(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_changeLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              localeProvider,
              locale: const Locale('zh', 'CN'),
              name: l10n.settings_languageChinese,
            ),
            const Divider(),
            _buildLanguageOption(
              context,
              localeProvider,
              locale: const Locale('en', 'US'),
              name: l10n.settings_languageEnglish,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single language option
  Widget _buildLanguageOption(
    BuildContext context,
    LocaleProvider localeProvider, {
    required Locale locale,
    required String name,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = localeProvider.locale == locale;

    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () async {
        // Close the dialog
        Navigator.of(context).pop();

        // Change the language
        await localeProvider.setLocale(locale);

        // Show success message
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settings_languageChanged(name)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// Show theme mode selection dialog
  void _showThemeModeDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isChinese,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_changeTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((mode) {
            final isSelected = themeProvider.themeMode == mode;
            return ListTile(
              title: Text(
                themeProvider.getThemeModeDisplayName(
                  mode,
                  isChinese: isChinese,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                Navigator.of(context).pop();
                await themeProvider.setThemeMode(mode);

                // Show success message
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.settings_themeChanged(
                        themeProvider.getThemeModeDisplayName(
                          mode,
                          isChinese: isChinese,
                        ),
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Show auto start confirmation dialog
  void _showAutoStartConfirmDialog(BuildContext context, bool enabled) {
    final l10n = AppLocalizations.of(context)!;

    // Check if running in debug mode
    final isDebugMode = _isRunningInDebugMode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? '启用开机自启' : '禁用开机自启'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              enabled
                  ? '将允许 Plugin Platform 在 Windows 启动时自动运行。'
                  : '将禁止 Plugin Platform 在 Windows 启动时自动运行。',
            ),
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
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
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

  /// Check if running in debug mode
  bool _isRunningInDebugMode() {
    try {
      // Check executable path
      final exePath = io.Platform.resolvedExecutable;
      // Debug versions usually in Debug directory
      return exePath.contains('Debug') || exePath.contains('debug');
    } catch (e) {
      // If detection fails, assume debug mode (safer)
      return true;
    }
  }

  /// Set auto start
  Future<void> _setAutoStart(bool enabled) async {
    try {
      final success = await PlatformServiceManager.autoStart.setEnabled(enabled);
      if (success) {
        // Update autoStart status in config
        if (_globalConfig != null) {
          final newFeatures = _globalConfig!.features.copyWith(autoStart: enabled);
          final newConfig = _globalConfig!.copyWith(features: newFeatures);
          await ConfigManager.instance.updateGlobalConfig(newConfig);

          if (mounted) {
            setState(() => _globalConfig = newConfig);
            _showSuccessMessage();
          }
        }
      } else {
        _showErrorMessage();
      }
    } catch (e) {
      debugPrint('Failed to set auto start: $e');
      _showErrorMessage();
    }
  }

  /// Update notification mode
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
}
