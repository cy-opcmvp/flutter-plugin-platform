# Task F1-03 报告：严格清单与能力契约

## 状态

`DONE_WITH_CONCERNS`

F1-03 已按 brief 的唯一需求边界实现，并严格先写两个测试文件、观察缺失公共 API 的 RED，再添加最小生产实现和 exports。最终 focused test、完整包测试、全目录 format gate 与 analyze 均通过。

## 实现

- 新增精确枚举：`PluginTarget` 六个目标、`PluginKind` 两种插件类型；JSON wire 值由精确枚举名编码，并由显式分支严格解码。
- 新增不可变 `CapabilityDescriptor` 与 `CapabilityRequirement`，共享 brief 指定的 ID 正则和正版本号校验；无 unchecked 公共构造器。
- 新增不可变 `PluginManifest`，验证非空文本、正版本、目标集合、能力 ID 去重、surface 约束和 sidecar 桌面目标；四个集合均保存保持顺序的 defensive unmodifiable snapshot。
- 新增静态 `PluginManifestCodec.decode`/`encode`，严格接受十二个必需顶层键、严格验证 JSON runtime shape、严格验证嵌套能力二键 schema，并把模型校验错误转换为只命名相关顶层字段的 `FormatException`。
- `encode` 每次创建新的顶层 map、列表和嵌套能力 map，不复用 manifest 的集合。
- 更新包入口导出全部 F1-03 公共类型。

## 严格 TDD 证据

工作目录均为：

`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

### RED

在任何 F1-03 生产源文件或新 export 创建之前，只创建了：

- `test/capability/capability_descriptor_test.dart`
- `test/manifest/plugin_manifest_codec_test.dart`

随后执行精确命令：

```powershell
dart test test/manifest test/capability
```

- 退出码：`1`
- 关键输出：
  - `Undefined name 'PluginManifestCodec'.`
  - `Undefined name 'PluginKind'.`
  - `'PluginTarget' isn't a type.`
  - `Method not found: 'PluginManifest'.`
  - `Method not found: 'CapabilityDescriptor'.`
  - `Method not found: 'CapabilityRequirement'.`
  - `00:00 +0 -2: Some tests failed.`
- RED 原因确认：全部是 F1-03 公共类型/导出尚不存在；不是测试语法、依赖或 SDK 环境失败。
- concern：命令在已完整打印 `Some tests failed` 后因当前 login PowerShell profile 未自动回收会话；立即发送 `Ctrl+C` 后得到退出码 1。后续全部 Dart 验证使用同一 Windows PowerShell 的 no-profile/login-false 执行方式，均正常自行退出。

### Focused GREEN

添加最小生产实现和 exports 后执行：

```powershell
dart test test/manifest test/capability
```

- 首次 GREEN：退出码 `0`，`00:00 +31: All tests passed!`
- 最终新鲜复验：退出码 `0`，`00:00 +31: All tests passed!`

### 完整包测试

精确命令：

```powershell
dart test
```

- 首次：退出码 `0`，`00:00 +46: All tests passed!`
- 最终新鲜复验：退出码 `0`，`00:00 +46: All tests passed!`
- F1-02 的 `PluginId`/`PluginFailure` 测试包含在完整包测试中并保持绿色。

### 全目录 format gate

精确命令：

```powershell
dart format --output=none --set-exit-if-changed .
```

- 首次 gate：退出码 `1`；只报告三个文件存在格式差异：
  - `lib/src/capability/capability_descriptor.dart`
  - `lib/src/manifest/plugin_manifest_codec.dart`
  - `test/manifest/plugin_manifest_codec_test.dart`
- 按 brief 要求仅使用以下只读命令查看格式结果：

```powershell
dart format --output=show lib\src\capability\capability_descriptor.dart
dart format --output=show lib\src\manifest\plugin_manifest_codec.dart
dart format --output=show test\manifest\plugin_manifest_codec_test.dart
```

- 等价格式改动全部通过 `apply_patch` 手工应用；未运行任何写入式 formatter。
- 修正后 gate：退出码 `0`，`Formatted 10 files (0 changed) in 0.02 seconds.`
- 最终新鲜复验：退出码 `0`，`Formatted 10 files (0 changed) in 0.02 seconds.`

### Analyze

精确命令：

```powershell
dart analyze
```

- 首次：退出码 `0`，`Analyzing plugin_contracts...` / `No issues found!`
- 最终新鲜复验：退出码 `0`，`Analyzing plugin_contracts...` / `No issues found!`

