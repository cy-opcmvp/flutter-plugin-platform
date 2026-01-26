library;

import 'dart:typed_data';
import 'dart:io';

/// 截图类型枚举
enum ScreenshotType {
  /// 全屏截图
  fullScreen,

  /// 区域截图
  region,

  /// 窗口截图
  window,
}

/// 图片格式枚举
enum ImageFormat { png, jpeg, webp }

/// 历史记录时间段分组
enum HistoryPeriod {
  /// 今日
  today,

  /// 三天内
  threeDays,

  /// 一周内
  week,

  /// 一周前
  older,
}

/// 截图记录模型
class ScreenshotRecord {
  /// 唯一标识符
  final String id;

  /// 文件路径
  final String filePath;

  /// 创建时间
  final DateTime createdAt;

  /// 文件大小（字节）
  final int fileSize;

  /// 截图类型
  final ScreenshotType type;

  /// 图片宽度
  final int? width;

  /// 图片高度
  final int? height;

  /// 元数据（可选，包含截图时的额外信息）
  final Map<String, dynamic>? metadata;

  ScreenshotRecord({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
    required this.type,
    this.width,
    this.height,
    this.metadata,
  });

  /// 从 JSON 创建实例
  factory ScreenshotRecord.fromJson(Map<String, dynamic> json) {
    return ScreenshotRecord(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileSize: json['fileSize'] as int,
      type: ScreenshotType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ScreenshotType.fullScreen,
      ),
      width: json['width'] as int?,
      height: json['height'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'type': type.name,
      'width': width,
      'height': height,
      'metadata': metadata,
    };
  }

  /// 验证记录是否有效
  bool isValid() {
    return filePath.isNotEmpty && File(filePath).existsSync();
  }

  /// 获取文件扩展名
  String get fileExtension {
    return filePath.split('.').last.toLowerCase();
  }

  /// 获取文件名（不含路径）
  String get fileName {
    return filePath.split(RegExp(r'[\\/]')).last;
  }

  /// 格式化文件大小显示
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 获取图片尺寸字符串
  String? get dimensions {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return null;
  }
}

/// 窗口信息模型
class WindowInfo {
  /// 窗口 ID
  final String id;

  /// 窗口标题
  final String title;

  /// 窗口边界
  final Rect bounds;

  /// 窗口所属应用名称（可选）
  final String? appName;

  /// 窗口图标（可选）
  final Uint8List? icon;

  WindowInfo({
    required this.id,
    required this.title,
    required this.bounds,
    this.appName,
    this.icon,
  });

  /// 从 JSON 创建实例
  factory WindowInfo.fromJson(Map<String, dynamic> json) {
    return WindowInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      bounds: Rect.fromLTWH(
        json['left'] as double,
        json['top'] as double,
        json['width'] as double,
        json['height'] as double,
      ),
      appName: json['appName'] as String?,
      icon: json['icon'] as Uint8List?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'left': bounds.left,
      'top': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
      'appName': appName,
      'icon': icon,
    };
  }
}

/// 矩形区域类
class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory Rect.fromLTWH(double left, double top, double width, double height) {
    return Rect(left: left, top: top, width: width, height: height);
  }

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toJson() {
    return {'left': left, 'top': top, 'width': width, 'height': height};
  }

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      left: json['left'] as double,
      top: json['top'] as double,
      width: json['width'] as double,
      height: json['height'] as double,
    );
  }
}
