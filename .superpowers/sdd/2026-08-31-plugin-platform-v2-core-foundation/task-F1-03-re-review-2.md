# Task F1-03 Fix Round 2 Scoped Re-review

本次仅复核仍开放的诊断泄露 finding 与 round-2 fix-only delta；未重做全任务审查，未运行 Git、子智能体或测试套件。

## 1. Finding verdict

**ADDRESSED**

### 生产证据

- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:8-10` 将可回显名称改为私有封闭 `const Set<String>`，集合当前且仅包含字面量 `command`；Round 1 的开放式字符/长度正则已删除。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:28-31` 仍先严格拒绝所有不在十二键 schema 内的 unknown key，并将其交给专用诊断函数。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\lib\src\manifest\plugin_manifest_codec.dart:230-235` 仅当封闭 allowlist 命中时才插入 `field`；唯一可能被插入的调用者键为明确批准的 `command`。所有其他 unknown key 不论字符、长度或语义，均无条件返回常量 `Invalid manifest: unknown field`，没有任何原始输入插值路径。

### 测试证据

- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\test\manifest\plugin_manifest_codec_test.dart:38-42`：普通 `command` unknown key 仍被拒绝，同时诊断保留 `command` 可定位性。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\test\manifest\plugin_manifest_codec_test.dart:44-75`：路径、空白、参数与 secret 混合 key 被拒绝，消息包含固定 `unknown field` 类别且不包含完整 key、路径片段或 secret。
- `E:\my\flutter-plugin-platform\v2\packages\plugin_contracts\test\manifest\plugin_manifest_codec_test.dart:77-105`：纯字母数字 `topSecret123` 被拒绝，消息不包含完整 key 或 `Secret123` 敏感片段，直接捕获 Round 1 通用正则回归。
- 三类测试共同约束了“批准名称可定位、路径/参数式输入匿名、alphanumeric secret 匿名”；均调用真实 codec 并使用手写 literal。

结论：封闭 allowlist 与固定 fallback 已消除任意非 `command` 调用者输入进入异常消息的路径，原 Important finding 已完整关闭。

## 2. New Breakage in Fix Diff

**None**

本轮 scoped delta 未发现新的 Critical、Important 或 Minor 破坏。变更仅替换私有诊断判定并新增针对性测试；未改变公开 API、十二键拒绝行为或已知字段诊断路径。

## 3. Out-of-Scope Observations

- fix-only package 显示本轮生产/测试变更仅涉及 codec 与 manifest codec 测试，另追加实现报告；未见与 finding 无关的范围扩张。
- 实现报告和 controller package 记录 manifest 27/27、focused 33/33、full 48/48、format 0 changed、analyze clean。按 scoped re-review 约束未重复运行这些命令。
- 本结论只关闭诊断泄露 finding，不重新评价初始任务已验收的其他契约。

## 4. 总 Verdict

**All findings addressed, no new Critical/Important breakage**

Round 2 使用只含 `command` 的封闭 allowlist，并由 command、路径/参数、alphanumeric secret 三类测试共同保护；开放 finding 已解决。
