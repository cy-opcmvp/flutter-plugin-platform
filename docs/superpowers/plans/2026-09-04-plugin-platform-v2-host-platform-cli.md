# Plugin Platform v2 Host, Platform Adapters & CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付 plugin_flutter UI Surface 契约与设计系统、唯一 Composition Root 的参考宿主 toolbox_host、六端平台能力接口与空实现、插件 CLI，并通过 G3 双验收（架构边界 + 构建证据）。

**Architecture:** `plugin_sidecar` 先补一层 `SidecarSession` 会话编排（消化 G2 三项遗留）；`plugin_flutter` 承载 UI Surface 契约、设计令牌与基础组件（唯一视觉来源）；`platform_capabilities` 纯 Dart 接口 + 六端 stub 包（联邦模式，本阶段全部返回结构化 unsupported）；`apps/toolbox_host` 是唯一 Composition Root 的 Flutter 宿主；`plugin_cli` 纯 Dart 实现创建/校验/打包。

**Tech Stack:** Flutter 3.38.7、Dart 3.10.7、pub workspace（Flutter 成员）、Material 3 + 自定义令牌、gen-l10n（zh/en）、`package:test` / `flutter_test`。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（重点 §4 目标结构、§9 UI Surface、§10 平台策略、§12 执行约束）

## Global Constraints

- 继承 Master Plan 全部约束与 M2 执行策略（测试精简、焦点验证 + F3-08 集中全量一次、验收合并到 G3、AI 不执行 Git）。
- **UI 编码硬门（用户指示）**：任何宿主/组件视觉代码开工前，F3-01 的艺术风格方向必须经用户确认冻结；F3-05/F3-06 依赖该门。
- `plugin_contracts`、`plugin_runtime`、`plugin_devkit`、`plugin_sidecar` 的 lib/ 继续**不得 import Flutter**；本阶段只允许给 plugin_sidecar 新增会话层文件。
- `plugin_flutter`、`apps/toolbox_host` 依赖 Flutter，但**不得 import 任何平台专属包**（win32、dart:ffi、窗口管理插件等）；宿主保持六端可编译图。
- `platform_capabilities` 与六个 `platform_capabilities_<target>` 包为纯 Dart；接口包零 Flutter 依赖。
- 所有新公共错误用 `PluginFailure`，新增错误码见本计划词汇表扩展。
- i18n：宿主与组件库所有用户可见文本经 gen-l10n（zh 默认 + en），禁止硬编码。
- 串行执行、单子智能体、实现/验收分离底线不变。

## 错误码词汇表扩展（M3 新增）

| 错误码 | details | 产生任务 |
|---|---|---|
| `surface.unsupported` | surface 类型、pluginId | F3-03 |
| `capability.unsupported` | capability、platform | F3-04 |
| `cli.invalid_manifest` | 字段路径（复用 contracts FormatException 消息） | F3-07 |
| `cli.missing_entrypoint` | entrypoint | F3-07 |
| `cli.pack_failed` | reason: ioError \| entrypointMissing | F3-07 |
| `session.start_failed` | 委托底层 process.start_failed 等原码透传 | F3-02 |

---

## 已冻结的技术决策

