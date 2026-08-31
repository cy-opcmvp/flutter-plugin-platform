# Plugin Platform v2 Core Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建不依赖 Flutter 和具体平台包的插件契约、生命周期运行时、能力解析器与开发测试工具。

**Architecture:** 在 `v2/` 下创建独立 Dart workspace。`plugin_contracts` 只定义稳定值对象、清单和接口；`plugin_runtime` 实现状态机、注册和能力解析；`plugin_devkit` 提供契约测试夹具。真实插件和 Flutter 宿主不进入本阶段。

**Tech Stack:** Dart 3.10、Dart workspace、`package:test`、`package:lints`，不引入 Flutter SDK。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`

## Global Constraints

- 本阶段不得导入 Flutter、`dart:ffi`、`win32` 或平台插件。
- 本阶段不得迁移计算器、截图、世界时钟、拼图或桌面宠物。
- 公共 API 由 Sol xhigh 实现，独立 Sol xhigh 验收。
- 实现与验收串行；同时最多运行一个子智能体。
- 每个任务遵循测试先行：失败测试、最小实现、通过验证。
- 每个任务开始和结束都更新 progress.yaml。
- AI 不执行 Git 命令。

---

## 文件结构

```text
v2/
  pubspec.yaml                              # workspace 成员和 SDK 下限
  analysis_options.yaml                     # 统一 lint
  packages/plugin_contracts/
    pubspec.yaml
    lib/plugin_contracts.dart               # 公共导出
    lib/src/identity/plugin_id.dart
    lib/src/manifest/plugin_manifest.dart
    lib/src/manifest/plugin_manifest_codec.dart
    lib/src/manifest/plugin_target.dart
    lib/src/capability/capability_descriptor.dart
    lib/src/lifecycle/plugin_lifecycle.dart
    lib/src/errors/plugin_failure.dart
    test/identity/plugin_id_test.dart
    test/manifest/plugin_manifest_codec_test.dart
    test/capability/capability_descriptor_test.dart
  packages/plugin_runtime/
    pubspec.yaml
    lib/plugin_runtime.dart
    lib/src/lifecycle/lifecycle_machine.dart
    lib/src/registry/plugin_registration.dart
    lib/src/registry/plugin_registry.dart
    lib/src/capability/capability_catalog.dart
    lib/src/resolution/plugin_resolver.dart
    test/lifecycle/lifecycle_machine_test.dart
    test/registry/plugin_registry_test.dart
    test/capability/capability_catalog_test.dart
    test/resolution/plugin_resolver_test.dart
  packages/plugin_devkit/
    pubspec.yaml
    lib/plugin_devkit.dart
    lib/src/fakes/fake_plugin.dart
    lib/src/matchers/plugin_failure_matcher.dart
    test/fakes/fake_plugin_test.dart
```

## Task F1-01：创建独立 Dart workspace

**Files:**

- Create: `v2/pubspec.yaml`
- Create: `v2/analysis_options.yaml`
- Create: `v2/packages/plugin_contracts/pubspec.yaml`
- Create: `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- Create: `v2/packages/plugin_runtime/pubspec.yaml`
- Create: `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- Create: `v2/packages/plugin_devkit/pubspec.yaml`
- Create: `v2/packages/plugin_devkit/lib/plugin_devkit.dart`

**Interfaces:**

- Produces: 三个能被 workspace 解析的 Dart package。
- Consumes: Dart SDK `^3.10.0`。

- [ ] **Step 1：把 F1-01 标记为 in_progress**

在 progress.yaml 中记录目标、文件范围、Sol xhigh 实现者和验证命令 `dart pub workspace list`。

- [ ] **Step 2：创建 workspace 根配置**

`v2/pubspec.yaml` 使用以下内容：

```yaml
name: plugin_platform_v2_workspace
publish_to: none
environment:
  sdk: ^3.10.0
workspace:
  - packages/plugin_contracts
  - packages/plugin_runtime
  - packages/plugin_devkit
```

`v2/analysis_options.yaml` 使用 `package:lints/recommended.yaml`，并启用 `strict-casts`、`strict-inference`、`strict-raw-types`。

- [ ] **Step 3：创建三个 package pubspec**

共同要求：

```yaml
publish_to: none
resolution: workspace
environment:
  sdk: ^3.10.0
