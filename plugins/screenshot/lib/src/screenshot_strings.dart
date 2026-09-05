/// 截图插件文案载体与解析器签名。
///
/// 插件包零 l10n 配置：宿主按当前语言从系统 arb 翻译构造
/// [ScreenshotStrings]，页面与设置只消费载体。
library;

import 'package:flutter/widgets.dart';

/// 截图文案载体（全部必填，杜绝缺翻译时的空文案）。
final class ScreenshotStrings {
  /// 创建文案载体。
  const ScreenshotStrings({
    required this.captureButton,
    required this.capturing,
    required this.resultTitle,
    required this.savedHint,
    required this.failureTitle,
    required this.settingsFormTitle,
    required this.settingsFilenamePrefix,
    required this.settingsFilenamePrefixPlaceholder,
    required this.settingsQuality,
    required this.qualityLossless,
    required this.qualityHigh,
    required this.qualityStandard,
    required this.qualityNote,
  });

  /// 捕获按钮文案。
  final String captureButton;

  /// 捕获进行中的按钮文案。
  final String capturing;

  /// 结果区标题。
  final String resultTitle;

  /// 保存成功提示（含完整落盘路径）。
  final String Function(String path) savedHint;

  /// 捕获失败提示标题（正文为结构化失败的 message）。
  final String failureTitle;

  /// 设置表单标题。
  final String settingsFormTitle;

  /// 文件名前缀字段标签。
  final String settingsFilenamePrefix;

  /// 文件名前缀占位符。
  final String settingsFilenamePrefixPlaceholder;

  /// 保存质量字段标签。
  final String settingsQuality;

  /// 质量选项：无损（默认）。
  final String qualityLossless;

  /// 质量选项：高。
  final String qualityHigh;

  /// 质量选项：标准。
  final String qualityStandard;

  /// 质量说明（PNG 无损预留说明）。
  final String qualityNote;
}

/// 文案解析器签名：宿主从 `AppLocalizations.of(context)` 构造载体。
typedef ScreenshotStringsResolver =
    ScreenshotStrings Function(BuildContext context);

/// 质量稳定键 → 展示文案（未知键回退无损）。
String screenshotQualityLabel(ScreenshotStrings strings, String key) {
  return switch (key) {
    'high' => strings.qualityHigh,
    'standard' => strings.qualityStandard,
    _ => strings.qualityLossless,
  };
}

/// 展示文案 → 质量稳定键（未匹配回退无损）。
String screenshotQualityKey(ScreenshotStrings strings, String label) {
  if (label == strings.qualityHigh) {
    return 'high';
  }
  if (label == strings.qualityStandard) {
    return 'standard';
  }
  return 'lossless';
}
