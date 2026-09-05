# Batch A 持久化缺口修复报告

**日期**: 2026-09-06
**范围**: 缺口① 宿主插件启用集合持久化；缺口② PluginStorage KV 契约 + 设置接线
**约束遵守**: 未触及 contracts/runtime/plugin_flutter/plugin_sidecar；未执行 git；未改 progress.yaml

---

## 一、文件清单

### 缺口②：PluginStorage 存储契约（KV 最小版）+ 设置接线

**接口包（platform_capabilities，纯 Dart 零 io）**
- `packages/platform_capabilities/lib/src/plugin_storage.dart`（新增）
  - `abstract interface class PluginStorage`：`read/write/delete(PluginId, String key)`，值为字符串（调用方自行 JSON 编解码），按 PluginId 命名空间隔离
  - `final class InMemoryPluginStorage implements PluginStorage`：默认实现（web/测试用）
  - `PluginFailure storageIoFailure(String reason, String message, [details])`：错误码 `storage.io_error`，`details.reason = read|write|delete`
- `packages/platform_capabilities/lib/platform_capabilities.dart`：barrel 追加 `export 'src/plugin_storage.dart';`
- `packages/platform_capabilities/test/plugin_storage_test.dart`（新增）：4 项

**Windows io 实现（platform_capabilities_windows）**
- `packages/platform_capabilities_windows/lib/src/plugin_storage_impl.dart`（新增）
  - `final class JsonPluginStorage implements PluginStorage`：构造注入 `rootDir`；每插件单 JSON 文件（整表读写）；写路径 `dir.create(recursive)` → `JsonEncoder.withIndent('  ')` → `.tmp` 文件 `flush: true` → `rename` 原子替换；读失败（I/O 或 JSON 损坏）与写失败均抛 `storage.io_error` 结构化失败；空 key 抛 `ArgumentError`
- `packages/platform_capabilities_windows/lib/platform_capabilities_windows.dart`：barrel 追加导出
- `packages/platform_capabilities_windows/test/plugin_storage_impl_test.dart`（新增）：5 项（真临时目录）

**插件设置接线（模型注入缝，插件包保持零平台依赖）**
- `plugins/calculator/pubspec.yaml`：dependencies 追加 `platform_capabilities`（path 依赖）
- `plugins/calculator/lib/src/ui/calculator_model.dart`：构造新增可选 `PluginStorage? storage`；新增 `loadFromStorage()`（异步读 `settings` 键恢复小数位/历史开关）；`updateSettings` 内 `unawaited` 即时写回（jsonEncode `{fractionDigits, showHistory}`）；读写失败静默降级（debugPrint，不抛出）
- `plugins/calculator/test/ui/calculator_model_storage_test.dart`（新增）：4 项
- `plugins/screenshot/lib/src/screenshot_model.dart`：同模式；恢复 `filenamePrefix`/`quality`（质量键按稳定键白名单校验，非法回退 `lossless` 而前缀正常恢复）；写回 `{filenamePrefix, quality}`
- `plugins/screenshot/test/ui/screenshot_model_storage_test.dart`（新增）：4 项

**宿主接线（toolbox_host）**
- `apps/toolbox_host/lib/src/host_storage.dart`（新增）：条件导出入口 `export 'host_storage_none.dart' if (dart.library.io) 'host_storage_io.dart';`
- `apps/toolbox_host/lib/src/host_storage_io.dart`（新增）：`createHostPluginStorage(dataRoot)` → `JsonPluginStorage(rootDir: '$dataRoot/plugin-data')`
- `apps/toolbox_host/lib/src/host_storage_none.dart`（新增）：web → `InMemoryPluginStorage()`（文档注明不持久化）
- `apps/toolbox_host/lib/src/host_composition_root.dart`：新增 `late final PluginStorage pluginStorage`（= 工厂产出）；`CalculatorModel`/`ScreenshotModel` 构造注入 `storage: pluginStorage`；构造末尾 `unawaited(model.loadFromStorage())`（组装保持同步，UI 先显默认值，恢复完成后模型 notifyListeners 刷新）

### 缺口①：宿主插件启用集合持久化

