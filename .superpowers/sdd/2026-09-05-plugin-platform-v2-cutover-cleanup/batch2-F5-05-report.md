# Batch 2 实施报告：F5-05（rules 整编 + roadmap + 切换后集中全量验证）

**日期**: 2026-09-05
**执行人**: 实现工程师（Claude）
**阶段**: M5 切换与清理（收官任务）
**状态**: ✅ 三项子任务全部完成；全量验证全绿（含一处验证设施一行修复，见偏差 #1）

---

## 一、rules 整编（按 F5-03 批准范围）

### 归档（git mv → `docs/archive/v1/claude-rules/`，9 件，v1 结构专属）

| # | 文件 | 归档理由 |
|---|------|---------|
| 1 | FILE_ORGANIZATION_RULES.md | v1 根目录/lib 结构专属 |
| 2 | JSON_CONFIG_RULES.md | v1 JSON 配置文件体系（v2 为声明式设置表单） |
| 3 | PLUGIN_CONFIG_SPEC.md | v1 插件 config/ 目录体系（v2 清单 configSchemaVersion） |
| 4 | PLUGIN_SETTINGS_SCREEN_RULES.md | v1 插件设置页面模式（v2 声明式 Surface） |
| 5 | REACTIVE_CONFIG_RULES.md | v1 GlobalConfig 响应式体系 |
| 6 | SINGLE_CONFIG_PATTERN_RULES.md | v1 dataStorage 单键配置模式（契约已随架构消失） |
| 7 | RULES_AUDIT_REPORT.md | v1 规则集的历史审计报告 |
| 8 | VERSION_CONTROL_RULES.md | v1 tag 体系（v2 版本即 CHANGELOG + release note） |
| 9 | VERSION_CONTROL_HISTORY.md | v1 tag 历史（追溯件，随规则体系归档） |

### 保留原样（通用规范，8 件）

`CODE_STYLE_RULES.md`、`TESTING_RULES.md`、`GIT_COMMIT_RULES.md`、`ERROR_HANDLING_RULES.md`、`PERFORMANCE_OPTIMIZATION_RULES.md`、`CONVERSATION_MANAGEMENT_RULES.md`、`DOCUMENTATION_NAMING_RULES.md`、`DOCUMENTATION_CHANGE_MANAGEMENT.md`

### 重写（1 件）

`.claude/rules/README.md` — 新索引：保留 8 件清单表 + 一句 v1 归档说明
（9 件移入 `docs/archive/v1/claude-rules/` 仅追溯）+ 指向 `.claude/CLAUDE.md`
「硬性纪律」节为 v2 结构唯一事实源；补充约定注明通用规范中的 v1 目录示例
仅视为风格示例。

---

## 二、roadmap 定稿

**新建**: `docs/roadmap.md`（中文）。

结构：四个分组共 **22 项**，每项一句说明 + 差异清单来源行——

- **能力契约层（7）**：窗口管理、全局热键、通知、音频、任务调度、网络访问、插件数据持久化（均标注前置关系）
- **截图七件套（8）**：区域选择 overlay（G4 决策 5 登记）、窗口捕获、编辑/标注、历史、热键接入、循环/定时截图、剪贴板 CF_DIB、保存配置面恢复（部分实现行余项单列，避免夸大 v2 现状）
- **插件移植（2）**：世界时钟（依赖存储+通知契约）、桌面宠物（依赖窗口管理契约）
- **框架与工具（5）**：Sidecar 动态目录发现（G4 决策 5 登记）、外部插件翻译资源（IPluginI18n 裁定入）、标签管理（裁定入）、CLI `publish`（裁定入）、全局配置体系余项

文末「**已裁定彻底消失（不在 roadmap）**」节：系统托盘（v1 未落地）、自动启动、
权限管理、服务测试界面、热重载包装、CLI build/test、进程内沙盒/服务定位器/
IPlugin 模型/平台适配层（随架构消失）、JSON 配置编辑器、旧全量翻译键、
JS/Java/C++ 样本——逐类点名，回溯指向差异清单与 `docs/archive/v1/`。

F5-03 五项裁定全部落实：标签管理/IPluginI18n/CLI publish → 入 roadmap；
系统托盘/自动启动 → 彻底消失节，不入清单。

---

## 三、切换后集中全量验证（M5 唯一一次全量）

