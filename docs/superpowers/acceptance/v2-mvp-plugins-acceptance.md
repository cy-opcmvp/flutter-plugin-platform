# M4 MVP 真实插件 独立验收报告

- **验收对象**: M4（mvp-plugins）F4-01 ~ F4-07
- **验收人**: 独立验收工程师（Terra 分插件核查 + Sol 汇总终验），与实现者无共享上下文
- **验收方式**: 只读验收（除本报告外未创建/修改任何文件），复跑测试与只读命令取证
- **验收日期**: 2026-09-05
- **输入**:
  - 规格 `docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md`（§2/§4/§10/§13）
  - 计划 `docs/superpowers/plans/2026-09-05-plugin-platform-v2-mvp-plugins.md`
  - 偏差台账 `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml`（M4 accepted_deviations）
  - 实现 `v2/`（plugins/calculator、plugins/screenshot、sidecars/python_sample、packages/platform_capabilities_windows、apps/toolbox_host）
  - 走查文档 `docs/guides/v2-plugin-dev-walkthrough.md`

---

## 结论速览

| 章节 | 结论 | Critical | Important | Minor |
|------|------|----------|-----------|-------|
| T1 计算器 | **通过** | 0 | 0 | 1 |
| T2 截图 | **通过** | 0 | 0 | 1 |
| T3 hash_tool | **通过** | 0 | 0 | 1 |
| 终验（Sol） | **通过** | 0 | 0 | 0 |

**总计**: 0 Critical / 0 Important / 3 Minor → **Approved**

---

## T1 计算器（Terra）

**结论：通过**（0 Critical / 0 Important / 1 Minor）

### 核查表

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| T1-1 | plugin.json targets 覆盖六端 | 通过 | `v2/plugins/calculator/plugin.json:8-15` targets = windows/macos/linux/android/ios/web；`kind: builtin`、`entrypoint: builtin://tools.calculator`、`requires: []`（零平台能力要求）、surfaces = page+settings |
| T1-2 | 零平台依赖（pubspec + import 全查） | 通过 | `v2/plugins/calculator/pubspec.yaml` dependencies 仅 flutter / plugin_contracts / plugin_flutter（均为纯 Dart/Flutter 包），无任何平台实现包；`grep -rn "^import" lib` 14 条全部为 plugin_contracts / plugin_flutter / flutter SDK / 包内相对路径，零 `dart:io`、零 `package:*_platform*` |
| T1-3 | 三端实构建内的编译图 | 通过（引用） | F4-07 build_matrix: SUCCESS（windows/macos/linux? 见终验 S3 三产物抽查）；六端 targets 中 web/macos/linux 编译覆盖以矩阵报告与宿主条件导出 web stub 为准，本节不重复构建 |
| T1-4 | 求值器测试覆盖抽查 | 通过 | `v2/plugins/calculator/test/logic/expression_parser_test.dart`：优先级与左结合 `2+3*4=14`/`10-4-3=3`/`20/4/5=1`/`7%3`（L43-48）；括号含嵌套 `(2+3)*4`、`((1+2)*(3+4)-10)/4`（L51-54）；一元负号 `-3+5`、`2*-3`、`-(2+3)`（L56-60）；除零与模零 `1/0`、`5%0`、`8/(3-3)` 带 position（L68-72）；错误路径 unexpectedToken/unbalancedParens/empty 各带定位（L74-90） |
| T1-5 | calc.invalid_expression 位置化错误码各 reason | 通过 | 同上 L36-39：所有失败路径统一断言 `failure.code == 'calc.invalid_expression'`、`details['reason']`（divideByZero/unexpectedToken/unbalancedParens/empty）、`details['position']`、`message contains '位置'` |
| T1-6 | devkit SurfaceContractChecks 走查测试真实断言 | 通过 | `v2/plugins/calculator/test/ui/surface_contract_test.dart:36/58/63/71-79`：checkPageProviderBuilds、checkSettingsProviderBuilds（真 pumpWidget 后调用）、checkManifestSurfaceDeclared 一致 + 不一致抛 `throwsStateError`；实现侧 `v2/packages/plugin_devkit/lib/src/checks/surface_contract_checks.dart:21-88` 为真实断言（构建异常包装 StateError、双向往返声明一致性检查），非空壳 |
| T1-7 | 宿主接线（第 2 张卡 + page/settings 提供方） | 通过 | `v2/apps/toolbox_host/lib/src/host_composition_root.dart:102-110` manifests 注册顺序 welcome→calculator→screenshot→hashTool，目录页按注册顺序渲染卡片（`plugin_directory_page.dart:44-49` 遍历 `registry.registrations.values`）→ 计算器为第 2 张卡；`host_composition_root.dart:138-142` pageProviders 注册 `CalculatorPageProvider`，`:150-152` settingsProviders 注册 `CalculatorSettingsProvider`（共享同一 `CalculatorModel`）；文案经 `plugins/calculator_plugin.dart` 宿主 l10n→`CalculatorStrings` 载体映射注入 |
| T1-8 | 测试复跑 | 通过 | `flutter test`（plugins/calculator）→ **23/23 All tests passed**（logic 14 + contract 4 + page 5），与控制器验证一致 |

