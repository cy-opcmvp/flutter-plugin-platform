library;

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/screenshot_settings.dart';

/// Windows 剪贴板方法通道
const _clipboardMethodChannel = MethodChannel('com.example.screenshot/clipboard');

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
      debugPrint('ClipboardService: Copying to clipboard, contentType=$contentType, hasImageBytes=${imageBytes != null}');

      switch (contentType) {
        case ClipboardContentType.image:
          if (imageBytes != null) {
            return await copyImage(imageBytes, filePath);
          }
          debugPrint('ClipboardService: ERROR - contentType is image but imageBytes is null!');
          return false;

        case ClipboardContentType.filename:
          final filename = path.basename(filePath);
          debugPrint('ClipboardService: Copying filename: $filename');
          // 在 Windows 上使用原生方法
          if (Platform.isWindows) {
            return await _setTextToClipboardWindows(filename);
          }
          await Clipboard.setData(ClipboardData(text: filename));
          return true;

        case ClipboardContentType.fullPath:
          debugPrint('ClipboardService: Copying full path: $filePath');
          // 在 Windows 上使用原生方法
          if (Platform.isWindows) {
            return await _setTextToClipboardWindows(filePath);
          }
          await Clipboard.setData(ClipboardData(text: filePath));
          return true;

        case ClipboardContentType.directoryPath:
          final directory = path.dirname(filePath);
          debugPrint('ClipboardService: Copying directory path: $directory');
          // 在 Windows 上使用原生方法
          if (Platform.isWindows) {
            return await _setTextToClipboardWindows(directory);
          }
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
  /// [filePath] 图片文件的完整路径（用于从文件重新读取完整数据）
  /// 返回是否成功复制
  Future<bool> copyImage(Uint8List imageBytes, String filePath) async {
    try {
      // 对于支持的平台，尝试使用系统剪贴板
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 桌面平台：保存到临时文件并尝试复制
        return await _copyImageOnDesktop(imageBytes, filePath);
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
      if (Platform.isWindows) {
        return await _getImageFromClipboardWindows();
      } else if (Platform.isMacOS || Platform.isLinux) {
        return await _getImageFromClipboardDesktop();
      } else {
        debugPrint('getImageFromClipboard not supported on this platform');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to get image from clipboard: $e');
      return null;
    }
  }

  /// 检查剪贴板是否包含图片
  Future<bool> hasImage() async {
    try {
      if (Platform.isWindows) {
        return await _hasImageWindows();
      } else if (Platform.isMacOS || Platform.isLinux) {
        return await _hasImageDesktop();
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Failed to check clipboard for image: $e');
      return false;
    }
  }

  /// 清空剪贴板
  Future<void> clear() async {
    try {
      if (Platform.isWindows) {
        await _clearClipboardWindows();
      } else if (Platform.isMacOS || Platform.isLinux) {
        await _clearClipboardDesktop();
      } else {
        // Web 和移动平台使用系统方法
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (e) {
      debugPrint('Failed to clear clipboard: $e');
    }
  }

  /// Windows: 从剪贴板获取图片
  Future<Uint8List?> _getImageFromClipboardWindows() async {
    // 使用平台通道调用 Windows 原生代码
    try {
      final result = await _clipboardMethodChannel.invokeMethod('getImageFromClipboard');

      if (result is Uint8List) {
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get image from clipboard (Windows): $e');
      return null;
    }
  }

  /// Windows: 检查剪贴板是否有图片
  Future<bool> _hasImageWindows() async {
    try {
      final result = await _clipboardMethodChannel.invokeMethod<bool>('hasImage');

      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check clipboard (Windows): $e');
      return false;
    }
  }

  /// Windows: 清空剪贴板
  Future<void> _clearClipboardWindows() async {
    try {
      await _clipboardMethodChannel.invokeMethod('clearClipboard');
    } catch (e) {
      debugPrint('Failed to clear clipboard (Windows): $e');
    }
  }

  /// 桌面平台 (macOS/Linux): 从剪贴板获取图片
  Future<Uint8List?> _getImageFromClipboardDesktop() async {
    // macOS/Linux 的实现框架
    debugPrint('getImageFromClipboard on macOS/Linux not yet implemented');
    return null;
  }

  /// 桌面平台 (macOS/Linux): 检查剪贴板是否有图片
  Future<bool> _hasImageDesktop() async {
    debugPrint('hasImage on macOS/Linux not yet implemented');
    return false;
  }

  /// 桌面平台 (macOS/Linux): 清空剪贴板
  Future<void> _clearClipboardDesktop() async {
    // macOS/Linux 可以通过设置空文本来清空
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// 在桌面平台复制图片
  Future<bool> _copyImageOnDesktop(Uint8List imageBytes, String filePath) async {
    try {
      if (Platform.isWindows) {
        // Windows: 使用原生方法将图片复制到剪贴板
        return await _copyImageWindows(imageBytes, filePath);
      } else {
        // macOS/Linux: 保存到临时文件并复制文件路径（临时方案）
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/screenshot_$timestamp.png');
        await tempFile.writeAsBytes(imageBytes);

        // 复制文件路径到剪贴板
        await Clipboard.setData(ClipboardData(text: tempFile.path));

        debugPrint('Image saved to: ${tempFile.path}');
        debugPrint('For full clipboard support, platform-specific code is needed');

        return true;
      }
    } catch (e) {
      debugPrint('Failed to copy image on desktop: $e');
      return false;
    }
  }

  /// 在 Windows 上复制图片到剪贴板（原生实现）
  Future<bool> _copyImageWindows(Uint8List imageBytes, String filePath) async {
    try {
      debugPrint('ClipboardService: Calling Windows native method setImageToClipboard');
      debugPrint('ClipboardService: imageBytes.length=${imageBytes.length}, first 20 bytes: ${imageBytes.take(20).toList()}');

      // 从文件重新读取图片数据（确保数据完整）
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ClipboardService: File does not exist: $filePath');
        return false;
      }

      final fileBytes = await file.readAsBytes();
      debugPrint('ClipboardService: Read from file: ${fileBytes.length} bytes');

      final result = await _clipboardMethodChannel.invokeMethod<bool>(
        'setImageToClipboard',
        fileBytes,  // 直接传递 Uint8List，不包装在列表中
      );

      debugPrint('ClipboardService: Windows native method returned: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('ClipboardService: Failed to copy image to clipboard (Windows): $e');
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

  /// 在 Windows 上复制文本到剪贴板（原生实现）
  Future<bool> _setTextToClipboardWindows(String text) async {
    try {
      debugPrint('ClipboardService: Calling Windows native method setTextToClipboard');
      debugPrint('ClipboardService: text=$text');

      final result = await _clipboardMethodChannel.invokeMethod<bool>(
        'setTextToClipboard',
        text,
      );

      debugPrint('ClipboardService: Windows native method returned: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('ClipboardService: Failed to copy text to clipboard (Windows): $e');
      return false;
    }
  }
}