### 3.1 逐包测试 —— **15 包 307 测试全绿**（预期 306+ ✅）

**纯 Dart（dart test）11 包，194**：

| 包 | 测试数 | 备注 |
|----|-------|------|
| plugin_contracts | 48 | All tests passed |
| plugin_runtime | 26 | All tests passed |
| plugin_sidecar | 93 | **含 Python e2e 真跑**（场景含 uninstall 收尾） |
| platform_capabilities | 5 | |
| platform_capabilities_windows | 3 | 含真机 GDI 烟囱用例 |
| platform_capabilities_macos/linux/android/ios/web | 各 2（计 10） | stub unsupported 失败语义 |
| plugin_cli | 9 | 含 F5-01 防自嵌套新用例 |

**Flutter（flutter test）4 包 + 宿主，113**：

| 包 | 测试数 | 备注 |
|----|-------|------|
| plugin_flutter | 37 | 含 zh/en 本地化用例 |
| plugin_devkit | 14 | |
| plugins/calculator | 23 | |
| plugins/screenshot | 13 | |
| apps/toolbox_host | 26 | 含 `sidecar_hash_e2e_test.dart` 独立复跑：**2/2 通过，Python 3.11.9 真进程全链，无 skip** |

**合计：307**（194 + 113）。

### 3.2 format + analyze

- `dart format --output=none --set-exit-if-changed apps packages plugins`：**180 files, 0 changed，exit 0** ✅
- `flutter analyze`（仓库根 workspace）：**No issues found!** ✅

### 3.3 依赖边界五项扫描（新根路径）

| # | 边界 | 结果 |
|---|------|------|
| 1 | plugin_contracts + plugin_runtime lib 中 `dart:io\|dart:ffi\|package:flutter\|package:win32` | **0 文件命中** ✅ |
| 2 | plugin_sidecar lib 中 `dart:io` | **仅 2 个允许文件**：`lib/src/package/io_file_system.dart`、`lib/src/process/io_process_launcher.dart` ✅ |
| 3 | 全仓 lib 真实 `import dart:ffi` | **仅** `packages/platform_capabilities_windows/lib/src/gdi_capture.dart` 一处（宿主三文件命中均为 `///` 注释文字提及，非 import）✅ |
| 4 | capability 七包 lib 中 `import dart:io` | **0 条** ✅ |
| 5 | plugins/calculator + plugins/screenshot lib 中 `dart:io/dart:ffi/win32` 真 import | **0 条**（4 处命中均为「零 dart:io」边界声明注释；package:flutter 为声明式 UI 层，非平台专属依赖）✅ |

### 3.4 构建矩阵（三端实构建）

首跑 **FAILED** —— 脚本 V2Root 推导漂移（见偏差 #1），一行修复后重跑：

```text
compile-graph OK    12 packages scanned, 0 platform-only imports
windows    OK  apps/toolbox_host/build/windows/x64/runner/Debug/toolbox_host.exe
web        OK  apps/toolbox_host/build/web/index.html
android    OK  apps/toolbox_host/build/app/outputs/flutter-apk/app-debug.apk
macos      SKIPPED-LOCAL-UNAVAILABLE（非 macOS 主机，compile-graph 静态检查替代证据）
linux      SKIPPED-LOCAL-UNAVAILABLE（同上）
ios        SKIPPED-LOCAL-UNAVAILABLE（同上）
RESULT: SUCCESS
```

三端产物实证（本次构建时间戳 2026-09-05 14:28–14:29）：
`toolbox_host.exe`（577,536 B）/ `web/index.html`（1,243 B）/ `app-debug.apk`（149,499,674 B）。诚实模型保持：无伪造六端声明。

### 3.5 CLI 冒烟

| 命令 | 结果 |
|------|------|
| `dart run plugin_cli validate plugins/calculator`（仓库根形式） | `OK tools.calculator (builtin v1.0.0)` exit 0 ✅ |
| `dart run plugin_cli validate plugins/screenshot`（仓库根形式） | `OK tools.screenshot (builtin v1.0.0)` exit 0 ✅ |
| `cd packages/plugin_cli && dart run plugin_cli validate ../../plugins/calculator`（走查文档原写法） | OK ✅ |
| 同上 `../../plugins/screenshot` | OK ✅ |
| 同上 `../../sidecars/python_sample` | `OK tools.hashtool (sidecar v1.0.0)` ✅ |

