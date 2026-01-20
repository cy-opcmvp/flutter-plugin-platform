library;

import '../../../core/models/base_plugin_settings.dart';

/// 计算器设置模型
class CalculatorSettings extends BasePluginSettings {
  /// 配置版本
  @override
  final String version;

  /// 计算精度（小数位数）
  final int precision;

  /// 角度模式 (deg/rad)
  final String angleMode;

  /// 历史记录大小
  final int historySize;

  /// 内存槽位数量
  final int memorySlots;

  /// 显示千分位分隔符
  final bool showGroupingSeparator;

  /// 启用振动反馈
  final bool enableVibration;

  /// 按钮声音音量 (0-100)
  final int buttonSoundVolume;

  CalculatorSettings({
    this.version = '1.0.0',
    required this.precision,
    required this.angleMode,
    required this.historySize,
    required this.memorySlots,
    required this.showGroupingSeparator,
    required this.enableVibration,
    required this.buttonSoundVolume,
  });

  /// 默认设置
  factory CalculatorSettings.defaultSettings() {
    return CalculatorSettings(
      version: '1.0.0',
      precision: 10,
      angleMode: 'deg',
      historySize: 50,
      memorySlots: 10,
      showGroupingSeparator: true,
      enableVibration: true,
      buttonSoundVolume: 50,
    );
  }

  /// 从 JSON 创建实例
  factory CalculatorSettings.fromJson(Map<String, dynamic> json) {
    return CalculatorSettings(
      version: json['version'] as String? ?? '1.0.0',
      precision: json['precision'] as int? ?? 10,
      angleMode: json['angleMode'] as String? ?? 'deg',
      historySize: json['historySize'] as int? ?? 50,
      memorySlots: json['memorySlots'] as int? ?? 10,
      showGroupingSeparator: json['showGroupingSeparator'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      buttonSoundVolume: json['buttonSoundVolume'] as int? ?? 50,
    );
  }

  /// 转换为 JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'precision': precision,
      'angleMode': angleMode,
      'historySize': historySize,
      'memorySlots': memorySlots,
      'showGroupingSeparator': showGroupingSeparator,
      'enableVibration': enableVibration,
      'buttonSoundVolume': buttonSoundVolume,
    };
  }

  /// 复制并修改部分设置
  @override
  CalculatorSettings copyWith({
    String? version,
    int? precision,
    String? angleMode,
    int? historySize,
    int? memorySlots,
    bool? showGroupingSeparator,
    bool? enableVibration,
    int? buttonSoundVolume,
  }) {
    return CalculatorSettings(
      version: version ?? this.version,
      precision: precision ?? this.precision,
      angleMode: angleMode ?? this.angleMode,
      historySize: historySize ?? this.historySize,
      memorySlots: memorySlots ?? this.memorySlots,
      showGroupingSeparator: showGroupingSeparator ?? this.showGroupingSeparator,
      enableVibration: enableVibration ?? this.enableVibration,
      buttonSoundVolume: buttonSoundVolume ?? this.buttonSoundVolume,
    );
  }

  /// 验证设置是否有效
  @override
  bool isValid() {
    if (precision < 0 || precision > 15) return false;
    if (!['deg', 'rad'].contains(angleMode)) return false;
    if (historySize < 10 || historySize > 500) return false;
    if (memorySlots < 1 || memorySlots > 20) return false;
    if (buttonSoundVolume < 0 || buttonSoundVolume > 100) return false;
    return true;
  }
}
