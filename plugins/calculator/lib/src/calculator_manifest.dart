/// 计算器插件清单的 Dart 构建器（镜像 `plugin.json`）。
///
/// plugin.json 面向 CLI validate 与包目录分发；宿主内存组装根经本文件
/// 取等价的 [PluginManifest]。两者字段必须逐一致（由宿主一致性测试固化）。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 计算器插件 ID 字符串。
const String kCalculatorPluginId = 'tools.calculator';

/// 计算器提供的能力 ID。
const String kCalculatorCapabilityEvaluate = 'calc.evaluate';

/// 构建计算器插件清单。
PluginManifest calculatorManifest() {
  return PluginManifest(
    id: PluginId.parse(kCalculatorPluginId),
    name: '计算器',
    version: '1.0.0',
    apiVersion: 1,
    kind: PluginKind.builtin,
    targets: const <PluginTarget>[
      PluginTarget.windows,
      PluginTarget.macos,
      PluginTarget.linux,
      PluginTarget.android,
      PluginTarget.ios,
      PluginTarget.web,
    ],
    entrypoint: 'builtin://tools.calculator',
    provides: <CapabilityDescriptor>[
      CapabilityDescriptor(kCalculatorCapabilityEvaluate, 1),
    ],
    requires: const <CapabilityRequirement>[],
    surfaces: const <String>['page', 'settings'],
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}
