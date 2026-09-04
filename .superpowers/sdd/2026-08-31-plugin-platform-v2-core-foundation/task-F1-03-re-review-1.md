# Task F1-03 Fix Round 1 Scoped Re-review

本次仅复核原 Important finding 与 fix-only delta；未重做全任务审查，未运行 Git 或测试套件。

## 1. Finding verdict

**NOT ADDRESSED**

原 finding 仍为 **Important**。

### 证据

- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:8-10` 将所谓安全未知键定义为 `^[a-z][A-Za-z0-9]{0,63}$`。该规则只判断字符形态和长度，无法判断键内容是否为 secret、环境值或其他敏感数据。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:230-233` 对任何匹配该模式的调用者输入仍直接执行 `FormatException('Invalid manifest unknown field: $field')`。例如未知键 `topSecret123`、`productionDatabasePassword123` 均匹配模式并会被完整回显，所以修复没有真正建立“任意敏感原始键不得插入诊断”的边界。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\test\manifest\plugin_manifest_codec_test.dart:38-42` 保留了普通 `command` 的可定位性，这一目标已实现。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\test\manifest\plugin_manifest_codec_test.dart:44-75` 的新增测试只使用含反斜杠、冒号、空格、连字符和等号的路径/参数式 key；该 key 必然不匹配正则，因此测试只能证明“不安全字符形态走固定消息”，无法捕获字母数字形态 secret 仍被回显的回归。

### 修复方向

不能用通用标识符正则推断调用者输入是否非敏感。若必须保留普通 `command` 可定位性，应仅对明确、封闭的安全诊断 allowlist（至少 `command`）回显名称，其他所有 unknown key 一律使用固定 `unknown field` 类别；同时新增如 `topSecret123` 的手写 unknown key 测试，断言消息不包含原始 key，并保留现有 `command` 测试。

## 2. New Breakage in Fix Diff

**None**

在本轮 scoped delta 中未发现独立于原 finding 的 Critical、Important 或 Minor 新破坏。当前问题是原诊断泄露 finding 只被部分修复，而不是新增回归类别。

## 3. Out-of-Scope Observations

- fix-only package 显示生产/测试 delta 仅涉及 codec 与其 manifest 测试，另追加实现报告；未见与本 finding 无关的公共 API 或阶段边界扩张。
- 实现报告与 controller package 记录 manifest 26/26、focused 32/32、full 47/47、format 0 changed、analyze clean。按复审约束未重复运行，这些绿色结果不能弥补上述未覆盖输入类别。
- 普通 `command` 诊断以及含路径/参数标点的 unknown key 匿名化均有直接测试证据；本结论不否定这两项局部改进。

## 4. 总 Verdict

**Findings remain open**

原 Important finding 尚未完全解决；需要以封闭 allowlist（或等效的不回显任意调用者输入方案）替代通用正则，并加入字母数字形态敏感键的回归测试。
