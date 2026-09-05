# Batch 4 实施报告：F3-07（plugin_cli）+ F3-08（构建矩阵、集中全量验证与文档）

**日期**：2026-09-05
**范围**：新建 `v2/packages/plugin_cli/`、新建 `scripts/v2/build-matrix.ps1`、修改 `v2/pubspec.yaml`（workspace 注册）、`v2/README.md`、`v2/packages/plugin_cli/README.md`；既有包最小修复见偏差列表
**批次计划**: `docs/superpowers/plans/2026-09-04-plugin-platform-v2-host-platform-cli.md`
**约束遵守**：未执行 git；未改 progress.yaml；plugin_cli 纯 Dart 零 Flutter；错误码与词汇表逐字一致

---

## 一、F3-07：plugin_cli

### 文件清单

| 文件 | 内容 |
|------|------|
| `pubspec.yaml` | 纯 Dart 包；依赖 plugin_contracts + plugin_sidecar（path）；dev 依赖 lints/test |
| `bin/plugin_cli.dart` | 进程入口：`exitCode = CliRunner.run(arguments, out: stdout, err: stderr)` |
| `lib/plugin_cli.dart` | barrel，导出 CliRunner |
| `lib/src/cli_runner.dart` | 三个错误码常量（`cli.invalid_manifest` / `cli.missing_entrypoint` / `cli.pack_failed`）、退出码常量（0/1/2）、子命令分发、用法输出、`writeFailure`（stderr 单行 JSON） |
| `lib/src/parsed_args.dart` | 手写参数解析（`--name value`、`--name=value`、`-o value`、位置参数） |
| `lib/src/path_util.dart` | 路径拼接 / 正斜杠规整 / 相对路径 / 目录规范化 |
| `lib/src/templates/builtin_template.dart` | builtin Dart 骨架（`PluginLifecycle` 最小实现），文件名 `<id 蛇形>_plugin.dart` |
| `lib/src/templates/sidecar_template.dart` | sidecar Python echo 骨架（`main.py`） |
| `lib/src/commands/create.dart` | `create --id --name --kind <dir>`；12 字段清单组装；拒绝覆盖；落盘前 codec 自校验 |
| `lib/src/commands/validate.dart` | `validate <dir>`；PluginManifestCodec 严格解码；sidecar 入口必须存在 |
| `lib/src/commands/pack.dart` | `pack <dir> -o <out.scp>`；递归收集（排除输出文件自身）；打包后 PackageReader 回读自校验 |
| `test/commands/cli_round_trip_test.dart` | 8 场景焦点测试（见下） |

### 侧car 模板协议（对齐 M2 夹具）

- 4 字节大端长度前缀帧（`struct ">I"`）；
- 启动先发送 `"ready"` 纯字符串帧（由宿主 SidecarSession 吞掉）；
- JSON-RPC 2.0 消息：`ping` → `pong`，未知方法返回 `-32601`。

### 焦点测试（8/8 通过）

| # | 场景 | 断言 |
|---|------|------|
| 1 | create(builtin) → validate | exit 0，两个生成物存在，stdout 含 `tools.demo` |
| 2 | create(sidecar) → validate | exit 0，stdout 含 `sidecar` |
| 3 | sidecar 骨架静态检查 | `">I"` 帧、`write_frame("ready")`、`"jsonrpc": "2.0"`、`-32601` |
| 4 | 删入口 → validate | exit 1，`cli.missing_entrypoint`，details.entrypoint=`main.py` |
| 5 | 篡改清单 → validate | exit 1，`cli.invalid_manifest`，details.field=`id` |
| 6 | pack → PackageReader 往返 | manifest.id/kind/entries 一致，`main.py` 字节一致 |
| 7 | pack 缺入口 | exit 1，`cli.pack_failed`，details.reason=`entrypointMissing`，不产出文件 |
| 8 | pack 缺 plugin.json | exit 1，`cli.pack_failed`，details.reason=`ioError` |

`dart test packages/plugin_cli` → **8/8 All tests passed**；`dart format` 0 changed；`dart analyze` No issues。

---

## 二、F3-08

### 1. 集中全量验证（v2/ 下）

