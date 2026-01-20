library;

import '../../../core/models/base_plugin_settings.dart';

/// 剪贴板内容类型
enum ClipboardContentType {
  /// 复制图片本身
  image,

  /// 复制文件名（不含路径）
  filename,

  /// 复制完整路径
  fullPath,

  /// 复制目录路径（不含文件名）
  directoryPath,
}

/// 剪贴板内容类型扩展
extension ClipboardContentTypeExtension on ClipboardContentType {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case ClipboardContentType.image:
        return 'Image';
      case ClipboardContentType.filename:
        return 'Filename';
      case ClipboardContentType.fullPath:
        return 'Full Path';
      case ClipboardContentType.directoryPath:
        return 'Directory Path';
    }
  }
}

/// 截图插件设置模型
class ScreenshotSettings extends BasePluginSettings {
  /// 配置版本
  @override
  final String version;

  /// 保存路径
  final String savePath;

  /// 文件名格式（支持占位符：{timestamp}, {date}, {time}, {index}）
  final String filenameFormat;

  /// 图片格式
  final ImageFormat imageFormat;

  /// 图片质量（1-100，仅对 JPEG 和 WebP 有效）
  final int imageQuality;

  /// 是否自动复制到剪贴板
  final bool autoCopyToClipboard;

  /// 剪贴板内容类型
  final ClipboardContentType clipboardContentType;

  /// 是否显示预览窗口
  final bool showPreview;

  /// 是否保存历史记录
  final bool saveHistory;

  /// 最大历史记录数量
  final int maxHistoryCount;

  /// 历史记录保留期限
  final Duration historyRetentionPeriod;

  /// 快捷键设置
  final Map<String, String> shortcuts;

  /// 钉图设置
  final PinSettings pinSettings;

  ScreenshotSettings({
    this.version = '1.0.0',
    required this.savePath,
    this.filenameFormat = 'screenshot_{timestamp}',
    this.imageFormat = ImageFormat.png,
    this.imageQuality = 95,
    this.autoCopyToClipboard = true,
    this.clipboardContentType = ClipboardContentType.image,
    this.showPreview = true,
    this.saveHistory = true,
    this.maxHistoryCount = 100,
    this.historyRetentionPeriod = const Duration(days: 30),
    required this.shortcuts,
    required this.pinSettings,
  });

  /// 默认设置
  factory ScreenshotSettings.defaultSettings() {
    return ScreenshotSettings(
      version: '1.0.0',
      savePath: '{documents}/Screenshots',
      clipboardContentType: ClipboardContentType.image,
      shortcuts: {
        'regionCapture': 'Ctrl+Shift+A',
        'fullScreenCapture': 'Ctrl+Shift+F',
        'windowCapture': 'Ctrl+Shift+W',
        'showHistory': 'Ctrl+Shift+H',
        'showSettings': 'Ctrl+Shift+S',
      },
      pinSettings: const PinSettings(),
    );
  }

  /// 从 JSON 创建实例
  factory ScreenshotSettings.fromJson(Map<String, dynamic> json) {
    return ScreenshotSettings(
      version: json['version'] as String? ?? '1.0.0',
      savePath: json['savePath'] as String? ?? '{documents}/Screenshots',
      filenameFormat:
          json['filenameFormat'] as String? ?? 'screenshot_{timestamp}',
      imageFormat: ImageFormat.values.firstWhere(
        (e) => e.name == json['imageFormat'] as String?,
        orElse: () => ImageFormat.png,
      ),
      imageQuality: json['imageQuality'] as int? ?? 95,
      autoCopyToClipboard: json['autoCopyToClipboard'] as bool? ?? true,
      clipboardContentType: json['clipboardContentType'] != null
          ? ClipboardContentType.values.firstWhere(
              (e) => e.name == json['clipboardContentType'] as String?,
              orElse: () => ClipboardContentType.image,
            )
          : ClipboardContentType.image,
      showPreview: json['showPreview'] as bool? ?? true,
      saveHistory: json['saveHistory'] as bool? ?? true,
      maxHistoryCount: json['maxHistoryCount'] as int? ?? 100,
      historyRetentionPeriod: Duration(
        days: json['historyRetentionDays'] as int? ?? 30,
      ),
      shortcuts: Map<String, String>.from(json['shortcuts'] as Map? ?? {}),
      pinSettings: json['pinSettings'] != null
          ? PinSettings.fromJson(json['pinSettings'] as Map<String, dynamic>)
          : const PinSettings(),
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'savePath': savePath,
      'filenameFormat': filenameFormat,
      'imageFormat': imageFormat.name,
      'imageQuality': imageQuality,
      'autoCopyToClipboard': autoCopyToClipboard,
      'clipboardContentType': clipboardContentType.name,
      'showPreview': showPreview,
      'saveHistory': saveHistory,
      'maxHistoryCount': maxHistoryCount,
      'historyRetentionDays': historyRetentionPeriod.inDays,
      'shortcuts': shortcuts,
      'pinSettings': pinSettings.toJson(),
    };
  }

