library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import 'models/screenshot_models.dart';
import 'models/screenshot_settings.dart';
import 'services/screenshot_service.dart';
import 'services/file_manager_service.dart';
import 'services/clipboard_service.dart';
import 'widgets/screenshot_main_widget.dart';

/// 智能截图插件
///
/// 参考 Snipaste 的专业截图工具，支持：
/// - 区域截图、全屏截图、窗口截图
/// - 图片标注和编辑
/// - 复制到剪贴板、保存到文件、钉在桌面
class ScreenshotPlugin implements IPlugin {
  late PluginContext _context;

  // 插件状态变量
  bool _isInitialized = false;
  final List<ScreenshotRecord> _screenshots = [];
  ScreenshotSettings _settings = ScreenshotSettings.defaultSettings();

  // 服务
  late ScreenshotService _screenshotService;
  late FileManagerService _fileManager;
  late ClipboardService _clipboard;

  // 用于触发UI更新的回调
  VoidCallback? _onStateChanged;

  @override
  String get id => 'com.example.screenshot';

  @override
  String get name => '智能截图';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    try {
      // 初始化服务
      _screenshotService = ScreenshotService();
      _fileManager = FileManagerService();
      _clipboard = ClipboardService();

      // 加载保存的状态
      await _loadSavedState();

      // 检查平台支持
      if (!_screenshotService.isAvailable) {
        debugPrint('$name: Screenshot not fully supported on this platform');
        // 不抛出异常，允许插件以降级模式运行
      }

      // 更新文件管理器的设置
      _fileManager.updateSettings(_settings);

      _isInitialized = true;

      await _context.platformServices.showNotification('$name 插件已成功初始化');
    } catch (e) {
      await _context.platformServices.showNotification('$name 插件初始化失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      // 保存当前状态
      await _saveCurrentState();

      _isInitialized = false;
    } catch (e) {
      debugPrint('Screenshot plugin disposal error: $e');
    }
  }

