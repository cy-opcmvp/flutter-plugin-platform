# Flutter Plugin Platform v2 M1 / G1 验收报告

**Verdict：Approved**

F1-01～F1-08 的实现、测试、文档、恢复状态与证据满足 M1 核心基础阶段门。无 Critical 或 Important finding；一项历史报告计数笔误保留为非阻塞 Minor。Controller 可将 F1-01～F1-08 与 M1 标记为 `accepted`。

## 分项结论

| 分项 | 结论 | 核查摘要 |
|---|---|---|
| Spec | Approved | PluginId、失败模型、严格 manifest、生命周期、注册/能力目录、解析器与 devkit 均符合 M1 绑定范围。 |
| Architecture | Approved | 依赖方向为 `plugin_contracts <- plugin_runtime <- plugin_devkit`；核心无 Flutter、平台、I/O、FFI 或 Sidecar 运行依赖。 |
| Test | Approved | Controller fresh evidence 为 contracts 48、runtime 26、devkit 8，均通过；主路径与关键异常覆盖充分，同类 devkit/capability 场景已参数化，指定 mutation 证据具有因果检测力。 |
| Docs | Approved | 三份 README 与当前公共 API、M1 边界及依赖方向一致；所列命令已由 controller 从 `v2` 根目录复现。 |
| Recovery | Approved | F1-01～F1-07 已独立验收，F1-08 为 `verified_pending_acceptance`；checkpoint、next action、报告与 review 路径完整，无 blocker。旧工程目录仍在。 |
| Evidence | Approved | G1 package 覆盖当前 33 个 `v2` 非生成文件；独立哈希核对为 33/33、0 mismatch、0 unlisted。未重复 controller 的测试、format、analyze 或 deps。 |

## 核心边界核查

| 范围 | 结论 | 证据摘要 |
|---|---|---|
| 纯 Dart 与依赖边界 | 通过 | contracts 无运行时依赖；runtime 仅依赖 contracts；devkit 才依赖 runtime 与直接 `matcher`。全部 `lib` 仅见 Dart/package imports，无 Flutter、`dart:io`、`dart:ffi`、win32 或平台全局。 |
| PluginId / Failure | 通过 | ID 正则精确；无公开未校验构造入口；值相等/hash 稳定。Failure 校验非空 code/message，并对 details 建立不可修改 map 快照。 |
| Manifest 与诊断 | 通过 | 十二个顶层字段严格 missing/unknown/type 校验；版本为正整数；targets、能力与 surfaces 去重；sidecar 必须非空入口且含桌面目标。未知键只对封闭 allowlist 中的 `command` 回显，其余使用固定诊断，路径、参数及字母数字 secret 测试均覆盖。 |
| Lifecycle | 通过 | 非法转换返回 `lifecycle.invalid_transition` 且不改变状态；成功/失败结果结构稳定；disposed 为终态。`LifecycleMachine` 仅持有 PluginId 与 state，不接收、保存或调用插件对象。 |
| Registry / Catalog | 通过 | 注册、注销与 capability catalog 以完整候选状态验证后提交；重复 PluginId、重复 provider 与未知注销不会留下部分状态；公开 registrations、manifest collections 与 failure details 均不可直接修改。 |
| Resolver | 通过 | target 由宿主显式传入；不读取平台/环境/文件。缺失能力、版本不足、provider 不可用传播、依赖环均返回逐插件结构化 failure；激活顺序 provider-before-consumer，稳定 tie 按输入顺序。 |
| Devkit | 通过 | FakePlugin 三操作独立计数、失败注入确定且原对象抛出；matcher 只比较稳定错误码。`matcher` 为 devkit 公开库的直接依赖，未依赖传递或 dev-only `test`。 |

## Findings

### Critical

无。

### Important

无。

### Minor

| ID | 文件:行 | Finding | Triage |
|---|---|---|---|
| M1 | `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-07-report.md:9` | 历史实现报告写 contracts 49/49；accepted baseline、fresh controller 与 G1 evidence 均为 48/48。 | 报告层计数笔误，不影响 exit 0、实现、测试或包边界。以 fresh 48/48 为权威证据；按约束不回写已验收报告，不阻塞 G1。 |

Finding 计数：**Critical 0 / Important 0 / Minor 1**。

## Ledger `Ruling:` triage