- `apps/toolbox_host/lib/src/host_preferences.dart`（新增）：`HostPreferences` 数据载体（`disabledPlugins: Set<String>`，带 ==/hashCode）+ 条件导出 load/save（签名写入文档注释）
- `apps/toolbox_host/lib/src/host_preferences_io.dart`（新增）：`loadHostPreferences(dataRoot)` / `saveHostPreferences(dataRoot, prefs)`；存 `<hostDataRoot>/host-preferences.json`；写为 `.tmp` + `rename` 原子替换；文件缺失/JSON 损坏/任何 I/O 失败均静默降级（debugPrint 后返回空集合 / 保留内存态）
- `apps/toolbox_host/lib/src/host_preferences_none.dart`（新增）：web stub——load 恒空集合、save 无操作
- `apps/toolbox_host/lib/main.dart`：`create()` 之后 `await loadHostPreferences(root.systemPaths.hostDataRoot())`，初始停用集合传 `ToolboxApp(initialDisabledPluginIds: ...)`
- `apps/toolbox_host/lib/src/app.dart`：`ToolboxApp` 新增可选参数 `initialDisabledPluginIds`（默认空集合，兼容既有调用）；`initState` 应用初始集合；`_togglePlugin` 中 `unawaited(saveHostPreferences(...))` 同步写回
- `apps/toolbox_host/test/host_preferences_test.dart`（新增）：5 项
- `apps/toolbox_host/test/app_test.dart`：pumpApp fixture 的 dataRoot 改为含 NUL 的路径（所有平台均不可写），toggle 触发的偏好保存与组装根的设置恢复静默降级，测试零落盘、不污染仓库

---

## 二、焦点测试结果

| 包 | 命令 | 结果 |
|---|---|---|
| platform_capabilities | `dart test` | 4/4 通过（含接口包零 dart:io 边界扫描） |
| platform_capabilities_windows | `dart test` | 8/8 通过（含 5 项 JsonPluginStorage：真临时目录往返+跨实例持久、命名空间隔离、原子写顺序简化+无残留 tmp、损坏文件读失败、不可写根写失败） |
| plugins/calculator | `flutter test` | 27/27 通过（含 4 项模型存储：无 storage 无操作、写回+恢复一致、损坏 JSON 静默、读失败静默） |
| plugins/screenshot | `flutter test` | 17/17 通过（含 4 项模型存储：无 storage 无操作、写回+恢复、非法质量键回退、读失败静默） |
| apps/toolbox_host | `flutter test` | 31/31 通过（原有 26 项回归 + 缺口① 新增 5 项：真临时目录 save→load 往返、缺失文件空、损坏 JSON 静默空、不可写路径 save 不抛、ToolboxApp 初始停用集合呈现「已停用」） |

静态检查：上述 5 包 `dart analyze` / `flutter analyze` 均 No issues；触及源码已 `dart format`（80 列）。

---

## 三、接线说明

1. **启动恢复**：`main()` → `HostCompositionRoot.create()`（组装同步完成，注入 `pluginStorage` 与两模型）→ `loadHostPreferences(hostDataRoot)` → `ToolboxApp(initialDisabledPluginIds: prefs.disabledPlugins)` → `initState` 应用。
2. **切换保存**：目录/详情页启用开关 → `_togglePlugin` 更新内存集合 → `unawaited(saveHostPreferences(...))` 写 `<hostDataRoot>/host-preferences.json`（原子替换，失败静默）。
3. **插件设置**：组装根以 `createHostPluginStorage(hostDataRoot)` 产出 `JsonPluginStorage`（`<hostDataRoot>/plugin-data/<pluginId>/kv.json`）注入两模型；每次 `updateSettings` 即时写回 `settings` 键，构造后异步 `loadFromStorage()` 恢复；错误模型 `storage.io_error`（reason: read|write|delete）。
4. **web 目标**：偏好恒空/无操作；插件存储为 `InMemoryPluginStorage`（不持久化），编译图零 dart:io/ffi。

---

## 四、偏差列表

1. **KV 文件布局**：为 `<rootDir>/<pluginId>/kv.json`（宿主 root = `$dataRoot/plugin-data`），未使用任务描述中的中间 `storage/` 段——`plugin-data` 已表达隔离语义，且与组装根现有 `sidecar-packages` 命名风格一致。
2. **设置统一单一 `settings` 键**：任务只给出字段名；每插件文件已物理隔离，单键 JSON 对象最简且与「单键存全部持久化数据」的仓库既有规范一致。
3. **条件导出 barrel 形态**：`host_preferences.dart` 本体只承载 `HostPreferences` 类型 + 纯 `export`（含 load/save 签名文档注释），`host_storage.dart` 为纯 `export`——本地声明同名函数会遮蔽条件导出符号，故函数体只存在于分支文件（同 `host_bytes_loader` 先例）。
4. **app_test fixture 变更**：pumpApp dataRoot 由 `'%TESTDATA%/host'` 改为 NUL 路径——缺口①接线后 toggle 会触发真实写盘，原 fixture 会在仓库内产生垃圾目录；NUL 路径使全部写路径静默降级，测试零落盘。
5. **ToolboxApp API 扩展**：新增可选 `initialDisabledPluginIds` 参数（默认空集合），既有调用点（composition_root_test 等）无需修改。
6. **加载时序**：组装根构造保持同步，模型设置恢复为构造末尾 `unawaited` 异步进行——UI 先以默认值呈现，恢复完成后经 notifyListeners 刷新（同步构造内无法 await，且符合「失败静默降级」约定）。
