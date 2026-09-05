# v2 Cutover 独立终验报告（M5 / G5）

- **验收日期**: 2026-09-05
- **验收人**: 独立终验工程师（与实现者零共享上下文，只读验收）
- **验收对象**: M5 切换与清理（commits `fbd4bfd` 旧工程移除、`2445f3e` v2 上移切换、`3ea1586` 文档统一；前置材料 `f8c021d`）
- **规格依据**: `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md` §13
- **计划依据**: `docs/superpowers/plans/2026-09-05-plugin-platform-v2-cutover-cleanup.md`
- **批复依据**: `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml` F5-03/F5-04/F5-05

---

## S1 删除范围 vs 批复逐项一致

**结论: 通过**（零超范围、零遗漏；2 项 Minor 见"发现分级"）

### 1.1 fbd4bfd 变更构成（git show --name-status 实测 467 files changed）

| 类型 | 数量 | 内容归属 | 批复对应 |
|---|---|---|---|
| D 删除 | 354 | lib 175 / test 5 / integration_test 1 / windows 24 / android 20 / ios 38 / macos 28 / linux 10 / web 7 / assets 3 / tools 4 / nuget-packages 33 / .github 1 / 根旧配置 6（pubspec.yaml、pubspec.lock、analysis_options.yaml、l10n.yaml、devtools_options.yaml、.github/PULL_REQUEST_TEMPLATE.md 归入 .github 项） | 删除组：lib·test·integration_test·六平台·assets·tools·.github·nuget-packages·旧 pubspec/analysis/l10n/devtools 配置 —— **全部在批复内** |
| R 重命名(归档) | 111 | .kiro 22 → docs/archive/v1/kiro/、docs 旧内容 88 → docs/archive/v1/、根杂项 BUILD_AND_TEST_AUTOSTART.md 1 → docs/archive/v1/ | 归档组：docs 旧内容 + .kiro + 根杂项 md → docs/archive/v1/ —— **全部在批复内** |
| A 新增 | 2 | cutover 计划文档 + batch1 报告（commit message 已声明"随附归档"） | 流程文档，非超范围删除 |

### 1.2 零遗漏核验（批复删除清单逐项 → 落地证据）

| 批复项 | 落地 |
|---|---|
| lib/ | 已删（175 文件），目录不存在 |
| test/ | 已删（5 文件），目录不存在 |
| integration_test/ | 已删（1 文件），目录不存在 |
| windows/ android/ ios/ linux/ macos/ web/ | 已删（127 文件），六个目录均不存在 |
| assets/ | 已删（3 文件），目录不存在 |
| tools/ | 已删（4 文件），目录不存在 |
| .github/ | 已删，目录不存在 |
| nuget-packages/ | 已删（33 文件），目录不存在 |
| 旧 pubspec/analysis/l10n/devtools 配置 | 已删（pubspec.yaml/lock、analysis_options.yaml、l10n.yaml、devtools_options.yaml） |
| build/（旧） | 物理不存在（git 未跟踪）；根 `.dart_tool/` 为当前 v2 workspace 生成物（package_config 含 toolbox_host），非 v1 残留 |

### 1.3 保留组核验

| 批复保留项 | 状态 |
|---|---|
| docs/superpowers/（含 cutover 差异清单） | 在位：design/plans/specs/cutover/v1-v2-feature-diff.md |
| walkdoc | 在位：docs/guides/v2-plugin-dev-walkthrough.md（2445f3e 已做路径修正 M） |
| RELEASE_NOTES_v2.0.0 | 在位：docs/releases/RELEASE_NOTES_v2.0.0.md |
| CHANGELOG 全史 | 在位：根 CHANGELOG.md |
| .gitignore / .git / .claude/rules 通用部分 | 在位（.claude/rules/ 9 文件：8 规则 + README 索引） |

### 1.4 8 项遗留待裁定文件原位未动核验

| 文件/组 | 存在 | 最后触碰 |
|---|---|---|
| LICENSE | 是 | 72b2dae 初始提交（M5 各 commit 未触碰） |
| setup-cli.bat / setup-cli.sh | 是 | 根目录原位 |
| test-screenshot-hotkey.ps1 | 是 | 根目录原位 |
| .claude/rules/temp_readme.txt | 是 | 原位 |
| scripts/ v1 脚本组（fix-nuget.ps1、update-i18n.bat、check-doc*.ps1/sh、check-docs.*、diagnose-autostart.bat、generate_icon.bat、generate_app_icon.py、install-cppwinrt.ps1、test-notification-fix.bat） | 是（15 项在位） | git log 确认最后改动为 v1 时代提交（fbc2838/02006c9），M5 三个 commit 零触碰 |