## 测试质量自审

- 所有新增测试名称均描述可捕获的生产破坏，例如 unknown-field 静默接受、正版本 guard 被移除、集合快照被别名替代或 encode 复用内部列表。
- 所有期望均来自手写 literal 和 brief 的固定 fixture；未用生产 builder 计算 expected JSON。
- 全部测试直接调用真实构造器和真实 codec；没有 mocks、fakes、source grep 或序列化框架。
- 失败断言同时验证 `FormatException` 类型及消息包含相关顶层字段；不冻结完整英文措辞。
- capability 构造器失败断言同时验证 `ArgumentError.name` 为 `id` 或 `version`。
- valid fixture 的 decode 逐字段断言全部十二个模型字段，encode 使用深集合相等断言精确十二键 fixture。

## Mutation check

以下现实 mutation 均由现有命名测试捕获：

| 现实 mutation | 捕获测试 |
| --- | --- |
| 删除 unknown top-level field 拒绝分支 | `catches unknown top-level fields being silently accepted` |
| 删除/放宽 descriptor 正版本 guard（包括把 `<= 0` 改成 `< 0`） | `catches zero or negative descriptor versions being accepted` |
| 删除/放宽 requirement 正版本 guard | `catches zero or negative requirement versions being accepted` |
| 删除/放宽 `apiVersion`、`configSchemaVersion`、`dataSchemaVersion` 任一正版本 guard | `catches non-positive manifest schema versions being accepted`（逐字段、0 与 -1） |
| nested capability version 不再通过正版本构造器 | `catches non-positive nested capability versions being accepted` |
| 删除 targets 非空判断 | `catches empty or duplicate target sets being accepted` |
| 删除 targets 去重判断 | `catches empty or duplicate target sets being accepted` |
| 删除 provides capability ID 去重 | `catches duplicate provided capability IDs being accepted` |
| 删除 requires capability ID 去重 | `catches duplicate required capability IDs being accepted` |
| 删除 sidecar 至少一个桌面目标判断 | `catches a sidecar manifest without a desktop target` |
| 用输入列表别名替代 defensive snapshot | `catches constructor input-list mutation changing a manifest` |
| 暴露可变集合替代 unmodifiable 集合 | `catches callers mutating exposed manifest collections` |
| encode 返回或复用 manifest 内部 map/list | `catches encoded map and list mutation changing a manifest` |

Mutation check 结论：brief 明确列出的 unknown-field、所有正版本语义、target 非空、两类能力去重、sidecar 桌面目标、defensive collections 与 encode isolation 均有至少一个直接命名、可观察真实行为的测试。

## Authored files

- `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
- `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart`
- `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
- `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md`

## Scope check

- 所有 `apply_patch` authored 改动仅落在 brief 允许的七个包文件和本报告。
- 未执行任何 Git 命令。
- 未调用或派发任何子智能体。
- 未修改 progress YAML、SDD ledger、brief、baseline 或 review 文件。
- 未手工修改 `pubspec.lock` 或 `.dart_tool`；Dart 验证可能触及的缓存仅视为 controller-owned cache state。
- 对新增 capability/manifest 源码与测试运行禁用依赖搜索，`rg` 退出码 `1`（无匹配）：未引入 `dart:io`、`dart:ffi`、Flutter、win32、runtime registration、Sidecar process 或 mock 依赖。
- 未实现注册、加载、生命周期、进程管理、业务插件或 F1-04 及后续能力。

## 自审结论

- API 与字段：匹配 brief 的公开类型、字段、枚举成员和 static codec call shape。
- 严格 schema：顶层精确十二键、全部必需；嵌套能力精确 `id`/`version` 两键；不接受错误 scalar/list/member/map-key runtime shape。
- 失败边界：codec 将无效 ID、模型 `ArgumentError`、枚举和 shape 错误转换为只含相关字段名且不含字段值、路径、环境变量或进程参数的 `FormatException`。
- 不可变性：所有字段为 `final`；集合保序、快照化且不可修改；encode 输出隔离。
- 未发现需求内部冲突。

## Concerns

- 唯一 concern 是 RED 命令的 login PowerShell profile 在完整失败摘要后未自动回收会话；已立即终止并获得退出码 1。该现象不影响 RED 原因判定，且 no-profile 的 focused GREEN、完整测试、format、analyze 均正常自行退出并最终复验通过。