### 发现

- **Minor T1-M1**：计算器字符串载体 `CalculatorStrings` 的键（如 `displayHint`、`historyTitle`）为宿主 camelCase 风格，未采用 `calc_` 前缀命名。已登记为 F4-03 accepted_deviations，裁定**接受**（宿主经 arb 映射注入，语义无歧义）。

---

## T2 截图（Terra）

**结论：通过**（0 Critical / 0 Important / 1 Minor）

### 核查表

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| T2-1 | plugin.json targets 仅 windows | 通过 | `v2/plugins/screenshot/plugin.json:8-10` targets = `["windows"]`，`kind: builtin`、provides `image.capture`、surfaces page+settings |
| T2-2 | 非 windows 目标解析出 unsupported_target（测试或机制） | 通过 | 机制：`packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart:217-231` `_failuresFor` 首项检查 `!manifest.targets.contains(target)` → `resolution.unsupported_target`（附 pluginId/target details）；测试：`apps/toolbox_host/test/composition_root_test.dart:51-73` 注入 android-only 清单于 windows target，断言不可用且 failures.first.code == `resolution.unsupported_target` |
| T2-3 | GDI 释放完整性（finally 全路径） | 通过 | `packages/platform_capabilities_windows/lib/src/gdi_capture.dart` 三条捕获路径全部 finally 收口：① `queryScreenInfo` screenDc finally `_releaseDc`（L273-275）；② `capturePhysical` 外层 finally 释放位图 `_deleteObject`（L343-345）、内存 DC `_deleteDc`（L346-348）、屏幕 DC `_releaseDc`（L349），且内层 finally 先恢复 `previousObject` 解除位图选中（L330-333）；③ `_readPixels` 两块原生缓冲 finally 释放 `calloc.free(info)`（L390-392）、`calloc.free(pixelBuffer)`（L398-400）。异常抛出路径（GetDC/SelectObject/BitBlt 失败）同样走 finally，零泄漏 |
| T2-4 | 真机捕获证据（PNG 魔数/宽高，复跑确认） | 通过 | 复跑 `flutter test`（packages/platform_capabilities_windows）3/3 通过，验收机实测输出：`烟囱捕获证据：width=2560 height=1440 bytes=290334`；断言位置 `test/gdi_capture_test.dart:32`（PNG 魔数 0x89 起始字节）、L44-47（解析 IHDR 宽高并断言 >0），产物落盘 Temp 供人工查验 |
| T2-5 | 插件包零平台依赖（只 import 能力接口包） | 通过 | `v2/plugins/screenshot/pubspec.yaml` dependencies 仅 flutter / **platform_capabilities（接口包）** / plugin_contracts / plugin_flutter，无 platform_capabilities_windows 等任何平台实现包；`grep -rn "^import" lib` 18 条中能力层仅 `capture_controller.dart:8` import `package:platform_capabilities/platform_capabilities.dart`（接口），无 dart:io、无 windows 包 |
| T2-6 | capture.failed reason 词汇一致 | 通过 | 能力层词汇表声明于 `packages/platform_capabilities_windows/lib/src/screen_capture_impl.dart:3-5`（reason ∈ `noScreen \| gdiError \| encodeError`）且全部失败路径一致使用（L50/62/66/90-91 noScreen，L112 gdiError，L124/128 encodeError）；插件层 `capture_controller.dart:85-89` 原样透传能力层 failure，新增 `saveError`（L104-109，落盘缝异常折算，F4-05 accepted deviation）；UI 经 `screenshot_page.dart:90-95` 直接呈现 failure.message |

