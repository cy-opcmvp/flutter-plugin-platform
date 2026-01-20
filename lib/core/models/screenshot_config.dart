library;

/// 截图插件配置
///
/// 包含截图插件的所有配置项
class ScreenshotConfig {
  /// 保存路径
  final String savePath;

  /// 文件名格式
  final String filenameFormat;

  /// 图片格式
  final String imageFormat;

  /// 图片质量
  final int imageQuality;

  /// 是否自动复制到剪贴板
  final bool autoCopyToClipboard;

  /// 是否显示预览窗口
  final bool showPreview;

  /// 是否保存历史记录
  final bool saveHistory;

  /// 最大历史记录数量
  final int maxHistoryCount;

  /// 历史记录保留期限（天数）
  final int historyRetentionDays;

  /// 快捷键设置
  final Map<String, String> shortcuts;

  /// 钉图设置
  final PinScreenshotConfig pinSettings;

  const ScreenshotConfig({
    required this.savePath,
    required this.filenameFormat,
    required this.imageFormat,
    required this.imageQuality,
    required this.autoCopyToClipboard,
    required this.showPreview,
    required this.saveHistory,
    required this.maxHistoryCount,
    required this.historyRetentionDays,
    required this.shortcuts,
    required this.pinSettings,
  });

  /// 从 JSON 创建实例
  factory ScreenshotConfig.fromJson(Map<String, dynamic> json) {
    return ScreenshotConfig(
      savePath: json['savePath'] as String? ?? '{documents}/Screenshots',
      filenameFormat:
          json['filenameFormat'] as String? ?? 'screenshot_{timestamp}',
      imageFormat: json['imageFormat'] as String? ?? 'png',
      imageQuality: json['imageQuality'] as int? ?? 95,
      autoCopyToClipboard: json['autoCopyToClipboard'] as bool? ?? true,
      showPreview: json['showPreview'] as bool? ?? true,
      saveHistory: json['saveHistory'] as bool? ?? true,
      maxHistoryCount: json['maxHistoryCount'] as int? ?? 100,
      historyRetentionDays: json['historyRetentionDays'] as int? ?? 30,
      shortcuts: Map<String, String>.from(
        json['shortcuts'] as Map? ?? _defaultShortcuts,
      ),
      pinSettings: json['pinSettings'] != null
          ? PinScreenshotConfig.fromJson(
              json['pinSettings'] as Map<String, dynamic>,
            )
          : PinScreenshotConfig.defaultConfig,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'savePath': savePath,
      'filenameFormat': filenameFormat,
      'imageFormat': imageFormat,
      'imageQuality': imageQuality,
      'autoCopyToClipboard': autoCopyToClipboard,
      'showPreview': showPreview,
      'saveHistory': saveHistory,
      'maxHistoryCount': maxHistoryCount,
      'historyRetentionDays': historyRetentionDays,
      'shortcuts': shortcuts,
      'pinSettings': pinSettings.toJson(),
    };
  }

  /// 获取默认配置
  static ScreenshotConfig get defaultConfig => ScreenshotConfig(
    savePath: '{documents}/Screenshots',
    filenameFormat: 'screenshot_{timestamp}',
    imageFormat: 'png',
    imageQuality: 95,
    autoCopyToClipboard: true,
    showPreview: true,
    saveHistory: true,
    maxHistoryCount: 100,
    historyRetentionDays: 30,
    shortcuts: Map<String, String>.from(_defaultShortcuts),
    pinSettings: PinScreenshotConfig.defaultConfig,
  );

  /// 复制并修改部分配置
  ScreenshotConfig copyWith({
    String? savePath,
    String? filenameFormat,
    String? imageFormat,
    int? imageQuality,
    bool? autoCopyToClipboard,
    bool? showPreview,
    bool? saveHistory,
    int? maxHistoryCount,
    int? historyRetentionDays,
    Map<String, String>? shortcuts,
    PinScreenshotConfig? pinSettings,
  }) {
    return ScreenshotConfig(
      savePath: savePath ?? this.savePath,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      imageFormat: imageFormat ?? this.imageFormat,
      imageQuality: imageQuality ?? this.imageQuality,
      autoCopyToClipboard: autoCopyToClipboard ?? this.autoCopyToClipboard,
      showPreview: showPreview ?? this.showPreview,
      saveHistory: saveHistory ?? this.saveHistory,
      maxHistoryCount: maxHistoryCount ?? this.maxHistoryCount,
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      shortcuts: shortcuts ?? this.shortcuts,
      pinSettings: pinSettings ?? this.pinSettings,
    );
  }

  /// 验证配置是否有效
  bool isValid() {
    return savePath.isNotEmpty &&
        imageQuality >= 1 &&
        imageQuality <= 100 &&
        maxHistoryCount > 0 &&
        historyRetentionDays > 0;
  }

  /// 默认快捷键
  static const Map<String, String> _defaultShortcuts = {
    'regionCapture': 'Ctrl+Shift+A',
    'fullScreenCapture': 'Ctrl+Shift+F',
    'windowCapture': 'Ctrl+Shift+W',
    'showHistory': 'Ctrl+Shift+H',
    'showSettings': 'Ctrl+Shift+S',
  };
}

/// 钉图配置
class PinScreenshotConfig {
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

  const PinScreenshotConfig({
    required this.alwaysOnTop,
    required this.defaultOpacity,
    required this.enableDrag,
    required this.enableResize,
    required this.showCloseButton,
  });

  /// 从 JSON 创建实例
  factory PinScreenshotConfig.fromJson(Map<String, dynamic> json) {
    return PinScreenshotConfig(
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

  /// 获取默认配置
  static const defaultConfig = PinScreenshotConfig(
    alwaysOnTop: true,
    defaultOpacity: 0.9,
    enableDrag: true,
    enableResize: false,
    showCloseButton: true,
  );

  /// 复制并修改部分配置
  PinScreenshotConfig copyWith({
    bool? alwaysOnTop,
    double? defaultOpacity,
    bool? enableDrag,
    bool? enableResize,
    bool? showCloseButton,
  }) {
    return PinScreenshotConfig(
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      defaultOpacity: defaultOpacity ?? this.defaultOpacity,
      enableDrag: enableDrag ?? this.enableDrag,
      enableResize: enableResize ?? this.enableResize,
      showCloseButton: showCloseButton ?? this.showCloseButton,
    );
  }
}
