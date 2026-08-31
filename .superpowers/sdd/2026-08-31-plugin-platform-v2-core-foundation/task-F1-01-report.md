# F1-01 实施报告：创建独立 Dart workspace

## 状态

PASS

已在 `v2/` 下创建 Dart 3.10 workspace，以及三个可解析的空 package：
`plugin_contracts`、`plugin_runtime`、`plugin_devkit`。未迁移或修改 legacy 实现。

## 实现内容

- 根 workspace 使用任务卡指定的名称、SDK 约束和三个成员路径。
- 根分析配置包含 `package:lints/recommended.yaml`，并启用
  `strict-casts`、`strict-inference`、`strict-raw-types`。
- 三个 package 均设置 `publish_to: none`、`resolution: workspace` 和
  `sdk: ^3.10.0`。
- `plugin_contracts` 无运行时依赖；`plugin_runtime` 仅以 path 依赖
  `plugin_contracts`；`plugin_devkit` 仅以 path 依赖前两个 package。
- 三个 package 均使用非 `any` 的稳定开发依赖约束：`lints: ^6.0.0`、
  `test: ^1.26.0`。Dart 3.10.7 实际解析为 `lints 6.1.0` 和 `test 1.31.1`。
- 三个公共 library 文件保持为空，未引入 Flutter、`dart:ffi`、`win32`、
  平台插件、业务插件或 Sidecar 代码。

## 验证记录

工作目录均为 `D:\my\flutter-plugins-platform\v2`。

1. `dart pub get`
   - 首次在 sandbox 内执行，约 120 秒无任何输出，按超时控制主动中止；
     退出码 1（中止导致）。
   - 随后以同一命令在允许联网的执行环境重试：退出码 0。
   - 关键输出：`Resolving dependencies...`、`Downloading packages...`、
     `Changed 48 dependencies!`。
   - 解析结果包含 `lints 6.1.0`、`test 1.31.1`，依赖清单中没有 Flutter
     package。

2. `dart pub workspace list`
   - 首次在 sandbox 内执行，60 秒无任何输出，主动中止；退出码 1
     （中止导致）。
   - 随后以同一命令在 sandbox 外重试：退出码 0。
   - 关键输出显示根 package `plugin_platform_v2_workspace`，并且 workspace
     成员恰好为：
     - `plugin_contracts` -> `packages\plugin_contracts\`
     - `plugin_runtime` -> `packages\plugin_runtime\`
     - `plugin_devkit` -> `packages\plugin_devkit\`

3. `dart analyze`
   - 首次执行：退出码 0，但报告三个
     `dangling_library_doc_comments` info，不满足任务要求的 no issues。
   - 按配置脚手架 schema 反馈移除三个悬空 library 文档注释，使入口文件
     保持真正为空。
   - 复跑同一命令：退出码 0。
   - 关键输出：`Analyzing v2...`、`No issues found!`。

4. 生成物清理
   - `dart pub get`/分析生成的 `v2/pubspec.lock` 与各级 `.dart_tool` 文件已
     使用 `apply_patch` 删除，不纳入任务结果。

## 改动文件

- `v2/pubspec.yaml`
- `v2/analysis_options.yaml`
- `v2/packages/plugin_contracts/pubspec.yaml`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- `v2/packages/plugin_runtime/pubspec.yaml`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- `v2/packages/plugin_devkit/pubspec.yaml`
- `v2/packages/plugin_devkit/lib/plugin_devkit.dart`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-01-report.md`

## 自检

- 对照任务卡逐一复核了 8 个生产文件，内容与精确配置和依赖方向一致。
- 最终 `v2/` 文件范围仅包含任务卡授权的 8 个生产文件；未保留 lock 或
  `.dart_tool` 生成文件。
- 授权源文件中无 Flutter、`dart:ffi`、`win32`、平台/业务插件或 Sidecar
  引用。
- 未修改 progress.yaml、ledger、legacy、测试或文档文件（本报告除外）。
- 未执行任何 Git 命令，未派发子智能体。

## 疑虑

- sandbox 内 Dart 子进程两次出现无输出挂起；在获准的 sandbox 外环境执行
  后验证正常通过。这是执行环境现象，未发现 workspace 配置缺陷。
- 由于任务卡要求不保留 `pubspec.lock` 和 `.dart_tool`，交付树本身不携带
  已解析状态；后续开发者首次使用前需要重新执行 `dart pub get`。
- 无架构歧义或超范围实现。