### 测试复跑

- plugins/screenshot：**13/13 All tests passed**
- apps/toolbox_host（app_test + composition_root_test）：**17/17 All tests passed**
- packages/platform_capabilities_windows（含真机烟囱）：**3/3 All tests passed**

### 发现

- **Minor T2-M1**：unsupported_target 的宿主测试使用合成 android-only 清单验证机制，未直接以截图真实清单在非 windows 目标下复现。机制为通用清单检查（targets 首项过滤），语义等价覆盖，裁定**接受**。

---

## T3 hash_tool（Terra）

**结论：通过**（0 Critical / 0 Important / 1 Minor）

### 核查表

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| T3-1 | sidecar_hash_e2e_test 复跑（本机有 Python，未降级） | 通过 | 验收机 Python 3.11.9 + hashlib 可用；复跑 `flutter test test/sidecar_hash_e2e_test.dart` → **2/2 All tests passed**，expanded reporter 确认「真 Python 环境：安装→启动→hash.compute→停止→卸载全链」实际执行（非 `markTestSkipped` 降级路径）；三摘要断言等于 hashlib 参考值（md5/sha1/sha256('abc')，L72-85，md5 `900150983cd24fb0d6963f7d28e17f72` 经本机 python 交叉验证一致） |
| T3-2 | Python 源协议合规 | 通过 | `v2/sidecars/python_sample/hash_tool.py`：① 4B 大端帧——读 `struct.unpack(">I", header)`（L23）/写 `struct.pack(">I", len(payload))`（L33）；② ready 首帧——`main()` 第一条语句 `write_frame(READY)`（L52）；③ JSON-RPC 2.0——响应均含 `"jsonrpc": "2.0"` + 回写 `id`（L66/74/81）；④ 零 pip——仅 import hashlib/json/struct/sys 标准库（L10-13），README L3 明示零 pip 依赖；⑤ 未知方法 -32601（L66-69，LookupError 分支）；附加：参数非法 -32602（L74-77） |
| T3-3 | .scp 经 PackageReader 往返 / CLI validate+pack 复现 | 通过 | 仓库 `hash-tool.scp`（3282 字节，与台账 F4-06 一致）头部为 `SCP1` 魔数（od 验证）；e2e 即真实往返证据——`installFromBytes` → `IoPackageFileSystem` 落盘解包 → 启动执行成功（e2e L44-56）；CLI 复现：`dart run plugin_cli validate sidecars/python_sample` → `OK tools.hashtool (sidecar v1.0.0)`；`pack sidecars/python_sample -o …` → `Packed 4 file(s) (8249 bytes)` 且 CLI 自带回读校验（usage L19-20） |
| T3-4 | bridge.not_installed 结构化断言 | 通过 | `apps/toolbox_host/test/sidecar_hash_e2e_test.dart:92-117`：会话工厂注入 `fail()` 断言不可达（L106-108），run 失败且 `failure.code == 'bridge.not_installed'`、`details['pluginId'] == 'tools.hashtool'`（L113-116）；单元层 `test/sidecar_command_bridge_test.dart:176-195` 同语义 + `factoryCalls == 0` |
| T3-5 | 命令失败透传语义 | 通过 | `test/sidecar_command_bridge_test.dart:241-258` 远端 RPC 错误（-32601）→ `bridge.command_failed` + `details.cause='rpc.remote_error'` + pluginId 透传；L260-286 start 工厂失败 → `command_failed` + `cause='session.start_failed'` + causeDetails 透传；L198-206 非法字节 → `package.bad_format`；桥实现词汇声明 `lib/src/sidecar_command_bridge.dart:11-12/214-215/246-248` 与测试一致 |