## Fix round 1

### Reviewer finding 与根因核验

- finding：unknown top-level key 由调用者控制，原实现把该 key 直接传给 `_fail(field)`，异常消息因此可能泄露完整路径、参数或 secret。
- 真实数据流：`json.keys` → unknown-field 分支 → `_fail(field)` → `FormatException('Invalid manifest field: $field')`。
- 根因确认：原有测试只使用安全常量 `command`，仅覆盖 unknown field 被拒绝和安全字段名可定位，未覆盖诊断消息对非安全 key 的脱敏边界。

### Bugfix TDD RED

先且仅修改 `test/manifest/plugin_manifest_codec_test.dart`，新增命名测试：

`catches sensitive unknown field keys leaking into diagnostics`

测试使用手写 unknown key literal：

`C:\Users\alice\AppData\plugin.exe --token=top-secret`

它断言真实 `PluginManifestCodec.decode` 抛出 `FormatException`，消息包含固定类别 `unknown field`，且不包含完整原始 key、`C:\Users\alice` 路径片段或 `top-secret`。

精确 RED 命令：

```powershell
dart test test/manifest/plugin_manifest_codec_test.dart
```

- 退出码：`1`
- 关键输出：`00:00 +3 -1: PluginManifestCodec catches sensitive unknown field keys leaking into diagnostics [E]`
- 实际泄露：`FormatException: Invalid manifest field: C:\Users\alice\AppData\plugin.exe --token=top-secret`
- 汇总：`00:00 +25 -1: Some tests failed.`
- RED 原因确认：新增测试唯一失败，直接证明当前生产分支同时缺少 `unknown field` 固定类别并原样泄露路径/参数/secret；不是语法、依赖或环境失败。

### 最小生产修复

随后只修改 `lib/src/manifest/plugin_manifest_codec.dart`：

- unknown-field 分支改为 `_failUnknownField(field)`。
- 受限安全标识符定义为以小写字母开头、后续仅字母数字、总长度不超过 64 的 lowerCamel-compatible key：`^[a-z][A-Za-z0-9]{0,63}$`。
- 安全 key 使用 `Invalid manifest unknown field: <field>`，因此原有 `command` 仍可定位。
- 任意不满足该受限模式的 unknown key 使用固定 `Invalid manifest: unknown field`，绝不插入原始 key。
- 未修改公开 API、已知字段错误路径或其他 codec 行为。

### GREEN 与回归验证

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

1. Focused manifest test：

```powershell
dart test test/manifest/plugin_manifest_codec_test.dart
```

- 退出码：`0`
- 关键输出：`00:00 +26: All tests passed!`

2. Manifest + capability focused test：

```powershell
dart test test/manifest test/capability
```

- 退出码：`0`
- 关键输出：`00:00 +32: All tests passed!`

3. 完整包测试：

```powershell
dart test
```

- 退出码：`0`
- 关键输出：`00:00 +47: All tests passed!`

4. 全目录只读 format gate：

```powershell
dart format --output=none --set-exit-if-changed .
```

- 退出码：`0`
- 关键输出：`Formatted 10 files (0 changed) in 0.02 seconds.`
- 本轮不需要 `--output=show` 或任何格式修正；未使用写入式 formatter。

5. Analyze：

```powershell
dart analyze
```

- 退出码：`0`
- 关键输出：`Analyzing plugin_contracts...` / `No issues found!`

### 覆盖与 mutation 自审

- 删除 `_failUnknownField` 分流、重新把任意 unknown key 交给 `_fail(field)`：新增敏感 key 测试失败。
- 把非安全 key 重新插入固定消息：新增测试的完整 key、路径片段或 secret 三个独立否定断言至少一个失败。
- 固定消息不再表明 unknown-field 类别：新增测试的 `contains('unknown field')` 断言失败。
- 把所有 unknown key 都匿名化：原有 `catches unknown top-level fields being silently accepted` 对 `command` 的可定位断言失败。
- 测试直接使用真实 codec 和手写 literal，不使用 mock、生产 helper 生成 expected 或源文本检查。

### Scope 与 concerns

- 本轮 authored 文件严格限定为：
  - `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
  - `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
  - `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md`
- 未修改任何其他生产、测试、progress、ledger、review 或 package 文件。
- 未执行 Git，未派发子智能体，全部编辑均使用 `apply_patch`。
- 本修复轮次无新增 concerns。

## Fix round 2

