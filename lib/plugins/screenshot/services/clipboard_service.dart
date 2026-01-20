library;

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/screenshot_settings.dart';

/// 剪贴板服务
///
/// 提供跨平台的剪贴板操作功能
class ClipboardService {
  /// 复制内容到剪贴板
  ///
  /// [filePath] 文件完整路径
  /// [contentType] 要复制的内容类型
  /// 返回是否成功复制
  Future<bool> copyContent(
    String filePath, {
    required ClipboardContentType contentType,
    Uint8List? imageBytes,
  }) async {
    try {
      switch (contentType) {
        case ClipboardContentType.image:
          if (imageBytes != null) {
            return await copyImage(imageBytes);
          }
          return false;

        case ClipboardContentType.filename:
          final filename = path.basename(filePath);
          await Clipboard.setData(ClipboardData(text: filename));
          return true;

        case ClipboardContentType.fullPath:
          await Clipboard.setData(ClipboardData(text: filePath));
          return true;

        case ClipboardContentType.directoryPath:
          final directory = path.dirname(filePath);
          await Clipboard.setData(ClipboardData(text: directory));
          return true;
      }
    } catch (e) {
      debugPrint('Failed to copy content to clipboard: $e');
      return false;
    }
  }

  /// 复制图片到剪贴板
  ///
  /// [imageBytes] 图片数据的字节数组
  /// 返回是否成功复制
  Future<bool> copyImage(Uint8List imageBytes) async {
    try {
      // 对于支持的平台，尝试使用系统剪贴板
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 桌面平台：保存到临时文件并尝试复制
        return await _copyImageOnDesktop(imageBytes);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台：使用平台特定的方法
        return await _copyImageOnMobile(imageBytes);
      } else {
        // Web 平台：降级方案
        return await _copyImageOnWeb(imageBytes);
      }
    } catch (e) {
      debugPrint('Failed to copy image to clipboard: $e');
      return false;
    }
  }

  /// 从剪贴板获取图片
  ///
  /// 返回图片数据的字节数组，如果剪贴板没有图片则返回 null
  Future<Uint8List?> getImageFromClipboard() async {
    try {
      // TODO: 实现从剪贴板获取图片
      // 这需要平台特定的实现
      debugPrint('Getting image from clipboard not yet implemented');
      return null;
    } catch (e) {
      debugPrint('Failed to get image from clipboard: $e');
      return null;
    }
  }

  /// 检查剪贴板是否包含图片
  Future<bool> hasImage() async {
    // TODO: 实现检查剪贴板内容
    return false;
  }

  /// 清空剪贴板
  Future<void> clear() async {
    // TODO: 实现清空剪贴板
  }

  /// 在桌面平台复制图片
  Future<bool> _copyImageOnDesktop(Uint8List imageBytes) async {
    try {
      // 保存到临时文件
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/screenshot_$timestamp.png');
      await tempFile.writeAsBytes(imageBytes);

      // 对于 Windows/macOS/Linux，我们需要使用平台通道
      // 这里提供一个基础的实现框架
      // 实际的图片复制需要平台原生代码

      // 临时方案：复制文件路径到剪贴板
      await Clipboard.setData(ClipboardData(text: tempFile.path));

      // 显示提示
      debugPrint('Image saved to: ${tempFile.path}');
      debugPrint(
        'For full clipboard support, platform-specific code is needed',
      );

      return true;
    } catch (e) {
      debugPrint('Failed to copy image on desktop: $e');
      return false;
    }
  }

  /// 在移动平台复制图片
  Future<bool> _copyImageOnMobile(Uint8List imageBytes) async {
    try {
      // 移动平台需要使用平台插件（如 flutter_cache_manager）
      // 这里提供基础框架
      debugPrint('Mobile clipboard copy not yet fully implemented');
      return false;
    } catch (e) {
      debugPrint('Failed to copy image on mobile: $e');
      return false;
    }
  }

  /// 在 Web 平台复制图片
  Future<bool> _copyImageOnWeb(Uint8List imageBytes) async {
    try {
      // Web 平台的 Clipboard API 对图片支持有限
      // 可以使用 ClipboardItem API（仅部分浏览器支持）
      debugPrint('Web clipboard copy limited support');
      return false;
    } catch (e) {
      debugPrint('Failed to copy image on web: $e');
      return false;
    }
  }
}