| Ruling | 结论 | 代价与最终判断 |
|---|---|---|
| 禁用 Git worktree，继续当前 checkout | 接受 | 代价是缺少 Git 级隔离与 diff 轨迹；M1 始终隔离在 `v2/`，完整快照和哈希清单提供替代审计，legacy 的 `lib/test` 及六端目录仍存在。 |
| 允许原实现者对暂停保留的 F1-02 测试做 formatter-equivalent reflow | 接受 | 原始字节连续性因换行/布局改变而丢失，但 LF-normalized hash、15 项断言保持及 fix-only re-review 证明行为未变，最终全目录 format 为 0。 |
| F1-04 为 workspace format 给空 `plugin_devkit.dart` 增加单个 LF | 接受 | 属跨任务触碰，但无声明和语义；后续 F1-07 已以正式 devkit 导出替代该 stub，不产生残留风险。 |
| 删除 lifecycle 脱离对象的 tautological callback/API 测试，改由结构审查守住 state-only 边界 | 接受，保留风险 | 代价是未来若新增可选 plugin/callback 参数，不一定由现有 unit test 自动失败。本次完整结构核查确认当前 machine 构造器、字段与方法不存在插件耦合；该风险应继续作为后续阶段 review checklist，而非伪造无因果测试。 |
| F1-07 将 `matcher` 作为 testing-only devkit 的直接 normal dependency | 接受 | 代价仅是 devkit 增加一个小型直接依赖；公共 matcher 位于 `lib/`，因此不能依赖传递或 dev-only `test`。runtime/contracts 依赖图未受污染。 |

## Deferred minor triage

F1-07 的 49/48 差异已归类为上表 M1：非阻塞、仅历史报告不准确。Fresh 证据明确为 contracts 48/48，故不再延期到 M2，也不要求回退或修改已验收 F1-07 文件。

## 测试与 mutation 证据

| 证据 | 结论 |
|---|---|
| contracts 48 / runtime 26 / devkit 8 | 三包主路径、严格输入异常、状态非法转换、冲突/原子性、解析传播/cycle 与 fake/matcher 均有直接覆盖。 |
| 参数化与最小性 | capability、registry rejection、resolver failure 与 devkit 三操作采用循环/record 合并；manifest 测试虽较多，但对应严格 schema 的不同关键失败类别，未见冷门矩阵膨胀。 |
| FakePlugin mutation | 将失败路径计数移到抛错后会被“尝试次数为 1”断言捕获，因果有效。 |
| Matcher mutation | 将 code 比较改为 message 比较会被“同 code、不同 message”用例捕获，因果有效。 |
| Lifecycle state-only | 初始无因果 fixture 已按 ruling 删除；当前不宣称自动 mutation 覆盖，改由本次结构审查给出真实边界证据。 |

## 文档、恢复与证据完整性

- `v2/README.md` 准确描述三个包、单向依赖、显式 target、能力契约依赖及 M1 排除项；contracts/runtime README 与当前公共面一致。
- README 命令由 controller fresh run 验证；`dart pub get --offline` 依赖本机缓存的限制已在 F1-08 报告如实披露，不影响本次已记录复现结果。
- progress.yaml 的 `current_task` 为 F1-08，M1 为 `in_progress`；F1-08 是唯一待本报告关闭的任务。ledger 与 progress 对 F1-01～F1-07 的 accepted 状态和 review 路径一致。
- G1 package 排除 `pubspec.lock` 与 `.dart_tool`，并明确其 controller-owned cache 身份；本次哈希核查确认 package 与当前全部 33 个非生成文件一致。
- 根目录旧工程的 `lib`、`test`、Android、iOS、Linux、macOS、Windows、Web 目录仍存在；未进入 M5 清理。

## 未覆盖项

| 项目 | 处置 |
|---|---|
| 六端 Flutter 构建矩阵、Flutter host、平台 adapters、Sidecar、CLI 与真实业务插件 | 属 M2～M4，不是 G1/M1 缺口。M1 仅证明核心契约与运行时无平台污染。 |
| lifecycle no-plugin coupling 的自动回归门禁 | 受已批准 ruling 限制，由后续独立结构审查持续检查。 |
| RED/GREEN 的完整时间序列重建 | 静态快照不能独立重建；任务报告、暂停哈希、controller 证据与独立 re-review 形成可接受审计链。 |
| G1 自行重跑测试/format/analyze/deps | 按验收约束未执行；结论基于 controller fresh evidence、完整源码/测试快照及独立哈希一致性检查。 |

## 最终决定

**Approved。** 无需回退任务。Controller 可将 **F1-01、F1-02、F1-03、F1-04、F1-05、F1-06、F1-07、F1-08 以及 M1** 标记为 `accepted`，随后按 Master Plan 冻结并启动 M2 详细计划。

建议提交信息：`feat(core): complete plugin platform v2 core foundation`
