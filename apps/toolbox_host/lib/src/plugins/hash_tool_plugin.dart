/// hash_tool Sidecar 插件宿主接线（F4-06）。
///
/// 样本包 `sidecars/python_sample/plugin.json` 面向 CLI validate 与 .scp
/// 分发；宿主内存组装根经本文件取等价的 [PluginManifest]（MVP 决策：
/// 静态清单常量注册，动态目录发现留 M5）。两者字段必须逐一致。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

import '../generated/host_l10n.dart';
import '../sidecar_command_bridge.dart';

/// hash_tool 插件 ID 字符串（与样本清单逐字一致）。
const String kHashToolPluginId = 'tools.hashtool';

/// hash_tool 提供的能力 ID（命令面唯一命令）。
const String kHashToolCapabilityCompute = 'hash.compute';

/// 样本包内入口脚本文件名（清单 entrypoint）。
const String kHashToolEntrypointFileName = 'hash_tool.py';

/// 构建 hash_tool 插件清单（镜像 `plugin.json`）。
PluginManifest hashToolManifest() {
  return PluginManifest(
    id: PluginId.parse(kHashToolPluginId),
    name: 'Hash 工具',
    version: '1.0.0',
    apiVersion: 1,
    kind: PluginKind.sidecar,
    targets: const <PluginTarget>[PluginTarget.windows],
    entrypoint: kHashToolEntrypointFileName,
    provides: <CapabilityDescriptor>[
      CapabilityDescriptor(kHashToolCapabilityCompute, 1),
    ],
    requires: const <CapabilityRequirement>[],
    surfaces: const <String>['command'],
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}

/// 把宿主 l10n 的 hash 文案映射为桥文案载体（字段一一对应）。
HashToolStrings hashToolStrings(HostL10n l10n) {
  return HashToolStrings(
    formTitle: l10n.hashFormTitle,
    textLabel: l10n.hashTextLabel,
    textPlaceholder: l10n.hashTextPlaceholder,
    md5Label: l10n.hashMd5Label,
    sha1Label: l10n.hashSha1Label,
    sha256Label: l10n.hashSha256Label,
  );
}
