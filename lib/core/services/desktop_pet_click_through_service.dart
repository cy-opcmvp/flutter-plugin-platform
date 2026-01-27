import 'package:flutter/services.dart';
import 'dart:io';
import 'platform_logger.dart';

/// 桌宠点击穿透服务
///
/// 提供跨平台的窗口点击穿透功能
/// - Windows: 使用 WM_NCHITTEST 消息处理
/// - macOS: 使用 NSWindow.ignoreMouseEvents
/// - Linux: 使用 GDK 窗口属性
class DesktopPetClickThroughService {
  static const MethodChannel _channel = MethodChannel('desktop_pet');

  // 单例模式
  static final DesktopPetClickThroughService _instance =
      DesktopPetClickThroughService._internal();
  factory DesktopPetClickThroughService() => _instance;
  DesktopPetClickThroughService._internal();

  /// 获取单例实例
  static DesktopPetClickThroughService get instance => _instance;

  bool _isInitialized = false;
  bool _isClickThroughEnabled = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Web 平台不支持点击穿透
    if (Platform.isAndroid || Platform.isIOS) {
      PlatformLogger.instance.logFeatureDegradation(
        'Desktop Pet Click Through Service',
        'Mobile platforms do not support click-through functionality',
      );
      _isInitialized = true;
      return;
    }

    // Web 平台不支持
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // 桌面平台支持
      _isInitialized = true;
      PlatformLogger.instance.logInfo(
        'Desktop Pet Click Through Service initialized',
      );
      return;
    }

    _isInitialized = true;
    PlatformLogger.instance.logFeatureDegradation(
      'Desktop Pet Click Through Service',
      'Platform does not support click-through functionality',
    );
  }

  /// 检查是否支持点击穿透
  bool get isSupported {
    if (!_isInitialized) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 设置点击穿透
  ///
  /// [enabled] 是否启用点击穿透
  /// - true: 鼠标事件穿透到桌面，无法与窗口交互
  /// - false: 鼠标事件被窗口捕获，可以正常交互
  Future<bool> setClickThrough(bool enabled) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isSupported) {
      PlatformLogger.instance.logWarning(
        'setClickThrough called on unsupported platform',
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('setClickThrough', {
        'enabled': enabled,
      });

      if (result == true) {
        _isClickThroughEnabled = enabled;
        PlatformLogger.instance.logInfo(
          'Click-through ${enabled ? "enabled" : "disabled"}',
        );
      }

      return result ?? false;
    } catch (e) {
      PlatformLogger.instance.logError('Failed to set click-through', e);
      return false;
    }
  }

  /// macOS 兼容方法：设置忽略鼠标事件
  ///
  /// 在 Windows 上等同于 setClickThrough
  Future<bool> setIgnoreMouseEvents(bool ignore) async {
    if (!Platform.isMacOS) {
      // 非 macOS 平台，使用标准方法
      return setClickThrough(ignore);
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await _channel.invokeMethod<bool>('setIgnoreMouseEvents', {
        'ignore': ignore,
      });

      if (result == true) {
        _isClickThroughEnabled = ignore;
        PlatformLogger.instance.logInfo(
          'Ignore mouse events ${ignore ? "enabled" : "disabled"}',
        );
      }

      return result ?? false;
    } catch (e) {
      PlatformLogger.instance.logError('Failed to set ignore mouse events', e);
      return false;
    }
  }

  /// 检查当前是否启用了点击穿透
  bool get isClickThroughEnabled => _isClickThroughEnabled;

  /// 更新宠物图标区域（用于 WM_NCHITTEST 判断）
  ///
  /// Windows 平台通过 WM_NCHITTEST 消息判断鼠标是否在宠物区域内
  /// 需要定期更新宠物区域（拖拽后、窗口大小变化）
  ///
  /// [left] 宠物图标左边界（窗口客户区坐标）
  /// [top] 宠物图标上边界（窗口客户区坐标）
  /// [right] 宠物图标右边界（窗口客户区坐标）
  /// [bottom] 宠物图标下边界（窗口客户区坐标）
  Future<void> updatePetRegion({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod('updatePetRegion', {
        'left': left.toInt(),
        'top': top.toInt(),
        'right': right.toInt(),
        'bottom': bottom.toInt(),
      });
    } catch (e) {
      // 静默失败，不影响其他功能
    }
  }
}