1. **艺术风格先行 + 三风格全部保留为可切换 preset**：F3-01 按**统一令牌 schema** 产出 3 个完整方向（全部达到可发布质量，非淘汰制）；用户门 = 确认三方向纳入 preset 集 + 指定默认方向。冻结产物为 `docs/superpowers/design/m3-art-direction.md` 的三个方向全量令牌表 + 默认方向批示；未确认前 F3-05/06 不得启动。
2. **SidecarSession 会话层**：`plugin_sidecar` 新增组合对象统一编排「进程 + 就绪 + 通道」，stdout 在会话内部单订阅分发，就绪帧（纯字符串首帧）由会话吞掉不进通道——结构性消除 G2 的广播摩擦与夹具约定耦合；同时移除 RpcChannel 无实效的 `decoder` 参数（尚无外部消费者，破坏性可接受，e2e 同步改造）。
3. **MVP 能力集最小化**：`platform_capabilities` 只定义 `ScreenCapture`（区域截图，M4 截图插件用）与 `SystemPaths`（宿主/插件数据目录解析）两个接口；六端全部 stub 返回 `capability.unsupported`；真实实现 M4 起按需进入对应平台包。
4. **宿主最小页面集**：插件目录（可用性+不可用原因）、插件详情（启用/停用/设置面/Sidecar 安装卸载）、设置（主题明暗、语言 zh/en）三页；宿主内置一个 `Welcome` 示例 builtin 插件页面证明 Surface 端到端。
5. **构建矩阵证据模型（诚实边界）**：本机（Windows）实构建 `flutter build windows`、`flutter build web`；Android 若 SDK 可用则 `flutter build apk --debug`，不可用则如实记录跳过；macOS/Linux/iOS 本机不可构建，以「编译图静态检查（平台专属依赖零混入）+ 每包 flutter/dart analyze + CI 预留脚本」作为替代证据，G3 Terra 按此模型验收，不伪造全六端构建声明。
6. **令牌契约 + 三 preset 可切换**：`plugin_flutter/lib/src/theme/tokens.dart` 定义令牌**契约**（色彩/字号/圆角/间距/动效的类型定义）；三个方向各一个 preset 实现文件；`AppTheme.build(preset, brightness)` 生成 3×2=6 套 ThemeData；`ThemeController`（ValueNotifier）支持运行时切换并经宿主公共配置持久化（规格 §7：主题属平台公共配置）。组件库与宿主**只消费契约类型**，禁止引用任何 preset 的具体值；新增风格 = 新增一个 preset 文件，零框架改动。
7. **CLI 形态**：`dart run plugin_cli <command>`；模板内嵌为 Dart 常量字符串；MVP 不发布 pub、不做交互式向导。
8. **v2/README 分阶段更新**：每个包交付时同步其 README；M3 边界段在 F3-08 汇总。

## 文件结构

```text
v2/
  pubspec.yaml                                  # workspace 增加 plugin_flutter、platform_capabilities、
                                                #   platform_capabilities_{windows,macos,linux,android,ios,web}、
                                                #   plugin_cli、apps/toolbox_host
  apps/toolbox_host/
    pubspec.yaml                                # Flutter application，resolution: workspace
    lib/main.dart                               # 入口，仅组装 PlatformHostApp
    lib/src/host_composition_root.dart          # 唯一 Composition Root（注册表/解析器/安装器/监督/能力装配）
    lib/src/app.dart                            # MaterialApp + 主题 + 路由
    lib/src/pages/plugin_directory_page.dart
    lib/src/pages/plugin_detail_page.dart
    lib/src/pages/settings_page.dart
    lib/src/plugins/welcome_plugin.dart         # 示例 builtin 插件（证明 Surface 端到端）
    lib/l10n/app_zh.arb  lib/l10n/app_en.arb
    test/host_composition_root_test.dart
    test/pages/plugin_directory_page_test.dart
  packages/plugin_flutter/
    pubspec.yaml                                # 依赖 flutter + plugin_contracts
    lib/plugin_flutter.dart
    lib/src/surface/plugin_ui_surface.dart      # F3-03 页面/设置/动作/小组件贡献接口
    lib/src/surface/declarative_form.dart       # F3-03 声明式表单模型
    lib/src/surface/declarative_result.dart     # F3-03 结构化结果模型
    lib/src/theme/tokens.dart                   # F3-05 令牌契约（唯一类型来源）
    lib/src/theme/presets/precision_tools.dart  # F3-05 方向A preset
    lib/src/theme/presets/warm_life.dart        # F3-05 方向B preset
    lib/src/theme/presets/dark_pro.dart         # F3-05 方向C preset
    lib/src/theme/app_theme.dart                # F3-05 build(preset, brightness) × 6 套
    lib/src/theme/theme_controller.dart         # F3-05 运行时切换 + 持久化钩子
    lib/src/widgets/plugin_card.dart            # F3-05
    lib/src/widgets/status_badge.dart           # F3-05（可用性+原因展示）
    lib/src/widgets/form_renderer.dart          # F3-05（声明式表单渲染）
    lib/src/widgets/result_renderer.dart        # F3-05
    test/surface/declarative_form_test.dart
    test/surface/declarative_result_test.dart
    test/theme/app_theme_test.dart
    test/widgets/form_renderer_test.dart
  packages/platform_capabilities/
    pubspec.yaml  lib/platform_capabilities.dart
    lib/src/capabilities.dart                   # F3-04 ScreenCapture/SystemPaths 接口 + Unsupported 默认实现
    lib/src/system_paths.dart
    test/capabilities_test.dart
  packages/platform_capabilities_windows/       # F3-04 其余五端同构，仅包名/平台标签不同
    pubspec.yaml  lib/platform_capabilities_windows.dart
    lib/src/stub.dart
    test/stub_test.dart
  packages/plugin_cli/
    pubspec.yaml  lib/plugin_cli.dart
    lib/src/commands/create.dart
    lib/src/commands/validate.dart
    lib/src/commands/pack.dart
    lib/src/templates/builtin_template.dart     # 内嵌模板常量
    lib/src/templates/sidecar_template.dart
    test/commands/cli_round_trip_test.dart
  packages/plugin_sidecar/                      # F3-02 仅新增会话层
    lib/src/session/sidecar_session.dart
    test/session/sidecar_session_test.dart
docs/superpowers/design/m3-art-direction.md     # F3-01 产出（三方向提案 + 已选方向）
docs/superpowers/acceptance/v2-host-platform-cli-acceptance.md   # G3 报告
scripts/v2/build-matrix.ps1                     # F3-08 构建矩阵脚本（含 CI 预留）
```

