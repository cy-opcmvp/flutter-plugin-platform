/// 截图插件宿主接线（F4-05）。
///
/// 截图包自身零 l10n 配置：宿主经 [screenshotStrings] 把 `shot*` 文案
/// （宿主 arb）映射为插件包定义的 [ScreenshotStrings] 载体，再由
/// [hostScreenshotStringsResolver] 在构建上下文时解析当前语言注入
/// 页面/设置提供方（与计算器接线同模式）。
library;

import 'package:flutter/widgets.dart';
import 'package:screenshot/screenshot.dart';

import '../generated/host_l10n.dart';

/// 把宿主 l10n 的截图文案映射为插件文案载体（字段一一对应）。
ScreenshotStrings screenshotStrings(HostL10n l10n) {
  return ScreenshotStrings(
    captureButton: l10n.shotCaptureButton,
    capturing: l10n.shotCapturing,
    resultTitle: l10n.shotResultTitle,
    savedHint: l10n.shotSavedHint,
    failureTitle: l10n.shotFailureTitle,
    settingsFormTitle: l10n.shotSettingsFormTitle,
    settingsSaveDir: l10n.shotSettingsSaveDir,
    saveDirPictures: l10n.shotSaveDirPictures,
    saveDirDocuments: l10n.shotSaveDirDocuments,
    saveDirPluginData: l10n.shotSaveDirPluginData,
    settingsFilenameTemplate: l10n.shotSettingsFilenameTemplate,
    settingsFilenameTemplatePlaceholder:
        l10n.shotSettingsFilenameTemplatePlaceholder,
    settingsFormat: l10n.shotSettingsFormat,
    formatPng: l10n.shotFormatPng,
    formatJpeg: l10n.shotFormatJpeg,
    settingsJpegQuality: l10n.shotSettingsJpegQuality,
    settingsAutoCopy: l10n.shotSettingsAutoCopy,
    autoCopyNone: l10n.shotAutoCopyNone,
    autoCopyImage: l10n.shotAutoCopyImage,
    autoCopyPath: l10n.shotAutoCopyPath,
    formatNote: l10n.shotFormatNote,
    fieldPath: l10n.shotFieldPath,
    fieldSize: l10n.shotFieldSize,
    fieldCopied: l10n.shotFieldCopied,
    copiedNone: l10n.shotCopiedNone,
    copiedImage: l10n.shotCopiedImage,
    copiedPath: l10n.shotCopiedPath,
    copiedFailed: l10n.shotCopiedFailed,
    regionButton: l10n.shotRegionButton,
    settingsHotkey: l10n.shotSettingsHotkey,
    hotkeyNote: l10n.shotHotkeyNote,
    hotkeyFailedHint: l10n.shotHotkeyFailedHint,
    regionCopiedHint: l10n.shotRegionCopiedHint,
    regionSelectorSave: l10n.regionSelectorSave,
    regionSelectorCopy: l10n.regionSelectorCopy,
    regionSelectorDiscard: l10n.regionSelectorDiscard,
    regionSelectorHint: l10n.regionSelectorHint,
  );
}

/// 构建宿主文案解析器：从上下文取宿主 l10n 再映射为插件载体。
ScreenshotStringsResolver hostScreenshotStringsResolver() {
  ScreenshotStrings resolve(BuildContext context) {
    return screenshotStrings(HostL10n.of(context));
  }

  return resolve;
}
