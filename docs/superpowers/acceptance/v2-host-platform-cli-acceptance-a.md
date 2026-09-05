# M3 验收报告 · A 门（架构边界）

- **日期**: 2026-09-05
- **阶段**: M3（Host / Platform / CLI）
- **验收范围**: 架构边界 9 项核查（只读验收，未修改任何生产代码）
- **结论**: **Approved**（0 Critical / 0 Important / 3 Minor，均不阻塞 A 门）

---

## 一、9 项核查表

| # | 核查项 | 结论 | 关键证据（文件:行号） |
|---|--------|------|----------------------|
| 1 | Composition Root 唯一性 | 通过 | 全仓非测试代码中 `PluginRegistry(` / `SidecarInstaller(` / `SidecarSupervisor(` 构造调用仅 2 处，均在唯一组装点：`v2/apps/toolbox_host/lib/src/host_composition_root.dart:39,48`。其余命中均为类定义（plugin_registry.dart:7 / sidecar_installer.dart:45 / sidecar_supervisor.dart:41）或包内封装（sidecar_session.dart:323 在会话 stop 时复用监督器 kill+宽限竞速语义，属 plugin_sidecar 内部实现细节，非组装点违规）。`ServiceLocator`/`getIt`/`GetIt` 全仓 0 命中，无 Service Locator 复辟。符合规格 §3.3「只有一个 Composition Root」。 |
| 2 | 依赖方向 | 通过 | pubspec 声明 + lib 实际 import 双向核对：contracts 零内部依赖（且无 flutter/dart:ffi/dart:io/win32 import，纯 Dart，符合规格 §3.1）；runtime lib 仅 import contracts（5 处）；devkit lib 实际 import contracts(3)+plugin_flutter(1)；plugin_flutter 仅 contracts(1)；sidecar 仅 contracts(9)；7 个 capabilities 包 pubspec 均仅依赖 contracts，lib 零 flutter import；plugin_cli→contracts+sidecar；toolbox_host 汇聚 contracts(6)+flutter(6)+runtime(2)+sidecar(1)，为唯一汇聚点。**附 Minor-1**：devkit pubspec 声明 `plugin_runtime` 但全包（含 test）0 引用，死依赖声明。 |
| 3 | 令牌保真抽查（3 preset × 10 值） | 通过 | 与冻结文档 `docs/superpowers/design/m3-art-direction.md` 逐值比对，30/30 全对（每个 preset 主/次/第三色亮暗 6 值 + success 文字色亮暗 2 值 + radiusMd + body 字号 + space.5 + durBase，均含亮/暗双套）：precision_tools primary #24538F/#85B3E8、success 文字 #1E7A3C/#74C68C、body 14/22/400、radiusMd 8、space5 24、durBase 160ms（preset 文件 21,25,29,52,90,97,108,132 行及暗色对应行）；warm_life primary #B4512F/#E58F68、success #4A7D38/#93CB7E、body 15/24/400、radiusMd 20、space5 24、durBase 240ms（warm_life.dart:22,26,30,53,98,104,115,139 及暗色对应行）；dark_pro primary #A18CFF/#5447B8、success #63C97F/#1F7A46、body 14/21/400、radiusMd 6、space5 20、durBase 120ms（dark_pro.dart:21,25,29,52,90,97,108,128 及暗色对应行）。 |
| 4 | 样式字面量纪律 | 通过 | 复跑静态扫描测试 `no_hardcoded_style_test.dart`（组件与宿主源码无硬编码样式字面量）→ All tests passed（扫描 lib/ 除 presets/ 外全部 dart 文件的 `Color(0x` 与 `fontSize:`）。独立 grep `Color(0x` 于 `plugin_flutter/lib/src/widgets/` 与 `toolbox_host/lib/`：0 命中。字号经 `token_text_style.dart:15` 的 `buildTokenTextStyle` 以 `spec.size` 唯一转换，不发明新值。 |
| 5 | Surface 语义 | 通过 | `declarative_form.dart` / `declarative_result.dart` 0 个 flutter import，纯数据模型 ✓。Widget 边界收敛于 `plugin_ui_surface.dart`（Page/Settings/Action Provider 接口，规格 §9 的 builtin 路径）。sidecar 无 Widget 注入路径：plugin_sidecar/lib 中 `package:flutter` import 与 `Widget` 引用均为 0 ✓（符合规格 §9「Sidecar 不能直接注入 Flutter Widget」）。`surface.unsupported` 产生处为工厂 `surfaceUnsupported`（plugin_ui_surface.dart:66-72，details 携带 surface+pluginId），**见 Minor-2**：生产代码无调用点，宿主以禁用按钮+说明标签显式兜底（plugin_detail_page.dart:113,116 `onPressed: provider == null ? null : ...` / `detailNoPage` 标签），非静默降级。 |
| 6 | i18n 抽查 | 通过 | 三页（plugin_directory_page / plugin_detail_page / settings_page）与 FormRenderer 源码 grep 硬编码中文与引号内英文 UI 句：除 settings_page.dart:94-95 语言选择器 `Text('中文')`/`Text('English')`（语言自名，显示为本语言是选择器惯例，**见 Minor-3**）外 0 命中；双引号变体补查 0 命中。翻译经 `HostL10n`（lib/l10n/app_zh.arb + app_en.arb）。 |
| 7 | G2 三项遗留消化 | 通过 | ① `decoder` 已移除：rpc_channel.dart 0 命中，构造无该参数；② `sidecar_session.dart` 存在，单订阅 stdout（:276 `process.stdout.listen` 唯一订阅点，:82 单一 `_subscription` 字段），就绪帧吞帧有约定与实现（:37 「[start] 内部单订阅 stdout：首字节即就绪，首帧（就绪帧）被吞掉不进通道」、:70 就绪前缓冲 payload 补投）；③ e2e/全仓 `_BroadcastingLauncher` 0 命中。 |
| 8 | devkit 边界演进裁定 | 接受 | devkit pubspec 依赖 flutter/matcher/plugin_contracts/plugin_runtime/plugin_flutter；`plugin_flutter` import 仅出现于 `lib/src/checks/surface_contract_checks.dart:8`。计划 F3-03 明文：「devkit 需加 plugin_flutter 依赖——devkit 本就是测试工具包，允许」，且 SurfaceContractChecks 定位即「插件作者在自己的测试环境调用的契约断言集」。**裁定：接受，无需修复**。附带问题归入 Minor-1。 |
| 9 | 错误码一致性 | 通过 | 计划词汇表 6 码逐字核对全部一致：`session.start_failed`（sidecar_session.dart:125,190，details.reason 透传底层原码）；`surface.unsupported`（plugin_ui_surface.dart:68）；`capability.unsupported`（platform_capabilities/lib/src/capabilities.dart:104，六端 stub 统一返回）；`cli.invalid_manifest` / `cli.missing_entrypoint` / `cli.pack_failed`（plugin_cli/lib/src/cli_runner.dart:8,11,14 常量定义，validate/pack 命令引用）。无变体拼写、无临场造码。 |

