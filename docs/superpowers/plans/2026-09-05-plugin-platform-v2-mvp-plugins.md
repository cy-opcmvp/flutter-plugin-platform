# Plugin Platform v2 MVP Plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付三个真实插件——计算器（六端 builtin）、截图（Windows 平台变体 builtin，含真实屏幕捕获）、hash_tool（Windows Python Sidecar 样本）——打通 CLI→打包→安装→运行→声明式 UI 全链路，并附可复现的插件开发走查文档，通过 G4 验收。

**Architecture:** builtin 插件以 workspace 成员 package 存在（宿主依赖并注册）；插件只依赖能力**接口包**，windows 真实实现在 `platform_capabilities_windows` 内以 `dart:ffi`+GDI 捕获、`image` 纯 Dart 包编码 PNG；Sidecar 样本是**非 Dart 目录**（plugin.json + Python），经 plugin_cli 产出 .scp 由宿主安装运行；宿主新增 SidecarCommandBridge 把声明式表单桥接到 RPC 命令并渲染结构化结果。

**Tech Stack:** 既有 13 包 + toolbox_host；新增 `image ^4.x`（纯 Dart PNG 编码，仅 windows 适配包）、`path_provider`（仅宿主 app）；Python 3 标准库 hashlib。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（§2 插件类型、§4 目标结构、§10 平台策略、§13 MVP 验收标准）

## Global Constraints

- 继承 Master Plan 全部约束与既有执行策略（测试精简、焦点验证 + F4-07 集中全量一次、验收合并到 G4、AI 不执行 Git）。
- **插件只依赖能力接口包**（platform_capabilities），不得 import 任何 `platform_capabilities_<target>`；平台实现由宿主 Composition Root 注入。
- 新增第三方依赖仅限：`image`（platform_capabilities_windows 内）、`path_provider`（toolbox_host 内）；其余包零新增。
- sidecars/python_sample 不进 workspace（它是被安装的运行物，不是 Dart 包）。
- 沿用诚实构建证据模型：六端达标 = 六端 manifest + 三端实构建 + compile-graph 干净；不伪造声明。
- 所有用户可见文本 l10n（zh/en）；错误码入词汇表。
- 视觉：计算器/截图插件 UI 全部消费 ThemeTokens 契约与既有组件，不发明样式值（M3 冻结延续）。

## 错误码词汇表扩展（M4 新增）

| 错误码 | details | 产生任务 |
|---|---|---|
| `calc.invalid_expression` | reason: empty \| unexpectedToken \| unbalancedParens \| divideByZero（message 含位置） | F4-03 |
| `capture.failed` | reason: noScreen \| gdiError \| encodeError | F4-04 |
| `bridge.not_installed` | pluginId | F4-06 |
| `bridge.command_failed` | 委托远端 rpc.remote_error / rpc.timeout 原码透传 | F4-06 |

---

## 已冻结的技术决策

1. **计算器**：表达式求值器（tokenize→parse→evaluate）纯 Dart，支持 `+ - * / %`、括号、一元负号、整数/小数；错误结构化（含 token 位置）；UI = 表达式行 + 按钮网格 + 历史列表；settings 走 PluginSettingsProvider（小数位数 0-12、历史开关）；manifest targets 六端、surfaces [page, settings]。
2. **截图 MVP 范围**：主屏**全屏捕获** → 预览（ResultRenderer image 真实解码）→ 保存 PNG 至插件数据目录并提示路径；**区域选择 overlay 延后**（登记 M5 roadmap，本计划不实现）；manifest targets=[windows]——其在其他端的「不可用+原因」展示即为平台变体语义的验收证据。
3. **Windows 捕获实现**：platform_capabilities_windows 内 `dart:ffi` 绑定 GDI（GetDC/CreateCompatibleDC/BitBlt/GetDIBits 得 BGRA 像素）+ `image` 包转 RGB 编码 PNG 字节；自绘 Rect 在此层转换为捕获坐标；旧工程 `native_screenshot_window.cpp` 仅作 GDI 流程参考，不复制代码。
4. **Python 样本 = hash_tool**：文本 → MD5/SHA1/SHA256 十六进制摘要（纯标准库 hashlib，零 pip 依赖）；声明式表单（多行文本 + 算法下拉）→ RPC 命令 `hash.compute` → fields 结构化结果（三种摘要并列返回）。
5. **SidecarCommandBridge（宿主新组件）**：按 sidecar 清单的 declarative form 描述生成表单 → 提交时经 SidecarSession.call 发命令 → 远端 result 以 ResultDescriptor 渲染；未安装时按钮禁用并示 `bridge.not_installed` 语义。
6. **宿主数据根**：path_provider（getTypographyApplicationSupportDirectory）→ ResolvedSystemPaths；web 端 kIsWeb 分支返回占位常量（web 无 sidecar，仅目录展示）。
7. **G4 验收模式**：沿用 G3——单模型环境下一个验收智能体按双角色分节执行：分插件核查（Terra 角色三节）+ 汇总终验（Sol 角色一节），报告 `v2-mvp-plugins-acceptance.md`。

