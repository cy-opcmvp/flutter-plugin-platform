library;

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import '../models/screenshot_models.dart';
import '../models/screenshot_settings.dart';

/// 截图捕获服务
///
/// 提供纯 Flutter 的截图实现，使用 RepaintBoundary 和 GlobalKey
class ScreenshotCaptureService {
  /// 当前设置
  ScreenshotSettings _settings = ScreenshotSettings.defaultSettings();

  /// 获取当前设置
  ScreenshotSettings get settings => _settings;

  /// 更新设置
  void updateSettings(ScreenshotSettings settings) {
    _settings = settings;
  }

  /// 捕获整个应用窗口的截图
  ///
  /// 返回截图的字节数据（根据设置中的格式编码），如果失败则返回 null
  Future<Uint8List?> captureFullScreen() async {
    try {
      // 获取当前的 RenderObject
      final context = _findCurrentContext();
      if (context == null) {
        debugPrint('Screenshot: Cannot find current context');
        return null;
      }

      // 查找根 RenderObject
      RenderObject? renderObject = context.findRenderObject();
      while (renderObject?.parent != null) {
        renderObject = renderObject!.parent;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
          'Screenshot: Root render object is not a RenderRepaintBoundary',
        );
        return null;
      }

      // 捕获截图
      final ui.Image image = await renderObject.toImage(
        pixelRatio: ui.window.devicePixelRatio,
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        debugPrint('Screenshot: Failed to convert image to byte data');
        return null;
      }

      // 根据设置编码图片
      return _encodeImage(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
      );
    } catch (e) {
      debugPrint('Screenshot: Failed to capture full screen - $e');
      return null;
    }
  }

  /// 捕获指定区域的截图
  ///
  /// [rect] 截图区域（屏幕坐标）
  /// 返回截图的字节数据（根据设置中的格式编码），如果失败则返回 null
  Future<Uint8List?> captureRegion(Rect rect) async {
    try {
      // 先捕获全屏
      final fullScreenBytes = await captureFullScreen();
      if (fullScreenBytes == null) return null;

      // 解码图片
      final image = img.decodeImage(fullScreenBytes);
      if (image == null) return null;

      // 裁剪指定区域
      final devicePixelRatio = ui.window.devicePixelRatio;
      final cropped = img.copyCrop(
        image,
        x: (rect.left * devicePixelRatio).round(),
        y: (rect.top * devicePixelRatio).round(),
        width: (rect.width * devicePixelRatio).round(),
        height: (rect.height * devicePixelRatio).round(),
      );

      // 根据设置编码图片
      return _encodeImageFromImage(cropped);
    } catch (e) {
      debugPrint('Screenshot: Failed to capture region - $e');
      return null;
    }
  }

  /// 捕获指定 Widget 的截图
  ///
  /// [globalKey] Widget 的 GlobalKey
  /// 返回截图的字节数据（根据设置中的格式编码），如果失败则返回 null
  Future<Uint8List?> captureWidget(
    GlobalKey<State<StatefulWidget>> globalKey,
  ) async {
    try {
      final RenderRepaintBoundary? boundary =
          globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('Screenshot: Cannot find RenderRepaintBoundary');
        return null;
      }

      final ui.Image image = await boundary.toImage(
        pixelRatio: ui.window.devicePixelRatio,
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        debugPrint('Screenshot: Failed to convert image to byte data');
        return null;
      }

      // 根据设置编码图片
      return _encodeImage(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
      );
    } catch (e) {
      debugPrint('Screenshot: Failed to capture widget - $e');
      return null;
    }
  }

  /// 获取主屏幕尺寸
  Future<Rect?> getPrimaryScreenSize() async {
    try {
      final size = ui.window.physicalSize;
      final pixelRatio = ui.window.devicePixelRatio;

      return Rect.fromLTWH(
        0,
        0,
        size.width / pixelRatio,
        size.height / pixelRatio,
      );
    } catch (e) {
      debugPrint('Screenshot: Failed to get screen size - $e');
      return null;
    }
  }

  /// 查找当前活动的 BuildContext
  BuildContext? _findCurrentContext() {
    // 这个方法需要从应用程序的导航器或根 widget 获取 context
    // 在实际使用中，应该通过其他方式传递 context
    // 这里返回 null，表示需要外部提供 context
    return null;
  }

  /// 根据设置编码图片（从原始 RGBA 字节数据）
  ///
  /// [bytes] 原始 RGBA 字节数据
  /// [width] 图片宽度
  /// [height] 图片高度
  /// 返回编码后的字节数据，如果失败则返回 null
  Uint8List? _encodeImage(Uint8List bytes, int width, int height) {
    try {
      // 将原始 RGBA 字节转换为 Image 对象
      // 先创建一个空图片
      final image = img.Image(width: width, height: height);

      // 将 RGBA 字节复制到图片中
      // image 包使用 RGBA 顺序，每像素 4 字节
      int byteIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (byteIndex + 3 < bytes.length) {
            image.setPixelRgba(x, y, bytes[byteIndex], bytes[byteIndex + 1], bytes[byteIndex + 2], bytes[byteIndex + 3]);
            byteIndex += 4;
          }
        }
      }

      return _encodeImageFromImage(image);
    } catch (e) {
      debugPrint('Screenshot: Failed to encode image - $e');
      return null;
    }
  }

  /// 根据设置编码图片（从已解码的 Image 对象）
  ///
  /// [image] 已解码的图片对象
  /// 返回编码后的字节数据，如果失败则返回 null
  Uint8List? _encodeImageFromImage(img.Image image) {
    try {
      switch (_settings.imageFormat) {
        case ImageFormat.png:
          // PNG 是无损格式，不使用质量设置
          final pngBytes = img.encodePng(image);
          return Uint8List.fromList(pngBytes);

        case ImageFormat.jpeg:
          // JPEG 使用质量设置（0-100）
          final jpgBytes = img.encodeJpg(
            image,
            quality: _settings.imageQuality,
          );
          return Uint8List.fromList(jpgBytes);
      }
    } catch (e) {
      debugPrint('Screenshot: Failed to encode image - $e');
      return null;
    }
  }
}

/// 带有截图捕获能力的 Widget
class ScreenshotCapturableWidget extends StatefulWidget {
  final Widget child;
  final Function(Uint8List)? onCapture;

  const ScreenshotCapturableWidget({
    super.key,
    required this.child,
    this.onCapture,
  });

  @override
  State<ScreenshotCapturableWidget> createState() =>
      _ScreenshotCapturableWidgetState();
}

class _ScreenshotCapturableWidgetState
    extends State<ScreenshotCapturableWidget> {
  final GlobalKey _globalKey = GlobalKey();

  /// 捕获此 Widget 的截图
  Future<Uint8List?> capture() async {
    try {
      final RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image uiImage = await boundary.toImage(
        pixelRatio: ui.window.devicePixelRatio,
      );
      final ByteData? byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) return null;

      // 编码为 PNG（ScreenshotCapturableWidget 不使用设置，保持简单）
      final decodedImage = img.decodeImage(byteData.buffer.asUint8List());
      if (decodedImage == null) return null;

      final pngBytes = img.encodePng(decodedImage);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      debugPrint('Screenshot: Failed to capture - $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _globalKey, child: widget.child);
  }
}
