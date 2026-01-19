library;

import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/screenshot_models.dart';
import '../models/screenshot_settings.dart';

/// 文件管理服务
///
/// 负责截图文件的保存、管理和历史记录
class FileManagerService {
  /// 当前设置
  ScreenshotSettings _settings = ScreenshotSettings.defaultSettings();

  /// 获取当前设置
  ScreenshotSettings get settings => _settings;

  /// 更新设置
  void updateSettings(ScreenshotSettings settings) {
    _settings = settings;
  }

  /// 获取默认保存路径
  Future<String> getDefaultSavePath() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      return path.join(documentsDir.path, 'Screenshots');
    } catch (e) {
      print('Failed to get default save path: $e');
      // 降级方案
      final currentDir = Directory.current.path;
      return path.join(currentDir, 'screenshots');
    }
  }

  /// 解析保存路径（处理占位符）
  Future<String> _resolveSavePath() async {
    String savePath = _settings.savePath;

    // 处理 {documents} 占位符
    if (savePath.contains('{documents}')) {
      final documentsDir = await getApplicationDocumentsDirectory();
      savePath = savePath.replaceAll('{documents}', documentsDir.path);
    }

    // 处理 {home} 占位符
    if (savePath.contains('{home}')) {
      final homeDir = await getApplicationDocumentsDirectory();
      savePath = savePath.replaceAll('{home}', homeDir.parent.path);
    }

    // 处理 {temp} 占位符
    if (savePath.contains('{temp}')) {
      final tempDir = await getTemporaryDirectory();
      savePath = savePath.replaceAll('{temp}', tempDir.path);
    }

    return savePath;
  }

  /// 确保保存目录存在
  Future<void> _ensureDirectoryExists(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 生成文件名
  Future<String> _generateFilename({String? customFormat}) async {
    final format = customFormat ?? _settings.filenameFormat;
    final now = DateTime.now();

    // 生成唯一的文件名
    String filename = format
        .replaceAll('{timestamp}', now.millisecondsSinceEpoch.toString())
        .replaceAll('{date}', DateFormat('yyyy-MM-dd').format(now))
        .replaceAll('{time}', DateFormat('HH-mm-ss').format(now))
        .replaceAll('{datetime}', DateFormat('yyyy-MM-dd_HH-mm-ss').format(now));

    // 处理 {index} 占位符 - 基于现有文件数量
    if (filename.contains('{index}')) {
      final savePath = await _resolveSavePath();
      final dir = Directory(savePath);
      int currentIndex = 1;

      if (await dir.exists()) {
        // 统计今天已有的截图数量
        final today = DateFormat('yyyy-MM-dd').format(now);
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains(today)) {
            currentIndex++;
          }
        }
      }

      filename = filename.replaceAll('{index}', currentIndex.toString());
    }

    // 添加扩展名
    final extension = _settings.imageFormat.extension;
    if (!filename.endsWith('.$extension')) {
      filename = '$filename.$extension';
    }

    // 如果文件已存在，添加序号确保唯一性
    final savePath = await _resolveSavePath();
    String finalPath = path.join(savePath, filename);
    int counter = 1;

    while (await File(finalPath).exists()) {
      final nameWithoutExt = path.basenameWithoutExtension(filename);
      final ext = path.extension(filename);
      finalPath = path.join(savePath, '${nameWithoutExt}_$counter$ext');
      counter++;
    }

    return path.basename(finalPath);
  }

  /// 保存截图到文件
  ///
  /// [imageBytes] 图片数据的字节数组
  /// [filename] 自定义文件名（可选）
  /// [subfolder] 子文件夹名称（可选）
  /// 返回保存的完整文件路径
  Future<String> saveScreenshot(
    Uint8List imageBytes, {
    String? filename,
    String? subfolder,
  }) async {
    try {
      // 解析保存路径
      String savePath = await _resolveSavePath();

      // 如果指定了子文件夹，添加到路径中
      if (subfolder != null && subfolder.isNotEmpty) {
        savePath = path.join(savePath, subfolder);
      }

      // 确保目录存在
      await _ensureDirectoryExists(savePath);

      // 生成文件名
      final finalFilename = filename ?? await _generateFilename();
      final filePath = path.join(savePath, finalFilename);

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      print('Screenshot saved to: $filePath');
      return filePath;
    } catch (e) {
      print('Failed to save screenshot: $e');
      rethrow;
    }
  }

  /// 获取截图历史记录
  ///
  /// [startDate] 开始日期（可选）
  /// [endDate] 结束日期（可选）
  /// [limit] 返回记录的最大数量
  Future<List<ScreenshotRecord>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final savePath = await _resolveSavePath();
      final dir = Directory(savePath);

      if (!await dir.exists()) {
        return [];
      }

      final records = <ScreenshotRecord>[];
      final now = DateTime.now();

      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final modified = stat.modified;

          // 日期过滤
          if (startDate != null && modified.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && modified.isAfter(endDate)) {
            continue;
          }

          // 创建记录
          final record = ScreenshotRecord(
            id: now.millisecondsSinceEpoch.toString(),
            filePath: entity.path,
            createdAt: modified,
            fileSize: stat.size,
            type: ScreenshotType.fullScreen, // 默认类型
          );

          records.add(record);

          // 限制数量
          if (records.length >= limit) {
            break;
          }
        }
      }

      // 按创建时间倒序排序
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return records;
    } catch (e) {
      print('Failed to get screenshot history: $e');
      return [];
    }
  }

  /// 删除截图文件
  Future<void> deleteScreenshot(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Screenshot deleted: $filePath');
      }
    } catch (e) {
      print('Failed to delete screenshot: $e');
    }
  }

  /// 清理过期截图
  ///
  /// [maxAge] 最大保留期限
  /// 返回删除的文件数量
  Future<int> cleanupOldScreenshots(Duration maxAge) async {
    try {
      final savePath = await _resolveSavePath();
      final dir = Directory(savePath);

      if (!await dir.exists()) {
        return 0;
      }

      final cutoffDate = DateTime.now().subtract(maxAge);
      int deletedCount = 0;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      print('Cleaned up $deletedCount old screenshots');
      return deletedCount;
    } catch (e) {
      print('Failed to cleanup old screenshots: $e');
      return 0;
    }
  }

  /// 设置默认保存路径
  Future<void> setDefaultSavePath(String newPath) async {
    _settings = _settings.copyWith(savePath: newPath);
  }

  /// 格式化文件大小显示
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