---

## 二、发现分级

### Critical（阻塞级）

无。

### Important（需修复后才能关闭对应任务）

无。

### Minor（不阻塞，建议后续消化）

- **Minor-1 devkit 死依赖声明**
  - 证据：`v2/packages/plugin_devkit/pubspec.yaml` dependencies 含 `plugin_runtime`（第 13-14 行）；但 `grep -rln "package:plugin_runtime" v2/packages/plugin_devkit`（含 test）0 命中。
  - 建议：M4 首个触碰 devkit 的任务顺带移除该声明（或补充说明保留原因），保持 pubspec 与实际依赖图一致。

- **Minor-2 `surface.unsupported` 失败通道无生产调用点**
  - 证据：工厂定义于 `plugin_flutter/lib/src/surface/plugin_ui_surface.dart:66`，仅在包内测试（test/surface/plugin_ui_surface_test.dart:15）被调用；宿主 `pageProviderFor` 为 null 时 UI 以禁用按钮 + `detailNoPage` 标签显式兜底（plugin_detail_page.dart:113,116）。
  - 评估：当前不构成「静默降级」（用户可获得明确反馈），符合规格 §9 底线；但规格「返回 unsupportedSurface」的失败通道在程序化路径（如未来 M4 插件目录按清单 surfaces 断言）尚未接线。
  - 建议：M4 引入真实 sidecar/builtin 插件时，将 `surfaceUnsupported` 接入宿主的程序化 surface 解析路径，并为按钮禁用态补充「未声明 page surface」的可解释原因展示（呼应规格 §10「宿主必须能展示插件不可用原因」，目录页已有 reasonText 先例 plugin_directory_page.dart:81）。

- **Minor-3 语言选择器语言自名硬编码**
  - 证据：`toolbox_host/lib/src/pages/settings_page.dart:94-95` `Text('中文')` / `Text('English')`。
  - 评估：语言自名（每语言以自身名字显示）是语言选择器通行惯例，翻译反而错误；但按最严字面规则属引号内用户可见文本。
  - 建议：加注释声明豁免理由，或改用带注释的常量，避免后续静态 i18n 扫描误报。

---

## 三、结论

**A 门：Approved。**

架构边界健康：组装唯一、依赖方向无倒置、令牌与冻结设计一致、样式字面量受静态扫描固化、sidecar 与 Widget 解耦、G2 三项遗留已结构性消化、错误码与计划词汇表逐字一致。3 项 Minor 均为卫生类改进，不阻塞 A 门，建议随 M4 相邻任务顺带消化。

*本报告为只读验收产物；验收过程未修改任何生产代码。*
