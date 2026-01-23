/// Settings Screen
///
/// Provides comprehensive application and plugin configuration management.
library;

import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/main.dart' show PluginPlatformApp;
import 'package:plugin_platform/core/services/locale_provider.dart';
import 'package:plugin_platform/core/services/theme_provider.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/services/platform_core.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'package:plugin_platform/plugins/plugin_registry.dart';
import 'tag_management_screen.dart';
import 'desktop_pet_settings_screen.dart';
import 'app_info_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _platformCore = PlatformCore();
    _loadConfigs();
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
          // Language Settings Section
          _buildSection(
            context,
            title: l10n.settings_language,
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
            ],
          ),

          // Global Configuration Sections
          if (_globalConfig != null) ...[
            // App Information
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
              ],
            ),
          ],

          // Plugin Management Section
          _buildSection(
            context,
            title: l10n.settings_plugins,
            children: [
              ListTile(
                leading: const Icon(Icons.extension),
                title: Text(l10n.settings_pluginManagement),
                subtitle: Text(l10n.settings_pluginManagement_desc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TagManagementScreen(),
                    ),
                  );
                },
              ),
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

          // Theme Settings Section
          _buildSection(
            context,
            title: l10n.settings_theme,
            children: [
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
                onTap: () => _showThemeModeDialog(context, themeProvider, localeProvider.isChinese),
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
    final modes = [
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ];

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
}
