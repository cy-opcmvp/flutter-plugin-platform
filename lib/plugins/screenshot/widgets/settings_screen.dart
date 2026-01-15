library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/screenshot_settings.dart';
import '../screenshot_plugin.dart';

/// 截图插件设置界面
class ScreenshotSettingsScreen extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const ScreenshotSettingsScreen({
    super.key,
    required this.plugin,
  });

  @override
  State<ScreenshotSettingsScreen> createState() => _ScreenshotSettingsScreenState();
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
    _filenameFormatController = TextEditingController(text: _settings.filenameFormat);
  }

  @override
  void dispose() {
    _savePathController.dispose();
    _filenameFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('截图设置'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 保存设置
          _buildSectionHeader('保存设置'),
          const SizedBox(height: 8),
          _buildSavePathTile(),
          _buildFilenameFormatTile(),
          _buildImageFormatTile(),
          _buildImageQualityTile(),

          const SizedBox(height: 24),

          // 功能设置
          _buildSectionHeader('功能设置'),
          const SizedBox(height: 8),
          _buildAutoCopyTile(),
          _buildShowPreviewTile(),
          _buildSaveHistoryTile(),
          _buildMaxHistoryCountTile(),

          const SizedBox(height: 24),

          // 快捷键设置
          _buildSectionHeader('快捷键'),
          const SizedBox(height: 8),
          _buildShortcutTiles(),

          const SizedBox(height: 24),

          // 钉图设置
          _buildSectionHeader('钉图设置'),
          const SizedBox(height: 8),
          _buildPinSettingsTiles(),

          const SizedBox(height: 32),

          // 保存按钮
          _buildSaveButton(),
        ],
      ),
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
  Widget _buildSavePathTile() {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: const Text('保存路径'),
      subtitle: Text(_settings.savePath),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectSavePath,
    );
  }

  /// 构建文件名格式设置
  Widget _buildFilenameFormatTile() {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('文件名格式'),
      subtitle: Text(_settings.filenameFormat),
      trailing: const Icon(Icons.chevron_right),
      onTap: _editFilenameFormat,
    );
  }

  /// 构建图片格式设置
  Widget _buildImageFormatTile() {
    return ListTile(
      leading: const Icon(Icons.image),
      title: const Text('图片格式'),
      subtitle: Text(_formatImageFormatName(_settings.imageFormat)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectImageFormat,
    );
  }

  /// 构建图片质量设置
  Widget _buildImageQualityTile() {
    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: const Text('图片质量'),
      subtitle: Text('${_settings.imageQuality}%'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _adjustImageQuality,
    );
  }

  /// 构建自动复制设置
  Widget _buildAutoCopyTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.content_copy),
      title: const Text('自动复制到剪贴板'),
      subtitle: const Text('截图后自动复制到剪贴板'),
      value: _settings.autoCopyToClipboard,
      onChanged: (value) {
        setState(() {
          _settings = _settings.copyWith(autoCopyToClipboard: value);
        });
      },
    );
  }

  /// 构建显示预览设置
  Widget _buildShowPreviewTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.preview),
      title: const Text('显示预览窗口'),
      subtitle: const Text('截图后显示预览和编辑窗口'),
      value: _settings.showPreview,
      onChanged: (value) {
        setState(() {
          _settings = _settings.copyWith(showPreview: value);
        });
      },
    );
  }

  /// 构建保存历史设置
  Widget _buildSaveHistoryTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.history),
      title: const Text('保存历史记录'),
      subtitle: const Text('保存截图历史以供查看'),
      value: _settings.saveHistory,
      onChanged: (value) {
        setState(() {
          _settings = _settings.copyWith(saveHistory: value);
        });
      },
    );
  }

  /// 构建最大历史记录数设置
  Widget _buildMaxHistoryCountTile() {
    return ListTile(
      leading: const Icon(Icons.format_list_numbered),
      title: const Text('最大历史记录数'),
      subtitle: Text('${_settings.maxHistoryCount} 条'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _adjustMaxHistoryCount,
    );
  }

  /// 构建快捷键设置
  Widget _buildShortcutTiles() {
    return Column(
      children: _settings.shortcuts.entries.map((entry) {
        return ListTile(
          leading: const Icon(Icons.keyboard),
          title: Text(_getShortcutDisplayName(entry.key)),
          subtitle: Text(entry.value),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editShortcut(entry.key, entry.value),
        );
      }).toList(),
    );
  }

  /// 构建钉图设置
  Widget _buildPinSettingsTiles() {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.vertical_align_top),
          title: const Text('始终置顶'),
          subtitle: const Text('钉图窗口始终在最前面'),
          value: _settings.pinSettings.alwaysOnTop,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                pinSettings: _settings.pinSettings.copyWith(alwaysOnTop: value),
              );
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.opacity),
          title: const Text('默认透明度'),
          subtitle: Text('${(_settings.pinSettings.defaultOpacity * 100).toInt()}%'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _adjustOpacity,
        ),
      ],
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _saveSettings,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('保存设置'),
    );
  }

  /// 选择保存路径
  void _selectSavePath() {
    showDialog(
      context: context,
      builder: (context) => _SavePathDialog(
        currentPath: _settings.savePath,
        onSave: (path) {
          setState(() {
            _settings = _settings.copyWith(savePath: path);
          });
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
        onSave: (format) {
          setState(() {
            _settings = _settings.copyWith(filenameFormat: format);
          });
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
        onSave: (format) {
          setState(() {
            _settings = _settings.copyWith(imageFormat: format);
          });
        },
      ),
    );
  }

  /// 调整图片质量
  void _adjustImageQuality() async {
    final quality = await showDialog<int>(
      context: context,
      builder: (context) => _ImageQualityDialog(currentQuality: _settings.imageQuality),
    );

    if (quality != null) {
      setState(() {
        _settings = _settings.copyWith(imageQuality: quality);
      });
    }
  }

  /// 调整最大历史记录数
  void _adjustMaxHistoryCount() async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) => _MaxHistoryCountDialog(currentCount: _settings.maxHistoryCount),
    );

    if (count != null) {
      setState(() {
        _settings = _settings.copyWith(maxHistoryCount: count);
      });
    }
  }

  /// 编辑快捷键
  void _editShortcut(String action, String currentShortcut) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('快捷键编辑功能待实现：$action'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 调整透明度
  void _adjustOpacity() async {
    final opacity = await showDialog<double>(
      context: context,
      builder: (context) => _OpacityDialog(currentOpacity: _settings.pinSettings.defaultOpacity),
    );

    if (opacity != null) {
      setState(() {
        _settings = _settings.copyWith(
          pinSettings: _settings.pinSettings.copyWith(defaultOpacity: opacity),
        );
      });
    }
  }

  /// 保存设置
  void _saveSettings() async {
    await widget.plugin.updateSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  /// 格式化图片格式名称
  String _formatImageFormatName(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'PNG (无损)';
      case ImageFormat.jpeg:
        return 'JPEG (较小文件)';
      case ImageFormat.webp:
        return 'WebP (现代格式)';
    }
  }

  /// 获取快捷键显示名称
  String _getShortcutDisplayName(String action) {
    switch (action) {
      case 'regionCapture':
        return '区域截图';
      case 'fullScreenCapture':
        return '全屏截图';
      case 'windowCapture':
        return '窗口截图';
      case 'showHistory':
        return '显示历史';
      case 'showSettings':
        return '打开设置';
      default:
        return action;
    }
  }
}