### 测试复跑

- apps/toolbox_host 全量（app 17 + bridge 7 + e2e 2）：**26/26 All tests passed**（分三次复跑取证）

### 发现

- **Minor T3-M1**：`dart run plugin_cli pack sidecars/python_sample` 会把目录中已存在的 `hash-tool.scp`（3282B）一并打入新包（8249B），产物与仓库内 .scp 不等值。属演示目录与打包输入重叠的工程卫生问题，不影响正确性（e2e 以仓库 .scp 为准）；建议后续在 pack 时排除 `*.scp` 或以独立 src 目录打包。

---

## 终验（Sol）

**结论：通过**（0 Critical / 0 Important / 0 Minor）

### S1 依赖方向终核（含批四跨批次边界修复重点裁定）

**重点裁定结论：批四 F4-07 两处跨批次边界修复已彻底收敛，无残留直连。**

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| S1-1 | 插件包零平台依赖 | 通过 | plugins/calculator：pubspec 仅 flutter/plugin_contracts/plugin_flutter，14 条 import 无 dart:io/平台包（T1-2）；plugins/screenshot：仅依赖接口包 platform_capabilities，18 条 import 中能力层仅 `capture_controller.dart:8` 接口导入（T2-5）；sidecar 目录（python_sample）为纯 Python 标准库 |
| S1-2 | dart:ffi 唯一收敛点 | 通过 | `packages/platform_capabilities_windows/lib/src/gdi_capture.dart:11` 为全工作区唯一直实 `import 'dart:ffi'`；grep 全区其余命中均为文档注释或该文件自身 |
| S1-3 | 宿主平台 import 收敛（重点裁定） | 通过 | 宿主 lib 全量：实际平台 import 仅 2 处——`host_data_root_io.dart:8`（path_provider）与 `host_screen_capture_io.dart:9`（platform_capabilities_windows），均位于 `*_io.dart` 条件导出分支内；`lib/main.dart`、`lib/app.dart` 及其余 lib 文件零直接平台 import（其余 grep 命中为文档注释文字）。**F4-07 台账所述"组装根直连 path_provider 与 windows 适配包"已不复存在** |
| S1-4 | 条件导出桶三件套结构化 | 通过 | 五条桶模式一致：`host_data_root.dart`、`host_screen_capture.dart`（`export io if (dart.library.js_interop) stub` 变体）、`host_bytes_loader.dart`、`sidecar_session_factory.dart`、`host_file_saver.dart` 各配 `*_io.dart`（真实现）+ `*_none.dart`/`*_stub.dart`（web 结构化占位：kWebHostDataRoot 常量、UnsupportedScreenCapture、恒 null/空串/unsupportedTarget 工厂）；web 构建实际通过（S3-3）为编译图纯净的实证 |
| S1-5 | web 编译图 | 通过（引用） | 批四报告 build matrix web 实构建 SUCCESS + 矩阵规则演进（`*_io.dart` 豁免）已在台账登记为 accepted deviation（见裁定表 A-7） |

### S2 走查文档可复现性

**结论：通过。文档命令在验收机逐一实跑有效。**

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| S2-1 | sidecar 路径 CLI validate+pack 逐条复跑 | 通过 | `dart run plugin_cli validate sidecars/python_sample` → `OK tools.hashtool (sidecar v1.0.0)`；`pack sidecars/python_sample -o /tmp/acc_doc_pack.scp` → `Packed 4 file(s) (8249 bytes)` 且 CLI 自带回读校验（为遵守只读约束，输出重定向至 /tmp 而非文档默认的仓库内路径；命令本身与文档一致有效） |
| S2-2 | CLI create 产出正确性 | 通过 | `create builtin --id com.example.demo -o /tmp/acc_create_demo` → 生成清单 `entrypoint: builtin://com.example.demo`（单斜杠，F4-05 修复确认闭环）；`validate` 回读 OK |
| S2-3 | builtin 抽查 | 通过 | `dart run plugin_cli validate plugins/calculator` → `OK tools.calculator (builtin v1.0.0)`；`validate plugins/screenshot` → OK（windows-only 清单合法） |
| S2-4 | 手动 Python 帧调试 | 通过 | 按 `docs/guides/v2-plugin-dev-walkthrough.md:176` 流程以临时脚本驱动 hash_tool.py：ready 首帧 → hash.compute('abc') result 帧（三摘要正确）→ 未知方法 -32601 错误帧，与文档描述逐一吻合 |
| S2-5 | 工作目录命令有效性 | 通过 | 全部命令以 `v2/` 为工作目录实跑成功，无需额外环境；e2e 命令（L167）与 S3 复跑一致 |

