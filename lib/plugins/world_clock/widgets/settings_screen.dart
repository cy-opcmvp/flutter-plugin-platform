library;

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../core/services/json_validator.dart';
import '../config/world_clock_config_defaults.dart';
import '../models/world_clock_settings.dart';
import '../world_clock_plugin.dart';

/// 世界时钟插件设置界面
class WorldClockSettingsScreen extends StatefulWidget {
  final WorldClockPlugin plugin;

  const WorldClockSettingsScreen({
    super.key,
    required this.plugin,
  });

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
    return Card(
      child: ListTile(
        title: Text(l10n.world_clock_setting_defaultTimeZone),
        subtitle: Text(_settings.defaultTimeZone),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectTimeZone(),
      ),
    );
  }

  Widget _buildTimeFormatTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        title: Text(l10n.world_clock_setting_timeFormat),
        subtitle: Text(_settings.timeFormat == '24h'
            ? l10n.world_clock_time_format_24h
            : l10n.world_clock_time_format_12h),
        trailing: SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: '12h',
              label: Text('12'),
            ),
            ButtonSegment(
              value: '24h',
              label: Text('24'),
            ),
          ],
          selected: {_settings.timeFormat},
          onSelectionChanged: (Set<String> selection) async {
            final newFormat = selection.first;
            final newSettings = _settings.copyWith(timeFormat: newFormat);
            if (await _saveSettings(newSettings)) {
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
      value: _settings.showSeconds,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(showSeconds: value);
        if (await _saveSettings(newSettings)) {
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
      subtitle: Text('倒计时完成时显示通知'),
      value: _settings.enableNotifications,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(enableNotifications: value);
        if (await _saveSettings(newSettings)) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.world_clock_setting_updateInterval),
                Text('${_settings.updateInterval} ms'),
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
                final newSettings = _settings.copyWith(updateInterval: value.toInt());
                if (await _saveSettings(newSettings)) {
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
    // TODO: 显示时区选择对话框
    // 暂时保持默认值
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

      return await _saveSettings(settings);
    } catch (e) {
      debugPrint('Failed to save config: $e');
      return false;
    }
  }

  Future<bool> _saveSettings(WorldClockSettings settings) async {
    try {
      widget.plugin.updateSettings(settings);
      return true;
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      return false;
    }
  }
}
