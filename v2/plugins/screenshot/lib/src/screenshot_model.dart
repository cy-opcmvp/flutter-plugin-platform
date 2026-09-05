/// 截图运行设置与状态模型。
///
/// 模型只存稳定键与原始输入；展示文案由宿主注入的文案载体渲染，
/// 插件包自身零 l10n 配置。
library;

import 'package:flutter/foundation.dart';

/// 保存质量的稳定键集合（下拉展示文案经文案载体映射）。
///
/// `lossless` 对应 PNG 无损保存；`high`/`standard` 为预留给未来
/// 有损编码的稳定键，当前实现一律以 PNG 原图保存。
const List<String> kScreenshotQualityKeys = <String>[
  'lossless',
  'high',
  'standard',
];

/// 默认文件名前缀。
const String kScreenshotDefaultFilenamePrefix = 'shot';

/// 截图运行设置。
final class ScreenshotSettings {
  /// 创建设置；[filenamePrefix] 非空白，[quality] 必须为稳定键之一。
  ///
  /// 断言依赖 `trim()`/`contains()` 等方法调用，无法声明为 const 构造。
  ScreenshotSettings({
    this.filenamePrefix = kScreenshotDefaultFilenamePrefix,
    this.quality = 'lossless',
  }) : assert(filenamePrefix.trim().isNotEmpty, 'filenamePrefix 不能为空白'),
       assert(kScreenshotQualityKeys.contains(quality), 'quality 必须为稳定键');

  /// 保存文件名前缀（实际文件名为 `{prefix}-{时间戳}.png`）。
  final String filenamePrefix;

  /// 保存质量稳定键（见 [kScreenshotQualityKeys]）。
  final String quality;

  /// 复制并按需覆盖部分字段（传 null 表示保留原值）。
  ScreenshotSettings copyWith({String? filenamePrefix, String? quality}) {
    return ScreenshotSettings(
      filenamePrefix: filenamePrefix ?? this.filenamePrefix,
      quality: quality ?? this.quality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotSettings &&
          filenamePrefix == other.filenamePrefix &&
          quality == other.quality;

  @override
  int get hashCode => Object.hash(filenamePrefix, quality);
}

/// 截图状态模型：当前设置（可变），UI 经 ListenableBuilder 订阅。
class ScreenshotModel extends ChangeNotifier {
  /// 创建模型；[settings] 缺省取默认设置。
  ScreenshotModel({ScreenshotSettings? settings})
    : _settings = settings ?? ScreenshotSettings();

  ScreenshotSettings _settings;

  /// 当前设置。
  ScreenshotSettings get settings => _settings;

  /// 更新设置并通知监听者。
  void updateSettings(ScreenshotSettings settings) {
    _settings = settings;
    notifyListeners();
  }
}
