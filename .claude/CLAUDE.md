# CLAUDE.md

本文件为 Claude Code 在本仓库工作时的指导。项目为 **v2 插件平台**（2026-09 由 v1 重写切换而来；v1 全部资产归档于 `docs/archive/v1/`，差异见 `docs/superpowers/cutover/v1-v2-feature-diff.md`）。

## 项目概述

跨平台（Windows 首发）插件平台 SDK + 桌面工具箱宿主。核心思想：

- **微内核契约**：`plugin_contracts`（纯 Dart）定义 PluginId/严格清单/能力/生命周期/结构化失败 `PluginFailure(code, message, details)`；`plugin_runtime` 提供注册表、按目标平台与能力的解析器、状态机。
- **能力注入**：插件只依赖 `platform_capabilities` 接口包；平台真实现（Windows GDI 屏幕捕获等）位于 `platform_capabilities_windows` 等端包，**只经宿主 `lib/src/*_io.dart` 条件导出进入编译图**——宿主源码禁止直连平台包（教训：直连会在该包引入 ffi 后污染 web 构建）。
- **Sidecar 进程隔离**：`plugin_sidecar` 提供 SCP1 安装包格式（路径安全+sha256）、长度前缀帧 JSON-RPC、进程监督（超时/回收）、`SidecarSession` 会话编排（吞就绪帧、单订阅 stdout）。
- **唯一 Composition Root**：`apps/toolbox_host/lib/src/host_composition_root.dart` 是全应用唯一组装点，无 Service Locator。

## 仓库结构

```text
（仓库根 = Dart pub workspace，17 成员）
apps/toolbox_host/    宿主（唯一 Composition Root、三页、三 preset 主题切换、命令桥）
packages/             contracts·runtime·flutter·sidecar·devkit·capabilities(×7)·cli
plugins/              builtin 插件：calculator（六端）、screenshot（仅 windows）
sidecars/python_sample/   hash_tool 样本（plugin.json + Python，非 Dart 包）
scripts/build-matrix.ps1  构建矩阵（诚实证据模型）
docs/superpowers/     规格 specs/、计划 plans/、验收 acceptance/、cutover/
docs/guides/v2-plugin-dev-walkthrough.md   插件开发走查（新开发者入口）
```

## 常用命令

```powershell
dart pub get
dart test packages/plugin_contracts        # 纯 Dart 包：dart test
flutter test apps/toolbox_host             # Flutter 包：flutter test
flutter run -d windows                     # 运行宿主
dart run plugin_cli create --id tools.x --name X --kind builtin|sidecar <dir>
dart run plugin_cli validate <dir> ; dart run plugin_cli pack <dir> -o out.scp
powershell -File scripts/build-matrix.ps1  # 三端实构建 + 编译图静态检查
```

## 硬性纪律（历史验收沉淀，违反会被复审退回）

1. **边界**：`plugin_contracts`/`plugin_runtime` 禁 Flutter/dart:io/ffi/win32；`plugin_sidecar` 的 dart:io 仅 `io_file_system.dart` 与 `io_process_launcher.dart`；`dart:ffi` 仅 `platform_capabilities_windows/lib/src/gdi_capture.dart`；插件包零平台依赖零 dart:io。
2. **样式令牌**：视觉值只允许存在于 `plugin_flutter/lib/src/theme/presets/`（静态扫描测试强制）；组件与宿主只消费 `ThemeTokens` 契约。三 preset 定义见 `docs/superpowers/design/m3-art-direction.md`（冻结）。
3. **错误码**：所有结构化失败用 `PluginFailure`，错误码词汇表见各里程碑计划文档（如 `capture.failed`/`bridge.not_installed` 等），新码须先入表。
4. **i18n**：用户可见文本一律走 gen-l10n（zh/en）；宿主 arb 为 camelCase 键，插件文案以插件短名做语义前缀（calc*/shot*/hash*）。语言自名（「中文」/「English」）为惯例豁免。
5. **测试策略**（用户指示）：安全/协议核心场景必须全覆盖；功能过于简单的不写测试；相似断言合并；每任务只跑焦点测试，全量验证集中一次。
6. **Git**：AI 不执行 git 命令（提交由用户做或用户明确授权后执行）；提交信息中文 Conventional Commits。
7. **Sidecar 协议**：4B 大端长度前缀帧 + 启动先发 `ready` 纯字符串帧（由 SidecarSession 吞掉，不进通道）；JSON-RPC 2.0 严格子集。

## SDD 执行模式（superpowers 流程）

- 状态唯一事实源：`docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`；每里程碑有独立计划与验收报告；实现报告在 `.superpowers/sdd/<里程碑>/`。
- 控制器（主会话）负责计划冻结/焦点验证/状态推进；实现由子智能体分批串行；验收由全新上下文只读智能体完成（实现与验收分离）。
- 实现者报告不算证据，控制器必须亲自复跑（历史上出现过两次报告与代码不符）。
- 派发子智能体的纪律：验收/巡检类注入上下文节约规则（禁整读文件、命令输出截尾、渐进落盘）。
