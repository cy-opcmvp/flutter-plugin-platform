# Batch 3 实施报告：F3-05（设计令牌与基础组件库）+ F3-06（工具箱宿主 App）

**日期**：2026-09-05
**范围**：`v2/packages/plugin_flutter/`（F3-05）、新建 `v2/apps/toolbox_host/`（F3-06）、`v2/pubspec.yaml`（workspace 成员注册）
**样式事实源**：冻结文档 `m3-art-direction.md`（全部令牌值逐值落地，未发明任何值）

---

## 一、F3-05 文件清单（plugin_flutter 内）

### 源码

| 文件 | 内容 |
|------|------|
| `lib/src/theme/tokens.dart` | `ThemeTokens` 契约（`ThemeExtension`）：`TokenColors` / `TokenRadius` / `TokenStroke` / `TokenSpacingSet` / `TokenTypography`，`ThemeTokens.of(context)` 取值入口 |
| `lib/src/theme/brightness_mode.dart` | `BrightnessMode` 枚举（从 app_theme 拆出，避免包内 import 环） |
| `lib/src/theme/app_theme.dart` | `AppTheme.build(preset, brightness) → ThemeData`，三方向 × 明暗共 6 套 ThemeData 组装 |
| `lib/src/theme/theme_controller.dart` | `ThemeController extends ValueNotifier<AppThemePreset>`，`select()` + 可选 `persist` 回调注入点 |
| `lib/src/theme/presets/precision_tools.dart` | precision_tools 明/暗两份令牌实例 |
| `lib/src/theme/presets/warm_life.dart` | warm_life 明/暗两份令牌实例 |
| `lib/src/theme/presets/dark_pro.dart` | dark_pro 明/暗两份令牌实例 |
| `lib/src/theme/presets/token_text_style.dart` | 字号/行高字面量唯一收敛点（presets/ 之外禁止 `fontSize:` 字面量） |
| `lib/src/widgets/plugin_card.dart` | 插件目录卡片（标题/描述/版本/状态徽章/原因文案/点击回调） |
| `lib/src/widgets/status_badge.dart` | `StatusBadge`（available/disabled/unavailable 三态，文案取包内 PluginFlutterL10n） |
| `lib/src/widgets/form_renderer.dart` | `FormRenderer`：text/number/select/checkbox/toggle-group 五种字段、必填校验、提交回填 `Map<String, Object?>` |
| `lib/src/widgets/result_renderer.dart` | `ResultRenderer`：text/table/image/fields 四种结果渲染 |
| `lib/src/widgets/token_text_style.dart` | 组件内文字样式辅助（引用 tokens.typography，不写 fontSize 字面量） |

### l10n

- `lib/l10n/plugin_flutter_zh.arb` / `plugin_flutter_en.arb`（zh 为模板）
- `lib/src/generated/plugin_flutter_l10n*.dart`（gen-l10n 产物：状态徽章三态文案、表单校验文案等）

### 测试

| 文件 | 覆盖点 |
|------|--------|
| `test/theme/app_theme_test.dart` | 6 套令牌实例逐值断言（对照冻结文档 `_expectedTable`） |
| `test/theme/no_hardcoded_style_test.dart` | 静态扫描：`Color(0x` 与 `fontSize:` 字面量只允许出现在 `lib/src/theme/presets/` |
| `test/widgets/plugin_card_test.dart` | 卡片渲染与点击回调 |
| `test/widgets/status_badge_test.dart` | 三态徽章渲染与原因文案 |
| `test/widgets/form_renderer_test.dart` | 五种字段渲染、必填校验拦截、提交值回填 |
| `test/widgets/result_renderer_test.dart` | 四种结果渲染 |
| `test/test_utils/widget_harness.dart` | 测试装配夹具（MaterialApp + 令牌注入 + l10n delegates） |

---

## 二、F3-06 文件清单（新建 v2/apps/toolbox_host）

### 应用源码