  /// 复制并修改部分设置
  @override
  ScreenshotSettings copyWith({
    String? version,
    String? savePath,
    String? filenameFormat,
    ImageFormat? imageFormat,
    int? imageQuality,
    bool? autoCopyToClipboard,
    ClipboardContentType? clipboardContentType,
    bool? showPreview,
    bool? saveHistory,
    int? maxHistoryCount,
    Duration? historyRetentionPeriod,
    Map<String, String>? shortcuts,
    PinSettings? pinSettings,
  }) {
    return ScreenshotSettings(
      version: version ?? this.version,
      savePath: savePath ?? this.savePath,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      imageFormat: imageFormat ?? this.imageFormat,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCopyToClipboard: autoCopyToClipboard ?? this.autoCopyToClipboard,
      clipboardContentType: clipboardContentType ?? this.clipboardContentType,
      showPreview: showPreview ?? this.showPreview,
      saveHistory: saveHistory ?? this.saveHistory,
      maxHistoryCount: maxHistoryCount ?? this.maxHistoryCount,
      historyRetentionPeriod:
          historyRetentionPeriod ?? this.historyRetentionPeriod,
      shortcuts: shortcuts ?? this.shortcuts,
      pinSettings: pinSettings ?? this.pinSettings,
    );
  }

  /// 验证设置是否有效
  @override
  bool isValid() {
    return savePath.isNotEmpty &&
        imageQuality >= 1 &&
        imageQuality <= 100 &&
        maxHistoryCount > 0;
  }
}

/// 钉图设置
class PinSettings {
  /// 是否始终置顶
  final bool alwaysOnTop;

  /// 默认透明度（0.0 - 1.0）
  final double defaultOpacity;

  /// 是否启用拖拽
  final bool enableDrag;

  /// 是否启用调整大小
  final bool enableResize;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  const PinSettings({
    this.alwaysOnTop = true,
    this.defaultOpacity = 0.9,
    this.enableDrag = true,
    this.enableResize = false,
    this.showCloseButton = true,
  });

  /// 从 JSON 创建实例
  factory PinSettings.fromJson(Map<String, dynamic> json) {
    return PinSettings(
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? true,
      defaultOpacity: (json['defaultOpacity'] as num?)?.toDouble() ?? 0.9,
      enableDrag: json['enableDrag'] as bool? ?? true,
      enableResize: json['enableResize'] as bool? ?? false,
      showCloseButton: json['showCloseButton'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'alwaysOnTop': alwaysOnTop,
      'defaultOpacity': defaultOpacity,
      'enableDrag': enableDrag,
      'enableResize': enableResize,
      'showCloseButton': showCloseButton,
    };
  }

  /// 复制并修改部分设置
  PinSettings copyWith({
    bool? alwaysOnTop,
    double? defaultOpacity,
    bool? enableDrag,
    bool? enableResize,
    bool? showCloseButton,
  }) {
    return PinSettings(
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      defaultOpacity: defaultOpacity ?? this.defaultOpacity,
      enableDrag: enableDrag ?? this.enableDrag,
      enableResize: enableResize ?? this.enableResize,
      showCloseButton: showCloseButton ?? this.showCloseButton,
    );
  }
}

/// 图片格式枚举
enum ImageFormat { png, jpeg, webp }

/// 图片格式扩展
extension ImageFormatExtension on ImageFormat {
  /// 获取文件扩展名
  String get extension {
    switch (this) {
      case ImageFormat.png:
        return 'png';
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.webp:
        return 'webp';
    }
  }

  /// 获取 MIME 类型
  String get mimeType {
    switch (this) {
      case ImageFormat.png:
        return 'image/png';
      case ImageFormat.jpeg:
        return 'image/jpeg';
      case ImageFormat.webp:
        return 'image/webp';
    }
  }
}
