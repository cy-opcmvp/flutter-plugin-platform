# AI 编码规则索引（v2）

本目录只保留**与具体仓库结构无关的通用规范**。项目结构、架构纪律（能力注入、
条件导出、样式令牌、边界约束、Sidecar 协议等）统一收敛到
[`.claude/CLAUDE.md`](../CLAUDE.md) 的「硬性纪律」节——那是 v2 的唯一结构事实源。

> **v1 归档说明**：原 9 件 v1 结构专属规则（文件组织 / JSON 配置 / 插件配置 /
> 配置页面 / 响应式配置 / 单一配置模式 / 规则审计 / 版本控制与 Tag 体系及其历史）
> 已移入 `docs/archive/v1/claude-rules/`，仅供追溯，不再约束 v2 开发。

## 现行规则清单

| # | 规则 | 适用范围 |
|---|------|---------|
| 1 | [代码风格规范](./CODE_STYLE_RULES.md) | 全部 Dart/Flutter 代码：命名、格式化（dart format）、注释、长度上限、禁用写法 |
| 2 | [测试规范](./TESTING_RULES.md) | 全部测试代码：AAA 模式、分组、Mock、覆盖率口径 |
| 3 | [Git 提交规范](./GIT_COMMIT_RULES.md) | 提交信息：中文 Conventional Commits、粒度、分支 |
| 4 | [错误处理规范](./ERROR_HANDLING_RULES.md) | 异常类型、输入验证、异步错误处理、日志（v2 结构化失败另见 CLAUDE.md `PluginFailure` 纪律） |
| 5 | [性能优化规范](./PERFORMANCE_OPTIMIZATION_RULES.md) | ValueNotifier 优先、最小 rebuild、RepaintBoundary、Isolate |
| 6 | [对话管理和错误分析规范](./CONVERSATION_MANAGEMENT_RULES.md) | 对话追踪、错误模式归类 |
| 7 | [文档命名规范](./DOCUMENTATION_NAMING_RULES.md) | kebab-case / UPPERCASE / snake_case 三类命名与目录归属 |
| 8 | [文档变更管理](./DOCUMENTATION_CHANGE_MANAGEMENT.md) | 文档与代码同步变更、跟踪表 |

**补充约定（v2）**：上述通用规范正文中若出现 v1 目录示例（`lib/core/`、
`lib/plugins/*/config/` 等），仅视为风格示例；实际目录一律以
[`.claude/CLAUDE.md`](../CLAUDE.md)「仓库结构」节为准。v2 特有的执行约束
（每任务焦点测试、全量集中一次、AI 不执行 git 命令、i18n 语义前缀等）
以 CLAUDE.md「硬性纪律」节为准。
