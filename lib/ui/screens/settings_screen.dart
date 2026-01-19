/// Settings Screen
///
/// Provides comprehensive application and plugin configuration management.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/main.dart' show PluginPlatformApp;
import 'package:plugin_platform/core/services/locale_provider.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'tag_management_screen.dart';

/// Settings Screen
///
/// Allows users to configure application settings including:
/// - Global configuration (app, features, services, advanced)
/// - Plugin-specific configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Global configuration
  GlobalConfig? _globalConfig;

  /// Screenshot plugin configuration
  Map<String, dynamic>? _screenshotConfig;

  /// Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  /// Load all configurations
  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);

    try {
      // Load global config
      _globalConfig = ConfigManager.instance.globalConfig;

      // Load screenshot plugin config
      _screenshotConfig = await ConfigManager.instance.loadPluginConfig(
        'com.example.screenshot',
      );
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
            // App Settings
            _buildSection(
              context,
              title: l10n.settings_app,
              children: [
                ListTile(
                  leading: const Icon(Icons.app_settings_alt),
                  title: Text(l10n.settings_appName),
                  subtitle: Text(_globalConfig!.app.name),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(l10n.settings_appVersion),
                  subtitle: Text(_globalConfig!.app.version),
                ),
              ],
            ),

            // Feature Settings
            _buildSection(
              context,
              title: l10n.settings_features,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.start),
                  title: Text(l10n.settings_autoStart),
                  value: _globalConfig!.features.autoStart,
                  onChanged: (value) => _updateFeature('autoStart', value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.web_asset),
                  title: Text(l10n.settings_minimizeToTray),
                  value: _globalConfig!.features.minimizeToTray,
                  onChanged: (value) => _updateFeature('minimizeToTray', value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.pets),
                  title: Text(l10n.settings_showDesktopPet),
                  value: _globalConfig!.features.showDesktopPet,
                  onChanged: (value) => _updateFeature('showDesktopPet', value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: Text(l10n.settings_enableNotifications),
                  value: _globalConfig!.features.enableNotifications,
                  onChanged: (value) =>
                      _updateFeature('enableNotifications', value),
                ),
              ],
            ),

            // Advanced Settings
            _buildSection(
              context,
              title: l10n.settings_advanced,
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
          ],

          // Plugin Configuration Section
          _buildSection(
            context,
            title: l10n.settings_plugins,
            children: [
              ListTile(
                leading: const Icon(Icons.label),
                title: Text(l10n.tag_title),
                subtitle: Text('管理插件标签和分类'),
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
                leading: const Icon(Icons.screenshot),
                title: Text(l10n.plugin_screenshot_name),
                subtitle: Text(l10n.plugin_screenshot_description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showScreenshotConfigScreen(context),
              ),
            ],
          ),

          // Theme Settings Section (placeholder for future implementation)
          _buildSection(
            context,
            title: l10n.settings_theme,
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.settings_theme),
                subtitle: Text(
                  localeProvider.isChinese ? '跟随系统' : 'Follow System',
                ),
                enabled: false, // Disable for now, will be implemented later
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Update feature configuration
  Future<void> _updateFeature(String key, bool value) async {
    if (_globalConfig == null) return;

    final newFeatures = _globalConfig!.features.copyWith(
      autoStart: key == 'autoStart' ? value : null,
      minimizeToTray: key == 'minimizeToTray' ? value : null,
      showDesktopPet: key == 'showDesktopPet' ? value : null,
      enableNotifications: key == 'enableNotifications' ? value : null,
    );

    final newConfig = _globalConfig!.copyWith(features: newFeatures);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      setState(() => _globalConfig = newConfig);
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  /// Update advanced configuration
  Future<void> _updateAdvanced(String key, bool value) async {
    if (_globalConfig == null) return;

    final newAdvanced = _globalConfig!.advanced.copyWith(
      debugMode: key == 'debugMode' ? value : null,
    );

    final newConfig = _globalConfig!.copyWith(advanced: newAdvanced);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      setState(() => _globalConfig = newConfig);
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  /// Show log level selection dialog
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

  /// Update log level
  Future<void> _updateLogLevel(String level) async {
    if (_globalConfig == null) return;

    final newAdvanced = AdvancedConfig(
      debugMode: _globalConfig!.advanced.debugMode,
      logLevel: level,
      maxLogFileSize: _globalConfig!.advanced.maxLogFileSize,
    );

    final newConfig = _globalConfig!.copyWith(advanced: newAdvanced);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      setState(() => _globalConfig = newConfig);
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage();
    }
  }

  /// Show screenshot configuration screen
  void _showScreenshotConfigScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScreenshotConfigScreen(
          config: _screenshotConfig ?? {},
          onSave: (config) async {
            try {
              await ConfigManager.instance.savePluginConfig(
                'com.example.screenshot',
                config,
              );
              setState(() => _screenshotConfig = config);
              _showSuccessMessage();
            } catch (e) {
              _showErrorMessage();
            }
          },
        ),
      ),
    );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settings_languageChanged(name)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}

