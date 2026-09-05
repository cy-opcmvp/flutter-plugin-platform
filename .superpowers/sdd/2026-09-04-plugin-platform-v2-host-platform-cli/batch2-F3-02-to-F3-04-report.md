# Batch 2 实施报告：F3-02 / F3-03 / F3-04

**批次计划**: `docs/superpowers/plans/2026-09-04-plugin-platform-v2-host-platform-cli.md`
**执行方式**: 串行（F3-02 → F3-03 → F3-04），每任务仅跑焦点验证 + 该包 analyze（workspace 全量留给 F3-08）
**日期**: 2026-09-05
**约束遵守**: 未动 contracts/runtime 生产代码；未执行 git；未改 progress.yaml；所有新建/修改 .dart 文件已 `dart format`；中文文档注释。

---

## Task F3-02：SidecarSession 会话编排

### 焦点验证

| 命令 | 结果 |
|------|------|
| `dart test test/session` | 8/8 All tests passed |
| `dart test test/e2e` | 6/6 All tests passed |
| `dart analyze`（plugin_sidecar） | No issues found |
| 回归 `dart test`（rpc/process/session/package 全量） | 53/53 All tests passed |

### 文件清单

**新增**:
- `v2/packages/plugin_sidecar/lib/src/session/sidecar_session.dart` — SidecarSession 静态 `start()` / `stop()`
- `v2/packages/plugin_sidecar/test/session/sidecar_session_test.dart` — 8 用例

**修改**:
- `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart` — barrel 导出 session
- `v2/packages/plugin_sidecar/lib/src/rpc/rpc_channel.dart` — 移除构造函数 decoder 参数
- `v2/packages/plugin_sidecar/test/e2e/python_sidecar_e2e_test.dart` — 改用 SidecarSession，删除 `_BroadcastingLauncher`
- `v2/packages/plugin_sidecar/README.md` — 同步会话编排说明（冻结决策 8）

### 实现要点

- `start()` 组合 launcher + 进程 spawn + `ready` 延迟器超时 → 就绪判定（首字节）→ 吞掉首帧（`"ready"` 不进通道）→ 建立 channel；失败路径进程必须已回收。
- `stop()` 通道关闭 + 进程停止。
- 失败统一 `session.start_failed`，details 委托底层原错误码透传（如 `process.spawn_failed`）。

---

## Task F3-03：plugin_flutter UI Surface 契约 + devkit 契约测试入口

### 焦点验证

| 命令 | 结果 |
|------|------|
| `flutter test`（plugin_flutter） | 12/12 All tests passed |
| `flutter test`（plugin_devkit） | 14/14 All tests passed |
| `dart analyze`（plugin_flutter） | No issues found |
| `dart analyze`（plugin_devkit） | No issues found |

### 文件清单

**新增**（package `v2/packages/plugin_flutter/`）:
- `pubspec.yaml` — 依赖 flutter + plugin_contracts（`resolution: workspace`）
- `lib/plugin_flutter.dart` — barrel
- `lib/src/surface/plugin_ui_surface.dart` — PluginPageProvider / PluginSettingsProvider / PluginActionProvider 接口族 + PluginAction + `surfaceUnsupported()`
- `lib/src/surface/declarative_form.dart` — FormDescriptor / FormFieldSpec 封闭族（textField/numberField/selectField/checkboxField/toggleGroup）
- `lib/src/surface/declarative_result.dart` — ResultDescriptor 封闭族（text/table/image/fields）+ ResultField
- `lib/src/surface/` 三测试文件（form 7 + result 3 + surface 2 = 12 用例）
- `README.md`

**修改**（package `v2/packages/plugin_devkit/`）:
- `pubspec.yaml` — 加 flutter sdk、plugin_flutter 依赖、flutter_test
- `lib/plugin_devkit.dart` — 导出 checks
- `lib/src/checks/surface_contract_checks.dart`（新增）— SurfaceContractChecks 四检查
- `test/checks/surface_contract_checks_test.dart`（新增）— 6 用例
- `test/fakes/fake_plugin_test.dart` — import 换 flutter_test
- `README.md`（新增）

**修改**（workspace）:
- `v2/pubspec.yaml` — 注册 packages/plugin_flutter

### 实现要点

- `surfaceUnsupported(surface, pluginId)` → `PluginFailure('surface.unsupported', …, details: {surface, pluginId})`，与词汇表逐字一致。
- 表单/结果描述符：封闭类型族 + kind 判别式 JSON 往返（`==`/`hashCode` 完整实现支撑往返等值断言）；key/label/必填/默认值齐全；重复 key、空 options、空白字段拒绝。
- devkit `SurfaceContractChecks`：checkPageProviderBuilds / checkSettingsProviderBuilds / checkManifestSurfaceDeclared（清单 surfaces 与实现族双向一致）/ checkActionsNonEmpty。

---

## Task F3-04：platform_capabilities 接口 + 六端 stub

### 焦点验证

| 命令 | 结果 |
|------|------|
| `dart test`（platform_capabilities） | 5/5 All tests passed |
| `dart test`（六个 stub 包） | 各 2/2 All tests passed（合计 12） |
| `dart analyze`（七包） | 全部 No issues found |
| `dart:io` 扫描 | 七包 lib/ 零 import（仅 system_paths.dart 注释提及） |