  @override
  Widget buildUI(BuildContext context) {
    return _ScreenshotPluginWidget(plugin: this);
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        // 激活快捷键监听（待实现）
        break;
      case PluginState.paused:
        await _saveCurrentState();
        break;
      case PluginState.inactive:
        await _saveCurrentState();
        break;
      case PluginState.error:
        break;
      case PluginState.loading:
        break;
    }
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return {
      'isInitialized': _isInitialized,
      'isAvailable': _screenshotService.isAvailable,
      'screenshots': _screenshots.map((s) => s.toJson()).toList(),
      'settings': _settings.toJson(),
      'lastUpdate': DateTime.now().toIso8601String(),
      'version': version,
    };
  }

  // 公开方法

  /// 检查截图服务是否可用
  bool get isAvailable => _screenshotService.isAvailable;

  /// 获取当前设置
  ScreenshotSettings get settings => _settings;

  /// 获取截图历史记录
  List<ScreenshotRecord> get screenshots => List.unmodifiable(_screenshots);

  /// 捕获全屏截图
  Future<void> captureFullScreen() async {
    final bytes = await _screenshotService.captureFullScreen();
    if (bytes != null) {
      await _processScreenshot(bytes, ScreenshotType.fullScreen);
    }
  }

  /// 捕获全屏截图（返回字节数据）
  Future<Uint8List?> captureFullScreenBytes() async {
    return await _screenshotService.captureFullScreen();
  }

  /// 捕获区域截图
  Future<void> captureRegion(Rect region) async {
    final bytes = await _screenshotService.captureRegion(region);
    if (bytes != null) {
      await _processScreenshot(bytes, ScreenshotType.region);
    }
  }

  /// 捕获区域截图（返回字节数据）
  Future<Uint8List?> captureRegionBytes(Rect region) async {
    return await _screenshotService.captureRegion(region);
  }

  /// 捕获窗口截图
  Future<void> captureWindow(String windowId) async {
    final bytes = await _screenshotService.captureWindow(windowId);
    if (bytes != null) {
      await _processScreenshot(bytes, ScreenshotType.window);
    }
  }

  /// 获取所有可用窗口
  Future<List<WindowInfo>> getAvailableWindows() async {
    return await _screenshotService.getAvailableWindows();
  }

  /// 删除截图记录
  Future<void> deleteScreenshot(String screenshotId) async {
    final index = _screenshots.indexWhere((s) => s.id == screenshotId);
    if (index != -1) {
      final record = _screenshots[index];
      await _fileManager.deleteScreenshot(record.filePath);
      _screenshots.removeAt(index);
      await _saveCurrentState();
      _onStateChanged?.call();
    }
  }

  /// 清空所有历史记录
  Future<void> clearHistory() async {
    for (final record in _screenshots) {
      await _fileManager.deleteScreenshot(record.filePath);
    }
    _screenshots.clear();
    await _saveCurrentState();
    _onStateChanged?.call();
  }

  /// 更新设置
  Future<void> updateSettings(ScreenshotSettings newSettings) async {
    _settings = newSettings;
    _fileManager.updateSettings(newSettings);
    await _saveCurrentState();
    _onStateChanged?.call();
  }

  /// 显示原生区域截图窗口（桌面级）
  ///
  /// 返回 true 如果成功显示窗口
  Future<bool> showNativeRegionCapture() {
    return _screenshotService.showNativeRegionCapture();
  }

  /// 获取区域选择结果（用于轮询）
  Future<RegionSelectedEvent?> getRegionSelectionResult() {
    return _screenshotService.getRegionSelectionResult();
  }

  /// 处理截图
  Future<void> _processScreenshot(
    Uint8List bytes,
    ScreenshotType type,
  ) async {
    try {
      // 生成文件名
      final filename = _generateFilename();

      // 保存到文件
      final filePath = await _fileManager.saveScreenshot(
        bytes,
        filename: filename,
      );

      // 创建记录
      final record = ScreenshotRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: filePath,
        createdAt: DateTime.now(),
        fileSize: bytes.length,
        type: type,
      );

      _screenshots.insert(0, record);

      // 限制历史记录数量
      if (_screenshots.length > _settings.maxHistoryCount) {
        final removed = _screenshots.removeLast();
        await _fileManager.deleteScreenshot(removed.filePath);
      }

      // 复制到剪贴板
      if (_settings.autoCopyToClipboard) {
        await _clipboard.copyImage(bytes);
      }

      // 保存状态
      await _saveCurrentState();

      // 通知 UI 更新
      _onStateChanged?.call();

      // 显示通知
      await _context.platformServices.showNotification('截图已保存');
    } catch (e) {
      debugPrint('Failed to process screenshot: $e');
      await _context.platformServices.showNotification('截图处理失败: $e');
    }
  }

  /// 生成文件名
  String _generateFilename() {
    return _settings.filenameFormat;
  }

  /// 加载保存的状态
  Future<void> _loadSavedState() async {
    try {
      // 加载设置
      final settingsData =
          await _context.dataStorage.retrieve<Map<String, dynamic>>('screenshotSettings');
      if (settingsData != null) {
        _settings = ScreenshotSettings.fromJson(settingsData);
      }

      // 加载截图历史记录（仅加载元数据，不加载实际文件）
      final screenshotsData =
          await _context.dataStorage.retrieve<List<dynamic>>('screenshots');
      if (screenshotsData != null) {
        _screenshots.clear();
        _screenshots.addAll(
          screenshotsData
              .map((data) => ScreenshotRecord.fromJson(data as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to load saved state: $e');
    }
  }

  /// 保存当前状态
  Future<void> _saveCurrentState() async {
    try {
      await _context.dataStorage.store(
        'screenshotSettings',
        _settings.toJson(),
      );

      // 只保存最近 100 条记录的元数据
      final screenshotsToSave = _screenshots.take(100).map((s) => s.toJson()).toList();
      await _context.dataStorage.store(
        'screenshots',
        screenshotsToSave,
      );
    } catch (e) {
      debugPrint('Failed to save state: $e');
    }
  }
}

// 插件UI Widget
class _ScreenshotPluginWidget extends StatefulWidget {
  final ScreenshotPlugin plugin;

  const _ScreenshotPluginWidget({required this.plugin});

  @override
  State<StatefulWidget> createState() => _ScreenshotPluginWidgetState();
}

class _ScreenshotPluginWidgetState extends State<_ScreenshotPluginWidget> {
  @override
  void initState() {
    super.initState();
    widget.plugin._onStateChanged = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.plugin._isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ScreenshotMainWidget(plugin: widget.plugin);
  }
}
