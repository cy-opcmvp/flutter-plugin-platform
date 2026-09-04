# F1-08 文档与集成证据

## 文档摘要

补充 v2 workspace、`plugin_contracts` 与 `plugin_runtime` 三份 README，记录 M1 包职责、依赖方向、显式目标、能力依赖和 Flutter/平台/Sidecar 边界；未扩展公共 API，也未修改生产代码、测试或 manifest。

## 验证记录

命令均从 `v2` 执行；包测试命令的工作目录按命令单列。

| # | 命令 | 结果 |
|---|---|---|
| 1 | `dart pub get --offline` | 退出码 0；依赖解析成功 |
| 2 | `dart pub workspace list` | 退出码 0；列出 3 个 workspace package |
| 3 | `dart test`（`packages/plugin_contracts`） | 退出码 0；48 tests passed |
| 4 | `dart test`（`packages/plugin_runtime`） | 退出码 0；26 tests passed |
| 5 | `dart test`（`packages/plugin_devkit`） | 退出码 0；8 tests passed |
| 6 | `dart format --output=none --set-exit-if-changed .` | 退出码 0；Formatted 25 files (0 changed) |
| 7 | `dart analyze` | 退出码 0；No issues found |
| 8 | `dart pub deps --style=compact` | 退出码 0；列出 Dart SDK 3.10.7、环境中的 Flutter SDK 3.38.7，以及本地三包和 test/lints/matcher 依赖；无 Flutter package 依赖 |
| 9 | `rg -n -S "package:flutter|dart:io|dart:ffi|win32|\bPlatform\b|Platform\.|Process\b|FileSystem|environment" packages/plugin_contracts/lib packages/plugin_runtime/lib packages/plugin_devkit/lib` | 退出码 0；未发现命中（无匹配的 rg 退出码 1 归一为 0） |

## 依赖与边界证据

- `plugin_runtime/pubspec.yaml` 仅声明 `plugin_contracts`；`plugin_devkit` 才依赖 runtime，依赖方向保持 `plugin_contracts <- plugin_runtime <- plugin_devkit`。
- `PluginResolver.resolve` 的目标参数为显式输入；M1 package `lib` 未使用 Flutter、`dart:io`、`dart:ffi`、win32 或平台全局。
- resolver 只生成解析、顺序和 `PluginFailure` 视图；lifecycle machine 不调用插件生命周期对象，registry/catalog 以候选状态验证后提交。

## 本任务编写文件

- `v2/README.md`
- `v2/packages/plugin_contracts/README.md`
- `v2/packages/plugin_runtime/README.md`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-08-report.md`

## Concerns

- F1-07 历史报告中的计数 minor 不在本任务修复；本次 fresh evidence 为 contracts/runtime/devkit `48/48`、`26/26`、`8/8`，留给 G1 triage。
- `dart pub get --offline` 依赖本机缓存；本报告记录的是当前工作区可复现结果。
- 按 baseline，验证产生或保留的 `v2/.dart_tool` 与 `v2/pubspec.lock` 仍作为 controller-owned 验证/恢复工件，不计入本任务 authored files。