### 1.5 docs/archive/v1/ 完整性抽查

- 28 个归档条目在位；三源齐全：`kiro/`（settings+specs+steering）、`claude-rules/`（恰 9 文件，与 F5-05 记录"rules 9 归档 8 保留"吻合）、旧 docs 内容（audits/examples/guides/fixes/platform-services/plugins/releases/reports/reference/migration 等）。

### 1.6 S1 发现

- [Minor] 物理空目录 `v2/` 残留在仓库根（git 不跟踪、无文件；上移 `v2/* → ./` 在 git 层完整，仅本地空壳目录未清扫）。
- [Minor] 计划 F5-03 材料字面写 ".kiro/specs/ → docs/archive/v1/specs/"，实际执行 ".kiro → docs/archive/v1/kiro/"（连 steering/settings 一并归档，内容更完整）。属于归档组批复内的良性偏差，路径命名与计划字面不一致。

---

## S2 切换后全量证据复跑

**结论: 通过**（本机独立复跑，全部复现）

### 2.1 抽包测试复跑（4 包抽验 + 1 包加验）

| 包 | 命令 | 结果 |
|---|---|---|
| packages/plugin_contracts | dart test | **48/48 All tests passed** |
| packages/plugin_cli | dart test | **9/9 All tests passed** |
| apps/toolbox_host | flutter test（包内） | **26/26 All tests passed**（含真 Python e2e 2/2，未降级） |
| plugins/calculator | flutter test | **23/23 All tests passed** |
| packages/platform_capabilities_windows（加验） | flutter test | **3/3**，真机 GDI 烟囱捕获本机复跑通过 |

### 2.2 根级静态检查

| 检查 | 结果 |
|---|---|
| `flutter analyze`（仓库根） | **No issues found!**（exit 0） |
| `dart format --output=none --set-exit-if-changed apps packages plugins` | **180 files, 0 changed**（exit 0） |

### 2.3 构建矩阵复跑（`powershell -File scripts/build-matrix.ps1`，重定向取证）

```
compile-graph OK   12 packages scanned, 0 platform-only imports
windows    OK      ...\apps\toolbox_host\build\windows\x64\runner\Debug\toolbox_host.exe
web        OK      ...\apps\toolbox_host\build\web\index.html
android    OK      ...\apps\toolbox_host\build\app\outputs\flutter-apk\app-debug.apk
macos/linux/ios    SKIPPED-LOCAL-UNAVAILABLE（诚实证据模型，非本机 OS）
RESULT: SUCCESS
```

三产物独立 `ls` 验证存在：toolbox_host.exe（577,536 B）、index.html（1,243 B）、app-debug.apk（149,499,674 B）。

### 2.4 Workspace

`dart pub workspace list` 输出 **17 行**（1 个 workspace 根 plugin_platform_v2_workspace + 16 成员包：packages 13 + apps 1 + plugins 2），与 F5-04 记录「17 成员解析成功」及 CLAUDE.md「17 成员」同一口径。

---

## S3 文档一致性零漂移

**结论: 有条件通过**（CLAUDE.md 硬纪律与走查文档零漂移；README 一条命令存在 Important 级漂移，见 3.4）

### 3.1 根 README 目录树 vs 实际

- apps/toolbox_host、packages 7 个核心包、plugins（calculator/screenshot）、sidecars/python_sample、scripts/build-matrix.ps1、docs/superpowers、walkdoc——逐项 ls 确认存在。
- 文档索引 5 个链接目标（差异清单、RELEASE_NOTES_v2.0.0、设计规格、Master Plan、walkdoc、M1-M4 验收报告）全部存在。
- 平台支持表与矩阵实测一致（Windows 全功能 / Web·Android 实构建通过 / macOS·Linux·iOS 静态检查）。
- [Minor] 目录树未列 6 个 `platform_capabilities_*` 端包，「六端 stub」表述归属含糊（实际 stub 位于端包内，如 `platform_capabilities_web/lib/src/stub.dart`），非结构性失真。

### 3.2 `.claude/CLAUDE.md` 硬纪律抽验 4 项（grep 实证）

