library;

import '../constants/app_version.dart' show AppVersion;

/// 全局应用配置
///
/// 包含应用的所有全局设置，从配置文件读取
class GlobalConfig {
  /// 应用配置
  final AppConfig app;

  /// 功能配置
  final FeatureConfig features;

  /// 服务配置
  final ServiceConfig services;

  /// 高级配置
  final AdvancedConfig advanced;

  const GlobalConfig({
    required this.app,
    required this.features,
    required this.services,
    required this.advanced,
  });

  /// 从 JSON 创建实例
  factory GlobalConfig.fromJson(Map<String, dynamic> json) {
    return GlobalConfig(
      app: AppConfig.fromJson(json['app'] as Map<String, dynamic>? ?? {}),
      features: FeatureConfig.fromJson(
        json['features'] as Map<String, dynamic>? ?? {},
      ),
      services: ServiceConfig.fromJson(
        json['services'] as Map<String, dynamic>? ?? {},
      ),
      advanced: AdvancedConfig.fromJson(
        json['advanced'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'app': app.toJson(),
      'features': features.toJson(),
      'services': services.toJson(),
      'advanced': advanced.toJson(),
    };
  }

  /// 获取默认配置
  static GlobalConfig get defaultConfig => GlobalConfig(
    app: AppConfig.defaultConfig,
    features: FeatureConfig.defaultConfig,
    services: ServiceConfig.defaultConfig,
    advanced: AdvancedConfig.defaultConfig,
  );

  /// 复制并修改部分配置
  GlobalConfig copyWith({
    AppConfig? app,
    FeatureConfig? features,
    ServiceConfig? services,
    AdvancedConfig? advanced,
  }) {
    return GlobalConfig(
      app: app ?? this.app,
      features: features ?? this.features,
      services: services ?? this.services,
      advanced: advanced ?? this.advanced,
    );
  }
}

/// 应用配置
class AppConfig {
  final String name;
  final String version;
  final String language;
  final String theme;
  final PluginViewMode pluginViewMode;
  final List<String> autoStartPlugins; // 自启动插件ID列表

  const AppConfig({
    required this.name,
    required this.version,
    required this.language,
    required this.theme,
    this.pluginViewMode = PluginViewMode.mediumIcon,
    this.autoStartPlugins = const [],
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    // 安全地转换 autoStartPlugins
    List<String> parseAutoStartPlugins(dynamic value) {
      if (value == null) return [];
      if (value is List<String>) return value;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return AppConfig(
      name: json['name'] as String? ?? 'Flutter Plugin Platform',
      version: json['version'] as String? ?? '0.0.0',
      language: json['language'] as String? ?? 'zh_CN',
      theme: json['theme'] as String? ?? 'system',
      pluginViewMode: _parsePluginViewMode(json['pluginViewMode'] as String?),
      autoStartPlugins: parseAutoStartPlugins(json['autoStartPlugins']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'language': language,
      'theme': theme,
      'pluginViewMode': pluginViewMode.name,
      'autoStartPlugins': autoStartPlugins,
    };
  }

  /// 复制并修改部分配置
  AppConfig copyWith({
    String? name,
    String? version,
    String? language,
    String? theme,
    PluginViewMode? pluginViewMode,
    List<String>? autoStartPlugins,
  }) {
    return AppConfig(
      name: name ?? this.name,
      version: version ?? this.version,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      pluginViewMode: pluginViewMode ?? this.pluginViewMode,
      autoStartPlugins: autoStartPlugins ?? this.autoStartPlugins,
    );
  }

  static const defaultConfig = AppConfig(
    name: AppVersion.appName,
    version: AppVersion.version,
    language: 'zh_CN',
    theme: 'system',
    pluginViewMode: PluginViewMode.mediumIcon,
    autoStartPlugins: [],
  );

  /// 解析插件视图模式
  static PluginViewMode _parsePluginViewMode(String? value) {
    if (value == null) return PluginViewMode.mediumIcon;
    return PluginViewMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PluginViewMode.mediumIcon,
    );
  }
}

/// 功能配置
class FeatureConfig {
  final bool autoStart;
  final bool minimizeToTray;
  final bool showDesktopPet;
  final bool enableNotifications;
  final DesktopPetConfig desktopPet;

  const FeatureConfig({
    required this.autoStart,
    required this.minimizeToTray,
    required this.showDesktopPet,
    required this.enableNotifications,
    required this.desktopPet,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) {
    return FeatureConfig(
      autoStart: json['autoStart'] as bool? ?? false,
      minimizeToTray: json['minimizeToTray'] as bool? ?? true,
      showDesktopPet: json['showDesktopPet'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      desktopPet: DesktopPetConfig.fromJson(
        json['desktopPet'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'minimizeToTray': minimizeToTray,
      'showDesktopPet': showDesktopPet,
      'enableNotifications': enableNotifications,
      'desktopPet': desktopPet.toJson(),
    };
  }

  /// 复制并修改部分配置
  FeatureConfig copyWith({
    bool? autoStart,
    bool? minimizeToTray,
    bool? showDesktopPet,
    bool? enableNotifications,
    DesktopPetConfig? desktopPet,
  }) {
    return FeatureConfig(
      autoStart: autoStart ?? this.autoStart,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      showDesktopPet: showDesktopPet ?? this.showDesktopPet,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      desktopPet: desktopPet ?? this.desktopPet,
    );
  }

  static const defaultConfig = FeatureConfig(
    autoStart: false,
    minimizeToTray: true,
    showDesktopPet: true,
    enableNotifications: true,
    desktopPet: DesktopPetConfig.defaultConfig,
  );
}

/// 桌面宠物配置
class DesktopPetConfig {
  /// 透明度 (0.3-1.0)
  final double opacity;

  /// 启用动画（呼吸和眨眼效果）
  final bool animationsEnabled;

  /// 启用交互（点击和拖拽）
  final bool interactionsEnabled;

  const DesktopPetConfig({
    required this.opacity,
    required this.animationsEnabled,
    required this.interactionsEnabled,
  });

  factory DesktopPetConfig.fromJson(Map<String, dynamic> json) {
    return DesktopPetConfig(
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      animationsEnabled: json['animations_enabled'] as bool? ?? true,
      interactionsEnabled: json['interactions_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opacity': opacity,
      'animations_enabled': animationsEnabled,
      'interactions_enabled': interactionsEnabled,
    };
  }

  /// 复制并修改部分配置
  DesktopPetConfig copyWith({
    double? opacity,
    bool? animationsEnabled,
    bool? interactionsEnabled,
  }) {
    return DesktopPetConfig(
      opacity: opacity ?? this.opacity,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      interactionsEnabled: interactionsEnabled ?? this.interactionsEnabled,
    );
  }

  /// 转换为 preferences Map（用于 DesktopPetWidget）
  Map<String, dynamic> toPreferencesMap() {
    return {
      'opacity': opacity,
      'animations_enabled': animationsEnabled,
      'interactions_enabled': interactionsEnabled,
    };
  }

  static const defaultConfig = DesktopPetConfig(
    opacity: 1.0,
    animationsEnabled: true,
    interactionsEnabled: true,
  );

  /// 验证配置是否有效
  bool isValid() {
    return opacity >= 0.3 && opacity <= 1.0;
  }
}

/// 服务配置
class ServiceConfig {
  final AudioServiceConfig audio;
  final NotificationServiceConfig notification;
  final TaskSchedulerServiceConfig taskScheduler;

  const ServiceConfig({
    required this.audio,
    required this.notification,
    required this.taskScheduler,
  });

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      audio: AudioServiceConfig.fromJson(
        json['audio'] as Map<String, dynamic>? ?? {},
      ),
      notification: NotificationServiceConfig.fromJson(
        json['notification'] as Map<String, dynamic>? ?? {},
      ),
      taskScheduler: TaskSchedulerServiceConfig.fromJson(
        json['taskScheduler'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio': audio.toJson(),
      'notification': notification.toJson(),
      'taskScheduler': taskScheduler.toJson(),
    };
  }

  ServiceConfig copyWith({
    AudioServiceConfig? audio,
    NotificationServiceConfig? notification,
    TaskSchedulerServiceConfig? taskScheduler,
  }) {
    return ServiceConfig(
      audio: audio ?? this.audio,
      notification: notification ?? this.notification,
      taskScheduler: taskScheduler ?? this.taskScheduler,
    );
  }

  static const defaultConfig = ServiceConfig(
    audio: AudioServiceConfig.defaultConfig,
    notification: NotificationServiceConfig.defaultConfig,
    taskScheduler: TaskSchedulerServiceConfig.defaultConfig,
  );
}

/// 音频服务配置
class AudioServiceConfig {
  final bool enabled;

  const AudioServiceConfig({required this.enabled});

  factory AudioServiceConfig.fromJson(Map<String, dynamic> json) {
    return AudioServiceConfig(enabled: json['enabled'] as bool? ?? true);
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled};
  }

  static const defaultConfig = AudioServiceConfig(enabled: true);
}

/// 通知模式枚举
enum NotificationMode {
  /// App 内部通知（使用 Flutter LocalNotifications）
  app,

  /// 系统级通知（Windows 使用 local_notifier，其他平台使用系统通知）
  system,
}

/// 通知服务配置
class NotificationServiceConfig {
  final bool enabled;
  final NotificationMode mode;

  const NotificationServiceConfig({
    required this.enabled,
    this.mode = NotificationMode.system,
  });

  factory NotificationServiceConfig.fromJson(Map<String, dynamic> json) {
    return NotificationServiceConfig(
      enabled: json['enabled'] as bool? ?? true,
      mode: json['mode'] == 'app'
          ? NotificationMode.app
          : NotificationMode.system,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'mode': mode.name,
    };
  }

  NotificationServiceConfig copyWith({
    bool? enabled,
    NotificationMode? mode,
  }) {
    return NotificationServiceConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
    );
  }

  static const defaultConfig = NotificationServiceConfig(
    enabled: true,
    mode: NotificationMode.system,
  );
}

/// 任务调度服务配置
class TaskSchedulerServiceConfig {
  final bool enabled;

  const TaskSchedulerServiceConfig({required this.enabled});

  factory TaskSchedulerServiceConfig.fromJson(Map<String, dynamic> json) {
    return TaskSchedulerServiceConfig(
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled};
  }

  static const defaultConfig = TaskSchedulerServiceConfig(enabled: true);
}

/// 插件视图模式枚举
enum PluginViewMode {
  largeIcon, // 大图标
  mediumIcon, // 中图标（默认）
  smallIcon, // 小图标
  list, // 列表
}

/// 高级配置
class AdvancedConfig {
  final bool debugMode;
  final String logLevel;
  final int maxLogFileSize;

  const AdvancedConfig({
    required this.debugMode,
    required this.logLevel,
    required this.maxLogFileSize,
  });

  factory AdvancedConfig.fromJson(Map<String, dynamic> json) {
    return AdvancedConfig(
      debugMode: json['debugMode'] as bool? ?? false,
      logLevel: json['logLevel'] as String? ?? 'info',
      maxLogFileSize: json['maxLogFileSize'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debugMode': debugMode,
      'logLevel': logLevel,
      'maxLogFileSize': maxLogFileSize,
    };
  }

  /// 复制并修改部分配置
  AdvancedConfig copyWith({
    bool? debugMode,
    String? logLevel,
    int? maxLogFileSize,
  }) {
    return AdvancedConfig(
      debugMode: debugMode ?? this.debugMode,
      logLevel: logLevel ?? this.logLevel,
      maxLogFileSize: maxLogFileSize ?? this.maxLogFileSize,
    );
  }

  static const defaultConfig = AdvancedConfig(
    debugMode: false,
    logLevel: 'info',
    maxLogFileSize: 10,
  );
}