---

## Task F3-01：艺术风格设计提案与用户确认门

**Files:**

- Create: `docs/superpowers/design/m3-art-direction.md`

**Interfaces:**

- Produces: 用户选定的设计方向（含完整令牌表），F3-05 依据其「已选方向」节实现 tokens.dart。
- Consumes: 设计规格 §9（Surface 类型）、宿主最小页面集（本计划决策 4）。

- [ ] **Step 1：写入任务卡**

progress.yaml 登记 F3-01 `in_progress`；注明这是用户交互门，无代码交付。

- [ ] **Step 2：产出三个完整方向提案**

设计智能体（使用 frontend-design/ui-ux-pro-max 技能库方法论）针对「桌面优先的插件工具箱应用（六端、Material 3 基座、含插件目录/详情/设置三页 + 声明式表单渲染）」产出 **3 个差异鲜明的方向**，每个方向必须包含：

```text
1. 设计理念（3-5 句：这个方向为谁、解决什么感受问题）
2. 色彩系统：主色/次色/中性阶/语义色（成功警告错误）/深浅两套，给出具体 HEX
3. 字体与字号阶：字体族（含 Windows 桌面回退链）、display/title/body/label 四级字号行高
4. 形状与密度：圆角阶梯、间距阶梯（4pt 基）、描边/阴影层级
5. 动效原则：时长阶梯、缓动、何物可动何物禁动
6. 应用示意：插件目录页与详情页的布局描述（结构化文字 + ASCII 线框）
7. 组件风格要点：卡片/状态徽章/表单控件/空状态各一句
```

三方向建议差异化轴（提案时可调整）：A 精密工具风（冷静中性、高密度、强调效率）；B 温暖生活风（暖色、圆润、亲和）；C 极简暗色专业风（深色优先、高对比、开发者气质）。

- [ ] **Step 3：控制器汇总提交用户确认**

控制器把三方向摘要呈现给用户（用 AskUserQuestion，preview 展示每个方向的线框与关键令牌）。用户确认事项：① 三方向全部纳入可切换 preset 集（可提出修改意见）；② 指定**默认方向**。

- [ ] **Step 4：冻结三方向全量令牌**