| 包 | 命令 | 结果 |
|----|------|------|
| plugin_contracts | `dart test packages/plugin_contracts` | 48/48 All tests passed |
| plugin_runtime | `dart test packages/plugin_runtime` | 26/26 All tests passed |
| plugin_sidecar | `dart test packages/plugin_sidecar` | 93/93 All tests passed |
| platform_capabilities（核心） | `dart test packages/platform_capabilities` | 5/5 All tests passed |
| platform_capabilities_windows / macos / linux / android / ios / web | `dart test packages/platform_capabilities_<p>`（×6） | 每包 2/2，共 12/12 All tests passed |
| plugin_cli | `dart test packages/plugin_cli` | 8/8 All tests passed |
| plugin_flutter | `flutter test packages/plugin_flutter` | 35/35 All tests passed（修复见偏差 1） |
| plugin_devkit | `flutter test packages/plugin_devkit` | 14/14 All tests passed |
| toolbox_host | `flutter test apps/toolbox_host` | 9/9 All tests passed |

全 workspace 合计 **250 个测试通过，0 失败**。

| 检查 | 结果 |
|------|------|
| `dart format --output=none --set-exit-if-changed .` | 131 files, 0 changed，exit 0 |
| `flutter analyze` | No issues found! (ran in 1.6s) |

### 依赖边界扫描

| 边界 | 方法 | 结果 |
|------|------|------|
| contracts/runtime lib 无 Flutter、无 dart:io | grep `^import 'package:flutter/` 与 `^import 'dart:io` | CLEAN（0 命中） |
| sidecar lib dart:io 仅两个适配文件 | grep `^import 'dart:io` | 仅 `io_file_system.dart`、`io_process_launcher.dart` |
| capability 七包零 dart:io 导入 | grep `^import 'dart:io`（精确导入语句） | CLEAN（0 命中；`system_paths.dart` 第 3 行注释文本提及 dart:io 非导入） |
| plugin_flutter 与 toolbox_host lib 无平台专属包 | grep just_audio/flutter_local_notifications/permission_handler/window_manager/shared_preferences/path_provider/url_launcher | CLEAN |
| devkit Flutter 依赖 | pubspec | 已升级为 Flutter 依赖（既有裁定，见 v2/README.md「devkit 边界演进」） |

### 2. 构建矩阵（scripts/v2/build-matrix.ps1）

脚本职责（六端证据模型，不伪造跳过端）：

1. **六端编译图静态检查**（跳过端的替代证据）：扫描 contracts / runtime / sidecar / flutter / toolbox_host lib + capability 七包——平台专属插件依赖（just_audio、flutter_local_notifications、permission_handler、window_manager、shared_preferences、path_provider、url_launcher）零导入；纯 Dart 包零 `dart:io` / `package:flutter` 导入语句（按导入语句行匹配，注释提及不算违规）。
2. `windows` / `web`：`flutter build` 实构建，记录退出码并 `Test-Path` 校验产物。
3. `android`：探测 Android SDK（ANDROID_HOME / ANDROID_SDK_ROOT / LocalAppData）后条件构建，未探测到输出 `SKIPPED-LOCAL-UNAVAILABLE`。
4. `macos` / `linux` / `ios`：非对应宿主系统，输出 `SKIPPED-LOCAL-UNAVAILABLE`。
5. CI 预留：脚本对本机状态无写死假设，可直接被 CI 引用；对应 runner 上跳过端可改为实构建。

实际执行记录（`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/v2/build-matrix.ps1`，退出码 **0**，`RESULT: SUCCESS`）：

| 端 | 状态 | 详情 |
|----|------|------|
| compile-graph | OK | 12 packages scanned, 0 platform-only imports |
| windows | OK | `flutter build windows --debug` 退出码 0；产物 `v2\apps\toolbox_host\build\windows\x64\runner\Debug\toolbox_host.exe`（577,536 B） |
| web | OK | `flutter build web` 退出码 0（首建，经偏差 2 修复后通过）；产物 `v2\apps\toolbox_host\build\web\index.html`（1,243 B） |
| android | OK | SDK 探测命中（`%LOCALAPPDATA%\Android\Sdk`，36.1.0）；`flutter build apk --debug` 退出码 0（首建，经偏差 2 修复后通过）；产物 `v2\apps\toolbox_host\build\app\outputs\flutter-apk\app-debug.apk`（144,937,756 B） |
| macos | SKIPPED-LOCAL-UNAVAILABLE | 非 macOS 宿主；compile-graph 静态检查为替代证据 |
| linux | SKIPPED-LOCAL-UNAVAILABLE | 非 Linux 宿主；compile-graph 静态检查为替代证据 |
| ios | SKIPPED-LOCAL-UNAVAILABLE | 非 macOS 宿主；compile-graph 静态检查为替代证据 |

