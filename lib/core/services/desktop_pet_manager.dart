import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'platform_logger.dart';
import 'desktop_pet_click_through_service.dart';

// Conditional imports for platform detection
import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_web.dart'
    as platform_helper;

/// Desktop Pet管理器 - 支持所有桌面平台
class DesktopPetManager with WindowListener {
  static const MethodChannel _channel = MethodChannel('desktop_pet');

  bool _isInitialized = false;
  bool _isDesktopPetMode = false;
  bool _isAlwaysOnTop = false;
  bool _isMonitoringWindow = false;

  // 点击穿透服务
  final DesktopPetClickThroughService _clickThroughService =
      DesktopPetClickThroughService();

  // Desktop pet preferences
  final Map<String, dynamic> _petPreferences = {
    'position': {'x': 100.0, 'y': 100.0},
    'size': {'width': 200.0, 'height': 200.0},
    'opacity': 1.0,
    'animations_enabled': true,
    'interactions_enabled': true,
    'auto_hide': false,
    'theme': 'default',
  };

  /// 初始化Desktop Pet管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 首先检查kIsWeb以确保web平台兼容性
    if (kIsWeb) {
      _isInitialized = true;
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Manager',
        'Web platform does not support desktop pet functionality',
      );
      return;
    }

    // 检查平台支持 - 如果不支持则优雅地跳过初始化
    if (!_isSupported) {
      _isInitialized = true;
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Manager',
        'Platform does not support desktop pet functionality',
      );
      return;
    }

    try {
      // 初始化点击穿透服务
      await _clickThroughService.initialize();

      // 加载用户偏好设置
      await _loadPetPreferences();

      _isInitialized = true;
      final platform = _getPlatformName();
      PlatformLogger.instance.logInfo(
        'Desktop Pet Manager initialized for $platform',
      );
    } catch (e) {
      // 即使平台特定功能失败，也允许基本功能
      _isInitialized = true;
      PlatformLogger.instance.logWarning(
        'Desktop Pet Manager initialized with basic functionality: $e',
      );
    }
  }

  /// 启用Desktop Pet模式
  Future<void> enableDesktopPetMode() async {
    if (!_isInitialized) await initialize();

    // Web平台直接返回，不执行任何操作
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Mode',
        'Web platform does not support desktop pet functionality',
      );
      return;
    }

    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Mode',
        'Platform does not support desktop pet functionality',
      );
      return;
    }

    try {
      // 使用window_manager创建桌面宠物窗口
      await _createDesktopPetWindow();

      _isDesktopPetMode = true;
      PlatformLogger.instance.logInfo('Desktop Pet mode enabled');
    } catch (e) {
      // 如果平台特定实现失败，使用基本实现
      PlatformLogger.instance.logWarning(
        'Platform specific implementation failed, using basic mode: $e',
      );
      _isDesktopPetMode = true;
    }
  }

  /// 禁用Desktop Pet模式
  Future<void> disableDesktopPetMode() async {
    if (!_isInitialized || !_isDesktopPetMode) return;

    // Web平台直接返回，不执行任何操作
    if (kIsWeb) {
      return;
    }

    // 检查平台支持
    if (!_isSupported) {
      return;
    }

    try {
      await _restoreMainWindow();
    } catch (e) {
      PlatformLogger.instance.logError('Desktop Pet Mode', e);
    }

    _isDesktopPetMode = false;
    _isAlwaysOnTop = false;
    PlatformLogger.instance.logInfo('Desktop Pet mode disabled');
  }

  /// 检查是否在Desktop Pet模式
  bool get isDesktopPetMode => _isDesktopPetMode;

  /// 检查窗口是否置顶
  bool get isAlwaysOnTop => _isAlwaysOnTop;

  /// 检查当前实例是否支持Desktop Pet功能
  bool get _isSupported => isSupported();

  /// 设置窗口置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isInitialized) return;

    // Web平台不支持窗口置顶功能
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Always On Top',
        'Web platform does not support window always-on-top',
      );
      return;
    }

    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Always On Top',
        'Platform does not support window always-on-top',
      );
      return;
    }

    try {
      await _channel.invokeMethod('setAlwaysOnTop', {
        'alwaysOnTop': alwaysOnTop,
      });
      _isAlwaysOnTop = alwaysOnTop;
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to set always on top: $e');
      // 在不支持的平台上，仍然记录状态
      _isAlwaysOnTop = alwaysOnTop;
    }
  }

  /// 更新Pet偏好设置
  Future<void> updatePetPreferences(Map<String, dynamic> preferences) async {
    _petPreferences.addAll(preferences);
    await _savePetPreferences();

    // 如果在Pet模式下，应用更改
    if (_isDesktopPetMode) {
      await _applyPetPreferences();
    }
  }

  /// 获取当前偏好设置
  Map<String, dynamic> get petPreferences => Map.from(_petPreferences);

  /// 平滑过渡到Desktop Pet模式
  Future<void> transitionToDesktopPet() async {
    if (_isDesktopPetMode) return;

    // Web平台不支持Desktop Pet过渡
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Web platform does not support desktop pet transitions',
      );
      return;
    }

    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Platform does not support desktop pet transitions',
      );
      return;
    }

    try {
      // 创建桌面宠物窗口（不隐藏，直接调整大小和属性）
      await _createDesktopPetWindow();

      _isDesktopPetMode = true;
    } catch (e) {
      // 回退到基本模式 - 直接启用Desktop Pet模式
      PlatformLogger.instance.logWarning(
        'Platform channel not available, using basic mode: $e',
      );
      _isDesktopPetMode = true;
    }
  }

  /// 过渡回完整应用模式
  Future<void> transitionToFullApplication() async {
    if (!_isDesktopPetMode) return;

    // Web平台不支持Desktop Pet过渡
    if (kIsWeb) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Web platform does not support desktop pet transitions',
      );
      return;
    }

    // 检查平台支持
    if (!_isSupported) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Transition',
        'Platform does not support desktop pet transitions',
      );
      return;
    }

    try {
      await _restoreMainWindow();

      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
    } catch (e) {
      // 回退到基本模式 - 直接禁用Desktop Pet模式
      PlatformLogger.instance.logWarning(
        'Platform channel not available, using basic mode: $e',
      );
      _isDesktopPetMode = false;
      _isAlwaysOnTop = false;
    }
  }

  /// 检查Desktop Pet是否支持
  static bool isSupported() {
    // Web平台不支持Desktop Pet功能 - 首先检查kIsWeb
    if (kIsWeb) return false;

    // 所有桌面平台都支持基本的Desktop Pet功能
    return _isDesktopPlatform();
  }

  /// 检查是否为桌面平台（避免在web上调用Platform）
  static bool _isDesktopPlatform() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;

    // 使用安全的平台检测助手
    return platform_helper.isWindows ||
        platform_helper.isMacOS ||
        platform_helper.isLinux;
  }

  /// 获取平台特定功能支持情况
  Map<String, bool> getPlatformCapabilities() {
    // Web平台不支持任何桌面特定功能
    if (kIsWeb) {
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }

    // 不支持的平台不支持任何桌面特定功能
    if (!_isSupported) {
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }

    // 桌面平台功能支持
    try {
      return {
        'always_on_top': _isDesktopPlatform(),
        'transparency': _isWindowsOrMacOS(),
        'system_tray': _isWindowsOrLinux(),
        'smooth_animations': _isWindowsOrMacOS(),
        'drag_and_drop': _isDesktopPlatform(),
        'right_click_menu': _isDesktopPlatform(),
        'resize': _isDesktopPlatform(),
      };
    } catch (e) {
      // 如果平台检测失败，返回保守的功能集
      PlatformLogger.instance.logError('Platform Capabilities', e);
      return {
        'always_on_top': false,
        'transparency': false,
        'system_tray': false,
        'smooth_animations': false,
        'drag_and_drop': false,
        'right_click_menu': false,
        'resize': false,
      };
    }
  }

  /// 检查是否为Windows或macOS平台
  bool _isWindowsOrMacOS() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;

    // 使用安全的平台检测助手
    return platform_helper.isWindows || platform_helper.isMacOS;
  }

  /// 检查是否为Windows或Linux平台
  bool _isWindowsOrLinux() {
    // 首先检查kIsWeb以避免在web平台上访问dart:io
    if (kIsWeb) return false;

    // 使用安全的平台检测助手
    return platform_helper.isWindows || platform_helper.isLinux;
  }

  /// 获取平台名称（Web安全）
  String _getPlatformName() {
    if (kIsWeb) return 'Web';

    // 使用安全的平台检测助手
    return platform_helper.operatingSystem;
  }

  // 私有方法

  /// 创建桌面宠物窗口
  Future<void> _createDesktopPetWindow() async {
    if (kIsWeb || !_isSupported) return;

    try {
      // 宠物窗口最终大小 - 120x120（给呼吸动画和边框留出空间）
      const petWindowSize = Size(120.0, 120.0);

      // 确保窗口管理器已初始化
      await windowManager.ensureInitialized();

      // 步骤 1: 获取当前窗口位置并保持不变
      final currentPosition = await windowManager.getPosition();
      final targetOpacity = _petPreferences['opacity'] ?? 1.0;

      PlatformLogger.instance.logInfo(
        '🎯 Step 1: 准备创建桌面宠物窗口\n'
        '   当前位置: (${currentPosition.dx}, ${currentPosition.dy})\n'
        '   目标透明度: $targetOpacity',
      );

      // 步骤 2: 先设置透明度为0（关键：在窗口可见前就设置为透明）
      PlatformLogger.instance.logInfo('🎯 Step 2: 设置初始透明度为 0.0（完全透明）...');
      await windowManager.setOpacity(0.0);
      
      final initialOpacity = await windowManager.getOpacity();
      PlatformLogger.instance.logInfo(
        '   验证: 初始透明度 = $initialOpacity (应为 0.0)',
      );

      // 【关键】等待透明度设置生效
      await Future.delayed(const Duration(milliseconds: 50));

      // 步骤 3: 设置所有窗口属性（此时窗口是透明的，即使可见也看不到）
      PlatformLogger.instance.logInfo('🎯 Step 3: 配置窗口属性（透明状态下）...');

      // 取消最小尺寸限制
      PlatformLogger.instance.logInfo('   - 设置最小尺寸为 0x0');
      await windowManager.setMinimumSize(const Size(0, 0));

      // 设置透明背景色
      PlatformLogger.instance.logInfo('   - 设置背景色为透明 (0x00000000)');
      await windowManager.setBackgroundColor(const Color(0x00000000));

      // 等待背景色设置生效
      await Future.delayed(const Duration(milliseconds: 50));

      // 设置窗口为无边框
      PlatformLogger.instance.logInfo('   - 设置为无边框窗口');
      await windowManager.setAsFrameless();

      // 调整窗口大小
      PlatformLogger.instance.logInfo('   - 设置窗口大小为 ${petWindowSize.width}x${petWindowSize.height}');
      await windowManager.setSize(petWindowSize);

      // 验证窗口大小
      final actualSize = await windowManager.getSize();
      PlatformLogger.instance.logInfo(
        '   - 验证尺寸: 请求 ${petWindowSize.width}x${petWindowSize.height}, '
        '实际 ${actualSize.width}x${actualSize.height}',
      );

      // 设置窗口属性
      PlatformLogger.instance.logInfo('   - 设置窗口属性（置顶、无阴影等）');
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimizable(false);

      // 等待所有属性设置完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证窗口状态
      final isVisibleAfterConfig = await windowManager.isVisible();
      final isAlwaysOnTopValue = await windowManager.isAlwaysOnTop();
      final opacityAfterConfig = await windowManager.getOpacity();
      
      PlatformLogger.instance.logInfo(
        '🎯 Step 3 验证:\n'
        '   尺寸: ${actualSize.width}x${actualSize.height}\n'
        '   可见性: $isVisibleAfterConfig\n'
        '   透明度: $opacityAfterConfig (应为 0.0)\n'
        '   置顶: $isAlwaysOnTopValue',
      );

      // 步骤 4: 确保窗口可见（如果还没显示的话）
      PlatformLogger.instance.logInfo('🎯 Step 4: 确保窗口可见（透明状态）...');
      
      if (!isVisibleAfterConfig) {
        await windowManager.show();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 启用点击穿透
      await _clickThroughService.setClickThrough(true);

      // 开始监听窗口事件
      _startWindowMonitoring();

      // 验证窗口显示状态
      final isVisibleNow = await windowManager.isVisible();
      final opacityNow = await windowManager.getOpacity();
      
      PlatformLogger.instance.logInfo(
        '   验证: 可见性 = $isVisibleNow, 透明度 = $opacityNow',
      );

      // 步骤 5: 逐渐恢复透明度（从0到目标值）
      PlatformLogger.instance.logInfo('🎯 Step 5: 恢复透明度到 $targetOpacity...');
      
      await windowManager.setOpacity(targetOpacity);
      await windowManager.focus();

      // 最终验证
      final finalOpacity = await windowManager.getOpacity();
      final finalSize = await windowManager.getSize();
      
      PlatformLogger.instance.logInfo(
        '🎯 完成！桌面宠物窗口创建成功\n'
        '   最终尺寸: ${finalSize.width}x${finalSize.height}\n'
        '   最终透明度: $finalOpacity\n'
        '   位置: (${currentPosition.dx}, ${currentPosition.dy})',
      );

      _isAlwaysOnTop = true;
    } catch (e) {
      PlatformLogger.instance.logError(
        'Failed to create desktop pet window',
        e,
      );
      _stopWindowMonitoring();
      rethrow;
    }
  }

  /// 开始监听窗口事件
  void _startWindowMonitoring() {
    if (_isMonitoringWindow) return;
    
    PlatformLogger.instance.logInfo('🔍 开始监听窗口事件...');
    windowManager.addListener(this);
    _isMonitoringWindow = true;
  }

  /// 停止监听窗口事件
  void _stopWindowMonitoring() {
    if (!_isMonitoringWindow) return;
    
    PlatformLogger.instance.logInfo('🔍 停止监听窗口事件');
    windowManager.removeListener(this);
    _isMonitoringWindow = false;
  }

  @override
  void onWindowEvent(String eventName) async {
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    final opacity = await windowManager.getOpacity();
    final isVisible = await windowManager.isVisible();
    
    PlatformLogger.instance.logInfo(
      '📊 [窗口事件] $eventName\n'
      '   尺寸: ${size.width}x${size.height}\n'
      '   位置: (${position.dx}, ${position.dy})\n'
      '   透明度: $opacity\n'
      '   可见性: $isVisible',
    );
  }

  @override
  void onWindowClose() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口关闭');
  }

  @override
  void onWindowFocus() async {
    final size = await windowManager.getSize();
    final opacity = await windowManager.getOpacity();
    
    PlatformLogger.instance.logInfo(
      '📊 [窗口事件] 窗口获得焦点\n'
      '   尺寸: ${size.width}x${size.height}\n'
      '   透明度: $opacity',
    );
  }

  @override
  void onWindowBlur() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口失去焦点');
  }

  @override
  void onWindowMaximize() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口最大化');
  }

  @override
  void onWindowUnmaximize() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口取消最大化');
  }

  @override
  void onWindowMinimize() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口最小化');
  }

  @override
  void onWindowRestore() async {
    final size = await windowManager.getSize();
    final opacity = await windowManager.getOpacity();
    
    PlatformLogger.instance.logInfo(
      '📊 [窗口事件] 窗口恢复\n'
      '   尺寸: ${size.width}x${size.height}\n'
      '   透明度: $opacity',
    );
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    final opacity = await windowManager.getOpacity();
    final isVisible = await windowManager.isVisible();
    
    PlatformLogger.instance.logInfo(
      '📊 [窗口事件] 窗口大小变化\n'
      '   新尺寸: ${size.width}x${size.height}\n'
      '   透明度: $opacity\n'
      '   可见性: $isVisible',
    );
  }

  @override
  void onWindowMove() async {
    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();
    
    PlatformLogger.instance.logInfo(
      '📊 [窗口事件] 窗口位置变化\n'
      '   新位置: (${position.dx}, ${position.dy})\n'
      '   尺寸: ${size.width}x${size.height}',
    );
  }

  @override
  void onWindowEnterFullScreen() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口进入全屏');
  }

  @override
  void onWindowLeaveFullScreen() {
    PlatformLogger.instance.logInfo('📊 [窗口事件] 窗口退出全屏');
  }

  /// 恢复主窗口
  Future<void> _restoreMainWindow() async {
    if (kIsWeb || !_isSupported) return;

    try {
      // 【监听】停止监听窗口事件
      _stopWindowMonitoring();

      // 禁用点击穿透
      await _clickThroughService.setClickThrough(false);

      // 恢复最小尺寸限制
      await windowManager.setMinimumSize(const Size(800, 600));

      // 恢复窗口到正常大小和位置
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.center();

      // 恢复窗口属性
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSkipTaskbar(false); // 在任务栏显示
      await windowManager.setHasShadow(true); // 有阴影
      await windowManager.setOpacity(1.0);

      // 恢复标题栏
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);

      // 确保窗口可见和聚焦
      await windowManager.show();
      await windowManager.focus();

      _isAlwaysOnTop = false;

      PlatformLogger.instance.logInfo('Main window restored successfully');
    } catch (e) {
      PlatformLogger.instance.logError('Failed to restore main window', e);
      rethrow;
    }
  }

  Future<void> _applyPetPreferences() async {
    if (!_isDesktopPetMode) return;

    // Web平台跳过偏好设置应用
    if (kIsWeb) return;

    // 不支持的平台跳过偏好设置应用
    if (!_isSupported) return;

    try {
      final position =
          _petPreferences['position'] as Map<String, dynamic>? ??
          {'x': 100.0, 'y': 100.0};
      final size =
          _petPreferences['size'] as Map<String, dynamic>? ??
          {'width': 200.0, 'height': 200.0};

      await windowManager.setPosition(Offset(position['x'], position['y']));
      await windowManager.setSize(Size(size['width'], size['height']));
      await windowManager.setOpacity(_petPreferences['opacity'] ?? 1.0);
      await windowManager.setAlwaysOnTop(
        _petPreferences['always_on_top'] ?? true,
      );
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to apply pet preferences: $e');
    }
  }

  Future<void> _loadPetPreferences() async {
    try {
      // 这里可以从本地存储加载偏好设置
      // 暂时使用默认值
      PlatformLogger.instance.logDebug(
        'Loaded pet preferences: $_petPreferences',
      );
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to load pet preferences: $e');
    }
  }

  Future<void> _savePetPreferences() async {
    try {
      // 这里可以保存偏好设置到本地存储
      PlatformLogger.instance.logDebug(
        'Saved pet preferences: $_petPreferences',
      );
    } catch (e) {
      PlatformLogger.instance.logWarning('Failed to save pet preferences: $e');
    }
  }
}