把确认结果回写 `m3-art-direction.md`：「三个已冻结方向」节各含完整令牌表（F3-05 逐值落地为三个 preset）+「默认方向」批示 + 冻结日期。此后 F3-05/06 只允许引用该文件，不得再发明样式值。

- [ ] **Step 5：记录检查点**

F3-01 `accepted`（用户确认即验收）。建议提交信息 `docs(m3): freeze three art direction presets`。

## Task F3-02：plugin_sidecar 会话层（消化 G2 三项输入）

**Files:**

- Create: `v2/packages/plugin_sidecar/lib/src/session/sidecar_session.dart`
- Create: `v2/packages/plugin_sidecar/test/session/sidecar_session_test.dart`
- Modify: `v2/packages/plugin_sidecar/lib/src/rpc/rpc_channel.dart`（移除 `decoder` 参数）
- Modify: `v2/packages/plugin_sidecar/test/e2e/python_sidecar_e2e_test.dart`（改用 SidecarSession，删除测试内 `_BroadcastingLauncher`）
- Modify: `v2/packages/plugin_sidecar/lib/plugin_sidecar.dart`（追加 export）

**Interfaces:**

- Consumes: `SidecarSupervisor`、`RpcChannel`、`StdioRpcTransport`、`SidecarSpawn`、`Delayer`、`PluginFailure`。
- Produces:

```dart
/// 统一编排进程+就绪+通道的会话对象；stdout 单订阅在内部消化。
final class SidecarSession {
  /// 就绪 = supervisor 首字节判定；首帧（纯字符串就绪帧）被会话吞掉，不进通道。
  static Future<SessionStartResult> start({
    required SidecarProcessLauncher launcher,
    required SidecarSpawn spawn,
    required Delayer delayer,
    required Duration startupTimeout,
    required Duration requestTimeout,
    void Function(PluginFailure failure)? onUnexpectedExit,
  });

  RpcChannel? get channel;        // 就绪后非空
  Future<StopResult> stop();      // 通道关闭 + 进程停止
}

// SessionStartResult: session + failure?（失败时进程已回收）
```

同时：`RpcChannel` 构造函数移除 `decoder` 参数（G2 minor 落实）；e2e 改造后夹具的 `write_frame("ready")` 约定由会话层文档化并吞掉。

- [ ] **Step 1：写入任务卡** — F3-02 `in_progress`。
- [ ] **Step 2：失败测试**（fake launcher + 受控 delayer）：start 成功后 channel 可用且首帧（就绪帧）未进入通道；启动超时/立即退出时进程已回收且无通道泄漏；call/stop 全链路；decoder 参数移除后旧签名编译失败确认。场景清单写入测试文件头注释。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过**（`dart test test/session` + e2e 改造后 `dart test test/e2e`）。
- [ ] **Step 4：记录检查点** — 建议 `feat(sidecar): add session orchestration layer`。

## Task F3-03：plugin_flutter UI Surface 契约

**Files:**

- Create: `v2/packages/plugin_flutter/pubspec.yaml`（依赖 flutter + plugin_contracts）
- Create: `v2/packages/plugin_flutter/lib/plugin_flutter.dart`
- Create: `v2/packages/plugin_flutter/lib/src/surface/plugin_ui_surface.dart`
- Create: `v2/packages/plugin_flutter/lib/src/surface/declarative_form.dart`
- Create: `v2/packages/plugin_flutter/lib/src/surface/declarative_result.dart`
- Create: `v2/packages/plugin_flutter/test/surface/declarative_form_test.dart`
- Create: `v2/packages/plugin_flutter/test/surface/declarative_result_test.dart`
- Create: `v2/packages/plugin_devkit/lib/src/checks/surface_contract_checks.dart` + `test/checks/surface_contract_checks_test.dart`（devkit 需加 plugin_flutter 依赖——devkit 本就是测试工具包，允许）
- Modify: `v2/packages/plugin_devkit/lib/plugin_devkit.dart`、`v2/packages/plugin_devkit/pubspec.yaml`
- Modify: `v2/pubspec.yaml`（注册成员）