```

`plugin_contracts` 只添加 `lints` 和 `test` 开发依赖；`plugin_runtime` 依赖 `plugin_contracts`；`plugin_devkit` 依赖前两个 package。

- [ ] **Step 4：运行 workspace 解析**

Working directory: `v2`

Run: `dart pub get`

Expected: 依赖解析成功，无 Flutter 依赖。

Run: `dart pub workspace list`

Expected: 列出三个 package。

- [ ] **Step 5：运行空包静态分析**

Working directory: `v2`

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 6：记录检查点**

将任务状态改为 `verified_pending_acceptance`，记录命令、退出码和建议提交信息 `feat(core): scaffold v2 dart workspace`。

## Task F1-02：实现 PluginId 与结构化错误

**Files:**

- Create: `v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart`
- Create: `v2/packages/plugin_contracts/lib/src/errors/plugin_failure.dart`
- Create: `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart`
- Modify: `v2/packages/plugin_contracts/lib/plugin_contracts.dart`

**Interfaces:**

- Produces: `PluginId.parse(String)`、`PluginId.tryParse(String)`、`PluginFailure(code, message, details)`。
- Consumes: 无项目内部依赖。

- [ ] **Step 1：写入任务卡**

将 F1-02 标记为 `in_progress`，限定只修改上述四个文件。

- [ ] **Step 2：编写 PluginId 失败测试**

测试必须覆盖：

```dart
expect(PluginId.parse('tools.calculator').value, 'tools.calculator');
expect(() => PluginId.parse('../escape'), throwsFormatException);
expect(() => PluginId.parse('Tools.Calculator'), throwsFormatException);
expect(() => PluginId.parse('single'), throwsFormatException);
expect(PluginId.tryParse('tools.clock'), isNotNull);
expect(PluginId.tryParse('bad/path'), isNull);
```

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_contracts`

Run: `dart test test/identity/plugin_id_test.dart`

Expected: 因 `PluginId` 尚不存在而失败。

- [ ] **Step 4：实现最小值对象**

`PluginId` 必须不可变，基于值实现相等和 hashCode，正则固定为：

```dart
RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$')
```

`PluginFailure` 包含稳定 `code`、可读 `message` 和不可变 `Map<String, Object?> details`。

- [ ] **Step 5：运行测试和分析**

Working directory: `v2/packages/plugin_contracts`

Run: `dart test test/identity/plugin_id_test.dart`

Expected: PASS。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 6：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(core): add validated plugin identity`。

## Task F1-03：实现清单模型和严格解码

**Files:**

- Create: `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart`
- Create: `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart`
- Create: `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
- Create: `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart`
- Create: `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
- Create: `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart`
- Modify: `v2/packages/plugin_contracts/lib/plugin_contracts.dart`

**Interfaces:**

- Produces: `PluginManifestCodec.decode(Map<String, Object?>)`、`PluginManifestCodec.encode(PluginManifest)`。
- Produces: `PluginTarget`、`PluginKind`、`CapabilityDescriptor`、`CapabilityRequirement`。
- Consumes: `PluginId`、`PluginFailure`。

- [ ] **Step 1：写入任务卡**

将 F1-03 标记为 `in_progress`，记录清单字段和错误码是公共契约。

- [ ] **Step 2：编写严格解码失败测试**

最小有效清单：

```dart
final json = <String, Object?>{
  'id': 'tools.calculator',
  'name': 'Calculator',
  'version': '1.0.0',
  'apiVersion': 1,
  'kind': 'builtin',
  'targets': ['windows', 'macos', 'linux', 'android', 'ios', 'web'],
  'entrypoint': 'CalculatorPlugin',
  'provides': <Object?>[],
  'requires': <Object?>[],
  'surfaces': ['page'],
  'configSchemaVersion': 1,
  'dataSchemaVersion': 1,
};
```

测试覆盖有效往返、未知字段、缺失字段、非法 ID、空 targets、重复能力、非正整数 schema 版本和 sidecar 缺失入口。

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_contracts`

Run: `dart test test/manifest test/capability`

Expected: 因类型或 codec 尚不存在而失败。

- [ ] **Step 4：实现目标平台和能力模型**

