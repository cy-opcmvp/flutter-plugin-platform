library;

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/screenshot_models.dart';
import '../platform/screenshot_platform_interface.dart';
import 'screenshot_capture_service.dart';

// Export RegionSelectedEvent for convenience
export '../platform/screenshot_platform_interface.dart'
    show RegionSelectedEvent;

/// 截图服务
///
/// 提供统一的截图功能接口，优先使用平台特定实现，降级到 Flutter 实现
class ScreenshotService {
  late ScreenshotPlatformInterface _platformService;
  ScreenshotCaptureService? _flutterCaptureService;

  ScreenshotService() {
    _platformService = ScreenshotPlatformInterface.instance;
    // 如果平台服务不可用，使用 Flutter 实现
    if (!_platformService.isAvailable) {
      _flutterCaptureService = ScreenshotCaptureService();
    }
  }

  /// 检查服务是否可用
  bool get isAvailable =>
      _platformService.isAvailable || _flutterCaptureService != null;

  /// 捕获全屏截图
  Future<Uint8List?> captureFullScreen() async {
    if (!isAvailable) {
      throw UnsupportedError('Screenshot is not supported on this platform');
    }

    // 优先使用平台实现
    if (_platformService.isAvailable) {
      return await _platformService.captureFullScreen();
    }

    // 降级到 Flutter 实现
    return await _flutterCaptureService?.captureFullScreen();
  }

  /// 捕获指定区域截图
  Future<Uint8List?> captureRegion(Rect rect) async {
    if (!isAvailable) {
      throw UnsupportedError('Screenshot is not supported on this platform');
    }

    // 优先使用平台实现
    if (_platformService.isAvailable) {
      return await _platformService.captureRegion(rect);
    }

    // 降级到 Flutter 实现
    return await _flutterCaptureService?.captureRegion(rect);
  }

  /// 捕获指定窗口截图
  Future<Uint8List?> captureWindow(String windowId) async {
    if (!isAvailable) {
      throw UnsupportedError('Screenshot is not supported on this platform');
    }

    // 只有平台实现支持窗口截图
    if (_platformService.isAvailable) {
      return await _platformService.captureWindow(windowId);
    }

    throw UnsupportedError(
      'Window capture is not supported in Flutter implementation',
    );
  }

  /// 获取所有可用窗口列表
  Future<List<WindowInfo>> getAvailableWindows() async {
    if (!isAvailable) {
      return [];
    }

    return await _platformService.getAvailableWindows();
  }

  /// 获取主屏幕尺寸
  Future<Rect?> getPrimaryScreenSize() async {
    if (!isAvailable) {
      return null;
    }

    // 优先使用平台实现
    if (_platformService.isAvailable) {
      return await _platformService.getPrimaryScreenSize();
    }

    // 降级到 Flutter 实现
    return await _flutterCaptureService?.getPrimaryScreenSize();
  }

  /// 更新设置
  ///
  /// 将设置传递给平台服务（如果可用）和 Flutter 捕获服务
  void updateSettings(dynamic settings) {
    // 更新 Flutter 捕获服务的设置
    _flutterCaptureService?.updateSettings(settings);

    // 注意：平台服务的设置更新通过平台通道处理
    // 这里不需要额外调用，因为平台实现会直接读取配置
  }

  /// 设置 Flutter 截图捕获服务的 context
  /// 这需要在有 BuildContext 的地方调用
  void setContext(BuildContext context) {
    // Flutter 实现需要 context，这里可以存储供后续使用
    // 实际实现可能需要更复杂的上下文管理
  }

  /// 显示原生区域截图窗口（桌面级）
  ///
  /// 返回 true 如果成功显示窗口
  Future<bool> showNativeRegionCapture() {
    if (!isAvailable) {
      throw UnsupportedError('Screenshot is not supported on this platform');
    }

    // 只有 Windows 原生实现支持
    if (_platformService.isAvailable) {
      return _platformService.showNativeRegionCapture();
    }

    throw UnsupportedError('Native window capture is not supported');
  }

  /// 获取区域选择结果（用于轮询）
  Future<RegionSelectedEvent?> getRegionSelectionResult() {
    if (!isAvailable) {
      throw UnsupportedError('Screenshot is not supported on this platform');
    }

    if (_platformService.isAvailable) {
      return _platformService.getRegionSelectionResult();
    }

    throw UnsupportedError('Native window capture is not supported');
  }
}