**Interfaces:**

- Consumes: `PluginId`、`PluginManifest`、`PluginFailure`。
- Produces:

```dart
/// builtin 插件向宿主贡献 UI 的接口族（sidecar 不实现此接口）。
abstract interface class PluginPageProvider {
  PluginId get pluginId;
  Widget buildPage(BuildContext context);
}
abstract interface class PluginSettingsProvider {
  Widget buildSettings(BuildContext context);
}
abstract interface class PluginActionProvider {
  List<PluginAction> actions(BuildContext context);   // 菜单/工具栏动作
}

/// Sidecar 的声明式 UI（宿主渲染，sidecar 不注入 Widget —— 规格 §9）。
/// FormDescriptor: title + List<FormFieldSpec>（textField/numberField/
///   selectField(options)/checkboxField/toggleGroup，均含 key/label/必填/默认值）
/// ResultDescriptor: kind: text|table|image(path)|fields —— 结构化结果四种
/// 渲染入口由 F3-05 的 FormRenderer/ResultRenderer 承担。
UnsupportedSurfaceFailure surfaceUnsupported(String surface, PluginId id);
// → PluginFailure('surface.unsupported', ...)
```

同时扩展 `plugin_devkit`（Master Plan「契约测试入口」承载点）：新增 `SurfaceContractChecks`——插件作者在**自己的测试环境**调用的契约断言集：`checkPageProviderBuilds`（buildPage 不抛且返回非空）、`checkSettingsProviderBuilds`、`checkManifestSurfaceDeclared`（清单 surfaces 与实现族一致）、`checkActionsNonEmpty`。纯 Flutter 测试工具，M4 插件逐个复用。

- [ ] **Step 1：写入任务卡**。
- [ ] **Step 2：失败测试**：表单/结果描述符的构造校验（空 title、空 key、select 无选项、重复 key 拒绝）、fromJson/toJson 往返、`surfaceUnsupported` 错误码与 details。合并用例，场景清单在文件头。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过 + 包 analyze 0 issues**。
- [ ] **Step 4：记录检查点** — 建议 `feat(flutter): define ui surface contracts`。

## Task F3-04：platform_capabilities 接口与六端空实现

**Files:**

- Create: `v2/packages/platform_capabilities/pubspec.yaml` + `lib/platform_capabilities.dart` + `lib/src/capabilities.dart` + `lib/src/system_paths.dart` + `test/capabilities_test.dart`
- Create: `v2/packages/platform_capabilities_{windows,macos,linux,android,ios,web}/`（六包同构：pubspec + 单导出 lib + `lib/src/stub.dart` + `test/stub_test.dart`）
- Modify: `v2/pubspec.yaml`（注册全部成员）

**Interfaces:**

- Produces:

```dart
abstract interface class ScreenCapture {
  /// 区域截图；不支持的平台返回结构化失败而非抛异常。
  Future<CaptureResult> captureRegion(Rect region);
}
abstract interface class SystemPaths {
  /// 宿主数据根目录与按 PluginId 隔离的插件数据目录（纯路径解析，不建目录）。
  String hostDataRoot();
  String pluginDataDir(PluginId id);
}
// 默认实现：UnsupportedScreenCapture(platform: 'windows') 等，
// 一律返回 PluginFailure('capability.unsupported',
//   details: {capability, platform})
```

- [ ] **Step 1：写入任务卡**。
- [ ] **Step 2：失败测试**：接口包默认实现返回 `capability.unsupported`（capability+platform 正确）；六个 stub 包各自返回携带本端标签的同一失败；`SystemPaths.pluginDataDir` 基于 PluginId 无路径穿越（id 已验证，测试确认拼接结果）。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过**（七包逐包 `dart test` + analyze；包小测试少而准）。
- [ ] **Step 4：记录检查点** — 建议 `feat(platform): add capability interfaces with six stubs`。

## Task F3-05：plugin_flutter 设计令牌与基础组件库

