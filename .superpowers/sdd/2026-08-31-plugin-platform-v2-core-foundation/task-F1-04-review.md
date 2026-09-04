# Task F1-04 独立验收报告

审查依据仅为 `task-F1-04-brief.md`、`task-F1-04-report.md` 与完整 `task-F1-04-review-package.md`。未执行 Git、未爬取仓库、未修改实现/测试/流程文件，也未重复 controller 已提供的新鲜测试、格式与分析套件。

## Part 1 — Spec Compliance

**总体结论：⚠️ 部分符合。** 当前生产代码与公开导出符合绑定契约；但一项明确要求的测试/破坏检测不是有效证据，因此任务整体尚不能按严格 Brief 验收为完成。

### 逐文件 Missing / Extra / Misunderstood 核对

| 文件 | 结论 | Missing | Extra | Misunderstood |
| --- | --- | --- | --- | --- |
| `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart` | ✅ | 无。八个 enum 值及三个 `Future<void>` 无参方法完整。 | 无。没有 identity、state、callback、context、stream、Flutter 或平台 API。 | 无。 |
| `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart` | ✅ | 无。identity、固定初态、只读 state、同步 transition、结果字段及 rejection failure 均完整。 | 无。没有任意初态入口、插件对象、插件调用路径、I/O、Flutter、FFI、win32、平台依赖或全局可变状态。 | 无。 |
| `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart` | ⚠️ | 缺少能真实捕获“状态机新增插件调用路径”的非同义反复测试；当前 counter fixture 与 machine 没有任何联系。 | 无越界功能测试；但第 183、203–205 行的脱离对象计数断言没有增加有效行为证据。 | 将“一个从未交给状态机、状态机也无法访问的对象计数保持 0”误当作“状态机没有调用插件”的破坏检测。第 25 行的 `isA` 断言也把声明本身产生的必然结果误称为精确接口漂移检测。 |
| `v2/packages/plugin_contracts/lib/plugin_contracts.dart` | ✅ | 无。新增 lifecycle export，并保留 package 中列出的 accepted F1-02/F1-03 exports。 | 无。 | 无。 |
| `v2/packages/plugin_runtime/lib/plugin_runtime.dart` | ✅ | 无。正确导出 machine/result 所在源。 | 无。 | 无。 |

### 绑定条款核对

- ✅ `PluginLifecycleState` 顺序与词汇精确；`PluginLifecycle` 只有 `activate`、`deactivate`、`dispose` 三个异步无参方法。
- ✅ `LifecycleMachine` 只能由 `PluginId` 构造，初态固定为 `discovered`；`pluginId` 不可变，`state` 只读，转换同步。
- ✅ `_isAllowed` 精确列出 8 条 normal edge 和 5 条 failure edge，没有同态或额外边；`disposed` 通过默认拒绝保持终态。
- ✅ 成功先验证后写入 requested state；拒绝在写状态前返回，机器状态不变。
- ✅ 每次拒绝都新建私有构造的 `LifecycleTransitionResult` 与 `PluginFailure`；结果字段均 `final`，`succeeded` 精确派生于 `failure == null`。
- ✅ failure code 为 `lifecycle.invalid_transition`，message 为非空固定文本，details 仅包含精确的 `pluginId`、`from`、`to`；既有 `PluginFailure` 行为及通过的不可修改断言提供了快照不可变证据。
- ✅ machine 源码没有接收、保存或调用 `PluginLifecycle` 的路径，当前生产实现满足 state-only 要求。
- ✅ 允许边、指定非法边、同态、disposed 全枚举终态、结果字段、独立 rejection、details 不可修改均有真实状态机测试；辅助函数仅用于 setup 或逐字段成功/拒绝断言，没有掩盖当前转换错误。
- ❌ Brief 第 11 项及 mutation 映射声称具名测试会捕获插件 callback 调用，但当前测试不能捕获新增的可选插件/回调路径；详见 Important I1。
- ✅ 报告提供先测试后生产的 RED、恢复后的 GREEN、一次真实 allowed-edge mutation 失败及恢复证据；controller 新鲜证据为 runtime 15/15、contracts 48/48、workspace format/analyze 通过。
- ✅ `plugin_devkit.dart` 的单个 LF 是 controller 明确授权、无 token/声明/行为的 baseline maintenance；不构成 F1-04 越界实现或风险问题。