## 文件结构

```text
v2/
  pubspec.yaml                                  # workspace 增加 plugins/calculator、plugins/screenshot
  plugins/
    calculator/
      pubspec.yaml                              # 依赖 plugin_flutter + plugin_contracts + plugin_devkit(测试)
      lib/calculator.dart
      lib/src/logic/expression_parser.dart      # 纯 Dart 求值器（零 Flutter）
      lib/src/logic/calculator_history.dart
      lib/src/ui/calculator_page.dart           # PluginPageProvider 实现
      lib/src/ui/calculator_settings.dart       # PluginSettingsProvider 实现
      test/logic/expression_parser_test.dart    # 业务测试核心
      test/logic/calculator_history_test.dart
      test/ui/surface_contract_test.dart        # SurfaceContractChecks 走查
      test/ui/calculator_page_test.dart
      plugin.json                               # 清单（CLI 生成后手工完善）
    screenshot/
      pubspec.yaml                              # 依赖 plugin_flutter + contracts + capabilities(接口)
      lib/screenshot.dart
      lib/src/capture_controller.dart           # 调 ScreenCapture 接口 + 组织结果
      lib/src/ui/screenshot_page.dart
      lib/src/ui/screenshot_settings.dart
      test/capture_controller_test.dart         # fake ScreenCapture 注入
      test/ui/surface_contract_test.dart
      plugin.json                               # targets: [windows]
  sidecars/python_sample/                       # 非 workspace：被安装的运行物
    plugin.json                                 # kind: sidecar, entrypoint: hash_tool.py
    hash_tool.py
  packages/platform_capabilities_windows/
    lib/src/gdi_capture.dart                    # FFI GDI 捕获（dart:ffi 允许区）
    lib/src/png_encoder.dart                    # image 包编码
    lib/src/screen_capture_impl.dart            # ScreenCapture 真实现
    test/gdi_capture_test.dart                  # 真机像素尺寸/DPI 烟囱测试
  packages/plugin_flutter/
    lib/src/widgets/result_renderer.dart        # Modify: image 类型增加 bytesLoader 注入
  apps/toolbox_host/
    lib/src/sidecar_command_bridge.dart         # F4-06 声明式表单↔RPC 桥
    lib/src/host_composition_root.dart          # Modify: 注册两插件/注入真数据根/接入桥
    pubspec.yaml                                # Modify: +plugins +path_provider
    test/sidecar_command_bridge_test.dart
docs/guides/v2-plugin-dev-walkthrough.md        # F4-07 走查文档
docs/superpowers/acceptance/v2-mvp-plugins-acceptance.md
```

---

## Task F4-01：前置清理与 surface 程序化接线（G3 输入消化）

**Files:**

- Modify: `v2/packages/plugin_devkit/pubspec.yaml`（删 plugin_runtime 死依赖）、`v2/apps/toolbox_host/lib/src/pages/settings_page.dart`（语言自名豁免注释）
- Modify: `v2/apps/toolbox_host/lib/src/host_composition_root.dart`（surface 可用性判定经 `surfaceUnsupported` 产生结构化失败，宿主目录页消费展示）

**Interfaces:**