| 纪律 | 实测 |
|---|---|
| `dart:ffi` 仅 `platform_capabilities_windows/lib/src/gdi_capture.dart` | ✅ 全仓库唯一真实 `import 'dart:ffi'`（宿主 host_screen_capture*.dart 3 处命中均为 `///` 文档注释） |
| plugin_contracts/plugin_runtime 禁 Flutter/dart:io/ffi | ✅ 两包 lib 零命中 |
| plugin_sidecar 的 dart:io 仅 io_file_system.dart + io_process_launcher.dart | ✅ 恰好两文件 |
| 插件包零平台依赖零 dart:io | ✅ calculator/screenshot 命中均为「零 dart:io」声明注释，无真实 import |
| 结构描述「17 成员」「capabilities(×7)」 | ✅ 与 workspace list、目录实际一致 |

### 3.3 `.claude/rules/README.md` 清单 vs 目录

- 清单 8 条（代码风格/测试/Git 提交/错误处理/性能优化/对话管理/文档命名/文档变更）与目录现存 8 规则一一对应；v1 归档说明与 `docs/archive/v1/claude-rules/`（恰 9 文件）吻合。
- [Minor] 目录中的 `temp_readme.txt`（v1 旧索引副本，属 8 项遗留待裁定之一，S1 已确认原位未动）未在 README 中注明。

### 3.4 命令抽验（README 3 条 + walkdoc 4 条，全部实跑）

| 来源 | 命令 | 结果 |
|---|---|---|
| README | `dart test packages/plugin_contracts`（根运行） | ✅ 48/48 |
| README | `flutter test apps/toolbox_host`（根运行） | ❌ **23/26，3 失败** |
| README | `dart run plugin_cli validate plugins/calculator`（根运行） | ✅ `OK tools.calculator (builtin v1.0.0)` |
| walkdoc | `cd packages/plugin_cli && dart run plugin_cli validate ../../plugins/calculator` | ✅ OK |
| walkdoc | `…validate ../../sidecars/python_sample` | ✅ `OK tools.hashtool (sidecar v1.0.0)` |
| walkdoc | `…pack ../../sidecars/python_sample -o …` | ✅ Packed 3 file(s)（4,852 B；F5-01 排除 .scp 修复生效） |
| walkdoc | `create --id tools.demo … + validate`（/tmp 往返） | ✅ Created → OK |

**[Important] README「常用命令」的 `flutter test apps/toolbox_host` 从仓库根运行失败 3 例**：`composition_root_test.dart`（×2）与 `sidecar_hash_e2e_test.dart`（×1）以包相对路径 `../../plugins/*/plugin.json`、`../../sidecars/*/hash-tool.scp` 读文件，依赖 CWD=包目录；根运行时 CWD=仓库根 → `PathNotFoundException`。包内 `flutter test`（walkdoc/ClaudeMD 口径）26/26 全绿，全量历史证据（307）不受影响。属文档命令与测试路径解析方式的漂移，非功能回归。

---

## S4 规格 §13 九条终核

| # | 验收标准 | 结论 | 证据来源 |
|---|---|---|---|
| 1 | Windows 宿主完成端到端运行 | **通过** | 本验：宿主 26/26（含真 Python e2e 全链「安装→启动→hash.compute→停止→卸载」）+ windows 实构建 exe 产出；M4 T2-4 真机 GDI 捕获烟囱（2560×1440 PNG 魔数/IHDR 断言）本验复跑 3/3 |
| 2 | 六端核心 SDK 可编译并通过契约测试 | **通过** | 矩阵 compile-graph OK（12 包扫描、0 平台专属 import 混入）+ 根 analyze No issues + plugin_contracts 48/48（本验复跑） |
| 3 | Windows 专属依赖不污染 Web 或其他平台构建 | **通过** | web 实构建 OK + compile-graph 0 混入 + `dart:ffi` 唯一性独立 grep 实证（S3.2）+ `*_io.dart` 条件导出机制核对 |
| 4 | 计算器在其六端目标矩阵通过业务测试 | **通过（诚实证据模型）** | plugin.json targets 六端（M4 T1-1）+ 本机可得端实构建（windows/web/android OK）+ 不可得端编译图静态检查替代（M3 决策 5，SKIPPED-LOCAL-UNAVAILABLE 如实标注）+ calculator 23/23 本验复跑 |
| 5 | 截图插件只在声明支持的平台加载 | **通过** | plugin.json targets=["windows"]（M4 T2-1）+ resolver `unsupported_target` 机制与注入测试（M4 T2-2）+ 宿主目录页「不可用徽章+原因文案」测试在 26/26 内 |
| 6 | Windows Python Sidecar 完成安装、启动、通信、停止、超时和卸载 | **通过** | 真 Python e2e 2/2 全链真跑（本验复跑于 26/26 内；M4 T3-1 hashlib 三摘要交叉验证一致，非 markTestSkipped 降级）+ `bridge.not_installed` 结构化断言（M4 T3-4）+ 进程监督超时用例（plugin_sidecar 包内，F5-05 全量 307） |
| 7 | CLI 能创建、校验和打包新插件 | **通过** | 本验：`create tools.demo` → `validate` OK 往返 + `pack python_sample` → 3 files/4,852 B + plugin_cli 9/9（含 pack 排除 .scp 新用例，F5-01 对 M4 T3-M1 的修复生效） |
| 8 | 新开发者只依据文档即可完成示例插件 | **通过** | walkdoc 为唯一入口，其 4 条核心命令（validate builtin / validate sidecar / pack / create）新根路径全部本验实跑有效；README 快速开始命令 2/3 直接有效（1 条见 S3.4 Important，包内口径下有效） |
| 9 | 删除伪签名、伪沙箱和模拟 IPC，不保留误导性的安全声明 | **通过** | 全库 grep「伪签名/伪沙箱/模拟 IPC/fake signature/mock sandbox」零命中；sha256 为真实完整性校验（M4 T3-3 SCP1 魔数 od 验证 + 往返实测）；IPC 为真子进程 stdio JSON-RPC（e2e 真跑）；文档无夸大安全声明（README「诚实证据模型」） |

