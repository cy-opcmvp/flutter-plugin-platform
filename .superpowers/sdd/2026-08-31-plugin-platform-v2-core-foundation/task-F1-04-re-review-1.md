# Task F1-04 Fix Round 1 Scoped Re-review

本轮仅复验初审 I1/M1、controller ruling 的执行情况以及 fix-only delta。依据为 Brief、追加 Fix round 1 的实现报告、fix-only package，并仅从初始完整 package 提取 `lifecycle_machine.dart` 做结构边界确认。未执行 Git、未爬取仓库、未运行测试，也未重做全任务审查。

## Findings

### I1 — ADDRESSED

初审问题：脱离状态机的 `_CountingLifecycle` 零计数断言与被测对象没有因果关系，不能检测新增 plugin/callback coupling。

复验结果：

- fix-only delta 完整删除 `catches the machine invoking plugin lifecycle callbacks` 测试。
- 完整删除只为这两个测试服务的 `_CountingLifecycle` fixture、三个 counter 和三个方法。
- 没有以 source grep、I/O、compile subprocess、mock、另一 fixture 或其他 tautology 替代。
- 追加报告明确撤回早先“该具名测试能够自动守住 callback 调用”的 mutation/self-review 陈述，并记录由 reviewer 结构门禁承担该负向架构边界。
- 依据初始完整 package 的 production hash 保持不变声明及 focused 结构复核，`LifecycleMachine` 构造器只有 `LifecycleMachine(this.pluginId)`；实例字段只有不可变 `PluginId pluginId` 与私有 `_state`；公开实例 API 只有只读 `state` 和同步 `transitionTo(...)`。源码中没有 `PluginLifecycle` 参数、字段、callback、activate/deactivate/dispose 调用或其他插件对象访问路径。

Controller ruling 被准确执行。已知代价——未来可选 plugin/callback coupling 没有专属 runtime unit-test failure——也被 package 与报告如实记录，没有继续伪装成自动测试覆盖。

### M1 — ADDRESSED

初审问题：`_CountingLifecycle implements PluginLifecycle` 编译成功后，`isA<PluginLifecycle>()` 必然为真，没有独立接口漂移检测能力。

复验结果：

- fix-only delta 完整删除 `catches lifecycle interface drifting from its three async methods` 测试及其无信息量 `isA<PluginLifecycle>()` 断言。
- 同一 fixture 已随 I1 一并删除，没有遗留仅为维持测试数量或类型声明而存在的代码。
- 没有新增测试名过度承诺、mirror assertion 或其他等价 tautology。

Controller ruling 被准确执行。

## New Breakage

**无。**

- 删除的两个测试本身没有有效独立检测力。
- callback 测试中经过的 active→deactivating→inactive 与 inactive→disposed 路径仍分别由现有 deactivation/reactivation 测试和 direct inactive disposal 测试覆盖。
- lifecycle vocabulary、固定初态/identity、13 条允许边、指定非法边、同态拒绝、disposed 终态、结果字段、稳定 failure diagnostics、状态不变及独立 failure/result 的有效覆盖均按 fix package 保留。
- Controller 新鲜证据显示 runtime focused/full 13/13、contracts 48/48、workspace format 与 analyze 均通过；按 scoped re-review 要求未重复运行。

## Out-of-Scope

**无。**

- fix-only production delta 为零，生命周期 production 文件及 exports 保持初审 hash。
- 实现变更仅删除 `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart` 中两个无效测试与其唯一 fixture；另在允许的 task report 中追加裁定、验证和范围说明。
- 未引入插件耦合、source inspection 测试、I/O、子进程、mock、平台依赖或其他功能。

## Verdict

**APPROVED**

I1 与 M1 均为 **ADDRESSED**；无 new breakage，无 out-of-scope 变更。Controller 对 Brief 第 11 项不可建立真实因果 runtime test 的裁定已被精确执行，且本轮 reviewer 结构门禁确认当前 `LifecycleMachine` 仍是纯 state-only machine，不接收、不保存、不调用 `PluginLifecycle` 或 plugin callback。