`PluginTarget` 固定包含 `windows`、`macos`、`linux`、`android`、`ios`、`web`。能力 ID 使用与 PluginId 相同的小写分段规则，版本必须为正整数。

- [ ] **Step 5：实现清单严格解码**

解码器先检查字段集合，再逐字段验证；错误使用 `FormatException`，消息包含字段名，不包含完整用户路径或进程参数。

- [ ] **Step 6：运行测试、格式化和分析**

Working directory: `v2/packages/plugin_contracts`

Run: `dart test`

Expected: PASS。

Run: `dart format --output=none --set-exit-if-changed .`

Expected: 0。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 7：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(core): define strict plugin manifest contract`。

## Task F1-04：定义生命周期接口并实现状态机

**Files:**

- Create: `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart`
- Create: `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart`
- Create: `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`
- Modify: `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- Modify: `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

**Interfaces:**

- Produces: `PluginLifecycleState`、`PluginLifecycle`、`LifecycleMachine.transitionTo`。
- Consumes: `PluginId`、`PluginFailure`。

- [ ] **Step 1：写入任务卡**

将 F1-04 标记为 `in_progress`，记录状态转换表是唯一行为来源。

- [ ] **Step 2：编写状态机失败测试**

测试至少覆盖：

```text
discovered -> resolved -> inactive -> activating -> active
active -> deactivating -> inactive
activating -> failed
failed -> disposed
inactive -> disposed
discovered -> active 必须失败
disposed -> 任意状态必须失败
```

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test test/lifecycle/lifecycle_machine_test.dart`

Expected: 因状态机尚不存在而失败。

- [ ] **Step 4：实现生命周期契约**

`PluginLifecycle` 只暴露：

```dart
abstract interface class PluginLifecycle {
  Future<void> activate();
  Future<void> deactivate();
  Future<void> dispose();
}
```

`LifecycleMachine` 不调用插件代码，只验证并记录状态转换；非法转换返回 `PluginFailure` 结果，不抛出未分类异常。

- [ ] **Step 5：运行测试和分析**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test test/lifecycle/lifecycle_machine_test.dart`

Expected: PASS。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 6：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(runtime): add deterministic plugin lifecycle`。

## Task F1-05：实现注册表和能力目录

**Files:**

- Create: `v2/packages/plugin_runtime/lib/src/registry/plugin_registration.dart`
- Create: `v2/packages/plugin_runtime/lib/src/registry/plugin_registry.dart`
- Create: `v2/packages/plugin_runtime/lib/src/capability/capability_catalog.dart`
- Create: `v2/packages/plugin_runtime/test/registry/plugin_registry_test.dart`
- Create: `v2/packages/plugin_runtime/test/capability/capability_catalog_test.dart`
- Modify: `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

**Interfaces:**

- Produces: `PluginRegistration`、`PluginRegistry.register`、`PluginRegistry.unregister`、`CapabilityCatalog.resolve`。
- Consumes: `PluginManifest`、`PluginId`、能力描述符。

- [ ] **Step 1：写入任务卡**

将 F1-05 标记为 `in_progress`，限定不实现平台加载器和业务插件。

- [ ] **Step 2：编写注册冲突测试**

覆盖唯一 PluginId、重复注册拒绝、未知注销返回结构化失败、查询结果不可变。

- [ ] **Step 3：编写能力解析测试**

覆盖单一提供者解析、缺少能力、版本不足、重复提供者冲突和插件注销后能力同步移除。

- [ ] **Step 4：验证测试先失败**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test test/registry test/capability`

Expected: 因注册表和能力目录尚不存在而失败。

- [ ] **Step 5：实现最小注册和解析**

注册和能力发布必须在同一方法内完成原子校验；任何冲突都不得留下部分状态。目录只保存契约和所有者，不保存 Flutter Widget 或平台句柄。

- [ ] **Step 6：运行测试和分析**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test`

Expected: PASS。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 7：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(runtime): add plugin registry and capability catalog`。

## Task F1-06：实现平台与能力解析器

**Files:**

