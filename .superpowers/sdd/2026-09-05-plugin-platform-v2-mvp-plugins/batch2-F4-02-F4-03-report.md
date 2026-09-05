# Batch2 报告：F4-02 宿主加固 + F4-03 计算器插件

**日期**: 2026-09-05
**计划**: `docs/superpowers/plans/2026-09-05-plugin-platform-v2-mvp-plugins.md`
**工作区**: `v2/`（Flutter workspace，Flutter 3.38.7 / Dart SDK ^3.10.0）
**约束遵守**: 未执行 git 操作；未修改 progress.yaml；未触碰 contracts/runtime/sidecar/capabilities 包。

---

## F4-02 宿主加固（真实数据根 + 图片真实解码）

### 变更文件

| 文件 | 变更 |
|------|------|
| `v2/packages/plugin_flutter/lib/src/widgets/result_renderer.dart` | 新增 `bytesLoader` 注入参数（`Future<Uint8List?> Function(String path)?`）。为 null 时保持原占位框行为；注入后经 FutureBuilder 取字节并 `Image.memory` 渲染，加载失败回退占位框并叠加错误提示文案 |
| `v2/packages/plugin_flutter/lib/l10n/plugin_flutter_zh.arb` / `plugin_flutter_en.arb` | 新增图片加载失败文案键（zh/en 双语），`flutter gen-l10n` 重新生成 |
| `v2/packages/plugin_flutter/lib/src/generated/plugin_flutter_l10n*.dart` | gen-l10n 生成产物 |
| `v2/packages/plugin_flutter/test/widgets/result_renderer_test.dart` | 追加 fake loader 场景：成功解码渲染图片、加载失败回退占位框 |
| `v2/apps/toolbox_host/pubspec.yaml` | 新增 `path_provider` 依赖 |
| `v2/apps/toolbox_host/lib/src/host_composition_root.dart` | 新增静态工厂 `Future<HostCompositionRoot> create(...)`：非 Web 走 `getApplicationSupportDirectory()`，Web 分支（`kIsWeb`）使用占位常量 `app-support://toolbox-host-web`；保留同步构造（显式 `hostDataRoot`）供测试注入。新增 `bytesLoader` 字段接线 `loadHostImageBytes` |
| `v2/apps/toolbox_host/lib/src/host_bytes_loader.dart` | 平台无关入口（条件导出骨架 + 占位常量声明） |
| `v2/apps/toolbox_host/lib/src/host_bytes_loader_io.dart` | dart:io 实现：`File.readAsBytes`，存在性/读取失败返回 null |
| `v2/apps/toolbox_host/lib/src/host_bytes_loader_none.dart` | 非 IO 平台桩实现（恒返回 null） |
| `v2/apps/toolbox_host/lib/main.dart` | 启动改为 `await HostCompositionRoot.create(...)` |
| `v2/apps/toolbox_host/test/composition_root_test.dart` | 追加 `create` 工厂注入解析器测试、bytesLoader 读文件/缺失路径测试 |
| `v2/apps/toolbox_host/windows/flutter/generated_plugins.cmake` | `flutter pub get` 自动生成（path_provider_windows 平台注册，非手工修改） |
| `v2/pubspec.yaml` | （F4-03 一并）workspace 注册 `plugins/calculator` |

### 焦点测试

- `plugin_flutter`: `flutter test` **37 全绿**，`flutter analyze` 零问题
- `toolbox_host`（F4-02 时点）: `flutter test` **12 全绿**，`flutter analyze` 零问题

---

## F4-03 计算器插件（六端 builtin）

### 变更文件

新建 `v2/plugins/calculator/`（依赖仅 `plugin_flutter` + `plugin_contracts`，dev: `plugin_devkit` + `flutter_test`；零平台依赖、零 dart:io）：

| 文件 | 说明 |
|------|------|
| `plugin.json` | id `tools.calculator`、kind builtin、targets 六端（windows/macos/linux/web/android/ios）、entrypoint `builtin://tools.calculator`、provides `[{id: calc.evaluate, version: 1}]`、surfaces `[page, settings]` |
| `pubspec.yaml` | 包声明（无 l10n 配置、无平台依赖） |
| `lib/calculator.dart` | 全量导出 |
| `lib/src/calculator_manifest.dart` | `calculatorManifest()` + `kCalculatorPluginId` |
| `lib/src/logic/expression_parser.dart` | 纯 Dart 求值器：`+ - * / %`、括号、一元负号、整数/小数、空白容忍；`evaluate(String) → CalcResult`（sealed `CalcValue`/`CalcError(PluginFailure)`）；错误码与词汇表逐字一致（`calc.empty` / `calc.unexpectedToken` / `calc.unbalancedParens` / `calc.divideByZero` / `calc.unknown`，details 带位置） |
| `lib/src/logic/calculator_history.dart` | 不可变历史条目 + 抽象 `CalculatorHistoryStore`（默认内存实现，上限 50） |
| `lib/src/ui/calculator_strings.dart` | `CalculatorSettings`（小数位数 0–12、历史开关）+ `CalculatorStrings` 文案载体（带位置参数字段为 `String Function(int)`）+ `CalculatorStringsResolver` typedef；插件包自身零 l10n 配置，文案由宿主注入 |
| `lib/src/ui/calculator_model.dart` | `ChangeNotifier` 模型：表达式/结果/错误/设置/历史；错误按 `details['reason']` 映射文案 |
| `lib/src/ui/calculator_page.dart` | `CalculatorPageProvider`：表达式显示行 + 5×4 按键网格 + 历史列表（点击回填）；全部消费 ThemeTokens/既有组件，零样式字面量 |
| `lib/src/ui/calculator_settings_screen.dart` | `CalculatorSettingsProvider`：小数位数 Slider（0–12）+ 历史开关 SwitchListTile |
| `test/logic/expression_parser_test.dart` | 求值器测试 |
| `test/logic/calculator_history_test.dart` | 历史测试 |
| `test/ui/test_harness.dart` | 共享骨架：主题令牌注入 + 固定文案载体 + 测试视口放大 |
| `test/ui/surface_contract_test.dart` | devkit SurfaceContractChecks 走查（4 场景） |
| `test/ui/calculator_page_test.dart` | 页面/设置组件测试（5 场景） |

