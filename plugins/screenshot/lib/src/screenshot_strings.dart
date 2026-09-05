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
    required this.settingsSaveDir,
    required this.saveDirPictures,
    required this.saveDirDocuments,
    required this.saveDirPluginData,
    required this.settingsFilenameTemplate,
    required this.settingsFilenameTemplatePlaceholder,
    required this.settingsFormat,
    required this.formatPng,
    required this.formatJpeg,
    required this.settingsJpegQuality,
    required this.settingsAutoCopy,
    required this.autoCopyNone,
    required this.autoCopyImage,
    required this.autoCopyPath,
    required this.formatNote,
    required this.fieldPath,
    required this.fieldSize,
    required this.fieldCopied,
    required this.copiedNone,
    required this.copiedImage,
    required this.copiedPath,
    required this.copiedFailed,
    required this.regionButton,
    required this.settingsHotkey,
    required this.hotkeyNote,
    required this.hotkeyFailedHint,
    required this.regionCopiedHint,
    required this.regionSelectorSave,
    required this.regionSelectorCopy,
    required this.regionSelectorDiscard,
    required this.regionSelectorHint,
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

  /// 保存目录字段标签。
  final String settingsSaveDir;

  /// 保存目录选项：系统图片目录。
  final String saveDirPictures;

  /// 保存目录选项：系统文档目录。
  final String saveDirDocuments;

  /// 保存目录选项：插件数据目录。
  final String saveDirPluginData;

  /// 文件名模板字段标签。
  final String settingsFilenameTemplate;

  /// 文件名模板占位符。
  final String settingsFilenameTemplatePlaceholder;

  /// 保存格式字段标签。
  final String settingsFormat;

  /// 格式选项：PNG（无损）。
  final String formatPng;

  /// 格式选项：JPEG（按质量压缩）。
  final String formatJpeg;

  /// JPEG 质量字段标签。
  final String settingsJpegQuality;

  /// 自动复制字段标签。
  final String settingsAutoCopy;

  /// 自动复制选项：不复制。
  final String autoCopyNone;

  /// 自动复制选项：复制图像。
  final String autoCopyImage;

  /// 自动复制选项：复制文件路径。
  final String autoCopyPath;

  /// 格式与目录说明。
  final String formatNote;

  /// 结果字段标签：保存路径。
  final String fieldPath;

  /// 结果字段标签：图像尺寸。
  final String fieldSize;

  /// 结果字段标签：自动复制。
  final String fieldCopied;

  /// 复制结果文案：未复制。
  final String copiedNone;

  /// 复制结果文案：已复制图像。
  final String copiedImage;

  /// 复制结果文案：已复制文件路径。
  final String copiedPath;

  /// 复制结果文案：复制失败。
  final String copiedFailed;

  /// 区域截图按钮文案（S1 批C）。
  final String regionButton;

  /// 全局热键字段标签。
  final String settingsHotkey;

  /// 热键说明（注册成功/失败的表现提示）。
  final String hotkeyNote;

  /// 热键注册失败提示（正文为失败 message）。
  final String hotkeyFailedHint;

  /// 区域截图「仅复制」成功提示。
  final String regionCopiedHint;

  /// overlay 工具条：保存。
  final String regionSelectorSave;

  /// overlay 工具条：复制。
  final String regionSelectorCopy;

  /// overlay 工具条：放弃。
  final String regionSelectorDiscard;

  /// overlay 操作提示（框选/ESC/Enter）。
  final String regionSelectorHint;
}

/// 文案解析器签名：宿主从 `AppLocalizations.of(context)` 构造载体。
typedef ScreenshotStringsResolver =
    ScreenshotStrings Function(BuildContext context);

/// 保存目录稳定键 → 展示文案（未知键回退插件数据目录）。
String screenshotSaveDirLabel(ScreenshotStrings strings, String key) {
  return switch (key) {
    '{pictures}' => strings.saveDirPictures,
    '{documents}' => strings.saveDirDocuments,
    _ => strings.saveDirPluginData,
  };
}

/// 展示文案 → 保存目录稳定键（未匹配回退插件数据目录）。
String screenshotSaveDirKey(ScreenshotStrings strings, String label) {
  if (label == strings.saveDirPictures) {
    return '{pictures}';
  }
  if (label == strings.saveDirDocuments) {
    return '{documents}';
  }
  return '{pluginData}';
}

/// 保存格式稳定键 → 展示文案（未知键回退 PNG）。
String screenshotFormatLabel(ScreenshotStrings strings, String key) {
  return key == 'jpeg' ? strings.formatJpeg : strings.formatPng;
}

/// 展示文案 → 保存格式稳定键（未匹配回退 PNG）。
String screenshotFormatKey(ScreenshotStrings strings, String label) {
  return label == strings.formatJpeg ? 'jpeg' : 'png';
}

/// 自动复制稳定键 → 展示文案（未知键回退不复制）。
String screenshotAutoCopyLabel(ScreenshotStrings strings, String key) {
  return switch (key) {
    'image' => strings.autoCopyImage,
    'path' => strings.autoCopyPath,
    _ => strings.autoCopyNone,
  };
}

/// 展示文案 → 自动复制稳定键（未匹配回退不复制）。
String screenshotAutoCopyKey(ScreenshotStrings strings, String label) {
  if (label == strings.autoCopyImage) {
    return 'image';
  }
  if (label == strings.autoCopyPath) {
    return 'path';
  }
  return 'none';
}

/// 自动复制结果稳定键（none/image/path/failed）→ 展示文案。
String screenshotCopyStatusLabel(ScreenshotStrings strings, String copyKey) {
  return switch (copyKey) {
    'image' => strings.copiedImage,
    'path' => strings.copiedPath,
    'failed' => strings.copiedFailed,
    _ => strings.copiedNone,
  };
}
