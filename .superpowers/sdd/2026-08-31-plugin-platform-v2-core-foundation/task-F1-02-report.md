# F1-02 GREEN 实现报告

## 状态

`DONE_WITH_CONCERNS`

生产实现、focused GREEN 与静态分析均已完成；全目录格式门禁因只读测试文件在当前 Dart formatter 下需要重排而退出 1。测试文件未被修改，生产文件范围格式检查退出 0。

## 实现

- 新增 `PluginId`：精确使用 `RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$')`，仅提供 `parse`、`tryParse` 和只读 `value`，未暴露公开未校验构造器。
- `PluginId.parse` 对无效格式抛出 `FormatException`；`tryParse` 对无效格式返回 `null`，实现中没有捕获或吞掉其他异常。
- `PluginId` 按 `value` 实现相等性、匹配的 `hashCode` 和仅返回已验证 ID 的 `toString()`。
- 新增 `PluginFailure`：按 `trim().isEmpty` 校验 `code` 与 `message`，失败时抛出且字段名分别为 `code` / `message` 的 `ArgumentError`。
- `PluginFailure.details` 在构造时通过 `Map<String, Object?>.unmodifiable` 创建防御性不可变快照。
- 包入口导出两个公共源文件。
- 未引入 Flutter、`dart:io`、`dart:ffi`、win32、平台包、runtime、业务代码、序列化、时间戳、堆栈或错误分类体系。

## RED 证据（恢复自控制器交接，未重复运行）

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

命令：

```powershell
dart test test/identity/plugin_id_test.dart
```

- 退出码：`1`
- 预期失败原因：`PluginId` 未定义且找不到 `PluginFailure`，属于缺失生产类型导致的正确 RED，而非语法或环境失败。
- 关键结尾：`Some tests failed.`
- 本轮遵守恢复指令，未为流程仪式重跑 RED。
- 当前测试文件按 LF 规范化后的 SHA-256：`1BC3F1840D71FAFD8EB3A99FB7869469E050ED59F876CF19B649F3E9F16E3B44`，与交接值一致。

## GREEN 与验证证据

工作目录均为：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

### Focused GREEN（最终 fresh 运行）

命令：

```powershell
dart test test/identity/plugin_id_test.dart
```

退出码：`0`

完整关键结果：

```text
00:00 +0: loading test/identity/plugin_id_test.dart
00:00 +0: PluginId catches valid dotted lowercase IDs being rejected
00:00 +1: PluginId catches path traversal being accepted as an ID
00:00 +2: PluginId catches uppercase characters bypassing validation
00:00 +3: PluginId catches a single segment being accepted as an ID
00:00 +4: PluginId catches an empty string being accepted as an ID
00:00 +5: PluginId catches malformed dotted segments bypassing validation
00:00 +6: PluginId catches tryParse rejecting a valid ID
00:00 +7: PluginId catches tryParse throwing instead of returning null
00:00 +8: PluginId catches equality or hash code drifting from the ID value
00:00 +9: PluginId catches toString exposing data beyond the validated ID
00:00 +10: PluginFailure catches constructor fields not preserving valid failure data
00:00 +11: PluginFailure catches blank failure codes bypassing validation
00:00 +12: PluginFailure catches blank failure messages bypassing validation
00:00 +13: PluginFailure catches later input-map mutation changing failure details
00:00 +14: PluginFailure catches callers mutating exposed failure details
00:00 +15: All tests passed!
```

### 全目录格式门禁（最终 fresh 运行）

命令：

```powershell
dart format --output=none --set-exit-if-changed .
```

退出码：`1`

完整关键结果：

```text
Changed test\identity\plugin_id_test.dart
Formatted 4 files (1 changed) in 0.01 seconds.
```

首次格式检查还指出 `lib\src\identity\plugin_id.dart` 需要格式化；该生产文件已使用 `apply_patch` 修正。最终检查仅剩只读测试文件。没有运行写入式 formatter，也没有修改测试。

### 生产文件格式补充检查

命令：

```powershell
dart format --output=none --set-exit-if-changed lib
```

退出码：`0`

完整结果：

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

### 静态分析（最终 fresh 运行）

命令：

```powershell
dart analyze
```

退出码：`0`

完整结果：

```text
Analyzing plugin_contracts...
No issues found!
```

验证环境：`Dart SDK version: 3.10.7 (stable) ... on "windows_x64"`。

## 自审与 mutation check

- 放宽 ID 正则会被路径穿越、大小写、单段、空字符串及畸形点分段测试捕获。
- 删除或破坏值相等性 / `hashCode` 一致性会被等值与哈希测试捕获。
- 直接保留输入 `details` map 会被“构造后修改输入 map”测试捕获。
- 返回可变 `details` map 会被“调用方修改公开 map”测试捕获。
- 源码自审确认：对象字段均为只读；`PluginId` 仅有私有构造器；`PluginFailure` 的 `ArgumentError.name` 与字段名一致；`tryParse` 没有宽泛 catch；未实现 F1-03 或其他功能。