### S3 集中全量证据复核

**结论：通过。**

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| S3-1 | 四包测试复跑 | 通过 | plugins/calculator 23/23、plugins/screenshot 13/13、apps/toolbox_host 26/26（含真 Python e2e 2/2，未降级）、packages/platform_capabilities_windows 3/3（含真机捕获烟囱 2560x1440）——均为验收机本机复跑非引用 |
| S3-2 | 根 analyze + format | 通过 | `flutter analyze`（v2/ 根）→ **No issues found**；`dart format --output=none --set-exit-if-changed .` → **180 files, 0 changed, exit 0** |
| S3-3 | 构建矩阵三产物存在性抽查 | 通过（抽查） | 按 F4-07 规则不整体复跑矩阵（6 端×数小时成本），抽查三产物均在位：`apps/toolbox_host/build/windows/x64/runner/Debug/toolbox_host.exe`（577536 B）、`build/web/index.html`、`build/app/outputs/flutter-apk/app-debug.apk`（182891354 B）；矩阵执行细节以批四报告为准（windows/web/android 实构建 OK，macos/linux/ios SKIPPED-LOCAL-UNAVAILABLE 以编译图替代，306 tests 0 fail） |

### S4 词汇表一致性

**结论：通过。四类错误码实现与文档逐字一致。**

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| S4-1 | calc.invalid_expression | 通过 | 实现统一断言 code+reason+position+message（T1-5）；走查文档词汇表（`v2-plugin-dev-walkthrough.md:212-215`）与 `v2/README.md:57-58` 声明一致 |
| S4-2 | capture.failed | 通过 | 能力层 reason 词汇 noScreen/gdiError/encodeError 声明与全部失败路径一致（T2-6）；插件层仅新增 saveError（已登记偏差 A-4）；文档词汇表含四 reason |
| S4-3 | bridge.not_installed / bridge.command_failed | 通过 | not_installed 结构化断言（T3-4）；command_failed 两 cause（rpc.remote_error / session.start_failed）透传测试一致（T3-5）；`sidecar_command_bridge.dart:11-12/214-215/246-248` 词汇声明与文档一致 |

### S5 i18n 与样式纪律抽查

**结论：通过。三插件各抽一文件，UI 文案零硬编码，样式字面量零违规。**

| # | 核查项 | 结论 | 证据 |
|---|--------|------|------|
| S5-1 | calculator 文案文件抽查 | 通过 | `plugins/calculator/lib/src/ui/calculator_strings.dart:3-5` 文件头明示"插件包自身零 l10n 配置：用户可见文案由宿主经 CalculatorStringsResolver 注入载体，插件 UI 只消费载体"（T1-7 宿主映射已取证）；camelCase 键风格为已登记偏差 A-2 |
| S5-2 | screenshot 文案文件抽查 | 通过 | `plugins/screenshot/lib/src/screenshot_page.dart` 多行 Text 调用（L79/101/124 等）实参全部为 `strings.resultTitle` / `strings.captureButton` 等载体字段，无裸字符串 |
| S5-3 | hash_tool 文案文件抽查 | 通过 | `apps/toolbox_host/lib/src/plugins/hash_tool_plugin.dart:46-50` `hashToolStrings(HostL10n)` 把宿主 l10n 的 hash 文案逐字段映射为 `HashToolStrings` 桥载体（formTitle/textLabel/md5Label…），桥 UI 消费载体不感知语言 |
| S5-4 | 插件包样式字面量零命中 | 通过 | `grep -rn "Colors\.\|Color(0x\|TextStyle(\|fontSize"` 扫 plugins/calculator/lib 与 plugins/screenshot/lib：唯一命中 `calculator_page.dart:107` 为 `Theme.of(context).textTheme.titleLarge ?? const TextStyle()` 主题回退（非硬编码样式字面量，良性）；两包其余 UI 样式均经 ThemeTokens |

