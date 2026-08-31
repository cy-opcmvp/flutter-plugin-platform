# Flutter Plugin Platform v2 Master Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从零构建可复用的 Flutter 多端插件平台 v2，并在独立验收后切换旧实现。

**Architecture:** 使用纯 Dart 微内核管理契约、生命周期和能力解析；内置 Dart 插件与桌面 Sidecar 共享清单语义但使用不同加载器；平台能力通过独立适配包隔离。新实现位于 `v2/`，旧工程保留到最终切换门。

**Tech Stack:** Dart 3.10、Flutter、JSON 清单、JSON-RPC/stdio、Dart package workspace、Flutter federated platform adapter pattern、Python Sidecar 样本。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`

## Global Constraints

- 核心 SDK 必须支持 Windows、macOS、Linux、Android、iOS、Web 的编译和契约测试。
- Windows 是首个端到端功能平台，不得把 Windows 依赖引入纯 Dart 核心。
- 旧 API 和旧实现无需兼容，但最终验收前不得批量删除旧代码。
- 框架搭建、真实插件实现、独立验收必须处于不同阶段。
- 实现者不得验收自己的任务；验收者只读检查并生成报告。
- 批量执行前必须询问用户是否创建 Goal。
- 子智能体默认最大并发数为 1，不允许多个写入智能体并发编辑。
- 普通业务默认 Luna high；跨平台、进程、文件系统、安全和公共契约自动升级。
- 每个任务必须更新 `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`。
- AI 不执行 Git 命令，只提供建议提交信息。

---

## 子项目与阶段门

### M0：设计与执行基线

- [x] 完成需求访谈和架构选择。
- [x] 固化设计规格。
- [x] 设置全局子智能体并发上限为 1。
- [x] 用户确认本次批量实施使用 Goal，且 Goal 已创建。

**完成条件：** 设计、计划、状态文件均可从磁盘读取；Goal 选择明确。

### M1：核心框架基础

**详细计划：** `docs/superpowers/plans/2026-08-31-plugin-platform-v2-core-foundation.md`

交付：

- Dart workspace 骨架。
- `plugin_contracts`。
- `plugin_runtime`。
- `plugin_devkit`。
- 生命周期状态机和能力解析器。
- 第一阶段契约文档。

**阶段门 G1：** 独立 Sol xhigh 验收核心边界、测试和文档；不通过则退回实现智能体。

### M2：Sidecar 框架

详细计划在 G1 通过后冻结，计划必须覆盖：

- 安装包格式和路径安全验证。
- 原子安装与卸载。
- JSON-RPC 帧协议。
- 进程监督、超时、取消和退出回收。
- Windows Python Sidecar 测试夹具。

**阶段门 G2：** 独立 Sol xhigh 安全和故障注入验收。

### M3：Flutter 宿主、平台能力与 CLI

详细计划在 G2 通过后冻结，计划必须覆盖：

- `plugin_flutter` UI Surface。
- 参考宿主 Composition Root。
- 六端平台能力接口和空实现行为。
- 插件创建、校验和打包 CLI。
- 六端构建矩阵和契约测试入口。

**阶段门 G3：** 独立 Sol high 验收架构边界，Terra high 验收平台构建证据。

### M4：MVP 真实插件

详细计划在 G3 通过后冻结，计划必须覆盖：

- 计算器六端插件。
- 截图插件及平台变体。
- Windows Python Sidecar 样本。
- 插件开发文档的可复现走查。

**阶段门 G4：** Terra high 分插件验收，Sol xhigh 汇总发布终验。

### M5：切换与旧代码清理

详细计划在 G4 通过后冻结，计划必须覆盖：

- v2 发布入口和打包产物。
- 旧功能差异清单。
- 用户确认不可逆清理范围。
- 删除旧实现后的全量验证。
- README、版本和文档索引统一。

**阶段门 G5：** 独立 Sol xhigh 最终验收。旧代码删除必须由用户在执行前再次确认。

## 智能体执行矩阵

| 工作 | 实现 | 验收 | 并发 |
|---|---|---|---|
| 设计和公共契约 | Sol xhigh | 独立 Sol xhigh | 串行 |
| 核心运行时 | Sol high/xhigh | 独立 Sol xhigh | 串行 |
| Sidecar 安装和 RPC | Sol xhigh | 独立 Sol xhigh | 串行 |
| 平台适配 | Terra high | 独立 Sol high | 串行 |
| 普通插件业务 | Luna high | 独立 Terra high | 串行 |
| 文档和机械测试 | Luna medium | 独立 Terra high | 串行 |
| 最终发布 | Sol xhigh | 另一 Sol xhigh | 串行 |

## 中断恢复算法

1. 读取设计规格、Master Plan 和 progress.yaml。
2. 跳过所有 `accepted` 任务。
3. 对 `in_progress` 和 `implemented_unverified` 任务检查实际文件。
4. 运行任务记录的最小验证命令。
5. 验证通过则推进到 `verified_pending_acceptance`；否则从现有实现继续修复。
6. 不重写已有实现，不根据聊天摘要宣布完成。
7. 更新 handoff 和 progress 后才启动下一个智能体。

## 用户 Git 检查点建议

AI 不执行以下命令。每个阶段门通过后，向用户提供 Conventional Commit 建议：

```text
docs: confirm plugin platform v2 design
feat(core): complete plugin platform v2 core foundation
feat(sidecar): complete sidecar runtime
feat(platform): complete host and platform adapters
feat(plugins): complete MVP plugin set
refactor: switch to plugin platform v2
```
