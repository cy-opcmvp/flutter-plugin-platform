library;

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../core/services/json_validator.dart';
import '../config/world_clock_config_defaults.dart';
import '../models/world_clock_settings.dart';
import '../models/world_clock_models.dart';
import '../world_clock_plugin.dart';

/// 世界时钟插件设置界面
class WorldClockSettingsScreen extends StatefulWidget {
  final WorldClockPlugin plugin;

  const WorldClockSettingsScreen({super.key, required this.plugin});

  @override
  State<WorldClockSettingsScreen> createState() =>
      _WorldClockSettingsScreenState();
}

class _WorldClockSettingsScreenState extends State<WorldClockSettingsScreen> {
  late WorldClockSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.plugin.settings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.world_clock_settings_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context),
            tooltip: l10n.settings_resetToDefaults,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 基础设置
          _buildSectionHeader(l10n.world_clock_settings_basic),
          const SizedBox(height: 8),
          _buildTimeZoneTile(l10n),
          _buildTimeFormatTile(l10n),
          _buildShowSecondsTile(l10n),

          const SizedBox(height: 24),

          // 通知设置
          _buildSectionHeader(l10n.world_clock_settings_notification),
          const SizedBox(height: 8),
          _buildEnableNotificationsTile(l10n),
          _buildUpdateIntervalTile(l10n),

          const SizedBox(height: 24),

          // JSON 编辑器
          _buildJsonEditorSection(context, l10n),
        ],
      ),
    );
  }

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

  Widget _buildTimeZoneTile(AppLocalizations l10n) {
    // 查找时区对应的中文名称
    final timeZoneInfo = TimeZoneInfo.findByTimeZoneId(_settings.defaultTimeZone);
    final displayName = timeZoneInfo?.displayName ?? _settings.defaultTimeZone;

    return Card(
      child: ListTile(
        title: Text(l10n.world_clock_setting_defaultTimeZone),
        subtitle: Text(displayName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectTimeZone(),
      ),
    );
  }

  Widget _buildTimeFormatTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        title: Text(l10n.world_clock_setting_timeFormat),
        subtitle: Text(l10n.world_clock_time_format_desc),
        trailing: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: '12h', label: Text('12')),
            ButtonSegment(value: '24h', label: Text('24')),
          ],
          selected: {_settings.timeFormat},
          onSelectionChanged: (Set<String> selection) async {
            final newFormat = selection.first;
            final newSettings = _settings.copyWith(timeFormat: newFormat);
            if (await _saveSettings(newSettings, context)) {
              setState(() {
                _settings = newSettings;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildShowSecondsTile(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.world_clock_setting_showSeconds),
      subtitle: Text(l10n.world_clock_showSeconds_desc),
      value: _settings.showSeconds,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(showSeconds: value);
        if (await _saveSettings(newSettings, context)) {
          setState(() {
            _settings = newSettings;
          });
        }
      },
    );
  }

  Widget _buildEnableNotificationsTile(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.world_clock_setting_enableNotifications),
      subtitle: Text(l10n.world_clock_enable_notifications_desc),
      value: _settings.enableNotifications,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(enableNotifications: value);
        if (await _saveSettings(newSettings, context)) {
          setState(() {
            _settings = newSettings;
          });
        }
      },
    );
  }

  Widget _buildUpdateIntervalTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.world_clock_setting_updateInterval,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.world_clock_update_interval_desc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_settings.updateInterval} ms'),
                Text(
                  _settings.updateInterval >= 1000
                      ? '${(_settings.updateInterval / 1000).toStringAsFixed(1)} s'
                      : '${_settings.updateInterval} ms',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _settings.updateInterval.toDouble(),
              min: 100,
              max: 10000,
              divisions: 99,
              label: '${_settings.updateInterval}',
              onChanged: (value) async {
                final newSettings = _settings.copyWith(
                  updateInterval: value.toInt(),
                );
                if (await _saveSettings(newSettings, context)) {
                  setState(() {
                    _settings = newSettings;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonEditorSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.json_editor_edit_json,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.world_clock_config_description),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openJsonEditor(context),
              icon: const Icon(Icons.edit),
              label: Text(l10n.json_editor_edit_json),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTimeZone() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _TimeZoneSelectionDialog(
        currentTimeZone: _settings.defaultTimeZone,
      ),
    );

    if (selected != null && selected != _settings.defaultTimeZone) {
      final newSettings = _settings.copyWith(defaultTimeZone: selected);
      if (await _saveSettings(newSettings, context) && mounted) {
        setState(() {
          _settings = newSettings;
        });
      }
    }
  }

  Future<void> _openJsonEditor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.world_clock_config_name,
          configDescription: l10n.world_clock_config_description,
          currentJson: _settings.toJsonString(),
          schema: null,
          defaultJson: WorldClockConfigDefaults.defaultConfig,
          exampleJson: WorldClockConfigDefaults.cleanExample,
          onSave: _saveConfig,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _settings = widget.plugin.settings;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.world_clock_settings_saved),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool> _saveConfig(String jsonString) async {
    try {
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = WorldClockSettings.fromJson(data);

      if (!settings.isValid()) {
        throw Exception('Invalid configuration values');
      }

      return await _saveSettings(settings, context);
    } catch (e) {
      debugPrint('Failed to save config: $e');
      return false;
    }
  }

  Future<bool> _saveSettings(WorldClockSettings settings, BuildContext context) async {
    try {
      widget.plugin.updateSettings(settings);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settings_configSaved),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settings_configSaveFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }
  }

  /// 显示恢复默认设置确认对话框
  Future<void> _showResetDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_resetToDefaults),
        content: Text(l10n.settings_resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resetToDefaults();
    }
  }

  /// 恢复默认设置
  Future<void> _resetToDefaults() async {
    try {
      // 从默认配置中解析设置
      final defaultData = jsonDecode(WorldClockConfigDefaults.defaultConfig)
          as Map<String, dynamic>;
      final defaultSettings = WorldClockSettings.fromJson(defaultData);

      // 保存默认设置
      widget.plugin.updateSettings(defaultSettings);

      if (mounted) {
        setState(() {
          _settings = defaultSettings;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_configSaved),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to reset to defaults: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_configSaveFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// 时区选择对话框
class _TimeZoneSelectionDialog extends StatefulWidget {
  final String currentTimeZone;

  const _TimeZoneSelectionDialog({required this.currentTimeZone});

  @override
  State<_TimeZoneSelectionDialog> createState() => _TimeZoneSelectionDialogState();
}

class _TimeZoneSelectionDialogState extends State<_TimeZoneSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.world_clock_time_zone),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: TimeZoneInfo.predefinedTimeZones.length,
          itemBuilder: (context, index) {
            final timeZone = TimeZoneInfo.predefinedTimeZones[index];
            final isSelected = timeZone.timeZoneId == widget.currentTimeZone;

            return RadioListTile<String>(
              title: Text(
                timeZone.displayName,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                timeZone.timeZoneId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              value: timeZone.timeZoneId,
              groupValue: widget.currentTimeZone,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop(value);
                }
              },
              selected: isSelected,
              activeColor: theme.colorScheme.primary,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