/// Screenshot Plugin Configuration Screen
class ScreenshotConfigScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const ScreenshotConfigScreen({
    Key? key,
    required this.config,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ScreenshotConfigScreen> createState() => _ScreenshotConfigScreenState();
}

class _ScreenshotConfigScreenState extends State<ScreenshotConfigScreen> {
  late TextEditingController _savePathController;
  late TextEditingController _filenameFormatController;
  late String _imageFormat;
  late int _imageQuality;
  late bool _autoCopyToClipboard;
  late bool _showPreview;
  late bool _saveHistory;
  late int _maxHistoryCount;
  late Map<String, String> _shortcuts;

  @override
  void initState() {
    super.initState();
    _savePathController = TextEditingController(
      text: widget.config['savePath'] ?? '{documents}/Screenshots',
    );
    _filenameFormatController = TextEditingController(
      text: widget.config['filenameFormat'] ?? 'screenshot_{timestamp}',
    );
    _imageFormat = widget.config['imageFormat'] ?? 'png';
    _imageQuality = widget.config['imageQuality'] ?? 95;
    _autoCopyToClipboard = widget.config['autoCopyToClipboard'] ?? true;
    _showPreview = widget.config['showPreview'] ?? true;
    _saveHistory = widget.config['saveHistory'] ?? true;
    _maxHistoryCount = widget.config['maxHistoryCount'] ?? 100;
    _shortcuts = Map<String, String>.from(
      widget.config['shortcuts'] ??
          {
            'regionCapture': 'Ctrl+Shift+A',
            'fullScreenCapture': 'Ctrl+Shift+F',
            'windowCapture': 'Ctrl+Shift+W',
          },
    );
  }

  @override
  void dispose() {
    _savePathController.dispose();
    _filenameFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenshot_config_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: l10n.common_save,
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: l10n.settings_general,
            children: [
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(l10n.settings_savePath),
                subtitle: Text(_savePathController.text),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editSavePath(context),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(l10n.settings_filenameFormat),
                subtitle: Text(_filenameFormatController.text),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editFilenameFormat(context),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(l10n.settings_imageFormat),
                subtitle: Text(_imageFormat.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectImageFormat(context),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.settings_imageQuality),
                subtitle: Text('$_imageQuality%'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editImageQuality(context),
              ),
            ],
          ),
          _buildSection(
            context,
            title: l10n.settings_behavior,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.content_copy),
                title: Text(l10n.settings_autoCopyToClipboard),
                value: _autoCopyToClipboard,
                onChanged: (value) =>
                    setState(() => _autoCopyToClipboard = value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.preview),
                title: Text(l10n.settings_showPreview),
                value: _showPreview,
                onChanged: (value) => setState(() => _showPreview = value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.history),
                title: Text(l10n.settings_saveHistory),
                value: _saveHistory,
                onChanged: (value) => setState(() => _saveHistory = value),
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: Text(l10n.settings_maxHistoryCount),
                subtitle: Text('$_maxHistoryCount'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editMaxHistoryCount(context),
              ),
            ],
          ),
          _buildSection(
            context,
            title: l10n.settings_shortcuts,
            children: [
              ListTile(
                leading: const Icon(Icons.crop),
                title: Text(l10n.settings_regionCapture),
                subtitle: Text(_shortcuts['regionCapture'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editShortcut(context, 'regionCapture'),
              ),
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: Text(l10n.settings_fullScreenCapture),
                subtitle: Text(_shortcuts['fullScreenCapture'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editShortcut(context, 'fullScreenCapture'),
              ),
              ListTile(
                leading: const Icon(Icons.window),
                title: Text(l10n.settings_windowCapture),
                subtitle: Text(_shortcuts['windowCapture'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editShortcut(context, 'windowCapture'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editSavePath(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _savePathController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_savePath),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '{documents}/Screenshots',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _savePathController.text = result);
    }
  }

  Future<void> _editFilenameFormat(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _filenameFormatController.text,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_filenameFormat),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'screenshot_{timestamp}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _filenameFormatController.text = result);
    }
  }

  Future<void> _selectImageFormat(BuildContext context) async {
    final formats = ['png', 'jpeg', 'webp'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            final isSelected = _imageFormat == format;
            return ListTile(
              title: Text(format.toUpperCase()),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() => _imageFormat = format);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _editImageQuality(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_imageQuality),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _imageQuality.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '$_imageQuality%',
                  onChanged: (value) =>
                      setDialogState(() => _imageQuality = value.toInt()),
                ),
                Text('$_imageQuality%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );
  }

  Future<void> _editMaxHistoryCount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _maxHistoryCount.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_maxHistoryCount),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '100'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.of(context).pop(value);
              }
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _maxHistoryCount = result);
    }
  }

  Future<void> _editShortcut(BuildContext context, String actionId) async {
    final l10n = AppLocalizations.of(context)!;
    final actionName =
        {
          'regionCapture': l10n.settings_regionCapture,
          'fullScreenCapture': l10n.settings_fullScreenCapture,
          'windowCapture': l10n.settings_windowCapture,
        }[actionId] ??
        actionId;

    final controller = TextEditingController(text: _shortcuts[actionId] ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionName),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Ctrl+Shift+A'),
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              // Allow only shortcut keys
              return TextEditingValue(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _shortcuts[actionId] = result);
    }
  }

  Future<void> _saveConfig() async {
    final config = {
      'savePath': _savePathController.text,
      'filenameFormat': _filenameFormatController.text,
      'imageFormat': _imageFormat,
      'imageQuality': _imageQuality,
      'autoCopyToClipboard': _autoCopyToClipboard,
      'showPreview': _showPreview,
      'saveHistory': _saveHistory,
      'maxHistoryCount': _maxHistoryCount,
      'historyRetentionDays': 30,
      'shortcuts': _shortcuts,
      'pinSettings': {
        'alwaysOnTop': true,
        'defaultOpacity': 0.9,
        'enableDrag': true,
        'enableResize': false,
        'showCloseButton': true,
      },
    };

    await widget.onSave(config);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

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
}