**F3-04 合计 17/17 用例通过。**

### 文件清单

**新增**（package `v2/packages/platform_capabilities/`）:
- `pubspec.yaml` — 纯 Dart，依赖 plugin_contracts（path）
- `lib/platform_capabilities.dart` — barrel
- `lib/src/capabilities.dart` — Rect（纯 Dart 值类）/ CaptureResult / ScreenCapture / UnsupportedScreenCapture
- `lib/src/system_paths.dart` — SystemPaths / UnsupportedSystemPaths / ResolvedSystemPaths
- `test/capabilities_test.dart` — 5 用例
- `README.md`

**新增**（六个同构 stub 包 `v2/packages/platform_capabilities_{windows,macos,linux,android,ios,web}/`，每包 5 文件）:
- `pubspec.yaml`（platform_capabilities path + dev 依赖 plugin_contracts/ints/test）
- `lib/platform_capabilities_{p}.dart` — 单导出
- `lib/src/stub.dart` — `{p}ScreenCapture` / `{p}SystemPaths` 顶层 const，携带本端平台标签
- `test/stub_test.dart` — 2 用例
- `README.md`

**修改**:
- `v2/pubspec.yaml` — workspace 注册 7 个新成员（现共 12 成员）

### 实现要点

- `captureRegion(Rect)` 不支持端返回 `CaptureResult.failure(PluginFailure('capability.unsupported', …, {capability: 'screenCapture', platform}))`，不抛异常。
- 错误码 `capability.unsupported` 与 details 键（capability/platform）与计划词汇表逐字一致；capability 标签 `'screenCapture'` / `'systemPaths'`。
- `ResolvedSystemPaths.pluginDataDir(id)` 返回 `'<root>/<id.value>'`：PluginId 已验证反向域格式（不含路径分隔符），无路径穿越空间（测试确认拼接结果）。
- 六端 stub 不 import `dart:io`，全部可编译于任意端。

---

## 偏差清单（共 10 项，均已评估为合理且不破坏接口契约）

1. **devkit lib 依赖 Flutter**：全局约束"四旧包 lib 不 import Flutter"与 F3-03 任务细节（SurfaceContractChecks 需 Widget/BuildContext）冲突，按任务细节执行——devkit 本就是测试工具包。
2. **devkit 测试改用 `flutter test`**：devkit 传递依赖 Flutter 后 `dart test` 不可用，pubspec 换 flutter_test，fake_plugin_test.dart import 同步修改。
3. **纯 Dart `Rect` 值类**：`captureRegion(Rect)` 的 Rect 计划未指明来源；capability 包零 Flutter 依赖约束下不能用 dart:ui Rect，自绘 left/top/width/height 值类（宽高非负校验）。
4. **`UnsupportedSystemPaths` 以 throw 表达失败**：`hostDataRoot()/pluginDataDir()` 签名要求返回 String，无法"返回"失败值；抛 `PluginFailure('capability.unsupported', …)`，调用方按结构化失败捕获处理。
5. **附加 `ResolvedSystemPaths` 参考实现**：满足计划 Step 2"pluginDataDir 测试确认拼接结果"步骤所需的可工作实现。
6. **plugin_flutter 增加第三个测试文件 `plugin_ui_surface_test.dart`**：覆盖计划 Interfaces 块中的 surfaceUnsupported 与 PluginAction（计划 Files 未列出，但接口需要测试）。
7. **声明式描述符与 Rect 全家族非 const 构造 + 运行时校验**：Dart const 构造无法在初始化列表调用校验函数，且 FormDescriptor 重复 key 校验无法 const 化；裁定非 const + ArgumentError（与 contracts PluginManifest 风格一致），测试同步去掉 const 字面量。
8. **SurfaceContractChecks 失败语义为抛 `StateError`**：matcher 包无顶层 fail/expect（属 test_api，生产 lib 不可依赖）；契约检查失败以中文消息 StateError 表达，在测试中未捕获即用例失败。
9. **plugin_flutter / plugin_devkit 补建 README.md**：两包此前无 README，按冻结决策 8"每个包交付时同步其 README"补建。
10. **六端 stub dev_dependencies 显式声明 plugin_contracts**：stub 测试直接断言 PluginFailure 字段，`depend_on_referenced_packages` lint 要求被 import 的包显式声明；放 dev_dependencies 保持生产依赖最小（仅 platform_capabilities）。

---

## 总结

| 任务 | 用例数 | analyze | 状态 |
|------|--------|---------|------|
| F3-02 SidecarSession | 14（session 8 + e2e 6） | 0 issues | 完成 |
| F3-03 plugin_flutter + devkit | 26（flutter 12 + devkit 14） | 0 issues ×2 | 完成 |
| F3-04 platform_capabilities + 六端 | 17（main 5 + 六端 2×6） | 0 issues ×7 | 完成 |

建议检查点提交信息（任务计划 Step 4，未执行 git，供编排方参考）：
- `feat(sidecar): add SidecarSession orchestration with ready handshaking`
- `feat(flutter): add UI surface contracts and devkit surface checks`
- `feat(platform): add capability interfaces with six stubs`