宿主接线（`v2/apps/toolbox_host/`）：

| 文件 | 变更 |
|------|------|
| `pubspec.yaml` | 依赖 `calculator`（path） |
| `lib/src/plugins/calculator_plugin.dart` | 新建：宿主 l10n（`HostL10n`）到 `CalculatorStrings` 载体的桥接 + `hostCalculatorStringsResolver()`（方法 tear-off 注入） |
| `lib/src/host_composition_root.dart` | 注册 `calculatorManifest()`；共享 `CalculatorModel` 单例供 page/settings 两个提供方；新增 `settingsProviders` 注册表（`Map<String, PluginSettingsProvider>`，键为插件 ID——`PluginSettingsProvider` 接口不带 pluginId，由宿主补齐映射）与 `settingsProviderFor(id)`；surface 程序化校验循环追加 settings 分支（声明 settings 而无提供方 → `surface.unsupported`） |
| `lib/src/pages/plugin_detail_page.dart` | 详情页在清单声明 `settings` 时内嵌「插件设置」卡片：有提供方则内嵌其设置 UI，否则占位文案 |
| `lib/l10n/app_zh.arb` / `app_en.arb` | 新增 `detailSettings`/`detailNoSettings` 与 12 个 `calc*` 前缀键（zh/en 双语，含 `{position}`/`{value}` int 占位符元数据），`flutter gen-l10n` 重新生成 |
| `lib/src/generated/host_l10n*.dart` | gen-l10n 生成产物 |
| `test/composition_root_test.dart` | 追加 2 测试：计算器注册与页面/设置提供方就位且无 surface 失败；`calculatorManifest()` 与 `plugin.json` 声明逐字段一致 |
| `test/app_test.dart` | 适配（目录第三张卡片 → 「可用」徽章计数）+ 追加「计算器详情页内嵌插件设置区」测试 |

`v2/pubspec.yaml`：workspace 注册 `plugins/calculator`。

### 焦点测试

- `calculator`: `flutter analyze` 零问题；`flutter test` **23 全绿**（logic 14 + surface_contract 4 + calculator_page 5）
- `toolbox_host`（F4-03 后）: `dart format` 干净；`flutter analyze` 零问题；`flutter test` **15 全绿**（composition_root 10 + app_test 5）

### CLI validate 输出

```
$ dart run plugin_cli validate plugins/calculator
OK tools.calculator (builtin v1.0.0)
```

---

## 偏差及理由

1. **CLI 生成的 entrypoint 手工修正**：`dart run plugin_cli create --id tools.calculator` 生成的 entrypoint 为 `builtin:tools.calculator`（单斜杠），与词汇表要求的 `builtin://tools.calculator` 不符。已手工改为 `builtin://tools.calculator`，并删除 CLI 生成的骨架 Dart 入口文件（builtin 插件由宿主直接注册，无 sidecar 入口文件）。CLI 模板问题留待后续任务修正工具本身。
2. **i18n 键风格**：任务描述为「calc_ 前缀」，实际采用宿主既有 arb 键的 camelCase 风格（`calcDisplayHint`、`calcErrorDivideByZero` 等）。宿主全部现有键均为 camelCase（`appTitle`、`navDirectory`），保持一致性优先；语义上仍以 `calc` 为前缀，zh/en 双语齐全。
3. **小数位数设置只影响后续求值**：`CalculatorModel.updateSettings` 不重新格式化已显示的历史结果（`toStringAsFixed` 在 evaluate 时固化）。行为合理且已在测试中按此语义覆盖（改设置后重新按 `=` 生效）。
4. **宿主计算器设置/历史不持久化**：模型与历史为内存态（`InMemoryCalculatorHistoryStore`）。F4-03 计划无持久化要求，`configSchemaVersion: 1` 已在清单中预留。
5. **`generated_plugins.cmake` 变更**：引入 `path_provider` 后由 `flutter pub get` 自动更新（path_provider_windows 注册），非手工编辑，属 F4-02 的必要副产物。
6. **app_test 断言适配**：目录注册计算器后从 2 张卡片变 3 张（windows 下均可用），「可用」徽章断言由 1 改为 2；停用 Welcome 后计算器仍可用故「可用」从 0 改为 1。均为接线带来的正确性适配，非放宽断言。

## 测试数汇总

| 任务 | 包 | 测试数 | analyze |
|------|-----|--------|---------|
| F4-02 | plugin_flutter | 37 全绿 | 零问题 |
| F4-02 | toolbox_host（时点） | 12 全绿 | 零问题 |
| F4-03 | calculator | 23 全绿 | 零问题 |
| F4-03 | toolbox_host（最终） | 15 全绿 | 零问题 |