| 文件 | 内容 |
|------|------|
| `pubspec.yaml` | `resolution: workspace`；依赖 plugin_flutter / plugin_contracts / plugin_runtime / plugin_sidecar / platform_capabilities / platform_capabilities_windows（path 相对路径）；`generate: true` |
| `l10n.yaml` | `output-class: HostL10n`、`output-dir: lib/src/generated`、zh 模板、`nullable-getter: false` |
| `lib/l10n/app_zh.arb` / `app_en.arb` | 宿主全部文案键（无硬编码） |
| `lib/src/generated/host_l10n*.dart` | gen-l10n 产物 |
| `lib/main.dart` | 仅引导：`_kHostDataRoot` 占位字符串 + `runApp(ToolboxApp(root: HostCompositionRoot(target: PluginTarget.windows, ...)))` |
| `lib/src/host_composition_root.dart` | **全应用唯一组装点**：ResolvedSystemPaths（纯字符串拼接）/ windowsScreenCapture / SidecarInstaller（rootDir = `$hostDataRoot/sidecar-packages`，构造不触发 I/O）/ PluginRegistry 注册 / PluginResolver 静态解析 / ThemeController（初始 warm_life，persist 注入点）/ pageProviders；可选注入参数 `extraManifests` 与 `themePersist` |
| `lib/src/brightness_mode.dart` | `BrightnessMode { system, light, dark }` |
| `lib/src/plugins/welcome_plugin.dart` | 内置欢迎插件：最小 builtin 清单 + `PluginPageProvider` 实现；`welcomeDemoForm(l10n)` 五字段演示表单与 `welcomeFormResultFields()` 结果映射，供欢迎页与详情页共用 |
| `lib/src/app.dart` | `ToolboxApp`：MaterialApp（theme/darkTheme 由 AppTheme.build 生成、themeMode 三态映射、合并 delegates = HostL10n + PluginFlutterL10n + Global 三件套）；`_HomeShell`：NavigationRail（目录/设置）+ 详情页 Navigator 压栈；宿主停用集合与语言状态持有 |
| `lib/src/pages/plugin_directory_page.dart` | 遍历 `registry.registrations` 渲染 PluginCard 网格；状态判定：宿主停用 → disabled；解析失败 → unavailable + 结构化原因（`resolution.unsupported_target` → 专属文案，否则通用文案带 code） |
| `lib/src/pages/plugin_detail_page.dart` | 五区块：基本信息（SelectableText）/ 启用开关 / 打开插件页面（provider==null 时禁用）/ 表单演示 + 结果回填 / Sidecar 占位面板 |
| `lib/src/pages/settings_page.dart` | 三节设置：主题方向（SegmentedButton 三方向）/ 明暗模式（三态）/ 语言（zh/en） |
| `README.md` | 结构说明与运行命令 |

### 测试

| 文件 | 覆盖点 |
|------|--------|
| `test/composition_root_test.dart`（5 测试） | windows 目标下 welcome 可用 + warm_life 初始；android-only 注入清单 → `resolution.unsupported_target` 结构化失败；路径纯字符串拼接断言；pageProviderFor 命中/未命中；themePersist 注入触发 |
| `test/app_test.dart`（4 测试） | 目录页可用/不可用徽章与原因文案；详情页停用 → 目录徽章联动"已停用"；语言切换 zh→en 全量生效；主题切换触发控制器与持久化注入 |

### workspace 注册

- `v2/pubspec.yaml`：`workspace` 成员新增 `- apps/toolbox_host`（现共 13 成员）。未改动其他成员。

---

## 三、验证结果

| 项目 | 结果 |
|------|------|
| F3-05 焦点测试（plugin_flutter） | **35 通过 / 0 失败**（`00:01 +35: All tests passed!`） |
| F3-06 焦点测试（toolbox_host） | **9 通过 / 0 失败**（composition_root 5 + app 4，`00:01 +9: All tests passed!`） |
| plugin_flutter `flutter analyze` | No issues found |
| toolbox_host `flutter analyze` | No issues found（继承 workspace 根 analysis_options：strict-casts / strict-inference / strict-raw-types） |
| `dart format`（两包） | 0 changed（全部 80 列内） |
| 硬编码样式扫描 | 静态扫描测试固化：`Color(0x` 与 `fontSize:` 仅存于 `presets/` |
| Windows 构建 | `flutter build windows --debug` **退出码 0**（22.2s） |

**构建产物路径**：
`E:\my\flutter-plugin-platform\v2\apps\toolbox_host\build\windows\x64\runner\Debug\toolbox_host.exe`

按约定未跑 workspace 全量测试（留 F3-08）；未执行 git，未改 progress.yaml。

---

## 四、令牌落地对照抽查表

> 「文档值」为冻结文档 m3-art-direction.md 的原始值；「代码值」取自 presets 源码，并由
> `test/theme/app_theme_test.dart` 的 `_expectedTable` 逐值断言——**测试通过即 文档值 == 代码值**。
> 每方向明暗合计均超过 8 个关键值。

### precision_tools（精密工具 · 冷蓝）

| 关键值 | 明暗 | 文档值 | 代码值 |
|--------|------|--------|--------|
| primary | light | `#24538F` | `0xFF24538F` |
| surface | light | `#FFFFFF` | `0xFFFFFFFF` |
| successContainer | light | `#D9F0DF` | `0xFFD9F0DF` |
| warningContainer | light | `#FBEACB` | `0xFFFBEACB` |
| n3 / outlineVariant | light | `#C9D2DB` | `0xFFC9D2DB` |
| radiusMd | light | 8.0 | 8.0 |
| radiusLg | light | 14.0 | 14.0 |
| strokeFocus | light | 2.0 | 2.0 |
| space7 | light | 48.0 | 48.0 |
| displaySize / bodyLineHeight | light | 28.0 / 22.0 | 28.0 / 22.0 |
| primary | dark | `#85B3E8` | `0xFF85B3E8` |
| surface | dark | `#1A2028` | `0xFF1A2028` |
| successContainer | dark | `#1E4A2B` | `0xFF1E4A2B` |
| warningContainer | dark | `#4A370F` | `0xFF4A370F` |
| n3 | dark | `#333E4A` | `0xFF333E4A` |

