library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide TargetPlatform;
import '../../core/interfaces/i_plugin.dart';
import '../../core/interfaces/i_platform_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../core/utils/platform_capability_helper.dart';
import 'models/screenshot_models.dart';
import 'models/screenshot_settings.dart' as ss;
import 'services/screenshot_service.dart';
import 'services/file_manager_service.dart';
import 'services/clipboard_service.dart';
import 'services/hotkey_service.dart';
import 'widgets/screenshot_main_widget.dart';
import 'widgets/settings_screen.dart';
import 'services/recurring_task_manager.dart';
import 'models/recurring_screenshot_task.dart';

/// 智能截图插件
///
/// 参考 Snipaste 的专业截图工具，支持：
/// - 区域截图、全屏截图、窗口截图
/// - 图片标注和编辑
/// - 复制到剪贴板、保存到文件、钉在桌面
///
/// 平台支持：
/// - Windows: 完整支持（已实现）
/// - Linux: 待实现（需要 X11/Wayland 支持）
/// - macOS: 待实现（需要 Quartz API 支持）
/// - Android/iOS: 部分支持（只能实现应用内截图）
/// - Web: 不支持（浏览器安全限制）
class ScreenshotPlugin extends PlatformPluginBase {
  late PluginContext _context;

  // 插件状态变量
  bool _isInitialized = false;
  bool _isScreenshotInProgress = false; // 截图操作进行中标志
  final List<ScreenshotRecord> _screenshots = [];
  ss.ScreenshotSettings _settings = ss.ScreenshotSettings.defaultSettings();

  // 服务
  late ScreenshotService _screenshotService;
  late FileManagerService _fileManager;
  late ClipboardService _clipboard;
  late HotkeyService _hotkeyService;
  late RecurringTaskManager _taskManager;

  /// 获取文件管理器服务（用于外部访问）
  FileManagerService get fileManager => _fileManager;

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
  PluginPlatformCapabilities get platformCapabilities =>
      _platformCapabilities ??= _createPlatformCapabilities();

  static PluginPlatformCapabilities? _platformCapabilities;