三端产物均经独立 `ls` 复核真实落盘（非仅脚本内 `Test-Path` 断言）。脚本 `ParseErrors=0`（Parser 静态验证），失败路径（退出码非 0 / 产物缺失 / 扫描 0 包 / 导入违规）均置 `RESULT: FAILED` + exit 1。

### 3. 文档

- `v2/packages/plugin_cli/README.md`（新建）：命令用法与示例、create 生成物字段、错误码与退出码表、依赖边界、验证命令。
- `v2/README.md`（更新）：包职责列表补全 M3 交付包并更新依赖方向；追加「M3 边界」段（plugin_flutter / platform_capabilities / toolbox_host / plugin_cli 职责、「devkit 边界演进」既有裁定、「六端构建证据模型」）；最小验证命令更新为 11 包组逐包测试 + format + analyze + 构建矩阵脚本。

---

## 三、偏差列表

### 偏差 1：plugin_flutter 测试 CWD 敏感（既有包问题，最小修复）

`test/theme/no_hardcoded_style_test.dart` 用相对路径 `Directory('lib')` 定位包源码，从包根运行通过、从 v2 workspace 根逐包运行（CWD=v2/）必然失败。F3-08 要求从 workspace 根集中验证，按「既有包问题报告并最小修复」约束处理：仅改该测试文件，新增 `resolveLibDir()` 双候选定位（`lib` 与 `packages/plugin_flutter/lib`），不触碰任何生产代码。修复后该包从 workspace 根运行 35/35 通过。

### 偏差 2：toolbox_host 补建 web / android 平台目录

`flutter build web` 首跑失败：工程未配置 web 平台（`This project is not configured for the web`）；`flutter build apk --debug` 首跑失败：无 android 平台目录（报 unsupported Gradle project）。按「web 构建失败须修复到成功」与本机 Android SDK 可用（应实构建）处理：

- `flutter create . --platforms web,android`（33 文件；`pubspec.yaml` 与 `lib/main.dart` md5 前后校验未被改动）；
- 删除生成物 `analysis_options.yaml`（include 了未依赖的 flutter_lints，破坏 analyze）与 `test/widget_test.dart`（默认模板引用不存在的 `MyApp`，破坏 analyze）；
- 复验：`flutter analyze` No issues、toolbox_host 9/9 通过、format 131 files 0 changed。

windows 平台目录为既有交付，未被触碰。

### 偏差 3：build-matrix.ps1 三轮修复（脚本自身问题）

| 轮次 | 现象 | 根因 | 修复 |
|------|------|------|------|
| 第 1 轮 | 脚本解析即失败（ParserError，行号偏移 9 行），一行未执行 | 文件为 UTF-8 无 BOM，PS 5.1 按 ANSI/GBK 解码，中文注释的多字节序列尾字节吞掉换行符 | 文件加 UTF-8 BOM |
| 第 2 轮 | `$V2Root` 解析为空，Join-Path 连锁失败；compile-graph 扫 0 包仍报 OK | `Join-Path a b c` 三参数形式是 PowerShell 6+（`-AdditionalChildPath`），PS 5.1 不支持 | 全部改为嵌套两参数 / 字符串插值；新增 V2Root 存在性检查（失败即 exit 1）；compile-graph 扫描 0 包时改报 FAILED（防假 OK） |
| 第 3 轮 | compile-graph 误报 `system_paths.dart` 有 dart:io 导入（实际是注释提及） | 检查用全文 `Contains('dart:io')`，命中注释文本 | 改为 `(?m)^\s*(import|export)\s+['"]dart:io['"]` 等导入语句行正则（platform-only / dart:io / flutter 三处同步修正） |

第 3 轮执行同时暴露并完成了偏差 2 的修复。

### 偏差 4：无其他生产代码改动

contracts / runtime / sidecar / flutter / capabilities 七包 / devkit 生产代码零改动；`v2/pubspec.yaml` 仅追加 workspace 成员 `packages/plugin_cli`。

---

## 四、验证命令退出码汇总

| 命令 | 退出码 |
|------|--------|
| `dart test packages/plugin_cli` | 0（8 tests passed） |
| 各包 `dart test` / `flutter test`（11 项） | 全部 0（合计 250 tests passed） |
| `dart format --output=none --set-exit-if-changed .` | 0 |
| `flutter analyze` | 0（No issues found） |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/v2/build-matrix.ps1`（最终轮） | 0（RESULT: SUCCESS；windows/web/android 三端 OK，macos/linux/ios SKIPPED-LOCAL-UNAVAILABLE） |