## Authored files

- `v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart`
- `v2/packages/plugin_contracts/lib/src/errors/plugin_failure.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-02-report.md`

测试文件保持只读；未修改 `progress.yaml`、SDD ledger、pause handoff 或其他文件。Dart 可能使用既有 `.dart_tool` / `v2/pubspec.lock` 恢复缓存，它们不属于 authored implementation。

## Concerns

- brief 要求 `dart format --output=none --set-exit-if-changed .` 退出 0，但父任务同时明确要求测试文件只读。当前 Dart 3.10.7 会重排交接测试文件中的三处表达式/调用格式，因此这两个约束无法同时满足。本轮保留测试原样并如实记录退出码 1；生产文件范围格式检查退出 0。
- 除上述只读测试格式门禁冲突外，无其他 concern。

## Fix round 1

### 修复后状态

`DONE`

独立 reviewer 的 Important finding 已处理：控制器明确允许对既有测试做 formatter-equivalent 纯布局修正，全目录格式门禁现退出 0。初始报告中的格式 concern 已解决。

### 改动

- 先运行只读 `dart format --output=show test/identity/plugin_id_test.dart`（退出码 `0`），确认 formatter 只要求三处调用布局重排，关键结尾为 `Formatted 1 file (1 changed) in 0.00 seconds.`。
- 使用 `apply_patch` 将大写 ID 的单个 `expect` 收拢为 formatter 布局，将 `ArgumentError.having` 收拢为 formatter 布局，并将输入 map 的 `PluginFailure` 构造调用展开为 formatter 布局。
- 第一次局部补丁后发现文件混有 CRLF/LF，导致全目录门禁仍报 `Changed test\identity\plugin_id_test.dart`；随后仍仅使用 `apply_patch` 对相同文本做全文件 LF 规范化。没有使用写入式 formatter。
- 未修改任何字符串、断言、测试名称、测试数量、测试顺序或生产文件。

### 覆盖测试

- `PluginId`：有效 ID、路径穿越、大小写、单段、空字符串、畸形点分段、`tryParse` 成功/失败、值相等与哈希、`toString`。
- `PluginFailure`：字段保留、空白 code/message 校验、输入 map 防御性拷贝、公开 map 不可变。
- 自审统计仍为 `15` 个 `test(...)`、`21` 个 `expect(...)`；focused test 仍执行并通过 15 个测试。

### 最终 fresh 验证

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

#### Focused test

命令：

```powershell
dart test test/identity/plugin_id_test.dart
```

退出码：`0`

完整关键输出：

```text
00:00 +0: loading test/identity/plugin_id_test.dart
00:00 +0: PluginId catches valid dotted lowercase IDs being rejected
00:00 +1: PluginId catches path traversal being accepted as an ID
00:00 +2: PluginId catches uppercase characters bypassing validation
00:00 +3: PluginId catches a single segment being accepted as an ID
00:00 +4: PluginId catches an empty string being accepted as an ID
00:00 +5: PluginId catches malformed dotted segments bypassing validation
00:00 +6: PluginId catches tryParse rejecting a valid ID
00:00 +7: PluginId catches tryParse throwing instead of returning null
00:00 +8: PluginId catches equality or hash code drifting from the ID value
00:00 +9: PluginId catches toString exposing data beyond the validated ID
00:00 +10: PluginFailure catches constructor fields not preserving valid failure data
00:00 +11: PluginFailure catches blank failure codes bypassing validation
00:00 +12: PluginFailure catches blank failure messages bypassing validation
00:00 +13: PluginFailure catches later input-map mutation changing failure details
00:00 +14: PluginFailure catches callers mutating exposed failure details
00:00 +15: All tests passed!
```

#### 全目录格式门禁

命令：

```powershell
dart format --output=none --set-exit-if-changed .
```

退出码：`0`

完整输出：

```text
Formatted 4 files (0 changed) in 0.01 seconds.
```

#### 静态分析

命令：

```powershell
dart analyze
```

退出码：`0`

完整输出：

```text
Analyzing plugin_contracts...
No issues found!
```

### 新哈希与语义自审

- 测试文件 LF-normalized SHA-256：`EE8056FC987554D6F37F273DD5C1D4FA8B32A0FB8B962D59A5535209F6B59A89`。
- 文件现为一致 LF（`CRLF = 0`、`LF = 112`）；全目录 formatter 证明确切布局无需再改。
- 修复只改变换行与调用排版；字符串字面量、闭包、matcher、赋值、断言目标以及执行顺序均保持不变。
- focused test 的同一 15 项名称和通过顺序与修复前一致，证明行为覆盖未丢失。
- 未修改生产文件、`progress.yaml`、SDD ledger、review 文件、pause handoff 或其他文件；未执行 Git，未派发子智能体。

### Fix round 1 concerns

- 无。