### Re-review finding 与根因

- Round 1 的通用“安全形态”正则 `^[a-z][A-Za-z0-9]{0,63}$` 仍将任意符合 lowerCamel/alphanumeric 形态的 unknown key 视为可回显。
- 精确反例 `topSecret123` 会进入 `_safeDiagnosticField.hasMatch(field)` 的 true 分支，产生 `Invalid manifest unknown field: topSecret123`。
- 根因不是路径字符过滤不足，而是开放形态规则无法判定一个调用者提供的标识符是否含敏感语义。只有封闭 allowlist 能保证未明确批准的 key 不被回显。

### Bugfix TDD RED

先且仅修改 `test/manifest/plugin_manifest_codec_test.dart`，新增独立命名测试：

`catches alphanumeric secret-shaped unknown keys leaking into diagnostics`

测试用手写纯字母数字 unknown key `topSecret123` 调用真实 `PluginManifestCodec.decode`，断言：

- 抛出 `FormatException`；
- 消息仍包含固定类别 `unknown field`；
- 消息不包含完整 key `topSecret123`；
- 消息不包含敏感片段 `Secret123`。

精确 RED 命令：

```powershell
dart test test/manifest/plugin_manifest_codec_test.dart
```

- 退出码：`1`
- 关键失败：`00:00 +4 -1: PluginManifestCodec catches alphanumeric secret-shaped unknown keys leaking into diagnostics [E]`
- 实际消息：`FormatException: Invalid manifest unknown field: topSecret123`
- 汇总：`00:00 +26 -1: Some tests failed.`
- RED 原因确认：新增测试唯一失败，直接证明当前通用正则回显纯字母数字 secret-shaped key；不是语法、依赖或环境问题。

### 最小生产修复

随后只修改 `lib/src/manifest/plugin_manifest_codec.dart`：

- 删除 `_safeDiagnosticField` 通用 RegExp。
- 新增私有封闭常量 allowlist `_diagnosticUnknownFieldAllowlist`。
- allowlist 当前精确只包含 `command`。
- `_failUnknownField` 仅在 `field == 'command'` 时回显定位；其他所有 unknown key 无条件返回固定 `Invalid manifest: unknown field`。
- 未新增公共 API，未改变已知字段诊断、decode/encode 行为或其他 manifest contract。

### GREEN 与回归验证

工作目录：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts`

1. Manifest focused：

```powershell
dart test test/manifest/plugin_manifest_codec_test.dart
```

- 退出码：`0`
- 关键输出：`00:00 +27: All tests passed!`

2. Manifest + capability focused：

```powershell
dart test test/manifest test/capability
```

- 退出码：`0`
- 关键输出：`00:00 +33: All tests passed!`

3. 完整包测试：

```powershell
dart test
```

- 退出码：`0`
- 关键输出：`00:00 +48: All tests passed!`

4. 全目录只读 format gate：

```powershell
dart format --output=none --set-exit-if-changed .
```

- 退出码：`0`
- 关键输出：`Formatted 10 files (0 changed) in 0.02 seconds.`
- 无格式差异，不需要 show-only 检查或 apply_patch 格式修正；未使用写入式 formatter。

5. Analyze：

```powershell
dart analyze
```

- 退出码：`0`
- 关键输出：`Analyzing plugin_contracts...` / `No issues found!`

### Mutation check 与自审

- 把封闭 allowlist 改回通用字符形态规则：`topSecret123` 回归测试失败。
- 把 `topSecret123` 或其他非批准 key 加入回显分支：完整 key/`Secret123` 否定断言失败。
- 固定匿名消息不再包含 `unknown field` 类别：两项敏感 unknown-key 测试失败。
- 从 allowlist 移除 `command` 或把所有 unknown key 匿名化：原有 `catches unknown top-level fields being silently accepted` 的 `command` 定位断言失败。
- 把路径/参数 key 加入回显：Round 1 的 `catches sensitive unknown field keys leaking into diagnostics` 失败。
- 新测试使用手写 literal、真实 codec 和行为断言，无 mocks、生产 helper expected 或源码文本检查。

### Scope 与 concerns

- 本轮 authored 文件严格限定为：
  - `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
  - `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
  - `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md`
- 未修改任何其他生产、测试、progress、ledger、review、package、brief 或 baseline 文件。
- 未执行 Git，未派发子智能体，全部编辑均使用 `apply_patch`。
- 本修复轮次无 concerns。