**Files:**

- Create: `v2/packages/plugin_flutter/lib/src/theme/tokens.dart`（令牌契约类型）
- Create: `v2/packages/plugin_flutter/lib/src/theme/presets/precision_tools.dart`（方向 A）
- Create: `v2/packages/plugin_flutter/lib/src/theme/presets/warm_life.dart`（方向 B）
- Create: `v2/packages/plugin_flutter/lib/src/theme/presets/dark_pro.dart`（方向 C）
- Create: `v2/packages/plugin_flutter/lib/src/theme/app_theme.dart`（build(preset, brightness) × 6 套）
- Create: `v2/packages/plugin_flutter/lib/src/theme/theme_controller.dart`（AppThemePreset 枚举 + ValueNotifier 切换 + 持久化回调注入）
- Create: `v2/packages/plugin_flutter/lib/src/widgets/plugin_card.dart`
- Create: `v2/packages/plugin_flutter/lib/src/widgets/status_badge.dart`
- Create: `v2/packages/plugin_flutter/lib/src/widgets/form_renderer.dart`
- Create: `v2/packages/plugin_flutter/lib/src/widgets/result_renderer.dart`
- Create: `v2/packages/plugin_flutter/lib/l10n/plugin_flutter_zh.arb` + `plugin_flutter_en.arb` + `l10n.yaml`（渲染器固定文案：必填提示/提交/重置等）
- Create: `v2/packages/plugin_flutter/test/theme/app_theme_test.dart`
- Create: `v2/packages/plugin_flutter/test/widgets/form_renderer_test.dart`
- Modify: `v2/packages/plugin_flutter/lib/plugin_flutter.dart`

**Interfaces:**

- Consumes: F3-01 三方向冻结令牌表、F3-03 表单/结果描述符。
- Produces:

```dart
enum AppThemePreset { precisionTools, warmLife, darkPro }

/// 令牌契约（tokens.dart）：组件库与宿主只依赖此类型。
abstract final class ThemeTokens { /* 色彩/字号/圆角/间距/动效时长 getter 契约 */ }

/// 三个 preset 均实现 ThemeTokens；AppTheme.build 生成 3 preset × 明暗 = 6 套 ThemeData。
final class AppTheme {
  static ThemeData build(AppThemePreset preset, Brightness brightness);
}

/// 运行时切换：设置页改 value → MaterialApp 重建主题；
/// 持久化经构造注入的回调交宿主公共配置（规格 §7）。
final class ThemeController extends ValueNotifier<AppThemePreset> {
  ThemeController(AppThemePreset initial, {Future<void> Function(AppThemePreset)? persist});
}
```

组件：`PluginCard`、`StatusBadge(availability)`、`FormRenderer(descriptor, onSubmit)`、`ResultRenderer(descriptor)`——全部只经 `Theme.of(context)`/`ThemeTokens.of(context)`（ThemeExtension）取值。

- [ ] **Step 1：写入任务卡**；**前置门检查：F3-01 已冻结，三 preset 逐值对照冻结令牌表**。
- [ ] **Step 2：失败测试**（精简）：三 preset 各构建明/暗两套主题且关键色与冻结表一致；ThemeController 切换触发通知并调用持久化回调；FormRenderer 渲染各字段类型并回填报价值、必填校验提示（l10n）；ResultRenderer 渲染四类结果；StatusBadge 展示不可用原因文本；**组件无硬编码颜色/字号的静态检查**（扫描 widgets/ 源码中 `Color(0x` 与 `fontSize:` 字面量，应仅存在于 presets/）。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过**（`flutter test` 本包）。
- [ ] **Step 4：记录检查点** — 建议 `feat(flutter): implement design tokens and base widgets`。

## Task F3-06：toolbox_host 参考宿主（唯一 Composition Root）

**Files:**