### 3.6 走查文档抽查（`docs/guides/v2-plugin-dev-walkthrough.md`）

| 文档位置 | 命令 | 结果 |
|---------|------|------|
| §2 最小验证 1 | `cd packages/plugin_contracts && dart test` | 48/48 ✅ |
| §2 最小验证 2 | `cd apps/toolbox_host && flutter test` | 26/26 ✅ |
| §2 最小验证 3 | `dart format --output=none --set-exit-if-changed .`（仓库根） | **exit 0、0 changed，命令有效**；输出含 41 条 v1 归档模板解析噪音（见偏差 #2） |
| §3.4 / §4.5 | validate 双插件 + python_sample | 全 OK ✅ |
| §4.4 | `flutter test test/sidecar_hash_e2e_test.dart` | 2/2 真 Python，无 skip ✅ |
| §4.2/4.1 佐证 | `python hash_tool.py` 冒烟 | 启动即发 `ready` 纯字符串帧，协议一致 ✅ |

---

## 四、偏差列表

| # | 偏差 | 定性与处置 |
|---|------|-----------|
| 1 | **`scripts/build-matrix.ps1` 一行修复**：V2Root 默认推导原为 `$PSScriptRoot/../../`（旧 `scripts/v2/` 两层深度），v2 上移后解析到 `E:\my` 导致首跑全 FAILED；改为 `$PSScriptRoot/../`（现 `scripts/` 一层），与脚本头部「默认仓库根」声明及 CLAUDE.md 记录的命令一致。**脚本属验证基础设施，非 v2 生产代码**；`-V2Root` 参数逻辑未动。重跑 SUCCESS | 必要修复（否则 G5 复跑必失败），已在 §3.4 留证 |
| 2 | 走查文档 §2 第三条命令（仓库根 `.` format）实跑有效（exit 0 / 0 changed），但根 `.` 现会扫到 `docs/archive/v1/templates/*.dart` 等 v1 归档模板，产生 41 条解析错误噪音（不影响退出码）。按零超范围原则**未改走查文档**；建议后续把该命令改为 `--set-exit-if-changed apps packages plugins` 或排除归档，交控制器/G5 文档一致性复核时定夺 | 观察项，功能通过 |
| 3 | `.claude/rules/temp_readme.txt`（1.9 KB，旧索引残留片段）不在本任务归档清单内，**未动**；建议随下批清理归档或删除，需控制器裁定 | 观察项 |
| 4 | `scripts/` 下仍有 v1 时代脚本残留（`fix-nuget.ps1`、`update-i18n.bat`、`diagnose-autostart.bat`、`generate_icon.bat`、`install-cppwinrt.ps1`、`check-doc*.ps1/sh` 等），不在本任务范围**未动**，供后续清理参考 | 观察项 |

---

## 五、硬约束遵守情况

- git 仅执行了授权的 `git mv`（9 件 rules 归档）；**零 commit、零 git rm**。
- 未触碰 `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`（其 M 状态为会话前已存在）。
- v2 生产代码零改动（唯一代码性修改为验证脚本 build-matrix.ps1 一行，见偏差 #1）。
- 长输出全部重定向临时文件或截尾；无大文件整读。

## 六、交付物汇总

**git mv（9）**：rules → `docs/archive/v1/claude-rules/`（清单见 §一）

**修改（2）**：`.claude/rules/README.md`（重写索引）、`scripts/build-matrix.ps1`（一行根修复，偏差 #1）

**新建（2）**：`docs/roadmap.md`、本报告

## 七、返回给控制器的要点

1. **测试总数**：15 包 **307 全绿**（纯 Dart 194 + Flutter 113）；两处 Python e2e（plugin_sidecar 内 + 宿主 hash 全链）均真跑无 skip。
2. **构建矩阵**：**SUCCESS** —— windows/web/android 三端实构建 OK + 产物实证；macos/linux/ios 如实 SKIPPED；compile-graph 12 包 0 平台专属 import。注意：首跑 FAILED 暴露并修复了脚本根推导漂移（一行，偏差 #1）。
3. **format/analyze/边界**：0 changed、No issues、边界五项全合规。
4. **走查抽查**：三条最小命令 + CLI validate（三种写法）+ e2e + Python 样本冒烟全部实跑有效。
5. **偏差**：4 项（1 项必要修复已留证；3 项观察项待控制器裁定）。
