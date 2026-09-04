# Task F1-04 报告：生命周期契约与确定性状态机

## 状态

`DONE`

F1-04 实现、focused/full 测试、workspace 全量格式门禁与 workspace analyze 均通过。先前的 0 字节 baseline blocker 已由 controller 明确裁定并按最小空语义维护解决，详见 `Context resolution`。

## 实现

- 在 `plugin_contracts` 定义精确的八值 `PluginLifecycleState` 生命周期词汇，以及只有 `activate`、`deactivate`、`dispose` 三个异步方法的 `PluginLifecycle` 接口。
- 在 `plugin_runtime` 实现只接收已校验 `PluginId` 的 `LifecycleMachine`；初始状态固定为 `discovered`，无任意初始状态入口，也不接收、保存或调用插件对象。
- 精确实现 8 条普通边和 5 条进入 `failed` 的边；同态、所有未列边及全部 `disposed -> *` 均拒绝。
- `LifecycleTransitionResult` 是 `final class`，构造器私有，四个字段只读，`succeeded` 精确派生自 `failure == null`。
- 非法转换返回全新的 `PluginFailure`，稳定代码为 `lifecycle.invalid_transition`；详情只有 `pluginId`、`from`、`to`，并通过 accepted `PluginFailure` 获得不可修改快照。
- 两个包的公共入口仅新增所需 exports，保留 F1-02/F1-03 accepted exports。

## 严格 TDD 证据

### RED

生产源和 exports 尚不存在时，仅先创建：

`v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_runtime`

命令：

```text
dart test test/lifecycle/lifecycle_machine_test.dart
```

退出码：`1`

关键原始输出：

```text
00:00 +0: loading test/lifecycle/lifecycle_machine_test.dart
00:00 +0 -1: loading test/lifecycle/lifecycle_machine_test.dart [E]
Failed to load "test/lifecycle/lifecycle_machine_test.dart":
test/lifecycle/lifecycle_machine_test.dart:323:23: Error: Type 'LifecycleMachine' not found.
test/lifecycle/lifecycle_machine_test.dart:380:43: Error: Type 'PluginLifecycle' not found.
test/lifecycle/lifecycle_machine_test.dart:8:14: Error: Undefined name 'PluginLifecycleState'.
00:00 +0 -1: Some tests failed.
```

RED 原因精确为 F1-04 公共类型/导出缺失；没有 Dart 语法、依赖解析或环境失败。

### 初次 GREEN

同一工作目录、同一 focused 命令，退出码：`0`。

```text
00:00 +15: All tests passed!
```

最终恢复 live mutation 后重新运行同一 focused 命令，退出码仍为 `0`：

```text
00:00 +15: All tests passed!
```

## 完整回归证据

### plugin_runtime full

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_runtime`

命令：`dart test`

最终退出码：`0`

```text
00:00 +15: All tests passed!
```

### plugin_contracts full

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

命令：`dart test`

最终退出码：`0`

```text
00:00 +48: All tests passed!
```

## 格式与分析证据

工作目录：`E:\my\flutter-plugin-platform\v2`

### Authored Dart 文件格式

命令：

```text
dart format --output=none --set-exit-if-changed packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart packages/plugin_contracts/lib/plugin_contracts.dart packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart packages/plugin_runtime/lib/plugin_runtime.dart packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart
```

最终退出码：`0`

```text
Formatted 5 files (0 changed) in 0.01 seconds.
```

### Workspace 全量格式门禁

首次命令：`dart format --output=none --set-exit-if-changed .`

首次退出码：`1`

```text
Changed packages\plugin_devkit\lib\plugin_devkit.dart
Changed packages\plugin_runtime\lib\src\lifecycle\lifecycle_machine.dart
Changed packages\plugin_runtime\test\lifecycle\lifecycle_machine_test.dart
Formatted 15 files (3 changed) in 0.03 seconds.
```

按 brief 使用 `dart format --output=show <path>` 只读检查；仅对两个允许的 F1-04 文件用 `apply_patch` 等价修正。最终复跑同一 workspace 命令，退出码仍为 `1`，但只剩禁止修改的基线文件：

```text
Changed packages\plugin_devkit\lib\plugin_devkit.dart
Formatted 15 files (1 changed) in 0.04 seconds.
```

只读元数据确认该既存文件仍为 `0` 字节；本任务没有修改它。

### Workspace analyze

命令：`dart analyze`

最终退出码：`0`

```text
Analyzing v2...
No issues found!
```

## Mutation 检查

执行了一次 live mutation：临时将允许边 `activating -> active` 从 `true` 改为 `false`，运行 focused 测试后退出码为 `1`。首个具名失败及核心差异为：

```text
LifecycleMachine successful transitions catches any activation-chain edge or result field being wrong [E]
Expected: PluginLifecycleState:<PluginLifecycleState.active>
  Actual: PluginLifecycleState:<PluginLifecycleState.activating>
