# Plugin Platform v2

M1 只交付不依赖 Flutter 和具体平台实现的核心基础：契约、纯 Dart 运行时和开发测试夹具。真实插件与 Flutter 宿主在后续里程碑接入。

## 包职责与依赖

- `plugin_contracts`：稳定的插件身份、失败值、清单、目标/种类、能力契约和生命周期接口。
- `plugin_runtime`：生命周期状态机、注册表/能力目录，以及按目标和能力依赖生成解析结果的纯逻辑。
- `plugin_devkit`：面向测试的 fake 插件和失败码 matcher。

依赖方向为：`plugin_contracts <- plugin_runtime <- plugin_devkit`。运行时不依赖 devkit；插件依赖能力契约，不直接依赖其他插件实现。

## M1 边界

宿主必须把目标显式传给 `PluginResolver.resolve(manifests, target)`；核心不读取平台全局状态、环境变量或文件系统。Builtin 与 Sidecar 清单共用同一套契约，但 M1 不包含 Flutter 宿主、平台适配器、Sidecar 安装器/进程/RPC、CLI 或业务插件。

契约中的目标词汇固定为 `windows`、`macos`、`linux`、`android`、`ios`、`web`。Windows-first 的端到端接入从后续里程碑开始。

## 最小验证命令

在本目录执行：

```powershell
dart pub get --offline
dart pub workspace list
dart test packages/plugin_contracts
dart test packages/plugin_runtime
dart test packages/plugin_devkit
dart format --output=none --set-exit-if-changed .
dart analyze
```
