/// 截图插件清单的 Dart 构建器（与 `plugin.json` 逐字段一致）。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 截图插件反向域 ID。
const String kScreenshotPluginId = 'tools.screenshot';

/// 截图能力 ID：主屏图像捕获。
const String kScreenshotCapabilityCapture = 'image.capture';

/// 构建截图插件清单（内置实现，仅声明 Windows 目标）。
PluginManifest screenshotManifest() {
  return PluginManifest(
    id: PluginId.parse(kScreenshotPluginId),
    name: '截图',
    version: '1.0.0',
    apiVersion: 1,
    kind: PluginKind.builtin,
    targets: const <PluginTarget>[PluginTarget.windows],
    entrypoint: 'builtin://$kScreenshotPluginId',
    provides: <CapabilityDescriptor>[
      CapabilityDescriptor(kScreenshotCapabilityCapture, 1),
    ],
    requires: const <CapabilityRequirement>[],
    surfaces: const <String>['page', 'settings'],
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}
