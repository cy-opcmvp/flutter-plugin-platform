# Task F1-06 Review

## Spec Compliance

结论：**Approved**。

- 显式目标与纯函数边界：公开入口显式接收 `PluginTarget`，输入先做只读快照；实现仅导入 `plugin_contracts`，未读取 registry/catalog、平台全局、环境、文件系统或 I/O（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:1`、`:4`、`:8`、`:25`）。
- provider 选择与失败传播：能力按已验收的唯一 capability ID 建索引；版本不足不会形成依赖边；目标不支持、missing、version-too-low 先进入不可用集合，再传播到消费者（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:13`、`:25`、`:30`、`:41`、`:129`）。目标不支持但声明了满足版本能力的 provider 会被解析为不可用 provider，消费者得到 `resolution.provider_unavailable`，符合关键场景（`:261`）。
- SCC 与传播后一致性：Tarjan 遍历仅限初始传播后仍有效的候选集合，只将多成员 SCC 或真实 self-edge 标为 cycle；cycle ID 按 manifest 输入顺序排序。cycle 标记后再次传播，逐插件 `available`、聚合 `available` 与 `failures` 均由最终失败状态一致生成（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:44`、`:48`、`:55`、`:61`、`:63`、`:80`、`:151`、`:195`）。
- 稳定激活顺序：拓扑边为 provider 到 consumer 的释放关系；每轮从 manifest 输入顺序中选择首个 ready 节点，保证 provider-before-consumer 与稳定 tie breaking（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:294`、`:304`、`:318`）。
- 深层不可变与输入顺序：manifest、逐插件 failures、聚合 maps/lists、聚合嵌套 failure lists 均为不可修改快照；failure details 中唯一列表 `cyclePluginIds` 也单独冻结。plugins、available、failures 与 cycle IDs 均保持输入顺序，failure 生成保持 requirement 顺序（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:8`、`:65`、`:98`、`:113`、`:116`、`:233`、`:284`）。
- 错误详情：四类非 cycle 错误与 cycle 错误均使用固定非空消息及规定字段，未包含路径、参数、环境、时间或异常文本（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:221`、`:235`、`:247`、`:261`、`:277`）。
- 测试与 mutation：测试文件恰好 5 个主/关键 `test` 组；missing/version-too-low 复用参数表；不可变断言内聚于既有场景。provider-before-consumer、传播结果、cycle 标记均有会因相应 mutation 失败的结果断言（`v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart:6`、`:51`、`:85`、`:100`、`:146`、`:163`、`:181`、`:197`、`:222`）。
- 导出范围：公共入口仅新增 resolver 导出（`v2/packages/plugin_runtime/lib/plugin_runtime.dart:5`）。

## Strengths

- 把候选 SCC 检测放在初始不可用传播之后，避免把已因 missing/version/target 失败的节点误报为 cycle；随后单独执行 cycle 后传播，阶段边界清晰（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:41`、`:44`、`:61`）。
- `PluginResolution.available` 直接由冻结后的 failures 推导，聚合失败视图也复用同一逐插件结果，降低状态漂移风险（`v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:73`、`:75`、`:104`）。
- 测试规模严格受控，参数化重复失败形状，并对聚合、逐插件、嵌套 details 的修改拒绝做了有实际检测力的断言（`v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart:36`、`:44`、`:100`、`:233`）。

## Critical

无。

## Important

无。

## Minor

无。

## Decision

**Approved**

Task quality：**High**。实现与测试聚焦、确定性强，完整满足 F1-06 的绑定 API、解析规则、错误结构、不可变性、顺序及最小测试约束。按审查要求未运行测试；门禁与 mutation 结果依据 `task-F1-06-report.md` 和完整 review package 验收。
