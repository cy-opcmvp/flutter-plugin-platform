library;

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/screenshot_models.dart';

/// 区域选择事件
class RegionSelectedEvent {
  final int x;
  final int y;
  final int width;
  final int height;

  const RegionSelectedEvent({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect toRect() => Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
}

/// 截图平台接口抽象
///
/// 定义了跨平台截图功能的统一接口
/// 不同平台需要实现此接口以提供平台特定的截图功能
abstract class ScreenshotPlatformInterface {
  /// 获取当前平台的实例
  static ScreenshotPlatformInterface? _instance;

  static ScreenshotPlatformInterface get instance {
    _instance ??= _createPlatformInstance();
    return _instance!;
  }

  /// 根据当前平台创建对应的实例
  static ScreenshotPlatformInterface _createPlatformInstance() {
    if (Platform.isWindows) {
      return WindowsScreenshotService();
    } else if (Platform.isMacOS) {
      return MacOSScreenshotService();
    } else if (Platform.isLinux) {
      return LinuxScreenshotService();
    } else {
      return FallbackScreenshotService();
    }
  }

  /// 检查服务是否可用
  bool get isAvailable;

  /// 捕获全屏截图
  ///
  /// 返回截图的字节数据，如果失败则返回 null
  Future<Uint8List?> captureFullScreen();

  /// 捕获指定区域截图
  ///
  /// [rect] 截图区域（屏幕坐标）
  /// 返回截图的字节数据，如果失败则返回 null
  Future<Uint8List?> captureRegion(Rect rect);

  /// 捕获指定窗口截图
  ///
  /// [windowId] 窗口 ID
  /// 返回截图的字节数据，如果失败则返回 null
  Future<Uint8List?> captureWindow(String windowId);

  /// 获取所有可用窗口列表
  ///
  /// 返回窗口信息列表，如果平台不支持则返回空列表
  Future<List<WindowInfo>> getAvailableWindows();

  /// 获取主屏幕尺寸
  ///
  /// 返回主屏幕的矩形区域
  Future<Rect?> getPrimaryScreenSize();

  /// 显示原生区域截图窗口（桌面级）
  ///
  /// 返回 true 如果成功显示窗口
  Future<bool> showNativeRegionCapture();

  /// 获取区域选择结果（用于轮询）
  ///
  /// 返回 null 如果还未完成，返回 RegionSelectedEvent 如果已选择，
  /// 返回 null 的单次调用表示用户取消
  Future<RegionSelectedEvent?> getRegionSelectionResult();
}

/// Windows 平台截图服务实现
class WindowsScreenshotService implements ScreenshotPlatformInterface {
  static const MethodChannel _channel = MethodChannel('com.example.screenshot/screenshot');

  WindowsScreenshotService();

  @override
  bool get isAvailable => Platform.isWindows;

  @override
  Future<Uint8List?> captureFullScreen() async {
    try {
      final result = await _channel.invokeMethod('captureFullScreen');
      if (result == null) return null;

      // Convert List<int> to Uint8List
      final List<int> dataList = List<int>.from(result);
      return Uint8List.fromList(dataList);
    } catch (e) {
      print('Failed to capture full screen: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> captureRegion(Rect rect) async {
    try {
      final result = await _channel.invokeMethod('captureRegion', {
        'x': rect.left.toInt(),
        'y': rect.top.toInt(),
        'width': rect.width.toInt(),
        'height': rect.height.toInt(),
      });
      if (result == null) return null;

      final List<int> dataList = List<int>.from(result);
      return Uint8List.fromList(dataList);
    } catch (e) {
      print('Failed to capture region: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> captureWindow(String windowId) async {
    try {
      final result = await _channel.invokeMethod('captureWindow', {
        'windowId': windowId,
      });
      if (result == null) return null;

      final List<int> dataList = List<int>.from(result);
      return Uint8List.fromList(dataList);
    } catch (e) {
      print('Failed to capture window: $e');
      return null;
    }
  }

  @override
  Future<List<WindowInfo>> getAvailableWindows() async {
    try {
      final result = await _channel.invokeMethod('getAvailableWindows');
      if (result == null) return [];

      final List<dynamic> windowList = List<dynamic>.from(result);
      final List<WindowInfo> windows = [];
      for (var windowMap in windowList) {
        final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(windowMap);

        // Parse icon data if present
        Uint8List? iconBytes;
        if (map['icon'] != null) {
          final List<int> iconData = List<int>.from(map['icon']);
          iconBytes = Uint8List.fromList(iconData);
        }

        windows.add(WindowInfo(
          id: map['id'] as String,
          title: map['title'] as String,
          bounds: Rect.fromLTWH(0, 0, 0, 0), // Bounds not provided by Windows API
          appName: map['appName'] as String?,
          icon: iconBytes,
        ));
      }
      return windows;
    } catch (e) {
      print('Failed to get available windows: $e');
      return [];
    }
  }

  @override
  Future<Rect?> getPrimaryScreenSize() async {
    // Windows API implementation
    // For now, return the primary screen size using Flutter's platform API
    try {
      // This is a simplified implementation
      // In a real implementation, you would query the actual screen dimensions
      return Rect.fromLTWH(0, 0, 1920, 1080); // Default fallback
    } catch (e) {
      print('Failed to get primary screen size: $e');
      return null;
    }
  }

  @override
  Future<bool> showNativeRegionCapture() async {
    try {
      final result = await _channel.invokeMethod('showNativeRegionCapture');
      return result == true;
    } catch (e) {
      print('Failed to show native region capture: $e');
      return false;
    }
  }

  @override
  Future<RegionSelectedEvent?> getRegionSelectionResult() async {
    try {
      final result = await _channel.invokeMethod('getRegionSelectionResult');
      if (result == null) {
        // 还未完成或用户取消（无法区分，需要通过多次 null 调用来判断取消）
        return null;
      }

      final Map<dynamic, dynamic> map = result as Map<dynamic, dynamic>;
      return RegionSelectedEvent(
        x: map['x'] as int,
        y: map['y'] as int,
        width: map['width'] as int,
        height: map['height'] as int,
      );
    } catch (e) {
      print('Failed to get region selection result: $e');
      return null;
    }
  }
}

/// macOS 平台截图服务实现
class MacOSScreenshotService implements ScreenshotPlatformInterface {
  const MacOSScreenshotService();

  @override
  bool get isAvailable => Platform.isMacOS;

  @override
  Future<Uint8List?> captureFullScreen() async {
    // TODO: 实现 macOS 全屏截图
    // 可以使用 CGDisplayCreateImage 等 Cocoa API
    throw UnimplementedError('macOS screenshot capture not yet implemented');
  }

  @override
  Future<Uint8List?> captureRegion(Rect rect) async {
    // TODO: 实现 macOS 区域截图
    throw UnimplementedError('macOS region capture not yet implemented');
  }

  @override
  Future<Uint8List?> captureWindow(String windowId) async {
    // TODO: 实现 macOS 窗口截图
    throw UnimplementedError('macOS window capture not yet implemented');
  }

  @override
  Future<List<WindowInfo>> getAvailableWindows() async {
    // TODO: 实现 macOS 窗口枚举
    // 可以使用 CGWindowListCopyWindowInfo
    return [];
  }

  @override
  Future<Rect?> getPrimaryScreenSize() async {
    // TODO: 实现 macOS 获取屏幕尺寸
    return null;
  }

  @override
  Future<bool> showNativeRegionCapture() async {
    throw UnimplementedError('macOS native window capture not yet implemented');
  }

  @override
  Future<RegionSelectedEvent?> getRegionSelectionResult() async {
    throw UnimplementedError('macOS native window capture not yet implemented');
  }
}

/// Linux 平台截图服务实现
class LinuxScreenshotService implements ScreenshotPlatformInterface {
  const LinuxScreenshotService();

  @override
  bool get isAvailable => Platform.isLinux;

  @override
  Future<Uint8List?> captureFullScreen() async {
    // TODO: 实现 Linux 全屏截图
    // X11: 使用 XGetImage
    // Wayland: 使用 xdg-desktop-portal
    throw UnimplementedError('Linux screenshot capture not yet implemented');
  }

  @override
  Future<Uint8List?> captureRegion(Rect rect) async {
    // TODO: 实现 Linux 区域截图
    throw UnimplementedError('Linux region capture not yet implemented');
  }

  @override
  Future<Uint8List?> captureWindow(String windowId) async {
    // TODO: 实现 Linux 窗口截图
    throw UnimplementedError('Linux window capture not yet implemented');
  }

  @override
  Future<List<WindowInfo>> getAvailableWindows() async {
    // TODO: 实现 Linux 窗口枚举
    return [];
  }

  @override
  Future<Rect?> getPrimaryScreenSize() async {
    // TODO: 实现 Linux 获取屏幕尺寸
    return null;
  }

  @override
  Future<bool> showNativeRegionCapture() async {
    throw UnimplementedError('Linux native window capture not yet implemented');
  }

  @override
  Future<RegionSelectedEvent?> getRegionSelectionResult() async {
    throw UnimplementedError('Linux native window capture not yet implemented');
  }
}

/// 降级处理服务（用于不支持的平台）
class FallbackScreenshotService implements ScreenshotPlatformInterface {
  const FallbackScreenshotService();

  @override
  bool get isAvailable => false;

  @override
  Future<Uint8List?> captureFullScreen() async {
    throw UnsupportedError('Screenshot capture is not supported on this platform');
  }

  @override
  Future<Uint8List?> captureRegion(Rect rect) async {
    throw UnsupportedError('Screenshot capture is not supported on this platform');
  }

  @override
  Future<Uint8List?> captureWindow(String windowId) async {
    throw UnsupportedError('Screenshot capture is not supported on this platform');
  }

  @override
  Future<List<WindowInfo>> getAvailableWindows() async {
    return [];
  }

  @override
  Future<Rect?> getPrimaryScreenSize() async {
    return null;
  }

  @override
  Future<bool> showNativeRegionCapture() async {
    throw UnsupportedError('Native window capture is not supported on this platform');
  }

  @override
  Future<RegionSelectedEvent?> getRegionSelectionResult() async {
    throw UnsupportedError('Native window capture is not supported on this platform');
  }
}
