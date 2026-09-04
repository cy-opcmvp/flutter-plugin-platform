# Task F1-03 独立验收报告

## 1. Spec Compliance

结论：❌。清单、能力模型、严格十二键 schema、sidecar 约束、不可变性与纯 Dart 边界均符合 brief；但未知顶层键的错误消息会原样回显任意输入键名，不满足 codec 错误不得回显完整路径、环境变量或进程参数的绑定要求。

| 文件 / 约束 | 结果 | Missing | Extra | Misunderstood |
| --- | --- | --- | --- | --- |
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart` | ✅ | 无；六个 `PluginTarget` 与两个 `PluginKind` 成员齐全 | 无 | 无；wire 值由严格 codec 分支和枚举名 encode 保持一致 |
| `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart` | ✅ | 无；descriptor/requirement、精确 ID 正则、正版本校验和只读字段齐全 | 无 unchecked 构造器、taxonomy 或 registry | 无 |
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart` | ✅ | 无；十二个只读字段、非空文本、正整数、集合去重、sidecar 桌面目标均实现 | 无命令字段、进程行为或后续阶段 API | 无；四个集合均为保序 defensive unmodifiable snapshot，原始合法文本未被 trim/normalize |
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart` | ❌ | 缺少对任意未知键名的安全诊断处理 | 无解析文本、框架或运行时 API | 未知键被当作可信字段标签直接插入异常消息，可能回显路径/参数/环境值；详见 I1 |
| `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart` | ✅ | brief 指定的两类有效值、大小写、路径语法、单段、空值、畸形点段、零/负版本均覆盖 | 无 mock/source grep | 无；期望来自手写 literal，descriptor 与 requirement 均直接调用真实构造器 |
| `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart` | ❌ | 缺少“恶意未知键名不得出现在错误消息中”的回归覆盖 | 无镜像 builder、mock 或框架 | 现有 unknown-field 测试只验证普通 `command` 键被拒绝，未约束绑定的敏感诊断边界；其余 brief 列举破坏类型均有直接覆盖 |
| `v2/packages/plugin_contracts/lib/plugin_contracts.dart` | ✅ | F1-03 六个公共类型/codec 均可由包入口访问 | 未导出实现细节或后续阶段 API | 无 |
| 纯 Dart、阶段边界与 authored scope | ✅ | 无 | package 显示仅七个允许包文件及实现报告有 authored 变更 | 无；controller 的 forbidden-dependency scan 为零匹配，未见 Flutter、`dart:ffi`、win32、plugin_runtime、业务插件或 sidecar 进程管理 |
| TDD 顺序及验证 | ⚠️ | 静态 filesystem package 无法独立重建 RED 发生时的时间状态 | 无 | 实现报告与 controller package 一致记录缺失 F1-03 API 的 RED、focused 31/31、full 46/46、format 0 changed、analyze clean；按验收约束未重复运行 |

特别核查结果：

- 顶层 schema 恰为十二键，先拒绝 missing/unknown，再做模型构造；各版本字段只接受 Dart `int`，列表成员和嵌套 map runtime shape 均严格检查。
- `provides` / `requires` 嵌套对象恰为 `id`、`version` 二键，错误统一映射到外层 `provides` 或 `requires`。
- `PluginId.parse` 是 codec 的既有跨文件依赖。为确认异常映射，本次仅额外做了一次 focused 只读检查：`v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart:10-13` 明确对非法 ID 抛出 `FormatException`，因此 codec 的 `id` 映射成立。未做其他源码巡检，未运行测试。
- sidecar 必须有非空 entrypoint 且至少命中 Windows/macOS/Linux；builtin 也遵守 brief 对 entrypoint 的统一非空约束。
- 构造器输入集合被复制为不可变列表；encode 新建顶层 map、各列表及能力嵌套 map，输出修改不会反向影响 manifest。
- 未发现超前公共 API、平台类型、运行时注册/生命周期、业务插件或边界污染。

## 2. Code Quality Review

### Strengths

- 模型职责清晰且实现克制：能力校验、manifest 不变量、wire codec 分层明确，没有引入序列化框架或运行时概念。
- constructor 与 codec 的错误边界处理总体正确：构造器保留 `ArgumentError.name`，codec 把 PluginId、能力和 manifest 校验失败收敛为相关顶层字段的 `FormatException`。
- 不可变性实现完整，不只将字段声明为 `final`，还同时防住输入列表别名、公开集合修改和 encode 输出别名。
- 测试使用手写固定 fixture 和逐字段 literal 断言；有效 decode、精确 encode、嵌套 schema、去重、sidecar、正版本及不可变性都直接执行真实生产代码，非镜像断言。
- 枚举 decode 使用显式穷举分支，避免 `values.byName` 一类未来枚举扩展意外扩大 wire schema。

### Issues

#### Critical

无。

#### Important

**I1 — 未知顶层键会被原样写入 `FormatException`，违反错误消息脱敏契约。**

- 位置：`E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:24-26`
- 证据：unknown-field 分支把调用者提供的 `field` 直接交给 `_fail(field)`，而 `_fail` 将其插入异常文本。若 JSON 键本身是完整路径、环境变量值或进程参数，异常与后续日志会原样包含该内容。
- 影响：实现不满足 brief“codec input failures ... must not echo full paths, environment variables, or process arguments”的明确约束；当前测试仅以安全常量 `command` 为未知键，无法捕获该回归。
- 修复方向：为未知键采用固定诊断（或只允许受限的安全标识符进入消息，其他键统一归类为 `unknown field`），不要把任意输入键直接拼入异常；保留普通未知字段可定位性的同时，新增含路径/参数式未知键的测试，断言 `FormatException` 且消息不包含原始敏感字符串。

#### Minor

无。

### Assessment

**Task quality：Needs fixes**

核心设计和绝大多数 binding contract 已正确完成，但 I1 是明确的 codec 错误边界违约。完成未知键诊断脱敏及相应回归测试后，可重新验收为 Approved。