### warm_life（温暖生活 · 暖橙陶土）

| 关键值 | 明暗 | 文档值 | 代码值 |
|--------|------|--------|--------|
| primary | light | `#B4512F` | `0xFFB4512F` |
| surface | light | `#FFFDF8` | `0xFFFFFDF8` |
| successContainer | light | `#DFEED4` | `0xFFDFEED4` |
| warningContainer | light | `#F8E9C8` | `0xFFF8E9C8` |
| n3 | light | `#DFD3C2` | `0xFFDFD3C2` |
| radiusSm / radiusMd | light | 12.0 / 20.0 | 12.0 / 20.0 |
| strokeFocus | light | 2.0 | 2.0 |
| space5 | light | 24.0 | 24.0 |
| displaySize / bodyLineHeight | light | 30.0 / 24.0 | 30.0 / 24.0 |
| primary | dark | `#E58F68` | `0xFFE58F68` |
| surface | dark | `#2B231C` | `0xFF2B231C` |
| successContainer | dark | `#2C4A20` | `0xFF2C4A20` |
| warningContainer | dark | `#4E3B14` | `0xFF4E3B14` |
| n3 | dark | `#3E3329` | `0xFF3E3329` |

### dark_pro（极简暗色 · 暗紫）

| 关键值 | 明暗 | 文档值 | 代码值 |
|--------|------|--------|--------|
| primary | dark | `#A18CFF` | `0xFFA18CFF` |
| surface | dark | `#1B1927` | `0xFF1B1927` |
| successContainer | dark | `#1C4A2A` | `0xFF1C4A2A` |
| warningContainer | dark | `#4E3D14` | `0xFF4E3D14` |
| n3 | dark | `#2B2840` | `0xFF2B2840` |
| radiusMd / radiusLg | dark | 6.0 / 10.0 | 6.0 / 10.0 |
| strokeFocus | dark | 1.0 | 1.0 |
| space7 | dark | 40.0 | 40.0 |
| displaySize / bodyLineHeight | dark | 26.0 / 21.0 | 26.0 / 21.0 |
| primary | light | `#5447B8` | `0xFF5447B8` |
| surface | light | `#FFFFFF` | `0xFFFFFFFF` |
| successContainer | light | `#D9EEDF` | `0xFFD9EEDF` |
| warningContainer | light | `#F5E8C9` | `0xFFF5E8C9` |
| n3 | light | `#D9D6E7` | `0xFFD9D6E7` |

---

## 五、偏差及理由

| # | 偏差 | 理由 |
|---|------|------|
| 1 | `ThemeTokens` 排版组访问器由计划稿的 `type` 更名为 **`typography`** | Flutter SDK `ThemeExtension` 自带 `type` 注册键成员，同名 getter 触发冲突；全包统一改名，语义不变 |
| 2 | `TokenColors.onSuccess` / `onWarning` 恒为 null | 冻结文档未定义这两个 on 容器色值；按"一个值都不许发明"原则不造默认值，消费处回退 `onSurface` |
| 3 | `ResultRenderer` 的 image 结果渲染为**结构化占位框**（路径 + 尺寸标注，非真实位图） | plugin_flutter 包内禁止 `dart:io`，无法读文件解码位图；结构契约（path 字段）完整保留，真实解码留给宿主后续阶段 |
| 4 | toolbox_host 实际依赖了任务清单未列出的 **platform_capabilities**（及 platform_capabilities_windows） | 组装点需持有 `ScreenCapture` 类型引用（`windowsScreenCapture`），类型定义在该包；属类型命名所需的最小依赖 |
| 5 | `_kHostDataRoot` 使用占位字符串 `'%APPDATA%/toolbox-host'`，未解析为真实用户目录 | 真实路径解析需要 dart:io/env（不进 lib 的约束）；composition root 以字符串注入接口已就绪，解析留后续阶段接入 |
| 6 | 宿主 arb **不含**状态徽章文案键（可用/已停用/不可用） | 该文案由 plugin_flutter 包内 l10n（PluginFlutterL10n）提供，宿主重复定义会形成死键；两 delegates 合并注册保证组件内文案可用 |
| 7 | `PluginManifest.provides` 列表为非 const（`CapabilityDescriptor` 构造非 const） | contracts 包 `CapabilityDescriptor` 构造带校验逻辑，本身非 const——属上游 API 设计而非本批偏差，仅作记录 |

**实现备注**（非偏差）：
- Flutter 3.38 的 `tester.pageBack()` 仅识别 Cupertino 返回键，F3-06 测试改用 `find.byIcon(Icons.arrow_back)`。
- `FormRenderer.didUpdateWidget` 以 descriptor 值相等性判断是否重置用户输入，因此每次 build 重建 `welcomeDemoForm(l10n)` 不会清空用户输入，且语言切换后字段标签即时更新。
- `welcomeFormResultFields` 对 null / 空集合统一映射为 `-`（`ResultField` 要求值非空白）。