---

## 发现分级汇总

**Critical: 0 ｜ Important: 1 ｜ Minor: 4**

| 级别 | 发现 | 位置 | 建议修复 |
|---|---|---|---|
| Important | README 命令 `flutter test apps/toolbox_host` 根运行 3 例 PathNotFound（测试以包相对路径读 fixture，依赖 CWD=包目录） | `README.md` 常用命令；`apps/toolbox_host/test/composition_root_test.dart`、`sidecar_hash_e2e_test.dart` | README 命令改为 `cd apps/toolbox_host && flutter test`（与 walkdoc/CLAUDE.md 口径对齐），或将测试的 fixture 路径改为 CWD 无关解析 |
| Minor | 物理空目录 `v2/` 残留于仓库根（git 不跟踪，仅本地空壳） | 仓库根 | 删除空目录 |
| Minor | `.kiro` 归档实际路径 `docs/archive/v1/kiro/` 与计划 F5-03 字面「docs/archive/v1/specs/」不一致（内容更完整，含 specs+steering+settings，属归档组批复内的良性偏差） | fbd4bfd、`docs/archive/v1/kiro/` | 在 cutover 计划或 progress.yaml 补一行备注即可，无需改动 |
| Minor | README 目录树未列 6 个 `platform_capabilities_*` 端包，「六端 stub」归属表述含糊 | `README.md` 架构总览 | 树中补一行「platform_capabilities_*（×6 端包：真实现/stub）」 |
| Minor | `temp_readme.txt`（v1 旧索引遗留副本）在 `.claude/rules/` 目录中，但 rules/README.md 未注明其遗留状态 | `.claude/rules/` | 与其余 7 项遗留待裁定一并提交用户裁定后删除或移入 docs/archive/v1/ |

遗留待裁定 8 项（LICENSE、setup-cli.bat/.sh、test-screenshot-hotkey.ps1、.claude/rules/temp_readme.txt、scripts/ v1 脚本组）经逐项核验**全部原位未被擅动**（S1.4），符合 F5-03「待用户补充裁定」约定，不构成违规。

---

## 最终结论

**Approved —— 四节均无 Critical，M5（切换与清理）与 Goal 完成。**

- S1 删除范围 vs 批复：**通过**（354 删 + 111 归档全部落在批复五组内，零超范围、零遗漏；8 项遗留待裁定原位未动）
- S2 全量证据复跑：**通过**（抽包 4+1 包全绿、analyze No issues、format 0 changed、矩阵 SUCCESS 三产物在位、workspace 17 行）
- S3 文档一致性：**有条件通过**（CLAUDE.md 硬纪律 4 项与走查文档零漂移；README 1 条命令 Important 级漂移，不阻断验收）
- S4 规格 §13 九条：**9/9 通过**（第 4 条按既定诚实证据模型：3 端实构建 + 3 端编译图静态检查，与 M3 决策 5 一致）

建议随下一批次处理 1 项 Important（README 命令口径）与 4 项 Minor；其中 8 项遗留待裁定文件与 Minor-5 需用户裁定，其余可由实现者直接修复。
