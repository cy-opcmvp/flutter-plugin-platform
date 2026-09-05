# Plugin Platform v2

M1 只交付不依赖 Flutter 和具体平台实现的核心基础：契约、纯 Dart 运行时和开发测试夹具。真实插件与 Flutter 宿主在后续里程碑接入。

## 包职责与依赖

- `plugin_contracts`：稳定的插件身份、失败值、清单、目标/种类、能力契约和生命周期接口。
- `plugin_runtime`：生命周期状态机、注册表/能力目录，以及按目标和能力依赖生成解析结果的纯逻辑。
- `plugin_devkit`：面向测试的 fake 插件、失败码 matcher 与 UI Surface 契约检查（见「devkit 边界演进」）。
- `plugin_sidecar`：桌面外部插件框架——SCP1 安装包构建/解析与原子安装、进程监督、stdio 帧化 JSON-RPC 与会话编排。
- `plugin_flutter`：插件 UI 的 Flutter 组件层——设计令牌与主题、插件卡片/状态徽章/表单渲染/结果渲染。
- `platform_capabilities`：系统能力契约的纯 Dart 接口；`platform_capabilities_{windows,macos,linux,android,ios,web}` 为六个同构平台 stub 包。
- `apps/toolbox_host`：Windows-first 宿主应用，全应用唯一组装点为 `HostCompositionRoot`。
- `plugin_cli`：插件脚手架与验证 CLI（create / validate / pack）。

依赖方向为：`plugin_contracts <- plugin_runtime <- plugin_devkit`，`plugin_contracts <- plugin_sidecar`，`plugin_contracts <- platform_capabilities <- platform_capabilities_{平台}`，`plugin_cli` 依赖 `plugin_contracts` + `plugin_sidecar`。宿主 `toolbox_host` 依赖 `plugin_contracts` / `plugin_runtime` / `plugin_sidecar` / `plugin_flutter` / `platform_capabilities`（+ 对应平台实现包），不依赖 devkit。运行时不依赖 devkit；sidecar 框架只依赖契约包（外加 `crypto` 摘要）；插件依赖能力契约，不直接依赖其他插件实现。

## M1 边界

宿主必须把目标显式传给 `PluginResolver.resolve(manifests, target)`；核心不读取平台全局状态、环境变量或文件系统。Builtin 与 Sidecar 清单共用同一套契约，但 M1 不包含 Flutter 宿主、平台适配器、Sidecar 安装器/进程/RPC、CLI 或业务插件。

契约中的目标词汇固定为 `windows`、`macos`、`linux`、`android`、`ios`、`web`。Windows-first 的端到端接入从后续里程碑开始。

## M2 边界

M2 交付桌面 sidecar 框架 `plugin_sidecar`，仅面向桌面平台（当前以 Windows 验证），不涉及移动端或 Web。包内 `dart:io` 被严格限定在两个适配器文件：`io_file_system.dart` 与 `io_process_launcher.dart`；安装、帧、RPC、监督等其余代码保持纯 Dart，通过抽象接口注入测试。Flutter 宿主（插件 UI 承载、sidecar 声明式结果渲染）在 M3 接入，本包无 UI。

## M3 边界

M3 在契约与 sidecar 框架之上接入宿主与工具链：

- `plugin_flutter`：设计令牌（`ThemeTokens` 契约 + precision_tools / warm_life / dark_pro 三套预设 × 明暗）、`AppTheme` 组装、`ThemeController`，以及插件卡片 / 状态徽章 / 表单渲染 / 结果渲染等 UI Surface 组件。样式值只允许出现在 `lib/src/theme/presets/`（静态扫描测试守护），文案走包内 l10n。
- `platform_capabilities`：系统能力（屏幕截图、系统路径等）的纯 Dart 接口层；六个平台 stub 包按平台提供实现位。核心包零 `dart:io`，平台实现经接口注入，宿主按需依赖对应平台包。
- `apps/toolbox_host`：宿主应用。`HostCompositionRoot` 是全应用唯一组装点（目标解析、sidecar 安装目录、插件注册与静态解析、主题控制器）；`main.dart` 只做引导。web / android 平台目录由 `flutter create . --platforms web,android` 生成（生成的 `analysis_options.yaml` 与 `test/widget_test.dart` 已移除，避免破坏既有 analyze 与测试基线）；windows 平台为既有交付。
- `plugin_cli`：开发者 CLI，纯 Dart 零 Flutter，用法与错误码见其 README。

### devkit 边界演进

`plugin_devkit` 在 M1/M2 是纯 Dart 测试夹具包；M3 的 UI Surface 契约检查（`SurfaceContractChecks`）需要 `Widget`/`BuildContext`，因此 devkit 的 lib 引入 Flutter 依赖，测试运行器相应从 `dart test` 换为 `flutter test`。这是有记录的边界放宽：devkit 定位是测试工具包，不是被插件或运行时依赖的生产库。

### 六端构建证据模型

Windows-first 交付下，仓库根 `scripts/v2/build-matrix.ps1` 对 toolbox_host 产出六端构建证据，不伪造跳过端：

- `windows` / `web`：本机实构建，记录退出码与产物路径；
- `android`：探测到 Android SDK 才实构建，否则 `SKIPPED-LOCAL-UNAVAILABLE`；
- `macos` / `linux` / `ios`：非对应宿主操作系统无法本地构建，如实输出 `SKIPPED-LOCAL-UNAVAILABLE`，以「六端编译图静态检查（平台专属插件依赖零混入 + 纯 Dart 包零 `dart:io`/Flutter 导入）+ `flutter analyze`」作为替代证据；
- 脚本对本机状态无写死假设，CI 可直接引用；在对应 runner 上跳过端可改为实构建。

## 最小验证命令

在本目录执行：

```powershell
dart pub get --offline
dart pub workspace list

# 纯 Dart 包
dart test packages/plugin_contracts
dart test packages/plugin_runtime
dart test packages/plugin_sidecar
dart test packages/platform_capabilities
dart test packages/plugin_cli

# Flutter 包与宿主应用
flutter test packages/plugin_flutter
flutter test packages/plugin_devkit
flutter test apps/toolbox_host

# 全 workspace 静态检查
dart format --output=none --set-exit-if-changed .
flutter analyze

# 六端构建矩阵（windows/web 实构建、android 条件构建、跳过端替代证据）
powershell -NoProfile -ExecutionPolicy Bypass -File ..\scripts\v2\build-matrix.ps1
```
