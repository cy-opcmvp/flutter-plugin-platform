library;

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../ui/widgets/json_editor_screen.dart';
import '../../../../ui/screens/path_placeholders_info_screen.dart';
import '../../../../core/services/json_validator.dart';
import '../config/screenshot_config_defaults.dart';
import '../models/screenshot_settings.dart';
import '../screenshot_plugin.dart';

/// 截图插件设置界面
class ScreenshotSettingsScreen extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const ScreenshotSettingsScreen({super.key, required this.plugin});

  @override
  State<ScreenshotSettingsScreen> createState() =>
      _ScreenshotSettingsScreenState();
}

class _ScreenshotSettingsScreenState extends State<ScreenshotSettingsScreen> {
  late TextEditingController _savePathController;
  late TextEditingController _filenameFormatController;
  late ScreenshotSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.plugin.settings;
    _savePathController = TextEditingController(text: _settings.savePath);
    _filenameFormatController = TextEditingController(
      text: _settings.filenameFormat,
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
        title: Text(l10n.screenshot_settings_title),
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

  /// 构建内容
  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 保存设置
        _buildSectionHeader(l10n.screenshot_settings_section_save),
        const SizedBox(height: 8),
        _buildSavePathTile(l10n),
        _buildFilenameFormatTile(l10n),
        _buildImageFormatTile(l10n),
        _buildImageQualityTile(l10n),

        const SizedBox(height: 24),

        // 功能设置
        _buildSectionHeader(l10n.screenshot_settings_section_function),
        const SizedBox(height: 8),
        _buildAutoCopyTile(l10n),
        _buildClipboardContentTypeTile(l10n),
        _buildShowPreviewTile(l10n),
        _buildSaveHistoryTile(l10n),
        _buildMaxHistoryCountTile(l10n),

        const SizedBox(height: 24),

        // 快捷键设置
        _buildSectionHeader(l10n.screenshot_settings_section_shortcuts),
        const SizedBox(height: 8),
        _buildShortcutTiles(l10n),

        const SizedBox(height: 24),

        // 钉图设置
        _buildSectionHeader(l10n.screenshot_settings_section_pin),
        const SizedBox(height: 8),
        _buildPinSettingsTiles(l10n),

        const SizedBox(height: 32),

        // JSON 编辑器入口
        _buildJsonEditorSection(context, l10n),
      ],
    );
  }

  /// 构建章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建保存路径设置
  Widget _buildSavePathTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(l10n.screenshot_savePath, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _settings.savePath,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectSavePath,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建文件名格式设置
  Widget _buildFilenameFormatTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: Text(
        l10n.screenshot_filenameFormat,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _settings.filenameFormat,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _editFilenameFormat,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建图片格式设置
  Widget _buildImageFormatTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.image),
      title: Text(l10n.screenshot_imageFormat, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _formatImageFormatName(_settings.imageFormat),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectImageFormat,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建图片质量设置
  Widget _buildImageQualityTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: Text(
        l10n.screenshot_imageQuality,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_settings.imageQuality}%',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _adjustImageQuality,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建自动复制设置
  Widget _buildAutoCopyTile(AppLocalizations l10n) {
    return SwitchListTile(
      secondary: const Icon(Icons.content_copy),
      title: Text(l10n.screenshot_autoCopy, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.screenshot_settings_auto_copy_desc,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      value: _settings.autoCopyToClipboard,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(autoCopyToClipboard: value);
        await widget.plugin.updateSettings(newSettings);
        if (mounted) {
          setState(() {
            _settings = newSettings;
          });
          _showSuccessMessage();
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建剪贴板内容类型设置
  Widget _buildClipboardContentTypeTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.paste),
      title: Text(
        l10n.screenshot_clipboard_content_type,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _getClipboardContentTypeDisplayName(l10n),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      enabled: _settings.autoCopyToClipboard,
      onTap: _selectClipboardContentType,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 获取剪贴板内容类型显示名称
  String _getClipboardContentTypeDisplayName(AppLocalizations l10n) {
    switch (_settings.clipboardContentType) {
      case ClipboardContentType.image:
        return l10n.screenshot_clipboard_type_image;
      case ClipboardContentType.filename:
        return l10n.screenshot_clipboard_type_filename;
      case ClipboardContentType.fullPath:
        return l10n.screenshot_clipboard_type_full_path;
      case ClipboardContentType.directoryPath:
        return l10n.screenshot_clipboard_type_directory_path;
    }
  }

  /// 构建显示预览设置
  Widget _buildShowPreviewTile(AppLocalizations l10n) {
    return SwitchListTile(
      secondary: const Icon(Icons.preview),
      title: Text(l10n.screenshot_showPreview, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.screenshot_settings_show_preview_desc,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      value: _settings.showPreview,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(showPreview: value);
        await widget.plugin.updateSettings(newSettings);
        if (mounted) {
          setState(() {
            _settings = newSettings;
          });
          _showSuccessMessage();
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建保存历史设置
  Widget _buildSaveHistoryTile(AppLocalizations l10n) {
    return SwitchListTile(
      secondary: const Icon(Icons.history),
      title: Text(l10n.screenshot_saveHistory, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.screenshot_settings_save_history_desc,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      value: _settings.saveHistory,
      onChanged: (value) async {
        final newSettings = _settings.copyWith(saveHistory: value);
        await widget.plugin.updateSettings(newSettings);
        if (mounted) {
          setState(() {
            _settings = newSettings;
          });
          _showSuccessMessage();
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建最大历史记录数设置
  Widget _buildMaxHistoryCountTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.format_list_numbered),
      title: Text(
        l10n.screenshot_maxHistoryCount,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_settings.maxHistoryCount} ${l10n.screenshot_settings_items}',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _adjustMaxHistoryCount,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建快捷键设置
  Widget _buildShortcutTiles(AppLocalizations l10n) {
    return Column(
      children: _settings.shortcuts.entries.map((entry) {
        return ListTile(
          leading: const Icon(Icons.keyboard),
          title: Text(
            _getShortcutDisplayName(entry.key, l10n),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(entry.value, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editShortcut(entry.key, entry.value),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  /// 构建钉图设置
  Widget _buildPinSettingsTiles(AppLocalizations l10n) {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.vertical_align_top),
          title: Text(
            l10n.screenshot_alwaysOnTop,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            l10n.screenshot_settings_always_on_top_desc,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          value: _settings.pinSettings.alwaysOnTop,
          onChanged: (value) async {
            final newSettings = _settings.copyWith(
              pinSettings: _settings.pinSettings.copyWith(alwaysOnTop: value),
            );
            await widget.plugin.updateSettings(newSettings);
            if (mounted) {
              setState(() {
                _settings = newSettings;
              });
              _showSuccessMessage();
            }
          },
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.opacity),
          title: Text(
            l10n.screenshot_defaultOpacity,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${(_settings.pinSettings.defaultOpacity * 100).toInt()}%',
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _adjustOpacity,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  /// 选择保存路径
  void _selectSavePath() {
    showDialog(
      context: context,
      builder: (context) => _SavePathDialog(
        currentPath: _settings.savePath,
        onSave: (path) async {
          final newSettings = _settings.copyWith(savePath: path);
          await widget.plugin.updateSettings(newSettings);
          if (mounted) {
            setState(() {
              _settings = newSettings;
            });
            _showSuccessMessage();
          }
        },
      ),
    );
  }

  /// 编辑文件名格式
  void _editFilenameFormat() {
    showDialog(
      context: context,
      builder: (context) => _FilenameFormatDialog(
        currentFormat: _settings.filenameFormat,
        onSave: (format) async {
          final newSettings = _settings.copyWith(filenameFormat: format);
          await widget.plugin.updateSettings(newSettings);
          if (mounted) {
            setState(() {
              _settings = newSettings;
            });
            _showSuccessMessage();
          }
        },
      ),
    );
  }

  /// 选择图片格式
  void _selectImageFormat() {
    showDialog(
      context: context,
      builder: (context) => _ImageFormatDialog(
        currentFormat: _settings.imageFormat,
        onSave: (format) async {
          final newSettings = _settings.copyWith(imageFormat: format);
          await widget.plugin.updateSettings(newSettings);
          if (mounted) {
            setState(() {
              _settings = newSettings;
            });
            _showSuccessMessage();
          }
        },
      ),
    );
  }

  /// 选择剪贴板内容类型
  void _selectClipboardContentType() {
    showDialog(
      context: context,
      builder: (context) => _ClipboardContentTypeDialog(
        currentType: _settings.clipboardContentType,
        onSave: (type) async {
          final newSettings = _settings.copyWith(clipboardContentType: type);
          await widget.plugin.updateSettings(newSettings);
          if (mounted) {
            setState(() {
              _settings = newSettings;
            });
            _showSuccessMessage();
          }
        },
      ),
    );
  }

  /// 调整图片质量
  void _adjustImageQuality() async {
    final quality = await showDialog<int>(
      context: context,
      builder: (context) =>
          _ImageQualityDialog(currentQuality: _settings.imageQuality),
    );

    if (quality != null) {
      final newSettings = _settings.copyWith(imageQuality: quality);
      await widget.plugin.updateSettings(newSettings);
      if (mounted) {
        setState(() {
          _settings = newSettings;
        });
        _showSuccessMessage();
      }
    }
  }

  /// 调整最大历史记录数
  void _adjustMaxHistoryCount() async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) =>
          _MaxHistoryCountDialog(currentCount: _settings.maxHistoryCount),
    );

    if (count != null) {
      final newSettings = _settings.copyWith(maxHistoryCount: count);
      await widget.plugin.updateSettings(newSettings);
      if (mounted) {
        setState(() {
          _settings = newSettings;
        });
        _showSuccessMessage();
      }
    }
  }

  /// 编辑快捷键
  void _editShortcut(String action, String currentShortcut) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.screenshot_shortcut_edit_pending(action)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 调整透明度
  void _adjustOpacity() async {
    final opacity = await showDialog<double>(
      context: context,
      builder: (context) =>
          _OpacityDialog(currentOpacity: _settings.pinSettings.defaultOpacity),
    );

    if (opacity != null) {
      final newSettings = _settings.copyWith(
        pinSettings: _settings.pinSettings.copyWith(defaultOpacity: opacity),
      );
      await widget.plugin.updateSettings(newSettings);
      if (mounted) {
        setState(() {
          _settings = newSettings;
        });
        _showSuccessMessage();
      }
    }
  }

  /// 显示成功消息
  void _showSuccessMessage() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.screenshot_settings_saved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 格式化图片格式名称
  String _formatImageFormatName(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'PNG';
      case ImageFormat.jpeg:
        return 'JPEG';
      case ImageFormat.webp:
        return 'WebP';
    }
  }

  /// 获取快捷键显示名称
  String _getShortcutDisplayName(String action, AppLocalizations l10n) {
    switch (action) {
      case 'regionCapture':
        return l10n.screenshot_shortcut_region;
      case 'fullScreenCapture':
        return l10n.screenshot_shortcut_fullscreen;
      default:
        return action;
    }
  }

  /// 构建 JSON 编辑器部分
  Widget _buildJsonEditorSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  l10n.screenshot_settings_json_editor,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.screenshot_settings_json_editor_desc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // 使用 Wrap 在小屏幕时自动换行
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openJsonEditor(context, false),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    l10n.json_editor_edit_json,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openJsonEditor(context, true),
                  icon: const Icon(Icons.restore, size: 16),
                  label: Text(
                    l10n.json_editor_reset_to_default,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 打开 JSON 编辑器
  Future<void> _openJsonEditor(
    BuildContext context,
    bool resetToDefault,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // 获取当前配置
    final currentJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(_settings.toJson());

    // 如果要重置，使用默认配置
    final initialJson = resetToDefault
        ? ScreenshotConfigDefaults.defaultConfig
        : currentJson;

    // 解析 Schema
    final schema = JsonSchema.fromJson(
      jsonDecode(ScreenshotConfigDefaults.schemaJson) as Map<String, dynamic>,
    );

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          configName: l10n.screenshot_settings_config_name,
          configDescription: l10n.screenshot_settings_config_description,
          currentJson: initialJson,
          schema: schema,
          defaultJson: ScreenshotConfigDefaults.defaultConfig,
          exampleJson: ScreenshotConfigDefaults.cleanExample,
          onSave: _saveJsonConfig,
        ),
      ),
    );

    if (result == true && mounted) {
      // 配置已保存，刷新界面
      setState(() {
        _settings = widget.plugin.settings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.screenshot_settings_json_saved),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  /// 保存 JSON 配置
  Future<bool> _saveJsonConfig(String jsonString) async {
    try {
      // 1. 校验 JSON
      final validationResult = JsonValidator.validateJsonString(jsonString);
      if (!validationResult.isValid) {
        throw Exception(validationResult.errorMessage);
      }

      // 2. 解析 JSON
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 3. 创建配置对象
      final settings = ScreenshotSettings.fromJson(data);

      // 4. 验证配置
      if (!settings.isValid()) {
        throw Exception('配置验证失败：请检查所有配置项是否符合要求');
      }

      // 5. 保存配置
      await widget.plugin.updateSettings(settings);

      return true;
    } catch (e) {
      debugPrint('保存配置失败: $e');
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
          jsonDecode(ScreenshotConfigDefaults.defaultConfig)
              as Map<String, dynamic>;
      final defaultSettings = ScreenshotSettings.fromJson(defaultData);

      // 保存默认设置
      await widget.plugin.updateSettings(defaultSettings);

      // 更新本地状态
      if (mounted) {
        setState(() {
          _settings = defaultSettings;
          _savePathController.text = defaultSettings.savePath;
          _filenameFormatController.text = defaultSettings.filenameFormat;
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

/// 保存路径对话框
class _SavePathDialog extends StatefulWidget {
  final String currentPath;
  final Function(String) onSave;

  const _SavePathDialog({required this.currentPath, required this.onSave});

  @override
  State<_SavePathDialog> createState() => _SavePathDialogState();
}

class _SavePathDialogState extends State<_SavePathDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_save_path_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: l10n.screenshot_savePath,
                    hintText: l10n.screenshot_settings_save_path_hint,
                    helperText: l10n.screenshot_settings_save_path_helper,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: l10n.screenshot_select_folder,
                onPressed: _selectFolder,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 查看可用占位符按钮
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PathPlaceholdersInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 18),
            label: Text(l10n.screenshot_settings_view_placeholders),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
          child: Text(l10n.common_save),
        ),
      ],
    );
  }

  /// 选择文件夹
  Future<void> _selectFolder() async {
    try {
      // TODO: 实现跨平台文件夹选择
      // 当前只显示提示，实际选择需要平台特定代码或第三方包
      // 可以使用 file_picker 包：https://pub.dev/packages/file_picker
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文件夹选择功能开发中，请手动输入路径'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to select folder: $e');
    }
  }
}

/// 文件名格式对话框
class _FilenameFormatDialog extends StatefulWidget {
  final String currentFormat;
  final Function(String) onSave;

  const _FilenameFormatDialog({
    required this.currentFormat,
    required this.onSave,
  });

  @override
  State<_FilenameFormatDialog> createState() => _FilenameFormatDialogState();
}

class _FilenameFormatDialogState extends State<_FilenameFormatDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentFormat);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_filename_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.screenshot_filenameFormat,
              helperText: l10n.screenshot_settings_filename_helper,
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleItem(
            'screenshot_{datetime}',
            'screenshot_2026-01-15_19-30-45',
          ),
          _buildExampleItem(
            'Screenshot_{date}_{index}',
            'Screenshot_2026-01-15_1',
          ),
          _buildExampleItem('{timestamp}', '1736952645000'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
          child: Text(l10n.common_save),
        ),
      ],
    );
  }

  Widget _buildExampleItem(String format, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              format,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const Text(' → ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 3,
            child: Text(
              example,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片格式对话框
class _ImageFormatDialog extends StatelessWidget {
  final ImageFormat currentFormat;
  final Function(ImageFormat) onSave;

  const _ImageFormatDialog({required this.currentFormat, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_format_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ImageFormat.values.map((format) {
          return RadioListTile<ImageFormat>(
            title: Text(_formatName(format)),
            subtitle: Text(_formatDescription(format, l10n)),
            value: format,
            groupValue: currentFormat,
            onChanged: (value) {
              if (value != null) {
                onSave(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _formatName(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'PNG';
      case ImageFormat.jpeg:
        return 'JPEG';
      case ImageFormat.webp:
        return 'WebP';
    }
  }

  String _formatDescription(ImageFormat format, AppLocalizations l10n) {
    switch (format) {
      case ImageFormat.png:
        return 'Lossless';
      case ImageFormat.jpeg:
        return 'Lossy, smaller';
      case ImageFormat.webp:
        return 'Modern format';
    }
  }
}

/// 图片质量对话框
class _ImageQualityDialog extends StatefulWidget {
  final int currentQuality;

  const _ImageQualityDialog({required this.currentQuality});

  @override
  State<_ImageQualityDialog> createState() => _ImageQualityDialogState();
}

class _ImageQualityDialogState extends State<_ImageQualityDialog> {
  late int _quality;

  @override
  void initState() {
    super.initState();
    _quality = widget.currentQuality;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_quality_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _quality.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '$_quality%',
            onChanged: (value) {
              setState(() {
                _quality = value.toInt();
              });
            },
          ),
          Center(
            child: Text(
              '$_quality%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_quality),
          child: Text(l10n.common_ok),
        ),
      ],
    );
  }
}

/// 最大历史记录数对话框
class _MaxHistoryCountDialog extends StatefulWidget {
  final int currentCount;

  const _MaxHistoryCountDialog({required this.currentCount});

  @override
  State<_MaxHistoryCountDialog> createState() => _MaxHistoryCountDialogState();
}

class _MaxHistoryCountDialogState extends State<_MaxHistoryCountDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.currentCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_history_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _count.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            label: '$_count ${l10n.screenshot_settings_items}',
            onChanged: (value) {
              setState(() {
                _count = value.toInt();
              });
            },
          ),
          Center(
            child: Text(
              '$_count ${l10n.screenshot_settings_items}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_count),
          child: Text(l10n.common_ok),
        ),
      ],
    );
  }
}

/// 透明度对话框
class _OpacityDialog extends StatefulWidget {
  final double currentOpacity;

  const _OpacityDialog({required this.currentOpacity});

  @override
  State<_OpacityDialog> createState() => _OpacityDialogState();
}

class _OpacityDialogState extends State<_OpacityDialog> {
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _opacity = widget.currentOpacity;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_opacity_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _opacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(_opacity * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _opacity = value;
              });
            },
          ),
          Center(
            child: Text(
              '${(_opacity * 100).toInt()}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_opacity),
          child: Text(l10n.common_ok),
        ),
      ],
    );
  }
}

/// 剪贴板内容类型对话框
class _ClipboardContentTypeDialog extends StatelessWidget {
  final ClipboardContentType currentType;
  final Function(ClipboardContentType) onSave;

  const _ClipboardContentTypeDialog({
    required this.currentType,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.screenshot_settings_clipboard_type_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ClipboardContentType.values.map((type) {
          return RadioListTile<ClipboardContentType>(
            title: Text(_getTypeDisplayName(type, l10n)),
            subtitle: Text(_getTypeDescription(type, l10n)),
            value: type,
            groupValue: currentType,
            onChanged: (value) {
              if (value != null) {
                onSave(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _getTypeDisplayName(ClipboardContentType type, AppLocalizations l10n) {
    switch (type) {
      case ClipboardContentType.image:
        return l10n.screenshot_clipboard_type_image;
      case ClipboardContentType.filename:
        return l10n.screenshot_clipboard_type_filename;
      case ClipboardContentType.fullPath:
        return l10n.screenshot_clipboard_type_full_path;
      case ClipboardContentType.directoryPath:
        return l10n.screenshot_clipboard_type_directory_path;
    }
  }

  String _getTypeDescription(ClipboardContentType type, AppLocalizations l10n) {
    switch (type) {
      case ClipboardContentType.image:
        return l10n.screenshot_clipboard_type_image_desc;
      case ClipboardContentType.filename:
        return l10n.screenshot_clipboard_type_filename_desc;
      case ClipboardContentType.fullPath:
        return l10n.screenshot_clipboard_type_full_path_desc;
      case ClipboardContentType.directoryPath:
        return l10n.screenshot_clipboard_type_directory_path_desc;
    }
  }
}