- Produces: 宿主对未支持 surface 的程序化失败通道（不再仅禁用按钮兜底）。
- Consumes: `surfaceUnsupported()`（plugin_flutter）。

步骤：删死依赖 → 复跑 devkit flutter test 确认无引用回归 → 豁免注释 → composition root 的 surface 判定接入 surfaceUnsupported 并在目录页数据模型透出 → 焦点测试（host flutter test）→ 检查点。建议 `chore(m4): digest g3 findings`。

## Task F4-02：宿主加固（真实数据根 + 图片真实解码）

**Files:**

- Modify: `v2/apps/toolbox_host/pubspec.yaml`（+path_provider）、`host_composition_root.dart`（数据根接线 + web 分支）
- Modify: `v2/packages/plugin_flutter/lib/src/widgets/result_renderer.dart`（image 结果接受注入 `Future<Uint8List?> Function(String path)` bytesLoader，默认 null 时维持占位框）

步骤：bytesLoader 注入点（含 widget 测试：注入后渲染真图）→ 宿主用 dart:io（app 层允许）+path_provider 实现加载器并注入 → 焦点测试两包 → 检查点。建议 `feat(host): real data root and image decoding`。

## Task F4-03：计算器插件（六端 builtin）

**Files:** 见文件结构 plugins/calculator 全树 + `v2/pubspec.yaml` 注册 + 宿主注册接线。

**Interfaces:**

- Produces: `ExpressionParser.evaluate(String) → CalcResult`（value 或 PluginFailure(calc.invalid_expression)）；`CalculatorPageProvider`/`CalculatorSettingsProvider`；plugin.json（id `tools.calculator`，targets 六端，provides `calc.evaluate` v1，surfaces [page,settings]）。
- Consumes: plugin_flutter Surface 族、devkit SurfaceContractChecks、ThemeTokens。

步骤：CLI `dart run plugin_cli create --id tools.calculator --name 计算器 --kind builtin plugins/calculator` 起步 → 求值器失败测试（运算优先级/括号/一元负/除零/非法 token 位置/空表达式）→ 实现求值器与历史（含持久化接口注入）→ UI 页面与设置（复用 FormRenderer 风格组件，l10n）→ SurfaceContractChecks 测试 → 宿主注册 → 焦点测试 `flutter test`（calculator + host 回归）→ 检查点。建议 `feat(plugins): add six-platform calculator`。

## Task F4-04：Windows ScreenCapture 真实现

**Files:** 见文件结构 platform_capabilities_windows 三源文件 + 测试。

**Interfaces:**

- Produces: `WindowsScreenCapture`（implements ScreenCapture）：`captureRegion(Rect)` → `CaptureResult`（PNG bytes + 尺寸）或 `PluginFailure(capture.failed)`；FFI 绑定收敛在 `gdi_capture.dart`。
- Consumes: 自绘 Rect（本层转 GDI 坐标，含 DPI 感知 GetDeviceCaps）。

步骤：失败测试（无屏/GDI 失败注入路径的结构化错误）→ FFI 绑定与捕获实现 → `image` 包 PNG 编码 → **真机烟囱测试**（捕获主屏，断言 PNG 魔数与宽高>0，存临时文件供人工查看）→ 焦点测试 + 包 analyze → 检查点。建议 `feat(platform): real windows screen capture`。

## Task F4-05：截图插件（Windows 平台变体）

**Files:** 见文件结构 plugins/screenshot 全树 + 注册接线。

**Interfaces:**

- Produces: plugin.json（id `tools.screenshot`，targets [windows]，provides `image.capture` v1，requires 无，surfaces [page,settings]）；`ScreenshotPageProvider`（捕获按钮 → CaptureController → ResultRenderer image 预览 → 保存至 pluginDataDir）；`ScreenshotSettingsProvider`（builtin 语义的设置页：保存质量/文件名模板，内部复用 FormRenderer 组件渲染字段）。
- Consumes: `WindowsScreenCapture` 由宿主注入（插件只见接口）、F4-02 bytesLoader（预览真实显示）。

步骤：CaptureController 失败测试（fake ScreenCapture 注入成功/失败两路）→ 页面与设置 UI → SurfaceContractChecks → 宿主注册（注入真实现）→ 焦点测试 → 检查点。建议 `feat(plugins): add windows screenshot variant`。