  /// 创建平台能力配置
  PluginPlatformCapabilities _createPlatformCapabilities() {
    return PlatformCapabilityHelper.custom(
      pluginId: id,
      capabilities: {
        // Windows - 完整支持
        TargetPlatform.windows: PlatformCapability.fullSupported(
          TargetPlatform.windows,
          '支持全屏截图、区域截图、窗口截图和原生桌面级区域选择',
        ),
        // Linux - 计划中
        TargetPlatform.linux: PlatformCapability.planned(
          TargetPlatform.linux,
          '计划支持 X11 和 Wayland 显示服务器',
        ),
        // macOS - 计划中
        TargetPlatform.macos: PlatformCapability.planned(
          TargetPlatform.macos,
          '计划支持 Quartz API',
        ),
        // Android - 部分支持
        TargetPlatform.android: PlatformCapability.partialSupported(
          TargetPlatform.android,
          '应用内截图',
          '只能截取本应用内容，无法实现真正的桌面级截图',
        ),
        // iOS - 部分支持
        TargetPlatform.ios: PlatformCapability.partialSupported(
          TargetPlatform.ios,
          '应用内截图',
          '只能截取本应用内容，无法实现真正的桌面级截图',
        ),
        // Web - 不支持
        TargetPlatform.web: PlatformCapability.unsupported(
          TargetPlatform.web,
          '浏览器安全策略限制，无法访问操作系统屏幕',
        ),
      },
      hideIfUnsupported: true, // 不支持的平台隐藏插件
    );
  }

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    try {
      // 初始化服务
      _screenshotService = ScreenshotService();
      _fileManager = FileManagerService();
      _clipboard = ClipboardService();
      _hotkeyService = HotkeyService();

      // 初始化任务管理器
      _taskManager = RecurringTaskManager(
        plugin: this,
        onTasksChanged: () {
          _onStateChanged?.call();
        },
      );

      // 初始化热键服务
      await _hotkeyService.initialize();
      _hotkeyService.setScreenshotService(_screenshotService);

      // 从单一配置加载设置
      final savedConfig = await _context.dataStorage
          .retrieve<Map<String, dynamic>>('screenshot_config');
      if (savedConfig != null) {
        _settings = ss.ScreenshotSettings.fromJson(savedConfig);
      }

      // 加载截图历史记录元数据（仅加载元数据，不加载实际文件）
      final screenshotsData = await _context.dataStorage
          .retrieve<List<dynamic>>('screenshot_history');
      if (screenshotsData != null) {
        _screenshots.clear();
        _screenshots.addAll(
          screenshotsData
              .map(
                (data) =>
                    ScreenshotRecord.fromJson(data as Map<String, dynamic>),
              )
              .toList(),
        );
      }

      // 清理遗留的循环任务列表（任务只在单次会话中有效）
      await _context.dataStorage.remove('recurring_tasks');
      debugPrint('ScreenshotPlugin: Cleared legacy recurring tasks');

      // 检查平台支持
      if (!isCurrentPlatformSupported) {
        debugPrint('$name: ${currentCapability.description}');
        if (!isCurrentPlatformFullySupported) {
          debugPrint('$name: 限制 - ${currentCapability.limitations ?? "无"}');
        }
        // 不抛出异常，允许插件以降级模式运行
      }

      // 更新文件管理器的设置
      _fileManager.updateSettings(_settings);

      // 注册快捷键
      await _registerHotkeys();

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
      // 停止所有循环任务
      _taskManager.dispose();

      // 删除任务列表（任务只在单次会话中有效，不保存到下次启动）
      await _context.dataStorage.remove('recurring_tasks');
      debugPrint('ScreenshotPlugin: Cleared recurring tasks on dispose');

      // 释放热键服务
      await _hotkeyService.dispose();

      // 保存配置
      await _saveConfig();

      _isInitialized = false;
    } catch (e) {
      debugPrint('Screenshot plugin disposal error: $e');
    }
  }

  @override
  Widget buildUI(BuildContext context) {
    return _ScreenshotPluginWidget(plugin: this);
  }

  /// 构建设置界面
  Widget buildSettingsScreen() {
    return ScreenshotSettingsScreen(plugin: this);
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        // 激活快捷键监听（待实现）
        break;
      case PluginState.paused:
        await _saveConfig();
        break;
      case PluginState.inactive:
        await _saveConfig();
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
  ss.ScreenshotSettings get settings => _settings;

  /// 获取截图历史记录
  List<ScreenshotRecord> get screenshots => List.unmodifiable(_screenshots);

  /// 检查是否有活动的循环任务
  bool _hasActiveRecurringTasks() {
    return _taskManager.tasks.any((task) => task.status == TaskStatus.running);
  }

  /// 捕获全屏截图
  Future<void> captureFullScreen() async {
    // 检查是否已有截图操作进行中
    if (_isScreenshotInProgress) {
      print('🔒 截图正在进行中，忽略全屏截图请求');
      await _context.platformServices.showNotification('截图正在进行中，请稍候');
      return;
    }

    // 检查是否有活动的循环任务
    if (_hasActiveRecurringTasks()) {
      print('⚠️ 检测到活动的循环任务，要求暂停');
      await _context.platformServices.showNotification('请先暂停定时截图任务');
      return;
    }

    _isScreenshotInProgress = true;
    print('🔒 截图状态：已锁定（全屏截图）');

    try {
      final bytes = await _screenshotService.captureFullScreen();
      if (bytes != null) {
        await _processScreenshot(bytes, ScreenshotType.fullScreen);
      }
    } finally {
      _isScreenshotInProgress = false;
      print('🔓 截图状态：已解锁');
    }
  }

  /// 捕获全屏截图（返回字节数据）
  Future<Uint8List?> captureFullScreenBytes() async {
    return await _screenshotService.captureFullScreen();
  }

  /// 捕获区域截图
  Future<void> captureRegion(Rect region) async {
    print('📸 captureRegion: 开始捕获区域 $region');
    final bytes = await _screenshotService.captureRegion(region);
    print('📸 captureRegion: 截图数据大小 = ${bytes?.length ?? 'null'}');
    if (bytes != null) {
      print('📸 captureRegion: 开始处理截图...');
      await _processScreenshot(bytes, ScreenshotType.region);
      print('📸 captureRegion: 截图处理完成');
    } else {
      print('📸 captureRegion: ⚠️ 截图数据为 null，跳过处理');
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
      await _saveConfig();
      _onStateChanged?.call();
    }
  }

  /// 清空所有历史记录
  Future<void> clearHistory() async {
    for (final record in _screenshots) {
      await _fileManager.deleteScreenshot(record.filePath);
    }
    _screenshots.clear();
    await _saveConfig();
    _onStateChanged?.call();
  }

  /// 更新设置
  Future<void> updateSettings(ss.ScreenshotSettings newSettings) async {
    _settings = newSettings;
    _fileManager.updateSettings(newSettings);
    _screenshotService.updateSettings(newSettings);
    await _saveConfig();
    _onStateChanged?.call();
  }

  // ========== 循环截图任务管理 ==========

  /// 获取所有循环任务
  List<RecurringScreenshotTask> get recurringTasks => _taskManager.tasks;

  /// 创建循环截图任务
  RecurringScreenshotTask createRecurringTask({
    required String name,
    String? windowId,
    String? windowTitle,
    required int intervalSeconds,
    int? totalShots,
    String? saveDirectory,
  }) {
    final task = _taskManager.createTask(
      name: name,
      windowId: windowId,
      windowTitle: windowTitle,
      intervalSeconds: intervalSeconds,
      totalShots: totalShots,
      saveDirectory: saveDirectory,
    );

    // 保存到配置
    _saveTasksConfig();

    return task;
  }

  /// 暂停循环任务
  void pauseRecurringTask(String taskId) {
    _taskManager.pauseTask(taskId);
    _saveTasksConfig();
  }

  /// 恢复循环任务
  void resumeRecurringTask(String taskId) {
    _taskManager.resumeTask(taskId);
    _saveTasksConfig();
  }

  /// 删除循环任务
  void deleteRecurringTask(String taskId) {
    _taskManager.deleteTask(taskId);
    _saveTasksConfig();
  }

  /// 保存任务配置
  Future<void> _saveTasksConfig() async {
    try {
      final tasksJson = _taskManager.exportTasksToJson();
      await _context.dataStorage.store('recurring_tasks', tasksJson);
    } catch (e) {
      debugPrint('Failed to save tasks config: $e');
    }
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

  /// 轮询获取区域选择结果（用于快捷键触发）
  Future<void> _pollForResultForHotkey() async {
    // 检查是否已有截图操作进行中
    if (_isScreenshotInProgress) {
      print('🔒 截图正在进行中，忽略快捷键触发');
      await _context.platformServices.showNotification('截图正在进行中，请稍候');
      return;
    }

    // 检查是否有活动的循环任务
    if (_hasActiveRecurringTasks()) {
      print('⚠️ 检测到活动的循环任务，要求暂停');
      await _context.platformServices.showNotification('请先暂停定时截图任务');
      return;
    }

    _isScreenshotInProgress = true;
    print('🔒 截图状态：已锁定（区域截图快捷键）');

    // 【关键修复】先显示原生区域选择窗口
    print('🔑 快捷键：显示原生区域选择窗口...');
    final windowShown = await showNativeRegionCapture();
    if (!windowShown) {
      print('🔑 快捷键：❌ 窗口显示失败');
      _isScreenshotInProgress = false;
      print('🔓 截图状态：已解锁');
      return;
    }
    print('🔑 快捷键：✅ 窗口已显示，开始轮询...');

    const maxPolls = 300; // 最多轮询 30 秒（每 100ms 一次）
    int polls = 0;
    int nullCount = 0; // 连续 null 次数计数器

    try {
      while (polls < maxPolls) {
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await getRegionSelectionResult();
        polls++;

        if (result != null) {
          print(
            '🔑 快捷键：✅ 收到选择结果: ${result.x}, ${result.y}, ${result.width}x${result.height}',
          );
          // 用户选择了区域
          final rect = result.toRect();
          print('🔑 快捷键：开始捕获区域: $rect');
          try {
            await captureRegion(rect);
            print('🔑 快捷键：✅ 区域捕获完成');
          } catch (e) {
            print('🔑 快捷键：❌ 区域捕获失败: $e');
          }
          return;
        } else {
          // 结果为 null
          nullCount++;
          // 【关键修复】如果连续 3 次获取到 null，说明窗口已关闭（用户按了 ESC）
          if (nullCount >= 3) {
            print('🔑 快捷键：❌ 检测到窗口已关闭（用户取消，连续 $nullCount 次 null）');
            // 用户取消了，提前退出轮询
            break;
          }
        }
      }

      if (polls >= maxPolls) {
        print('🔑 快捷键：⏰ 轮询超时，用户可能取消了截图');
      }
    } finally {
      _isScreenshotInProgress = false;
      print('🔓 截图状态：已解锁');
    }
  }

  /// 处理截图
  Future<void> _processScreenshot(Uint8List bytes, ScreenshotType type) async {
    try {
      print('📸 _processScreenshot: 开始处理截图, 大小: ${bytes.length} bytes');

      // 保存到文件（不传入 filename，让 FileManagerService 自动生成唯一的文件名）
      print('📸 _processScreenshot: 保存到文件...');
      final filePath = await _fileManager.saveScreenshot(bytes);
      print('📸 _processScreenshot: ✅ 文件已保存: $filePath');

      // 创建记录
      print('📸 _processScreenshot: 创建记录...');
      final record = ScreenshotRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: filePath,
        createdAt: DateTime.now(),
        fileSize: bytes.length,
        type: type,
      );

      _screenshots.insert(0, record);
      print('📸 _processScreenshot: ✅ 记录已创建，当前历史记录数: ${_screenshots.length}');

      // 限制历史记录数量
      if (_screenshots.length > _settings.maxHistoryCount) {
        final removed = _screenshots.removeLast();
        await _fileManager.deleteScreenshot(removed.filePath);
        print('📸 _processScreenshot: 删除最旧的记录: ${removed.filePath}');
      }

      // 复制到剪贴板
      if (_settings.autoCopyToClipboard) {
        print('📸 _processScreenshot: 复制到剪贴板 (${_settings.clipboardContentType})...');
        await _clipboard.copyContent(
          filePath,
          contentType: _settings.clipboardContentType,
          imageBytes: bytes,
        );
        print('📸 _processScreenshot: ✅ 已复制到剪贴板');
      } else {
        print('📸 _processScreenshot: ⏭️ 跳过复制到剪贴板（未启用）');
      }

      // 保存配置和历史
      print('📸 _processScreenshot: 保存配置...');
      await _saveConfig();
      print('📸 _processScreenshot: ✅ 配置已保存');

      // 通知 UI 更新
      print('📸 _processScreenshot: 通知 UI 更新...');
      _onStateChanged?.call();
      print('📸 _processScreenshot: ✅ UI 已通知');

      // 显示通知
      print('📸 _processScreenshot: 显示通知...');
      await _context.platformServices.showNotification('截图已保存');
      print('📸 _processScreenshot: ✅ 通知已显示');

      print('📸 _processScreenshot: ✅ 截图处理完成');
    } catch (e) {
      print('📸 _processScreenshot: ❌ 处理失败: $e');
      await _context.platformServices.showNotification('截图处理失败: $e');
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    try {
      // 保存设置到单一配置键
      await _context.dataStorage.store('screenshot_config', _settings.toJson());

      // 只保存最近 100 条记录的元数据到 dataStorage
      final screenshotsToSave = _screenshots
          .take(100)
          .map((s) => s.toJson())
          .toList();
      await _context.dataStorage.store('screenshot_history', screenshotsToSave);
    } catch (e) {
      debugPrint('Failed to save config: $e');
    }
  }

  /// 注册快捷键
  Future<void> _registerHotkeys() async {
    final shortcuts = _settings.shortcuts;

    print('🔑 ========== 开始注册快捷键 ==========');
    print('🔑 当前快捷键配置: $shortcuts');

    // 注册区域截图快捷键
    if (shortcuts.containsKey('regionCapture')) {
      print('🔑 注册区域截图快捷键: ${shortcuts['regionCapture']}');
      final success = await _hotkeyService.registerHotkey(
        'regionCapture',
        shortcuts['regionCapture']!,
        () async {
          print('🔑 🔥 热键回调被调用（区域截图）');

          // 检查是否已有截图操作进行中
          if (_isScreenshotInProgress) {
            print('🔒 截图正在进行中，忽略区域截图快捷键');
            await _context.platformServices.showNotification('截图正在进行中，请稍候');
            return;
          }

          // 轮询获取并处理区域选择结果
          await _pollForResultForHotkey();
        },
      );
      print('🔑 ${success ? "✅" : "❌"} 区域截图快捷键注册${success ? "成功" : "失败"}');
    }

    // 注册全屏截图快捷键
    if (shortcuts.containsKey('fullScreenCapture')) {
      print('🔑 注册全屏截图快捷键: ${shortcuts['fullScreenCapture']}');
      final success = await _hotkeyService.registerHotkey(
        'fullScreenCapture',
        shortcuts['fullScreenCapture']!,
        () async {
          print('🔑 🔥 热键回调被调用（全屏截图）');

          // 检查是否已有截图操作进行中
          if (_isScreenshotInProgress) {
            print('🔒 截图正在进行中，忽略全屏截图快捷键');
            await _context.platformServices.showNotification('截图正在进行中，请稍候');
            return;
          }

          // 执行全屏截图
          await captureFullScreen();
        },
      );
      print('🔑 ${success ? "✅" : "❌"} 全屏截图快捷键注册${success ? "成功" : "失败"}');
    }

    print('🔑 ========== 热键注册完成 ==========');
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
  void dispose() {
    // 清理回调
    widget.plugin._onStateChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.plugin._isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ScreenshotMainWidget(plugin: widget.plugin);
  }
}
