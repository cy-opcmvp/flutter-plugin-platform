# plugin_cli

`plugin_cli` 是插件开发者的命令行脚手架与验证工具：一键生成合法的插件骨架、严格校验清单、打包 SCP1 安装包：

- `create`：在目标目录生成最小合法 `plugin.json`（12 个必需字段）与入口骨架；`builtin` 生成实现 `PluginLifecycle` 的 Dart 骨架，`sidecar` 生成符合 M2 夹具协议的 Python echo 骨架。
- `validate`：用 `PluginManifestCodec` 严格解码 `<dir>/plugin.json`；`kind=sidecar` 时入口文件必须存在，否则失败。
- `pack`：把 `<dir>` 下全部文件（`plugin.json` 必含）打进 SCP1 容器，随后立即用 `PackageReader` 回读自校验，防止产出不可读的包。

本包是纯 Dart 命令行工具，零 Flutter 依赖，可在 CI 或任意装有 Dart SDK 的环境中运行。

## 命令用法

在 v2 workspace 根执行（`plugin_cli` 已注册进 pub workspace）：

```powershell
# 生成 builtin 插件骨架（Dart）
dart run plugin_cli create --id tools.demo --name Demo --kind builtin <dir>

# 生成 sidecar 插件骨架（Python，对齐 M2 帧协议）
dart run plugin_cli create --id tools.demo --name Demo --kind sidecar <dir>

# 校验插件目录
dart run plugin_cli validate <dir>

# 打包为 SCP1 安装包并自校验
dart run plugin_cli pack <dir> -o out.scp
```

### create

| 选项 | 说明 |
|------|------|
| `--id` | 反向域插件 ID，如 `tools.demo`（非法即用法错误） |
| `--name` | 展示名 |
| `--kind` | `builtin` 或 `sidecar` |
| `<dir>` | 目标目录（最后的位置参数；不存在则创建） |

- 已存在 `plugin.json` 或入口文件时拒绝覆盖（保护既有插件）。
- 生成物：
  - `plugin.json`：`id` / `name` / `version`（1.0.0）/ `apiVersion`（1）/ `kind` / `targets` / `entrypoint` / `provides` / `requires` / `surfaces` / `configSchemaVersion`（1）/ `dataSchemaVersion`（1）。
  - builtin：`<id 蛇形>_plugin.dart`（如 `tools.demo` → `tools_demo_plugin.dart`），`entrypoint` 为 `builtin:<id>`，`targets` 含全部六端，`surfaces` 为 `['page']`。
  - sidecar：`main.py`，`entrypoint` 为 `main.py`，`targets` 为 `['windows']`（sidecar 仅桌面端），`surfaces` 为 `['command']`。
- 落盘前对生成清单做一次 `PluginManifestCodec` 严格解码（防御模板与 codec 漂移）。

sidecar 骨架内置 M2 夹具协议：4 字节大端长度前缀帧（`struct ">I"`）、启动先发送 `"ready"` 就绪字符串帧（由宿主会话吞掉）、JSON-RPC 2.0 消息（`ping` → `pong`，未知方法返回 `-32601`）。

### validate

成功输出形如 `OK tools.demo (sidecar v1.0.0)`；失败向 stderr 输出单行 JSON（见下）。

### pack

- 递归打包 `<dir>` 下全部文件，路径为正斜杠相对路径；输出文件自身被排除，避免自包含。
- 目录缺少 `plugin.json` 时失败，不产出文件。
- 打包后立即 `PackageReader.fromBytes(bytes).read()` 回读校验，任何 `PackageException` 都会使命令失败且不写出文件。

## 错误码与退出码

失败输出为 stderr 上的单行 JSON：`{"code": "...", "message": "...", "details": {...}}`，便于脚本消费。

| 错误码 | 触发场景 | details |
|--------|---------|---------|
| `cli.invalid_manifest` | 清单缺失 / JSON 非法 / 字段解码失败 | `field`、`message` 或 `path` |
| `cli.missing_entrypoint` | sidecar 清单声明的入口文件不存在 | `entrypoint` |
| `cli.pack_failed` | 打包或自校验失败 | `reason`：`ioError` / `entrypointMissing` / 底层 `PackageException` 原因（如 `manifestMissing`） |

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 结构化失败（见上表） |
| 2 | 用法错误（缺参、未知命令、ID/kind 非法、拒绝覆盖等） |

## 依赖边界

依赖方向为 `plugin_contracts <- plugin_cli`、`plugin_sidecar <- plugin_cli`。本包只依赖契约包（清单与 ID 严格解码）与 sidecar 框架（SCP1 打包/回读），不依赖 `plugin_runtime` / `plugin_devkit` / Flutter。作为开发者工具，`dart:io` 在命令实现中直接使用（读写插件目录是其职责本身），核心分发逻辑（`CliRunner`）保持纯 Dart、通过 `StringSink` 注入输出，测试无需真实进程。

## 验证命令

在本目录（或 workspace 根 `v2/`）执行：

```powershell
dart pub get --offline
dart test
dart format --output=none --set-exit-if-changed .
dart analyze
```