- Create: `v2/apps/toolbox_host/pubspec.yaml`（Flutter application，依赖 plugin_flutter/plugin_runtime/plugin_contracts/plugin_sidecar/platform_capabilities_windows 等）
- Create: `v2/apps/toolbox_host/lib/main.dart`
- Create: `v2/apps/toolbox_host/lib/src/host_composition_root.dart`
- Create: `v2/apps/toolbox_host/lib/src/app.dart`
- Create: `v2/apps/toolbox_host/lib/src/pages/plugin_directory_page.dart`
- Create: `v2/apps/toolbox_host/lib/src/pages/plugin_detail_page.dart`
- Create: `v2/apps/toolbox_host/lib/src/pages/settings_page.dart`（界面风格选择：三 preset + 明暗跟随系统；语言 zh/en；选择经公共配置持久化）
- Create: `v2/apps/toolbox_host/lib/src/plugins/welcome_plugin.dart`
- Create: `v2/apps/toolbox_host/lib/l10n/app_zh.arb` + `app_en.arb` + `l10n.yaml`
- Create: `v2/apps/toolbox_host/test/host_composition_root_test.dart`
- Create: `v2/apps/toolbox_host/test/pages/plugin_directory_page_test.dart`
- Modify: `v2/pubspec.yaml`（注册 apps/toolbox_host）

**Interfaces:**

- Consumes: 前序全部公共 API（Registry/Resolver/Installer/Session/能力 stub/plugin_flutter 组件）。
- Produces: 可运行宿主。Composition Root 是全应用唯一组装点：构造 registry（注册 Welcome builtin + Sidecar 清单目录扫描的占位装配）、resolver（目标平台由 main 显式传入 `PluginTarget.windows`）、installer/supervisor 会话工厂、能力实例注入。

- [ ] **Step 1：写入任务卡**。
- [ ] **Step 2：失败测试**（精简核心）：Composition Root 装配后目录页数据源含 Welcome 且可用性正确；人为注入不可用插件（目标不匹配）时 StatusBadge 呈现结构化原因；语言切换 zh/en 生效（l10n 委托）。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过**（`flutter test` 本 app）。
- [ ] **Step 4：Windows 烟囱运行**：`flutter run -d windows` 由用户手动确认视觉（好看属性的人工验收点）；智能体只需 `flutter build windows --debug` 成功。
- [ ] **Step 5：记录检查点** — 建议 `feat(host): add reference host with single composition root`。

## Task F3-07：plugin_cli（create/validate/pack）

**Files:**

- Create: `v2/packages/plugin_cli/pubspec.yaml` + `lib/plugin_cli.dart` + `lib/src/commands/{create,validate,pack}.dart` + `lib/src/templates/{builtin_template,sidecar_template}.dart`
- Create: `v2/packages/plugin_cli/test/commands/cli_round_trip_test.dart`
- Modify: `v2/pubspec.yaml`

**Interfaces:**

- Consumes: `PluginManifestCodec`、`PackageBuilder`、`PackageReader.fromBytes`。
- Produces:

```text
dart run plugin_cli create --id tools.demo --name Demo --kind builtin|sidecar <dir>
  → 生成 plugin.json（合法最小清单）+ kind 对应入口骨架文件
dart run plugin_cli validate <dir>
  → 清单严格解码 + sidecar 时 entrypoint 文件存在检查；输出 OK/结构化错误（exit 1）
dart run plugin_cli pack <dir> -o <out.scp>
  → SCP1 打包；pack 后立即用 PackageReader.fromBytes 自校验
```

- [ ] **Step 1：写入任务卡**。
- [ ] **Step 2：失败测试**（核心闭环）：create(builtin)→validate OK；create(sidecar)→validate OK（含入口存在）；删除入口→validate 报 `cli.missing_entrypoint`；篡改清单字段→`cli.invalid_manifest`；pack→reader 往返一致；pack 缺入口→`cli.pack_failed(entrypointMissing)`。
- [ ] **Step 3：验证失败 → 实现 → 焦点测试通过**。
- [ ] **Step 4：记录检查点** — 建议 `feat(cli): add plugin create validate pack`。

## Task F3-08：六端构建矩阵、集成验证与文档

**Files:**

