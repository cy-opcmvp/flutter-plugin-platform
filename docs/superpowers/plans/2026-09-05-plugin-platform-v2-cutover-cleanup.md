# Plugin Platform v2 Cutover & Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成发布收尾、产出旧功能差异清单、经用户逐项确认后删除旧实现并切换仓库到 v2，最终以统一文档与全量验证通过 G5 终验。

**Architecture:** 删除旧工程后把 `v2/` 上移为仓库根（推荐布局，见决策 1），根 pubspec 即 workspace 根；旧文档归档不删除；`.claude/` 项目指令重写为 v2 现实。**F5-03 是不可逆操作的唯一授权门**——差异清单与删除范围未经用户逐项确认前，任何旧文件不得删除。

**Tech Stack:** 既有 v2 全部资产；git mv/删除由用户在确认后授权执行（或用户自行执行）。

**Spec:** `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（§1 产品边界、§4 目标结构、§12 执行约束、§13 验收标准）

## Global Constraints

- **不可逆硬门**：F5-04 的每一条删除/移动必须出现在 F5-03 的确认清单里且经用户逐项批准；清单之外零删除。
- 继承既有执行策略（测试精简、焦点验证 + F5-05 集中全量、验收 G5 一次、git 操作需用户授权）。
- 旧文档一律**归档**（移入 `docs/archive/v1/`）而非删除——文档无运行成本，保留追溯。
- v2 生产代码本阶段原则上零改动（仅 F5-01 的收尾小修：pack 排除、版本号）；任何额外改动须在报告中说明并经 G5 复核。
- 发布版本号建议 **v2.0.0**（主版本 = 架构重写；旧 tag 止于 v0.4.4），CHANGELOG 新开 2.0.0 条目。

## 已冻结的技术决策（决策 1 需用户在计划审阅时认可或否决）

1. **仓库布局：v2 上移为根**（推荐）——删除旧工程后 `git mv v2/* ./`，根即 workspace 根 + apps/ + packages/ + plugins/ + sidecars/。理由：单一项目仓库、无 v2 命名债、未来贡献者零歧义。备选：保留 `v2/` 目录、根 README 跳转——迁移成本为零但永久背负目录债。
2. **旧文档归档**：`docs/` 旧内容与 `.kiro/specs/` 移入 `docs/archive/v1/`；`docs/superpowers/`（v2 过程资产）原位保留。
3. **`.claude/CLAUDE.md` 全面重写**为 v2 架构（workspace 结构、三插件、能力注入模式、条件导出纪律、走查文档指针）；`.claude/rules/` 中项目结构相关规则同步更新，通用规范（代码风格/Git/测试/错误处理）保留。
4. **i18n 前缀约定落定**（G4 T1-M1）：宿主 arb 保持 camelCase，**插件语义前缀作为命名约定**写入 CLAUDE.md（如 calc*/shot*/hash*），不迁移现有键。
5. **G4 其余 Minors**：pack 排除 `*.scp` 本阶段修（F5-01）；区域选择 overlay 与 sidecar 动态目录发现登记 post-2.0 roadmap（`docs/roadmap.md` 新建），不在 M5 实现。
6. **G5**：独立验收者只读，重点复核删除范围与确认清单逐项一致、切换后全量证据、文档索引一致性。

## 文件结构（切换后仓库根）

```text
./                        # 仓库根 = workspace 根（决策 1）
  pubspec.yaml            # v2/pubspec.yaml 上移
  analysis_options.yaml
  apps/toolbox_host/  packages/…(16)  plugins/…(2)  sidecars/python_sample/
  scripts/v2/build-matrix.ps1
  docs/
    superpowers/          # v2 规格/计划/验收（原位）
    guides/v2-plugin-dev-walkthrough.md
    roadmap.md            # 新建：post-2.0 待办
    archive/v1/           # 旧 docs 与 .kiro/specs 归档
  .claude/CLAUDE.md       # 重写
  README.md  CHANGELOG.md # 重写/新开 2.0.0
```

---

## Task F5-01：发布收尾小修

**Files:**

- Modify: `v2/packages/plugin_cli/lib/src/commands/pack.dart`（排除目录内 `*.scp`，防自嵌套；含测试）
- Modify: `v2/apps/toolbox_host/pubspec.yaml`（version 2.0.0）、根 README 的版本徽章位
- Create: `docs/releases/RELEASE_NOTES_v2.0.0.md`（用户视角：三插件、三主题、平台范围、已知限制引用 roadmap）
- Modify: `CHANGELOG.md`（2.0.0 条目：v1→v2 重写摘要 + 破坏性说明 + 迁移指向）

