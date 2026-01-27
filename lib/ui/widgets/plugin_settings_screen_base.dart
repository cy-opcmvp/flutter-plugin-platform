library;

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../core/services/json_validator.dart';

/// 插件配置页面基类
///
/// 提供配置页面的通用实现，子类只需实现具体的配置 UI。
///
/// 使用示例：
/// ```dart
/// class MyPluginSettingsScreen extends PluginSettingsScreen<MyPlugin, MyPluginSettings> {
///   @override
///   Widget buildConfigContent(BuildContext context, AppLocalizations l10n) {
///     return Column(
///       children: [
///         _buildSectionHeader(l10n.my_plugin_settings_basic),
///         _buildSwitchTile(
///           title: l10n.my_plugin_enable_feature,
///           value: settings.enableFeature,
///           onChanged: (value) => saveConfig(settings.copyWith(enableFeature: value)),
///         ),
///       ],
///     );
///   }
/// }
/// ```
abstract class PluginSettingsScreen<T extends Object, S extends Object>
    extends StatefulWidget {
  /// 插件实例
  final T plugin;

  const PluginSettingsScreen({super.key, required this.plugin});

  /// 配置对象 getter
  S get settings;

  /// 更新配置方法
  Future<void> Function(S) get updateSettings;

  /// 配置默认值（用于 JSON 编辑器）
  String get defaultConfig;

  /// 清理后的示例配置（用于 JSON 编辑器）
  String get cleanExample;

  /// JSON Schema（可选，用于校验）
  String? get schemaJson => null;

  @override
  State<PluginSettingsScreen<T, S>> createState() =>
      _PluginSettingsScreenState<T, S>();
}

class _PluginSettingsScreenState<T extends Object, S extends Object>
    extends State<PluginSettingsScreen<T, S>> {
  late S _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
  }

  /// 保存配置并更新界面
  Future<void> saveConfig(S newSettings) async {
    try {
      await widget.updateSettings(newSettings);
      if (mounted) {
        setState(() {
          _currentSettings = newSettings;
        });
        showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to save config: $e');
      if (mounted) {
        showErrorMessage();
      }
    }
  }

  /// 获取当前配置
  S get settings => _currentSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle(l10n)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          buildConfigContent(context, l10n),

          const SizedBox(height: 32),

          // JSON 编辑器入口
          buildJsonEditorSection(context, l10n),
        ],
      ),
    );
  }

  /// 构建配置内容（子类实现）
  Widget buildConfigContent(BuildContext context, AppLocalizations l10n) {
    throw UnimplementedError('Subclasses must implement buildConfigContent');
  }

  /// 获取页面标题
  String getTitle(AppLocalizations l10n) {
    throw UnimplementedError('Subclasses must implement getTitle');
  }

  /// 构建章节标题
  Widget buildSectionHeader(String title) {
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

  /// 构建 Switch 开关配置项
  Widget buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? secondary,
  }) {
    return SwitchListTile(
      secondary: secondary != null ? Icon(secondary) : null,
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null
          ? Text(subtitle, overflow: TextOverflow.ellipsis, maxLines: 2)
          : null,
      value: value,
      onChanged: (newValue) async {
        await saveConfig(onChanged(newValue) as S);
      },
    );
  }

  /// 构建分段按钮配置项
  Widget buildSegmentedTile<T>({
    required String title,
    required T value,
    required List<ButtonSegment<T>> segments,
    required ValueChanged<T> onSelected,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            SegmentedButton<T>(
              segments: segments,
              selected: {value},
              onSelectionChanged: (selection) async {
                final newValue = onSelected(selection.first);
                await saveConfig(newValue as S);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建列表项配置（点击后弹出对话框）
  Widget buildListTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData? leading,
    IconData? trailing,
  }) {
    return ListTile(
      leading: leading != null ? Icon(leading) : null,
      title: Text(title, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, overflow: TextOverflow.ellipsis, maxLines: 2),
      trailing: trailing != null
          ? Icon(trailing)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建滑块配置项
  Widget buildSliderTile({
    required String title,
    required int value,
    required int min,
    required int max,
    String? unit,
    int? divisions,
    String? Function(int)? labelFormatter,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: divisions,
                    label: labelFormatter != null
                        ? (labelFormatter(value) ?? '$value')
                        : '$value ${unit ?? ''}',
                    onChanged: (newValue) async {
                      final newSettings = _onSliderChanged(newValue.toInt());
                      if (newSettings != null) {
                        await saveConfig(newSettings);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  labelFormatter != null
                      ? (labelFormatter(value) ?? '$value')
                      : '$value ${unit ?? ''}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 滑块值变化回调（子类可选实现）
  S? _onSliderChanged(int value) => null;

  /// 构建 JSON 编辑器入口
  Widget buildJsonEditorSection(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: Text(
            l10n.json_editor_edit_json,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: _openJsonEditor,
        ),
      ],
    );
  }

  /// 打开 JSON 编辑器
  void _openJsonEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final initialJson = _currentSettings is Map
        ? const JsonEncoder.withIndent('  ').convert(_currentSettings)
        : _currentSettings.toString();

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: getTitle(l10n),
          configDescription: getConfigDescription(l10n),
          currentJson: initialJson,
          schema: widget.schemaJson != null
              ? jsonDecode(widget.schemaJson!)
              : null,
          defaultJson: widget.defaultConfig,
          exampleJson: widget.cleanExample,
          onSave: _saveJsonConfig,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _currentSettings = widget.settings;
      });
      showSuccessMessage();
    }
  }

  /// 保存 JSON 配置（子类可选实现）
  Future<bool> _saveJsonConfig(String jsonString) async {
    try {
      // 1. 校验 JSON
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      // 子类实现具体的保存逻辑
      return await saveJsonConfigImpl(jsonString);
    } catch (e) {
      debugPrint('Failed to save config: $e');
      return false;
    }
  }

  /// 子类实现 JSON 保存逻辑
  Future<bool> saveJsonConfigImpl(String jsonString) async {
    // 默认实现：子类应该重写此方法
    throw UnimplementedError('Subclasses must implement saveJsonConfigImpl');
  }

  /// 获取配置描述（用于 JSON 编辑器）
  String getConfigDescription(AppLocalizations l10n) {
    return l10n.json_editor_config_description;
  }

  /// 显示成功消息
  void showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_config_saved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误消息
  void showErrorMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settings_configSaveFailed),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
