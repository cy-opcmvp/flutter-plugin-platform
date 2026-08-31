# Plugin Platform v2 restart prompt

继续 `D:\my\flutter-plugins-platform` 中已暂停的 Flutter Plugin Platform v2 Goal，不要重新审查旧工程，也不要重新规划已确认的架构。

先完整读取并以磁盘为准：

1. `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`
2. `docs/superpowers/plans/2026-08-31-plugin-platform-v2-master-plan.md`
3. `docs/superpowers/plans/2026-08-31-plugin-platform-v2-core-foundation.md`
4. `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`
5. `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/progress.md`
6. `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-02-brief.md`
7. `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-02-pause-handoff.md`

这是现有批量任务的恢复，继续使用 Goal 方式，无需重新询问是否创建 Goal。遵守以下限制：与我始终使用中文；Windows PowerShell；AI 不执行 Git；最多一个子智能体并发；禁止嵌套委派；框架与业务分开；实现与验收使用不同智能体；每个任务都写入恢复状态；旧代码在 M5 再次得到我确认前不得删除。

从 `F1-02-green-implementation` 恢复：当前测试已写好并由控制层确认 RED，退出码 1 的原因是 `PluginId`/`PluginFailure` 尚不存在。不要重写测试，不要从 F1-01 或 RED 重做。先核对 pause handoff 中的文件/hash，然后派发一个新的 Sol xhigh 实现智能体，仅完成 F1-02 的最小生产实现、GREEN、format、analyze 和实施报告。实现智能体结束后，再派发另一个 Sol xhigh 只读 reviewer；审查通过才标记 F1-02 accepted 并进入 F1-03。

恢复时先给我一句简短状态说明，然后直接继续，不要重复询问已确认的产品决策。
