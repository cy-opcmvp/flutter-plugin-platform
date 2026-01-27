/// Desktop Pet Settings Screen
///
/// 桌面宠物设置页面
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/core/services/config_manager.dart';
import 'package:plugin_platform/core/services/desktop_pet_manager.dart';
import 'package:plugin_platform/core/models/global_config.dart';
import 'package:plugin_platform/ui/widgets/json_editor_screen.dart';
import 'package:plugin_platform/core/services/json_validator.dart';

/// Desktop Pet Settings Screen
///
/// 桌面宠物设置页面，提供独立的宠物配置界面
class DesktopPetSettingsScreen extends StatefulWidget {
  const DesktopPetSettingsScreen({super.key});

  @override
  State<DesktopPetSettingsScreen> createState() =>
      _DesktopPetSettingsScreenState();
}

class _DesktopPetSettingsScreenState extends State<DesktopPetSettingsScreen> {
  /// 全局配置
  GlobalConfig? _globalConfig;

  /// 加载状态
  bool _isLoading = true;

  /// 桌面宠物管理器
  late final DesktopPetManager _desktopPetManager;

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
    } catch (e) {
      debugPrint('Failed to load desktop pet config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _globalConfig == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.desktopPet_settings_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final petConfig = _globalConfig!.features.desktopPet;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.desktopPet_settings_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(),
            tooltip: l10n.settings_resetToDefaults,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 外观设置
          _buildSectionHeader(l10n.desktopPet_section_appearance),
          const SizedBox(height: 8),
          _buildOpacityTile(petConfig, l10n),

          const SizedBox(height: 24),

          // 行为设置
          _buildSectionHeader(l10n.desktopPet_section_behavior),
          const SizedBox(height: 8),
          _buildAnimationsEnabledTile(petConfig, l10n),
          _buildInteractionsEnabledTile(petConfig, l10n),

          const SizedBox(height: 24),

          // JSON 编辑器
          _buildJsonEditorSection(l10n),
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

  /// 透明度设置
  Widget _buildOpacityTile(DesktopPetConfig petConfig, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.opacity, size: 20),
                const SizedBox(width: 8),
                Text(l10n.desktopPet_opacity),
                const Spacer(),
                Text('${(petConfig.opacity * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: petConfig.opacity,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              label: '${(petConfig.opacity * 100).round()}%',
              onChanged: (value) async {
                await _updateOpacity(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 动画开关
  Widget _buildAnimationsEnabledTile(
    DesktopPetConfig petConfig,
    AppLocalizations l10n,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.animation),
      title: Text(l10n.desktopPet_enableAnimations),
      subtitle: Text(l10n.desktopPet_animationsSubtitle),
      value: petConfig.animationsEnabled,
      onChanged: (value) async {
        await _updateAnimationsEnabled(value);
      },
    );
  }

  /// 交互开关
  Widget _buildInteractionsEnabledTile(
    DesktopPetConfig petConfig,
    AppLocalizations l10n,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.touch_app),
      title: Text(l10n.desktopPet_enableInteractions),
      subtitle: Text(l10n.desktopPet_interactionsSubtitle),
      value: petConfig.interactionsEnabled,
      onChanged: (value) async {
        await _updateInteractionsEnabled(value);
      },
    );
  }

  /// JSON 编辑器入口
  Widget _buildJsonEditorSection(AppLocalizations l10n) {
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
            Text(l10n.desktopPet_config_description),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openJsonEditor(),
              icon: const Icon(Icons.edit),
              label: Text(l10n.json_editor_edit_json),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 配置更新方法 =====

  /// 更新透明度
  Future<void> _updateOpacity(double value) async {
    if (_globalConfig == null) return;

    final newPetConfig = _globalConfig!.features.desktopPet.copyWith(
      opacity: value,
    );
    await _updatePetConfig(newPetConfig);

    // 实时更新桌面宠物窗口透明度
    try {
      await _desktopPetManager.updatePetPreferences({'opacity': value});
    } catch (e) {
      debugPrint('Failed to update pet window opacity: $e');
    }
  }

  /// 更新动画开关
  Future<void> _updateAnimationsEnabled(bool value) async {
    if (_globalConfig == null) return;

    final newPetConfig = _globalConfig!.features.desktopPet.copyWith(
      animationsEnabled: value,
    );
    await _updatePetConfig(newPetConfig);

    // 实时更新桌面宠物动画设置
    try {
      await _desktopPetManager.updatePetPreferences({
        'animations_enabled': value,
      });
    } catch (e) {
      debugPrint('Failed to update pet animations: $e');
    }
  }

  /// 更新交互开关
  Future<void> _updateInteractionsEnabled(bool value) async {
    if (_globalConfig == null) return;

    final newPetConfig = _globalConfig!.features.desktopPet.copyWith(
      interactionsEnabled: value,
    );
    await _updatePetConfig(newPetConfig);

    // 实时更新桌面宠物交互设置
    try {
      await _desktopPetManager.updatePetPreferences({
        'interactions_enabled': value,
      });
    } catch (e) {
      debugPrint('Failed to update pet interactions: $e');
    }
  }

  /// 更新桌面宠物配置
  Future<void> _updatePetConfig(DesktopPetConfig newPetConfig) async {
    if (_globalConfig == null) return;

    final newFeatures = _globalConfig!.features.copyWith(
      desktopPet: newPetConfig,
    );
    final newConfig = _globalConfig!.copyWith(features: newFeatures);

    try {
      await ConfigManager.instance.updateGlobalConfig(newConfig);
      if (mounted) {
        setState(() => _globalConfig = newConfig);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint('Failed to update desktop pet config: $e');
      _showErrorMessage();
    }
  }

  /// 重置为默认配置
  Future<void> _resetToDefaults() async {
    if (_globalConfig == null) return;

    const newPetConfig = DesktopPetConfig.defaultConfig;
    await _updatePetConfig(newPetConfig);
  }

  /// 显示成功消息
  void _showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.desktopPet_settingsSaved),
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

  /// 显示重置确认对话框
  Future<void> _showResetDialog() async {
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

    if (confirmed == true) {
      await _resetToDefaults();
    }
  }

  /// 打开 JSON 编辑器
  Future<void> _openJsonEditor() async {
    if (_globalConfig == null) return;

    final l10n = AppLocalizations.of(context)!;
    final currentJson = jsonEncode(_globalConfig!.features.desktopPet.toJson());

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.desktopPet_config_name,
          configDescription: l10n.desktopPet_config_description,
          currentJson: currentJson,
          schema: null,
          defaultJson: jsonEncode(DesktopPetConfig.defaultConfig.toJson()),
          exampleJson: jsonEncode(DesktopPetConfig.defaultConfig.toJson()),
          onSave: _saveJsonConfig,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.desktopPet_settingsSaved),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 保存 JSON 配置
  Future<bool> _saveJsonConfig(String jsonString) async {
    try {
      // 1. JSON 语法校验
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      // 2. 解析 JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final petConfig = DesktopPetConfig.fromJson(data);

      // 3. 验证配置
      if (!petConfig.isValid()) {
        throw Exception('Invalid configuration values');
      }

      // 4. 保存配置
      await _updatePetConfig(petConfig);
      return true;
    } catch (e) {
      debugPrint('Failed to save config: $e');
      return false;
    }
  }
}
