# Batch 1 实施报告：F5-01（发布收尾）+ F5-02（旧功能差异清单）

**日期**: 2026-09-05
**执行人**: 实现工程师（Claude）
**阶段**: M5 切换与清理
**状态**: ✅ 两任务全部完成，焦点验证通过

---

## F5-01 发布收尾

### 执行明细

| # | 项目 | 结果 |
|---|------|------|
| 1 | `v2/packages/plugin_cli/lib/src/commands/pack.dart`：目录收集时排除 `*.scp`（防自嵌套，G4 T3-M1）；`test/commands/cli_round_trip_test.dart` 新增第 9 个用例 | ✅ 完成 |
| 2 | `v2/apps/toolbox_host/pubspec.yaml`：`version: 0.1.0` → `version: 2.0.0` | ✅ 完成 |
| 3 | `CHANGELOG.md`：头部（格式声明之后、`[Unreleased]` 之前）新增 `## [2.0.0] - 2026-09-05` 节，节首注明旧条目为 v1 时代记录全部保留；含 Added/Changed/Breaking-Removed/Migration；Breaking 段链接差异清单 | ✅ 完成 |
| 4 | 新建 `docs/releases/RELEASE_NOTES_v2.0.0.md`（中文用户视角：概述/三插件/三主题/Sidecar 全链/六端证据/平台支持矩阵/已知限制指向 roadmap/安装运行方式） | ✅ 完成 |
| 5 | 焦点验证（见下） | ✅ 全绿 |

### 变更文件清单（F5-01）

**修改**：
- `v2/packages/plugin_cli/lib/src/commands/pack.dart` — `_collectEntries` 在输出文件自身排除之后新增：目录内既有 `*.scp`（大小写不敏感后缀判断）一律跳过，注释说明防自嵌套动机（python_sample 目录内已存在 hash-tool.scp，重复 pack 必然触发）
- `v2/packages/plugin_cli/test/commands/cli_round_trip_test.dart` — 头部场景清单补第 9 条；新增用例 `pack excludes pre-existing .scp files in the plugin directory`（于插件根与目录内各放 stale.scp，打包后断言产物 2 条目、不含任何 .scp、plugin.json/main.py 完整）
- `v2/apps/toolbox_host/pubspec.yaml` — 仅 version 字段
- `CHANGELOG.md` — 仅插入 2.0.0 节，其余零改动
- `README.md`（仓库根） — 仅「📦 当前版本」块：v0.4.1 → v2.0.0、发布日期 2026-09-05、加 RELEASE_NOTES 链接（授权依据：计划文件 F5-01 Files 列明「根 README 的版本徽章位」）

**新建**：
- `docs/releases/RELEASE_NOTES_v2.0.0.md`

### 焦点验证结果

| 检查 | 结果 |
|------|------|
| `v2/packages/plugin_cli` `dart test` | **9/9 通过**（含新增防自嵌套用例） |
| `v2/packages/plugin_cli` `dart format` | Formatted 11 files (**0 changed**) |
| `v2/packages/plugin_cli` `dart analyze` | **No issues found!** |
| `v2/apps/toolbox_host` `flutter analyze` | **No issues found!** |

---

## F5-02 旧功能差异清单

**唯一新建文档**：`docs/superpowers/cutover/v1-v2-feature-diff.md`（新建 `cutover/` 目录）

### 结构（按任务书）

1. **用途说明**：F5-03 删除确认的唯一审阅材料、生成日期 2026-09-05、扫描范围（lib/、windows/runner/、tools/、CHANGELOG/README/docs、v2 全现状）、分类口径六值定义
2. **逐特性对照表**：A 旧内置插件（11 行）/ B 桌面宠物（1 行）/ C 平台服务层（6 行）/ D 平台工程能力（20 行），共 **38 行**；每行含旧特性、旧实现位置（目录级，原生层单列 `windows/runner/*.cpp`）、v2 现状、分类、说明/去向
3. **随旧代码删除而消失的能力（汇总，最重要）**：**32 条**，每条标注去向（`roadmap` / `随架构消失` / `彻底消失` / `待用户裁定`）
4. **post-2.0 roadmap 草稿**：12 项（1 区域选择 overlay、2 sidecar 动态目录发现为 G4 决策 5 明确登记项；待裁定项明确不入草稿，待 F5-03 后由 F5-05 定稿 `docs/roadmap.md`）
5. **复核口径说明**：供 F5-03 使用