## Task F4-06：Python hash_tool 样本与命令桥

**Files:** `v2/sidecars/python_sample/{plugin.json,hash_tool.py}`（完整 Python 源：4B 帧协议 + ready 首帧 + `hash.compute` 返回三摘要 fields）；`toolbox_host/lib/src/sidecar_command_bridge.dart` + 测试；宿主详情页接线。

**Interfaces:**

- Produces: `SidecarCommandBridge.run(sidecar 安装态, formDescriptor, values)` → 提交经 `SidecarSession.channel.call('hash.compute', params)` → `ResultDescriptor`（fields：md5/sha1/sha256）。
- Consumes: SidecarInstaller、SidecarSession、declarative form/result、F4-01 bridge 语义。

步骤：Python 源 + plugin.json（CLI create 起步再完善，`dart run plugin_cli validate`/`pack` 产出 hash-tool.scp 入 sidecars 目录）→ 桥失败测试（未安装 not_installed / 命令失败透传 / 成功路径 fake session）→ 宿主详情页 sidecar 面板接线（安装 .scp→启动→表单→结果）→ **e2e 测试**：真 Python 从 .scp 安装→会话→compute→三摘要断言（无 Python skip）→ 检查点。建议 `feat(plugins): add python hash-tool sidecar sample`。

## Task F4-07：开发文档走查与集中全量验证

**Files:**

- Create: `docs/guides/v2-plugin-dev-walkthrough.md`（中文：前置→CLI create→实现要点→validate→pack→宿主安装→运行→契约检查；builtin 与 sidecar 两条路径）
- Modify: `v2/README.md`（M4 边界段）、`v2/plugins/*/README.md`、`v2/sidecars/python_sample/README.md`

步骤：走查文档（以 hash_tool 真实产出过程为底稿）→ **集中全量验证**（逐包测试预期 250+新增全绿、format、analyze、边界扫描）→ 构建矩阵复跑（三端实构建，含新插件编译图）→ 宿主全家福人工运行留证（目录页三插件卡片：计算器可用、截图可用、hash_tool 可安装）→ 检查点。建议 `feat(plugins): complete mvp plugin set`。

## Task G4：双角色分节验收

- [ ] **分插件核查（Terra 角色三节）**：计算器（六端证据模型、求值器测试覆盖、契约检查）、截图（平台变体语义——非 windows 端不可用原因、真捕获证据、无越界依赖）、hash_tool（全链路 e2e 证据、协议合规、CLI 产物可复现）。
- [ ] **汇总终验（Sol 角色一节）**：插件零平台实现依赖（只依赖接口包）、依赖方向、l10n 抽查、样式纪律抽查（新 UI 无字面量）、错误码词汇表一致、走查文档可复现性（按文档逐步执行验证）。
- [ ] 结论写入 `v2-mvp-plugins-acceptance.md`；通过 → M4 `accepted`，M5 计划冻结启动。建议 `feat(plugins): complete MVP plugin set`。

---

## 与规格条款的覆盖对照（自审）

| 规格条款 | 任务 |
|---|---|
| §13 计算器六端目标矩阵通过业务测试 | F4-03（六端 manifest+三端实构建+compile-graph+逻辑测试） |
| §13 截图插件只在声明支持的平台加载 | F4-05（targets=[windows]，他端不可用原因展示） |
| §13 Windows Python Sidecar 安装/启动/通信/停止/超时/卸载 | F4-06 e2e（M2 会话层已备超时/停止语义） |
| §13 CLI 能创建、校验和打包新插件 | F4-03/05/06 全部经 CLI 起步 + F4-07 走查复现 |
| §13 新开发者只依据文档即可完成示例插件 | F4-07 走查文档 + G4 可复现性验证 |
| §4 目标结构 plugins/ sidecars/ 落地 | 全部任务文件结构 |
| G3 六项 M4 输入 | F4-01（死依赖/接线/注释）、F4-02（数据根/图片解码）、F4-04（Rect 转换） |
| Master Plan M4 四项 + G4 | F4-03~07 + G4 |