步骤：pack 排除 + 测试 → 版本与发布说明 → CHANGELOG → 焦点验证（cli 包 + host analyze）→ 检查点。建议 `chore(release): prepare v2.0.0`。

## Task F5-02：旧功能差异清单（用户审阅材料）

**Files:**

- Create: `docs/superpowers/cutover/v1-v2-feature-diff.md`

**Interfaces:**

- Produces: F5-03 确认门的唯一输入材料。

内容要求（逐特性表格）：

```text
维度：旧功能 → v2 现状（已实现/等价实现/部分实现/未实现→roadmap/有意放弃）
必须覆盖：三旧插件（计算器/截图[区域选择/编辑器/历史/热键]/世界时钟）、
桌面宠物、平台服务（通知/音频/任务调度）、标签管理、JSON 配置编辑器、
旧 i18n 覆盖面、桌面窗口管理（置顶/托盘等若有）
每行附：旧实现位置（目录级）、v2 对应物或 roadmap 链接、放弃理由（如适用）
末尾：明确的「随旧代码删除而消失的能力」汇总节 + roadmap.md 草稿
```

步骤：扫描旧 `lib/`、旧 docs、旧 CHANGELOG 提取特性面 → 与 v2 实测对照 → 成稿 → 检查点（建议 `docs(cutover): catalog v1 feature diff`）。

## Task F5-03：【用户确认门】删除范围逐项确认 ⚠️ 不可逆

**Files:** 无代码产出；产出用户批复（记录于 progress.yaml）。

控制器把三份材料呈交用户：

1. 差异清单（F5-02）
2. **删除范围逐项清单**（精确到目录/文件）：
   ```text
   删除：lib/ test/ integration_test/ windows/ android/ ios/ linux/ macos/ web/
        assets/ tools/ build/（旧） .dart_tool/ 等
   归档：docs/（旧内容）→ docs/archive/v1/；.kiro/specs/ → docs/archive/v1/specs/
   重写：README.md CHANGELOG.md(头部) .claude/CLAUDE.md .claude/rules/（结构相关）
   上移：v2/* → ./（决策 1，若用户认可）
   保留：.git/ .gitignore scripts/v2/ docs/superpowers/ .claude/rules 通用部分
   ```
3. Git 操作方式：用户自行执行 / 授权 AI 执行（两段式：删除提交 + 切换提交）

**未经逐项批准，F5-04 不得启动。** 用户可增删任何条目。

## Task F5-04：仓库切换（严格按批准范围）

步骤：归档移动（git mv docs 旧内容）→ 旧代码删除（git rm 按清单）→ v2 上移（git mv v2/* ./，含 workspace 校验 `dart pub get` + `flutter analyze`）→ 提交两段（`refactor: remove legacy v1 implementation` + `refactor: switch to plugin platform v2`，用户授权下执行）。每步后跑最小验证（workspace list + analyze）确认仓库始终可解析。

## Task F5-05：切换后全量验证与文档统一

步骤：**集中全量**（逐包 306+ 测试、format、analyze、边界扫描、构建矩阵三端实构建、宿主真机运行截图留证）→ README/CLAUDE.md/rules 重写 → roadmap.md 定稿 → docs 索引统一（MASTER_INDEX 或新导航）→ 检查点（建议 `docs: unify v2 documentation`）。

## Task G5：独立最终验收

只读四节：① 删除范围 vs 用户批复逐项一致（零超范围删除、清单项零遗漏）② 切换后全量证据复跑（抽包测试 + 矩阵 + 产物）③ 文档一致性（README/CLAUDE.md/rules 与实际结构零漂移、走查文档命令在新路径有效）④ 规格验收标准 §13 全项终核。报告 `docs/superpowers/acceptance/v2-cutover-acceptance.md`。通过 → M5 与 Goal 完成，标记最终 accepted。

---

## 与规格条款的覆盖对照（自审）

| 条款 | 任务 |
|---|---|
| v2 发布入口和打包产物 | F5-01 |
| 旧功能差异清单 | F5-02 |
| 用户确认不可逆清理范围 | F5-03（硬门） |
| 删除旧实现后的全量验证 | F5-05 |
| README、版本和文档索引统一 | F5-01/F5-05 |
| G5 终验 | G5 |
| Master Plan M5 五项 | 全覆盖 |
| G4 Minors（pack 排除/前缀约定/roadmap） | F5-01 决策 4/5 |
| §13「新开发者只依据文档完成示例插件」持续有效 | G5 ③ 走查文档新路径复验 |