- Create: `scripts/v2/build-matrix.ps1`
- Create: `v2/packages/plugin_flutter/README.md`、`v2/packages/platform_capabilities/README.md`、`v2/packages/plugin_cli/README.md`、`v2/apps/toolbox_host/README.md`
- Modify: `v2/README.md`（M3 边界段 + 更新验证命令）
- Modify: `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`

**Interfaces:**

- Consumes: 全部 M3 交付。
- Produces: 构建矩阵证据 + 完整文档。

- [ ] **Step 1：写入任务卡**。
- [ ] **Step 2：集中全量验证**（M3 唯一一次）：
  - 纯 Dart 五包逐包 `dart test`（contracts/runtime/devkit/sidecar/platform_capabilities 系）+ Flutter 三包 `flutter test`（plugin_flutter/toolbox_host/plugin_cli 按其类型）
  - `dart format --output=none --set-exit-if-changed .`（v2 根）+ `flutter analyze`（v2 根）
  - 依赖边界扫描：四旧包 lib 无 Flutter/IO；plugin_flutter 与 toolbox_host 无平台专属包；platform_capabilities_* 零 Flutter
- [ ] **Step 3：构建矩阵**（诚实证据模型，决策 5）：`build-matrix.ps1` 依次执行并记录退出码——`flutter build windows --debug`、`flutter build web`（toolbox_host）；Android 探测 SDK 后条件执行 `flutter build apk --debug`；macos/linux/ios 行输出 `SKIPPED-LOCAL-UNAVAILABLE`；脚本内嵌六端静态编译图检查（grep 平台依赖）。证据写入报告。
- [ ] **Step 4：文档**：四份 README（职责/边界/命令）+ v2/README M3 段。
- [ ] **Step 5：记录检查点** — 建议 `feat(platform): complete host adapters and cli`。

## Task G3：双门独立验收

- [ ] **G3-A（独立 Sol high，只读）**：架构边界审查——Composition Root 唯一性（无第二服务图）、依赖方向、UI 编码门是否被遵守（F3-05/06 样式值全部溯源到冻结令牌）、surface.unsupported/capability.unsupported 语义与规格 §9/§10 一致、i18n 无硬编码抽查、G2 三输入确已消化。报告并入 G3 报告 A 节。
- [ ] **G3-B（独立 Terra high，只读）**：构建证据核验——复跑 build-matrix.ps1、逐包测试复跑、诚实证据模型核查（跳过项如实标注）、Windows 烟囱构建产物存在。报告 B 节。
- [ ] **结论**：写入 `docs/superpowers/acceptance/v2-host-platform-cli-acceptance.md`；通过 → F3-01~08 + M3 `accepted`，进入 M4 规划；不通过 → 退回修复。建议提交 `feat(platform): complete host and platform adapters`。

---

## 与规格条款的覆盖对照（自审）

| 规格条款 | 任务 |
|---|---|
| §2.1 builtin 可贡献页面/设置/动作/小组件 | F3-03 接口族 |
| §2.2/§9 sidecar 命令+声明式表单+结构化结果、不注入 Widget | F3-03 模型 + F3-05 渲染器 |
| §9 unsupportedSurface 明确拒绝 | F3-03 surface.unsupported |
| §4 目标结构 apps/packages 落地 | 全部任务文件结构 |
| §10 六端可编译、Windows 专属不污染 | F3-04 stub + F3-08 矩阵 |
| §10 宿主能展示不可用原因 | F3-05 StatusBadge + F3-06 目录页 |
| §3.3 唯一 Composition Root | F3-06 |
| Master Plan M3 五项 + G3 双门 | F3-01~08 + G3 |
| 用户指示：UI 前艺术风格设计并确认 | F3-01 硬门（Global Constraints 第 2 条） |
| 用户指示：三风格做成可配置可切换 | 决策 1/6 + F3-05 三 preset + ThemeController + F3-06 设置页切换与持久化 |
| G2 三项 M3 输入 | F3-02（会话层/decoder/就绪帧） |