/// 保存路径对话框
class _SavePathDialog extends StatefulWidget {
  final String currentPath;
  final Function(String) onSave;

  const _SavePathDialog({
    required this.currentPath,
    required this.onSave,
  });

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
    return AlertDialog(
      title: const Text('设置保存路径'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '保存路径',
              hintText: '{documents}/Screenshots',
              helperText: '可用占位符: {documents}, {home}, {temp}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
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
    return AlertDialog(
      title: const Text('设置文件名格式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '文件名格式',
              helperText: '可用占位符: {timestamp}, {date}, {time}, {datetime}, {index}',
            ),
          ),
          const SizedBox(height: 16),
          const Text('示例格式：', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildExampleItem('screenshot_{datetime}', 'screenshot_2026-01-15_19-30-45'),
          _buildExampleItem('Screenshot_{date}_{index}', 'Screenshot_2026-01-15_1'),
          _buildExampleItem('{timestamp}', '1736952645000'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
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
            child: Text(format, style: const TextStyle(fontFamily: 'monospace')),
          ),
          const Text(' → ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 3,
            child: Text(example, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey)),
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

  const _ImageFormatDialog({
    required this.currentFormat,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择图片格式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ImageFormat.values.map((format) {
          return RadioListTile<ImageFormat>(
            title: Text(_formatName(format)),
            subtitle: Text(_formatDescription(format)),
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

  String _formatDescription(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return '无损压缩，文件较大';
      case ImageFormat.jpeg:
        return '有损压缩，文件较小';
      case ImageFormat.webp:
        return '现代格式，压缩率高';
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
    return AlertDialog(
      title: const Text('设置图片质量'),
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_quality),
          child: const Text('确定'),
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
    return AlertDialog(
      title: const Text('设置最大历史记录数'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _count.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            label: '$_count 条',
            onChanged: (value) {
              setState(() {
                _count = value.toInt();
              });
            },
          ),
          Center(
            child: Text(
              '$_count 条',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_count),
          child: const Text('确定'),
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
    return AlertDialog(
      title: const Text('设置默认透明度'),
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_opacity),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