## Part 2 — Quality Review

### Strengths

- 转换表使用显式 record switch；审查时可逐边与 Brief 对照，不依赖隐式序号、集合推导或业务回调。
- rejection 路径在任何 mutation 前返回，并为每次调用构造独立 failure/result；这使失败语义稳定且易验证。
- result 构造器私有、类型与字段不可变，公开 API 面积恰好满足契约。
- 测试对全部 13 条允许边均有覆盖，activation、deactivation/reactivation、failure/disposal、direct disposal 的 expected state 均为手写 enum，而非镜像生产转换表。
- disposed 对八个 enum 请求逐个检查，精确覆盖终态；非法详情也检查了精确 map 与不可修改性。
- 当前生产代码保持纯 Dart，依赖范围及公共 exports 都很克制。

### Issues

#### Critical

无。

#### Important

**I1 — 插件回调测试是不可达 fixture 的同义反复，不能捕获其声称的破坏。**

- 文件/行：`v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart:183`、`:203`–`:205`
- 证据：`_CountingLifecycle` 仅被创建，既未传给 `LifecycleMachine`，也未通过任何其他路径与 machine 关联。因此无论 transition 实现做什么，这个特定对象的三个计数都必然保持 0。举例：若未来给 machine 增加一个可选 `PluginLifecycle`/callback 字段，并仅在传入时调用，现有 15 个测试仍可全部通过。
- 影响：当前生产源码确实没有插件调用路径，但测试并未落实 Brief 第 11 项的“prove”要求，也不支持报告中“invoke plugin callbacks mutation 会被该具名测试捕获”的结论。该回归会违反 state-only 核心边界，却没有自动门禁。
- 修复：将“fixture 能以精确三个 async 方法实现接口”和“machine 公共面不能接收/保存/调用插件”拆成不同契约检查；为后者采用 controller 认可、且能与 machine API/调用路径建立真实因果关系的结构性或负向编译门禁，并实际注入一次插件调用路径 mutation，确认对应具名门禁失败后再恢复。若在 Brief 同时禁止 source/API inspection、I/O 与 plugin 注入的约束下无法构造这种测试，应由 controller 澄清该验收项，而不能继续把脱离对象的零计数当作证据。

#### Minor

**M1 — 接口漂移测试的运行时断言没有独立检测力，测试名过度承诺。**

- 文件/行：`v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart:21`–`:25`
- 证据：`_CountingLifecycle implements PluginLifecycle` 一旦成功编译，`expect(lifecycle, isA<PluginLifecycle>())` 必然成立；真正有价值的是 fixture 的编译期 method/override 约束。新增带默认实现的额外 public API 等漂移不会被这个断言捕获。
- 影响：不影响当前接口源码的正确性，但会让维护者误以为测试已守住“exactly three methods”的完整负面 API 面积。
- 修复：把测试名与说明收窄为“fixture with the required three async methods compiles”，删除无信息量的 `isA` 断言，或与 I1 一并加入真正的 API surface 门禁；不要宣称该运行时断言能捕获所有接口漂移。

### Assessment

**Needs fixes**

生产实现本身可评为正确、简洁且范围合规；阻止批准的是绑定测试要求的实质缺口，而不是当前状态机行为错误。修复 I1（或取得 controller 对该内在测试约束的明确裁定）并重新提供具名 mutation 失败/恢复证据后，可转为 Approved。Task quality：**B（生产代码 A；测试破坏检测 B-）**。
