# F1-07 验证报告

| 项目 | 结果 |
| --- | --- |
| 首次 focused（源码/导出未创建） | 预期失败：仅缺失 `FakePlugin`、`FakePluginOperation`、`hasPluginFailureCode` 类型/导出 |
| `dart pub get --offline`（`v2`） | 通过 |
| devkit focused / full | 8/8 通过 |
| runtime full | 26/26 通过 |
| contracts full | 49/49 通过 |
| workspace format | 通过，25 文件、0 变更 |
| workspace analyze | 通过，No issues found |

| 关键 mutation | 结果 |
| --- | --- |
| activate 失败前跳过尝试次数递增 | 被 focused 捕获：期望 1、实际 0 |
| matcher 改为比较 `message` | 被 focused 捕获：匹配期望 true、实际 false |

| 范围 | 内容 |
| --- | --- |
| fake | `PluginLifecycle` 三操作、独立计数、失败对象原样抛出、失败配置不可变快照 |
| matcher | 直接依赖 `package:matcher`，代码匹配、类型/代码 mismatch 描述、空 code 校验 |
| 测试 | 单文件四组，重复操作参数化，无 I/O、延迟、进程或运行时状态 |

Concerns: 无 blocker；`pub get` 产生的 lock/cache 状态按 brief 由 controller 管理。