- Create: `v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart`
- Create: `v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart`
- Modify: `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

**Interfaces:**

- Produces: `PluginResolver.resolve(manifests, target)` 和逐插件 `PluginResolution`。
- Consumes: `PluginManifest`、`PluginTarget`、能力目录契约。

- [ ] **Step 1：写入任务卡**

将 F1-06 标记为 `in_progress`，记录解析结果必须能解释不可用原因。

- [ ] **Step 2：编写解析失败测试**

覆盖目标平台匹配、平台不支持、必需能力缺失、能力版本不足、依赖环和稳定拓扑顺序。

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test test/resolution/plugin_resolver_test.dart`

Expected: 因解析器尚不存在而失败。

- [ ] **Step 4：实现纯解析器**

解析器不得读取 `Platform`、环境变量或文件系统；目标平台由宿主显式传入。结果包含 `available`、`activationOrder` 和结构化 `failures`。

- [ ] **Step 5：运行测试和分析**

Working directory: `v2/packages/plugin_runtime`

Run: `dart test test/resolution/plugin_resolver_test.dart`

Expected: PASS。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 6：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `feat(runtime): resolve plugins by platform and capability`。

## Task F1-07：创建开发测试夹具

**Files:**

- Create: `v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart`
- Create: `v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart`
- Create: `v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart`
- Modify: `v2/packages/plugin_devkit/lib/plugin_devkit.dart`

**Interfaces:**

- Produces: 可记录激活、停用、释放调用次数和注入失败的 `FakePlugin`。
- Produces: 按错误码断言的测试 matcher。
- Consumes: `plugin_contracts`、`plugin_runtime`。

- [ ] **Step 1：写入任务卡**

将 F1-07 标记为 `in_progress`，记录夹具只用于测试，不进入生产运行时。

- [ ] **Step 2：编写夹具自测**

覆盖调用计数、指定阶段失败、错误码 matcher 成功和错误信息不匹配。

- [ ] **Step 3：验证测试先失败**

Working directory: `v2/packages/plugin_devkit`

Run: `dart test test/fakes/fake_plugin_test.dart`

Expected: 因夹具尚不存在而失败。

- [ ] **Step 4：实现最小夹具**

FakePlugin 不使用延时或真实进程；失败通过构造参数确定，保证测试完全确定性。

- [ ] **Step 5：运行测试和分析**

Working directory: `v2/packages/plugin_devkit`

Run: `dart test`

Expected: PASS。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 6：记录检查点**

状态改为 `verified_pending_acceptance`，建议提交信息 `test(core): add deterministic plugin devkit`。

## Task F1-08：框架集成验证与文档

**Files:**

- Create: `v2/README.md`
- Create: `v2/packages/plugin_contracts/README.md`
- Create: `v2/packages/plugin_runtime/README.md`
- Create: `docs/superpowers/acceptance/v2-core-foundation-acceptance.md`
- Modify: `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`

**Interfaces:**

- Produces: G1 验收输入和可复现命令。
- Consumes: F1-01 至 F1-07 的代码与测试。

- [ ] **Step 1：写入任务卡**

将 F1-08 标记为 `in_progress`，记录本任务只补充文档和执行全量验证。

- [ ] **Step 2：编写边界文档**

README 必须说明包职责、依赖方向、目标平台由宿主传入、插件不可直接相互依赖，以及本阶段不包含 Flutter 宿主和 Sidecar。

- [ ] **Step 3：运行三个包的完整测试**

分别以三个 package 目录为 working directory 运行 `dart test`。

Expected: 全部 PASS。

- [ ] **Step 4：运行 workspace 静态检查**

Working directory: `v2`

Run: `dart format --output=none --set-exit-if-changed .`

Expected: 0。

Run: `dart analyze`

Expected: 0 errors。

- [ ] **Step 5：启动独立验收智能体**

使用全新上下文的 Sol xhigh，只读读取设计规格、核心计划和 v2 文件。验收者必须检查依赖边界、错误模型、非法转换、能力冲突、平台纯净性和恢复记录，不得修改生产代码。

- [ ] **Step 6：写入验收结论**

验收报告记录所有命令、通过项、失败项和未覆盖项。通过后将 F1-01 至 F1-08 和 M1 标记为 `accepted`；未通过则把具体任务退回原实现等级。

- [ ] **Step 7：提供用户检查点建议**

建议提交信息：`feat(core): complete plugin platform v2 core foundation`。AI 不执行 Git 命令。

