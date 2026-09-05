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
    settingsFilenamePrefix: l10n.shotSettingsFilenamePrefix,
    settingsFilenamePrefixPlaceholder:
        l10n.shotSettingsFilenamePrefixPlaceholder,
    settingsQuality: l10n.shotSettingsQuality,
    qualityLossless: l10n.shotQualityLossless,
    qualityHigh: l10n.shotQualityHigh,
    qualityStandard: l10n.shotQualityStandard,
    qualityNote: l10n.shotQualityNote,
  );
}

/// 构建宿主文案解析器：从上下文取宿主 l10n 再映射为插件载体。
ScreenshotStringsResolver hostScreenshotStringsResolver() {
  ScreenshotStrings resolve(BuildContext context) {
    return screenshotStrings(HostL10n.of(context));
  }

  return resolve;
}