### 分类统计（38 行对照表）

- 等价实现 6（计算器、全屏截图、描述符、外部插件链路、管理 UI、发布体系）
- 部分实现 5（JSON 编辑器、截图保存配置、插件沙盒、i18n 覆盖面、全局配置）
- 未实现→roadmap 12（截图区域选择/窗口捕获/编辑器/历史/热键/循环任务/剪贴板、世界时钟、桌面宠物、通知/音频/任务调度、数据存储、窗口管理、网络管理）
- 有意放弃 8（ServiceLocator/服务管理器、权限管理、服务测试界面、IPlugin 模型、热重载包装、平台适配抽象层、拼图游戏[README 失实，代码本不存在]、CLI build/test）
- 待用户裁定 5（标签管理、外部插件 i18n、系统托盘、自动启动、CLI publish）
- 其余 2 行为组合表述（旧 CLI 行含「有意放弃 + 待裁定」；全局配置行「部分实现+roadmap」）

### 关键事实核查记录

- 托盘：`lib/core/services/system_tray/` 为空目录，仅 `platform_config.dart` 留有配置节——v1 未落地，标待裁定并注明「删除无运行时损失」
- 拼图游戏：旧 README 内置插件表宣称「3x3 滑动拼图 ✅ 完整实现」，但 `lib/plugins/` 下无对应代码（grep 零命中）——文档失实，标有意放弃
- 剪贴板复制（CF_DIB）：v1 `[Unreleased]` 段刚完成原生实现、未随 tag 发布即遇 v2 重写——已在对照表行注明
- IPluginI18n：v0.4.4 刚交付即遇重写——标待裁定并注明
- 截图 v2 设置面：仅 `settingsFilenamePrefix` + `settingsQuality` 两项（声明式表单），与其余子特性分开标注，避免夸大 v2 现状

### 硬约束遵守情况

- 全程未删除/未移动任何旧工程文件（lib/、docs/、.kiro/ 等只读）；F5-02 仅扫描与记录
- 未执行任何 git 操作
- 未修改 progress.yaml

---

## 偏差列表

| # | 偏差 | 说明 |
|---|------|------|
| 1 | 修改了根 `README.md` 的版本徽章位 | 任务 prompt 四项未明列，但计划文件 F5-01 Files 列明「根 README 的版本徽章位」；按计划执行，仅动「📦 当前版本」块 |
| 2 | `v2/packages/plugin_cli/README.md` L53 pack 描述存在漂移 | 现文只写「输出文件自身被排除」，未提新增的 `*.scp` 目录排除。该文件不在 F5-01 授权修改清单内，按零修改原则未更新；建议 F5-04/F5-05 顺手补一句 |
| 3 | `v2/apps/toolbox_host/pubspec.yaml` description 仍写「M3 阶段 F3-06」 | 同为授权外文件内容，未改；发布物描述陈旧但不影响功能，留待后续 |
| 4 | 差异清单中「已实现」分类值未被使用 | 六分类口径中该值与「等价实现」在 v1→v2 语境下语义重叠；实际 38 行全部落入其余五类，未强行凑值 |

---

## 交付物汇总

**修改（5）**：`v2/packages/plugin_cli/lib/src/commands/pack.dart`、`v2/packages/plugin_cli/test/commands/cli_round_trip_test.dart`、`v2/apps/toolbox_host/pubspec.yaml`、`CHANGELOG.md`、`README.md`

**新建（3）**：`docs/releases/RELEASE_NOTES_v2.0.0.md`、`docs/superpowers/cutover/v1-v2-feature-diff.md`、本报告

## 返回给控制器的要点

1. **F5-01 测试结果**：plugin_cli `dart test` 9/9（含新用例）、format 0 changed、`dart analyze` 干净；toolbox_host `flutter analyze` 干净
2. **消失能力条目数**：汇总节 **32 条**（对照表 38 行）
3. **待用户裁定项**：5 项——标签管理、外部插件 i18n（IPluginI18n）、系统托盘（v1 未落地）、自动启动、CLI `publish`
4. **偏差列表**：见上节 4 项