```

随后立即用 `apply_patch` 恢复，并获得最终 focused/full GREEN 证据。

现实 mutation 与具名测试覆盖映射：

| Mutation | 捕获它的具名测试 |
| --- | --- |
| 删除允许边 | `catches any activation-chain edge or result field being wrong`（已 live 验证） |
| 添加禁止的 `discovered -> active` | `catches discovered-to-active mutation or unstable diagnostics` |
| 校验前修改状态 | `catches discovered entering failed or mutating before rejection`，以及各拒绝测试的机器状态断言 |
| 允许任意 `disposed -> *` | `catches disposed losing terminal behavior for any requested state`（遍历八个枚举值） |
| 非法转换抛异常而非返回失败 | 各 `LifecycleMachine rejected transitions ...` 具名测试会以测试错误失败 |
| 错误 failure code/details 或可修改 details | `catches discovered-to-active mutation or unstable diagnostics` |
| 复用 result/failure 实例 | `catches illegal attempts reusing result or failure instances` |
| 调用插件回调 | `catches the machine invoking plugin lifecycle callbacks`（三项计数均手写期望为 0） |

## 自审

- enum 精确包含且只包含 `discovered`、`resolved`、`inactive`、`activating`、`active`、`deactivating`、`failed`、`disposed`。
- `PluginLifecycle` 精确为三个无参数 `Future<void>` 方法；私有计数 fixture 可直接实现该接口。
- `LifecycleMachine` 只存 `PluginId` 和当前状态；无插件对象、callback、context、I/O、Flutter、平台 API、服务定位器或全局可变状态。
- 成功结果逐字段验证 previous/requested/post state、null failure 与 `succeeded == true`；拒绝结果验证状态不变、non-null failure 与 `succeeded == false`。
- 激活、停用、重新激活、所有非 discovered 失败边、失败后释放、inactive 直接释放、同态拒绝及 disposed 终态均由真实代码测试覆盖。
- 重复非法尝试返回独立 result/failure 实例；非法转换不抛出且不变更状态。
- 测试无 mocks、clock、delay、I/O、Flutter、平台 API或源文本 grep；成功链期望均为手写枚举/字段。
- 未实现 F1-05 或后续的 install、registry、catalog、resolver、加载器、Sidecar、Flutter 或业务插件能力。

## Authored files

- `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart`
- `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart`
- `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-04-report.md`

未修改 progress YAML、ledger、brief、baseline、review；除 controller 授权的单字节空 stub 基线维护外，未修改任何其他源文件。未运行 Git 命令，未派发子智能体。

## Concerns / 所需上下文

历史 blocker 是 `v2/packages/plugin_devkit/lib/plugin_devkit.dart`：该文件在本任务开始时即存在且为 0 字节，Dart formatter 会为其生成格式化内容，因此最初的 workspace 全量格式命令 exit `1`；同时它不在 F1-04 production authored files 中，原 brief 又禁止修改其他文件。

该 concern 已由 controller 的 SDD ledger 裁定解决；恢复验证后无剩余 concern。

## Context resolution

### Controller 裁定

Controller 已在 SDD ledger 记录范围裁定：允许把既有 0 字节 `v2/packages/plugin_devkit/lib/plugin_devkit.dart` 仅规范化为 Dart formatter 的空白 LF 输出，作为跨任务 baseline maintenance；禁止向该文件添加 export、声明、注释或任何 F1-07 行为。

### 精确变更

- 仅用 `apply_patch` 将该 stub 从 `0` 字节改为 `1` 字节。
- 只读字节检查原始输出：

```text
ByteCount=1
Bytes=10
```

- 唯一字节为十进制 `10`（LF）。文件仍不包含 token、注释、声明、export 或可执行语义，因此是精确的空语义 formatter-equivalent 变更。
- 此项是 controller-authorized baseline maintenance，不计入 F1-04 production authored scope；恢复期间未修改任何生命周期源或测试。

### 新鲜验证证据

工作目录 `E:\my\flutter-plugin-platform\v2`：

`dart format --output=none --set-exit-if-changed .`，退出码 `0`：

```text
Formatted 15 files (0 changed) in 0.03 seconds.
```

`dart analyze`，退出码 `0`：

```text
Analyzing v2...
No issues found!
```

工作目录 `E:\my\flutter-plugin-platform\v2\packages\plugin_runtime`：

- `dart test test/lifecycle/lifecycle_machine_test.dart`，退出码 `0`：`00:00 +15: All tests passed!`
- `dart test`，退出码 `0`：`00:00 +15: All tests passed!`

工作目录 `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`：

- `dart test`，退出码 `0`：`00:00 +48: All tests passed!`

### Scope 与 concerns

- 本次恢复只修改 controller 授权的空 stub 和本报告。
- 未修改 lifecycle production code、exports 或 tests；未实现 F1-07 行为。
- 未运行 Git 命令，未派发子智能体，所有写入均通过 `apply_patch`。
- 原 workspace format blocker 已消除；无剩余 concerns。

## Fix round 1

### Reviewer findings 与处理

- **I1**：删除 `catches the machine invoking plugin lifecycle callbacks`。该测试创建 `_CountingLifecycle` 后从未把它交给 `LifecycleMachine`，因此三个零计数与 machine 行为没有因果关系，无法捕获未来新增 plugin/callback 路径。
- **M1**：删除 `catches lifecycle interface drifting from its three async methods`。fixture 已成功 `implements PluginLifecycle` 后，`isA<PluginLifecycle>()` 只重复 Dart 编译器已经证明的类型关系，测试名过度承诺了接口漂移检测能力。
- 删除只被上述两个测试使用的完整 `_CountingLifecycle` fixture；没有用 source grep、I/O、负向编译子进程或其他同义反复替代。

### Controller ruling

Controller 已在 SDD ledger 裁定：`LifecycleMachine` 的绑定设计禁止接收或保存 `PluginLifecycle`。在不引入契约明确禁止的耦合前提下，无法建立“machine 调用 plugin/callback”的真实因果 runtime unit test。state-only / no-plugin 的 machine API 与字段边界改由独立 reviewer 执行结构门禁。

因此，本报告早先 mutation 表和自审中关于 `_CountingLifecycle` fixture、callback 零计数测试能够自动守住“machine 不调用插件”的陈述，均由本节明确取代：F1-04 unit tests 不再声称能自动检测未来新增的 plugin/callback API 或字段；该负向架构边界依赖 controller 指定的 reviewer 结构门禁。

### 测试计数与剩余覆盖

- runtime focused/full 测试数由 `15` 降为 `13`，精确删除两个 tautological tests。
- 保留的 13 个测试继续覆盖：八值生命周期词汇；固定 `discovered` 初态与 `PluginId` identity；完整激活链；停用/重新激活链；`activating -> failed -> disposed`；`resolved`、`inactive`、`active`、`deactivating` 进入 `failed`；`inactive -> disposed`；非法 transition 的稳定 code/message/details、不变状态和失败结果语义；`discovered -> failed`、`active -> inactive`、同态拒绝；`disposed` 对全部枚举值保持终态；重复非法转换返回独立 result/failure 实例。
- 生产生命周期契约、转换表、失败结构和 exports 均未改动。

### 新鲜验证证据

工作目录 `E:\my\flutter-plugin-platform\v2\packages\plugin_runtime`：

- `dart test test/lifecycle/lifecycle_machine_test.dart`：退出码 `0`，`00:00 +13: All tests passed!`
- `dart test`：退出码 `0`，`00:00 +13: All tests passed!`

工作目录 `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`：

- `dart test`：退出码 `0`，`00:00 +48: All tests passed!`

工作目录 `E:\my\flutter-plugin-platform\v2`：

- `dart format --output=none --set-exit-if-changed .`：退出码 `0`，`Formatted 15 files (0 changed) in 0.03 seconds.`
- `dart analyze`：退出码 `0`，`Analyzing v2...` / `No issues found!`

### Scope / concerns

- 本轮仅修改 `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart` 和本报告。
- 未修改 production code、exports、packages、brief、baseline、progress、ledger 或 review artifacts；未运行 Git 命令，未派发子智能体；所有写入均通过 `apply_patch`。
- 无阻塞 concern。已知验证边界：state-only / no-plugin API 与字段约束不由 unit test 自动守护，按 controller ruling 由独立 reviewer 做结构门禁。