---

## 偏差裁定表

对照 `docs/superpowers/plans/2026-08-31-plugin-platform-v2-progress.yaml` M4 台账（F4-03 ×3、F4-05 ×2、F4-07 ×2）逐项裁定：

| # | 台账偏差 | 裁定 | 依据 |
|---|---------|------|------|
| A-1 | F4-03：plugin_cli create 生成 builtin 单斜杠 entrypoint（模板 bug，F4-05 前修复） | **接受（已闭环）** | 修复定位在 create 命令（台账 F4-05 cli_entrypoint_fix）；S2-2 实跑产出 `builtin://com.example.demo` 单斜杠正确，bug 无残留 |
| A-2 | F4-03：i18n 键用宿主 camelCase 风格而非 calc_ 前缀 | **接受** | 载体模式（S5-1/T1-7）语义无歧义，键由宿主 arb 统一管理；登记为 T1-M1，建议后续批次统一命名约定 |
| A-3 | F4-03：小数位设置只影响后续求值；历史/设置为内存态 | **接受** | 计划无持久化要求，行为在 23/23 测试中有明确边界；不构成规格偏离 |
| A-4 | F4-05：saveError 为插件层新增 reason（能力成功但落盘失败） | **接受** | 语义必要且合理（能力层成功后落盘缝异常折算，`capture_controller.dart:104-109`），词汇表已同步收录；不破坏 capture.failed 四 reason 契约 |
| A-5 | F4-05：quality 为预留键，MVP 存 PNG 原图 | **接受** | 计划即 PNG-only，预留键无行为影响；建议后续接入时补配置文档 |
| A-6 | F4-07：跨批次边界修复——组装根直连 path_provider 与 windows 适配包，经 host_data_root/host_screen_capture 条件导出收敛（web 编译图曾实际失败，矩阵抓出后修复） | **接受（已彻底收敛）** | 本验收重点裁定：宿主实际平台 import 仅 2 处且均在 `*_io.dart` 条件分支内（S1-3），五条导出桶 web 分支全部结构化 stub（S1-4），web 实构建通过为实证；**无残留直连** |
| A-7 | F4-07：build-matrix 规则演进——宿主 `*_io.dart` 条件导出分支豁免平台插件检查 | **接受** | 豁免仅限条件导出的 io 分支文件（其平台依赖被结构化隔离），规则演进方向正确且与 S1-3 取证一致；建议矩阵脚本内注释固化该豁免理由 |

---

## 最终结论

# **Approved**

- **T1 计算器：通过**（0 Critical / 0 Important / 1 Minor）
- **T2 截图：通过**（0 Critical / 0 Important / 1 Minor）
- **T3 hash_tool：通过**（0 Critical / 0 Important / 1 Minor）
- **终验（Sol）：通过**（0 Critical / 0 Important / 0 Minor）
- **合计：0 Critical / 0 Important / 3 Minor**
- 四节全无 Critical、无边界级 Important，3 项 Minor 均为工程卫生/命名约定类建议且台账已登记或本报告已给出建议动作，不阻塞验收。
- 7 项台账偏差全部裁定**接受**（其中 A-1 create 模板 bug、A-6 跨批次边界修复均已验证彻底收敛闭环）。
- M4（mvp-plugins，F4-01 ~ F4-07）独立验收**通过**，建议进入 G4 门禁流程并推进 M5 规划。

### 验收期间合规声明

- 本验收全程只读：除本报告 `docs/superpowers/acceptance/v2-mvp-plugins-acceptance.md` 外未创建或修改任何项目文件。
- 全部验证命令在仓库工作区只读执行；涉及写入的复现动作（CLI pack/create 产物、临时帧调试脚本）均输出到仓库外 `/tmp`，未污染仓库。
- 未整体复跑 6 端构建矩阵（遵循 F4-07 规则以批四报告为基线 + 三产物抽查替代），已在 S3-3 声明。



