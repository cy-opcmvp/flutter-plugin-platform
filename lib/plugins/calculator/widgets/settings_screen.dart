library;

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../core/services/json_validator.dart';
import '../config/calculator_config_defaults.dart';
import '../models/calculator_settings.dart';
import '../calculator_plugin.dart';

/// 计算器插件设置界面
class CalculatorSettingsScreen extends StatefulWidget {
  final CalculatorPlugin plugin;

  const CalculatorSettingsScreen({super.key, required this.plugin});

  @override
  State<CalculatorSettingsScreen> createState() =>
      _CalculatorSettingsScreenState();
}

class _CalculatorSettingsScreenState extends State<CalculatorSettingsScreen> {
  late CalculatorSettings _settings;

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
        title: Text(l10n.calculator_settings_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context),
            tooltip: l10n.settings_resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
        ),
        child: _buildContent(context, l10n),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基础设置
        _buildSectionHeader(l10n.calculator_settings_basic),
        const SizedBox(height: 8),
        _buildPrecisionTile(l10n),
        _buildAngleModeTile(l10n),
        _buildHistorySizeTile(l10n),

        const SizedBox(height: 24),

        // 显示设置
        _buildSectionHeader(l10n.calculator_settings_display),
        const SizedBox(height: 8),
        _buildGroupingSeparatorTile(l10n),

        const SizedBox(height: 24),

        // 交互设置
        _buildSectionHeader(l10n.calculator_settings_interaction),
        const SizedBox(height: 8),
        _buildVibrationTile(l10n),
        _buildSoundVolumeTile(l10n),

        const SizedBox(height: 24),

        // JSON 编辑器
        _buildJsonEditorSection(context, l10n),
      ],
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

  Widget _buildPrecisionTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.calculator_setting_precision),
                      const SizedBox(height: 4),
                      Text(
                        '${_settings.precision} ${l10n.calculator_decimal_places}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('0 - 15', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _settings.precision.toDouble(),
              min: 0,
              max: 15,
              divisions: 15,
              label: '${_settings.precision}',
              onChanged: (value) async {
                final newSettings = _settings.copyWith(
                  precision: value.toInt(),
                );
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

  Widget _buildAngleModeTile(AppLocalizations l10n) {
    return Card(
      child: ListTile(
        title: Text(l10n.calculator_setting_angleMode),
        subtitle: Text(
          _settings.angleMode == 'deg'
              ? l10n.calculator_angle_mode_degrees
              : l10n.calculator_angle_mode_radians,
        ),
        trailing: SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'deg',
              label: Text(l10n.calculator_angle_mode_degrees_short),
            ),
            ButtonSegment(
              value: 'rad',
              label: Text(l10n.calculator_angle_mode_radians_short),
            ),
          ],
          selected: {_settings.angleMode},
          onSelectionChanged: (Set<String> selection) async {
            final newMode = selection.first;
            final newSettings = _settings.copyWith(angleMode: newMode);
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

  Widget _buildHistorySizeTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.calculator_setting_historySize),
                      const SizedBox(height: 4),
                      Text(
                        l10n.calculator_history_size_description(
                          _settings.historySize,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('10 - 500', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _settings.historySize.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              label: '${_settings.historySize}',
              onChanged: (value) async {
                final newSettings = _settings.copyWith(
                  historySize: value.toInt(),
                );
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

  Widget _buildGroupingSeparatorTile(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.calculator_setting_showGroupingSeparator),
      subtitle: Text(l10n.calculator_grouping_separator_description),
      value: _settings.showGroupingSeparator,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(showGroupingSeparator: value);
        if (await _saveSettings(newSettings)) {
          setState(() {
            _settings = newSettings;
          });
        }
      },
    );
  }

  Widget _buildVibrationTile(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(l10n.calculator_setting_enableVibration),
      subtitle: Text(l10n.calculator_vibration_description),
      value: _settings.enableVibration,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(enableVibration: value);
        if (await _saveSettings(newSettings)) {
          setState(() {
            _settings = newSettings;
          });
        }
      },
    );
  }

  Widget _buildSoundVolumeTile(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.calculator_setting_buttonSoundVolume),
                      const SizedBox(height: 4),
                      Text(
                        '${_settings.buttonSoundVolume}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _settings.buttonSoundVolume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _settings.buttonSoundVolume.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_settings.buttonSoundVolume}%',
              onChanged: (value) async {
                final newSettings = _settings.copyWith(
                  buttonSoundVolume: value.toInt(),
                );
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
            Text(l10n.calculator_config_description),
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

  Future<void> _openJsonEditor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.calculator_config_name,
          configDescription: l10n.calculator_config_description,
          currentJson: _settings.toJsonString(),
          schema: null,
          defaultJson: CalculatorConfigDefaults.defaultConfig,
          exampleJson: CalculatorConfigDefaults.cleanExample,
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
            content: Text(l10n.calculator_settings_saved),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool> _saveConfig(String jsonString) async {
    try {
      // 1. JSON 语法校验
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      // 2. 解析 JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 3. 创建配置对象
      final settings = CalculatorSettings.fromJson(data);

      // 5. 验证配置
      if (!settings.isValid()) {
        throw Exception('Invalid configuration values');
      }

      // 6. 保存配置
      return await _saveSettings(settings);
    } catch (e) {
      debugPrint('Failed to save config: $e');
      return false;
    }
  }

  Future<bool> _saveSettings(CalculatorSettings settings) async {
    try {
      // TODO: 集成到插件的配置持久化
      // 现在只是更新内存中的设置
      widget.plugin.updateSettings(settings);
      return true;
    } catch (e) {
      debugPrint('Failed to save settings: $e');
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
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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
      final defaultData =
          jsonDecode(CalculatorConfigDefaults.defaultConfig)
              as Map<String, dynamic>;
      final defaultSettings = CalculatorSettings.fromJson(defaultData);

      // 保存默认设置
      if (await _saveSettings(defaultSettings) && mounted) {
        setState(() {
          _settings = defaultSettings;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.settings_configSaved),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to reset to defaults: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.settings_configSaveFailed,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
