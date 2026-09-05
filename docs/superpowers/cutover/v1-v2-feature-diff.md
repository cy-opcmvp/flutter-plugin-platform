# v1 → v2 功能差异清单

> **用途**：本清单是 F5-03（删除范围逐项确认，不可逆操作授权门）的唯一审阅
> 材料。用户按行裁定后，F5-04 严格按批准范围删除旧实现。
>
> **生成日期**: 2026-09-05
>
> **扫描范围**（只读，未删除/未移动任何文件）：
> - 旧工程源码：`lib/plugins/`（calculator / screenshot / world_clock）、
>   `lib/core/`（interfaces / models / services / config）、`lib/ui/`、
>   `lib/l10n/`、`lib/main.dart`、`windows/runner/`（原生层）、`tools/`
> - 旧文档与历史：`CHANGELOG.md`（v0.1.0–v0.4.4 + Unreleased）、
>   `README.md`、`.claude/CLAUDE.md` 项目概述节、`docs/MASTER_INDEX.md`
> - v2 现状：`v2/README.md`、`docs/guides/v2-plugin-dev-walkthrough.md`、
>   `v2/plugins/`（calculator / screenshot）、`v2/sidecars/python_sample/`、
>   `v2/apps/toolbox_host/`、`v2/packages/`（16 包）、
>   `docs/superpowers/acceptance/` 六份验收报告交付摘要
>
> **分类口径**：`已实现` / `等价实现`（架构不同但用户能力等同）/
> `部分实现`（v2 有对应物但覆盖面缩水）/ `未实现→roadmap`（v2 无对应物，
> 已列入文末 roadmap 草稿）/ `有意放弃`（被 v2 架构或决策显式替代）/
> `待用户裁定`（归属需要用户在 F5-03 决定）。

---

## 逐特性对照表

### A. 旧内置插件

| 旧特性 | 旧实现位置 | v2 现状 | 分类 | 说明/去向 |
|--------|-----------|---------|------|-----------|
| 计算器（基本运算/百分比/历史记录/配置界面） | `lib/plugins/calculator/` | `v2/plugins/calculator/`（六端 targets，求值与历史在纯 Dart 模型层，23 个测试，`calc.invalid_expression` 位置化错误码，声明式 page/settings Surface + devkit 契约检查） | 等价实现 | v2 为重写版；v1 的 `config/` JSON 配置文件体系（defaults/schema/docs）由 v2 声明式设置表单替代 |
| 截图——全屏捕获 | `lib/plugins/screenshot/` + `windows/runner/screenshot_plugin.cpp` | `v2/plugins/screenshot/` + `v2/packages/platform_capabilities_windows`（GDI，`dart:ffi` 隔离在实现包内），能力经 `platform_capabilities` 接口注入 | 等价实现 | v2 捕获全屏 → 保存文件，声明式结果渲染 |
| 截图——区域选择（桌面级原生 overlay：遮罩/控制点/实时尺寸/ESC 取消/双缓冲防闪烁） | `lib/plugins/screenshot/widgets/screenshot_overlay.dart`、`screenshot_window.dart` + `windows/runner/native_screenshot_window.cpp`（约 400 行原生窗口） | 无（v2 仅全屏捕获） | 未实现→roadmap | G4 决策 5 已明确登记 post-2.0 roadmap |
| 截图——窗口捕获（窗口列表选择、隐藏本窗后截取） | `lib/plugins/screenshot/widgets/window_capture_screen.dart` | 无 | 未实现→roadmap | 依赖窗口枚举原生能力 |
| 截图——图片编辑/标注（矩形标注、画笔路径、撤销/重做栈） | `lib/plugins/screenshot/widgets/image_editor_screen.dart` + `models/annotation_models.dart` | 无 | 未实现→roadmap | |
| 截图——历史记录（缩略图列表、最大条数/保留期配置） | `lib/plugins/screenshot/widgets/history_screen.dart` + `models/screenshot_models.dart` | 无 | 未实现→roadmap | |
| 截图——全局热键（系统级注册/原生回调） | `lib/plugins/screenshot/services/hotkey_service.dart` + `windows/runner/hotkey_manager.cpp` | 无 | 未实现→roadmap | 依赖全局热键能力契约 |
| 截图——循环/定时截图任务（任务 CRUD、定时器、状态持久化） | `lib/plugins/screenshot/services/recurring_task_manager.dart` + `models/recurring_screenshot_task.dart` | 无 | 未实现→roadmap | |
| 截图——剪贴板复制（CF_DIB 图片、文件名/路径复制，Windows 原生剪贴板 API） | `lib/plugins/screenshot/services/clipboard_service.dart` + `windows/runner/flutter_window.cpp`（`com.example.screenshot/clipboard` 通道） | 无（捕获结果仅保存文件） | 未实现→roadmap | v1 末段（Unreleased）刚完成原生实现，尚未随 tag 发布即遇 v2 重写 |
| 截图——保存配置（保存路径占位符 `{documents}`、文件名格式、图片格式/质量、自动复制、历史策略、快捷键映射） | `lib/plugins/screenshot/models/screenshot_settings.dart` + `config/` + `widgets/settings_screen.dart` + `services/file_manager_service.dart` | v2 设置表单仅 **文件名前缀 + 图片质量** 两项（`screenshot_settings.dart`） | 部分实现 | 路径/格式/自动复制/历史策略等配置项消失，随对应能力入 roadmap |
| 世界时钟（10+ 时区、倒计时提醒+通知、实时刷新、持久化、24h/秒/动画设置） | `lib/plugins/world_clock/`（plugin + models + widgets + config） | 无 | 未实现→roadmap | v0.2.1 引入；需按 v2 契约重写 |

### B. 桌面宠物

| 旧特性 | 旧实现位置 | v2 现状 | 分类 | 说明/去向 |
|--------|-----------|---------|------|-----------|
| 桌面宠物（独立透明窗口、置顶、点击穿透、呼吸/眨眼动画、拖拽交互、右键菜单、设置面板、偏好 ValueNotifier 实时生效与持久化） | `lib/core/services/desktop_pet_manager.dart`、`desktop_pet_click_through_service.dart`、`desktop_pet_menu_manager.dart` + `lib/ui/screens/desktop_pet_screen.dart`、`desktop_pet_settings_screen.dart` + `lib/ui/widgets/desktop_pet_widget.dart` + `windows/runner/`（`desktop_pet` MethodChannel） | 无 | 未实现→roadmap | 依赖窗口管理（无边框/置顶/穿透）能力契约，roadmap 需先立该契约 |

### C. 平台服务层

| 旧特性 | 旧实现位置 | v2 现状 | 分类 | 说明/去向 |
|--------|-----------|---------|------|-----------|
| 通知服务（即时/定时通知、权限管理，`flutter_local_notifications`） | `lib/core/services/notification/` + `lib/core/interfaces/services/i_notification_service.dart` | 无服务层 | 未实现→roadmap | 规划为能力契约形式重建 |
| 音频服务（播放/系统音效，`just_audio` + Windows SystemSound 回退） | `lib/core/services/audio/` | 无服务层 | 未实现→roadmap | 同上 |
| 任务调度服务（一次性/周期任务、暂停恢复、`SharedPreferences` 持久化） | `lib/core/services/task_scheduler/` + `i_task_scheduler_service.dart` | 无服务层 | 未实现→roadmap | 同上 |
| 服务定位器 + 服务管理器（`registerSingleton`/`registerFactory`、统一初始化入口） | `lib/core/services/service_locator.dart`、`platform_service_manager.dart`、`platform_services.dart` | `HostCompositionRoot` 组装根 + `platform_capabilities` 能力注入（清单 `requires` 声明 + 平台包实现） | 有意放弃 | v2 架构显式替代：静态组装与接口注入，不做运行时服务定位 |
| 权限管理（`permission_manager`、`permission/` 目录） | `lib/core/services/permission/`、`permission_manager.dart` | 无 | 有意放弃 | v1 中 Windows 构建即禁用（`permission_handler` 未启用），无实际运行时损失 |
| 服务测试界面（三平台服务内置测试面板） | `lib/ui/screens/service_test_screen.dart` | 无 | 有意放弃 | 随平台服务层消失；v2 各能力有独立测试套件与验收证据 |

### D. 平台工程能力

| 旧特性 | 旧实现位置 | v2 现状 | 分类 | 说明/去向 |
|--------|-----------|---------|------|-----------|
| 标签管理系统（标签 CRUD/颜色、插件打标、按标签过滤目录） | `lib/core/services/tag_manager.dart`、`tag_color_helper.dart` + `lib/ui/screens/tag_management_screen.dart`、`plugin_tag_assignment_screen.dart` + `lib/ui/widgets/tag_filter_bar.dart` | 无 | 待用户裁定 | v2 规格未规划；若保留需入 roadmap，若放弃请在 F5-03 标注 |
| JSON 配置编辑器（语法/Schema 校验、格式化/压缩、示例加载、重置） | `lib/ui/widgets/json_editor_screen.dart` + `lib/core/services/json_validator.dart` + `lib/plugins/*/config/` | 无通用 JSON 编辑器；插件配置为清单 `configSchemaVersion` 声明 + 声明式设置表单 | 部分实现 | 常规配置经声明式表单覆盖；原始 JSON 直编与 Schema 校验能力消失 |
| 插件描述符系统（`plugin_descriptor.json` + `isValid()` 反向域/语义版本校验） | `lib/plugins/*/config/` + `lib/core/models/plugin_models.dart` | v2 `plugin.json` + `PluginManifestCodec` 严格解码（12 必需字段、反向域 `PluginId`、`apiVersion`、targets/surfaces） | 等价实现 | v2 清单表达力更强且校验更严 |
| 旧插件 CLI（`create-internal`/`create-external`/`build`/`test`/`package`/`validate`/`publish` 七命令脚手架） | `tools/plugin_cli.dart` | `v2/packages/plugin_cli`：`create`（builtin/sidecar 骨架 + 帧协议模板）/ `validate`（严格解码）/ `pack`（SCP1 打包 + 回读自校验 + 排除 `*.scp` 防自嵌套） | 部分实现 | `create`/`validate` 等价且更严；`build`/`test` 有意放弃（v2 workspace 直接用 `dart test`/`flutter test`，不再包装）；`publish` 无对应物（待用户裁定：是否需要发布通道）；`pack` 为 v2 新增 |
| 外部插件系统（Python/JS/Java/C++ 多语言声明、启动器/沙盒/管理器、IPC 桥、外部插件管理屏） | `lib/core/services/external_plugin_manager.dart`、`external_plugin_sandbox.dart`、`external_plugin_launcher.dart`、`ipc_bridge.dart` + `lib/ui/screens/external_plugin_management_screen.dart` | `v2/packages/plugin_sidecar`（SCP1 原子安装、进程监督、4B 大端长度前缀 stdio JSON-RPC 2.0）+ `v2/sidecars/python_sample`（hash_tool 落地）+ 宿主 `SidecarCommandBridge` 全链 | 等价实现 | 架构重写：v1 为通道抽象（多语言未逐一落地），v2 为已验收的真实进程链路（G2 攻击矩阵 + e2e）；附带样本收窄为 Python 一种，其余语言经同协议可接 |
| `IPlugin` 开发模型（`initialize/dispose/buildUI/onStateChanged/getState` + `PluginContext`：platformServices/dataStorage/networkAccess/configuration/i18n） | `lib/core/interfaces/i_plugin.dart` + `lib/core/services/plugin_manager.dart`、`plugin_launcher.dart`、`plugin_registry_service.dart` | `PluginLifecycle` + 能力注入 + 声明式 Surface（page/settings/actions/command）+ 状态机/注册表在 `plugin_runtime` | 有意放弃 | 架构重写核心对象；旧插件需按 v2 契约重写（走查文档 `docs/guides/v2-plugin-dev-walkthrough.md`） |
| 插件沙盒/安全监控/需求校验 | `lib/core/services/plugin_sandbox.dart`、`security_monitor.dart`、`requirement_validator.dart` | 无进程内沙盒；sidecar 经进程隔离 + SCP1 摘要校验 + 路径安全攻击矩阵验收 | 部分实现 | 外部插件隔离由进程边界承担；进程内权限沙盒能力消失 |
| 插件数据存储（`dataStorage` KV 持久化抽象） | `lib/core/services/plugin_data_storage.dart` | v2 仅有宿主数据根（`path_provider`，sidecar 安装目录用）；插件级持久化契约未定义（v2 三插件均不持久化） | 未实现→roadmap | 世界时钟/截图历史等移植前需先立存储契约 |
| 外部插件 i18n（`IPluginI18n` 翻译注册、占位符替换、语言回退） | `lib/core/interfaces/i_plugin_i18n.dart` + `lib/core/services/plugin_i18n_helper.dart` | 无对应（UI 文案由宿主 l10n + 契约文案载体（如 `CalculatorStrings`）注入；sidecar 结果为数据而非文案） | 待用户裁定 | v0.4.4 刚交付即遇重写；若 sidecar 需自携带翻译资源则入 roadmap |
| 旧 i18n 覆盖面（zh/en 双语，`app_zh.arb` 约 1167 键，覆盖全部界面含三插件设置） | `lib/l10n/`（arb + generated） | v2 `host_l10n` + `plugin_flutter` l10n（宿主界面与组件级文案，键数远少于 v1）+ 插件文案载体注入 | 部分实现 | v2 按现有界面按需覆盖；v1 插件设置/标签/宠物等键随对应功能消失 |
| 窗口管理定制（`window_manager`：尺寸/置顶/show/focus/`WindowListener`，宠物与截窗依赖） | `lib/main.dart` + `lib/core/services/desktop_pet_manager.dart` | v2 宿主为标准 Flutter 窗口，无窗口管理定制 | 未实现→roadmap | 置顶/穿透/无边框等需窗口管理能力契约 |
| 系统托盘（配置项 + 空服务目录；**无落地实现**） | `lib/core/config/platform_config.dart`（`system_tray` 配置节）+ `lib/core/services/system_tray/`（空目录） | 无 | 待用户裁定 | v1 即未落地（仅预留配置与空目录），删除无运行时损失；若视为规划项可入 roadmap |
| 全局配置系统（GlobalConfig JSON Schema/defaults/example + `ConfigManager`） | `lib/core/config/` + `lib/core/services/config_manager.dart` | v2 宿主设置页仅主题方向（三 preset × 明暗）切换；无全局配置文件/Schema | 部分实现 | 剩余配置诉求（调试开关等）入 roadmap |
| 自动启动（开机自启） | `lib/core/services/auto_start_service.dart` | 无 | 待用户裁定 | |
| 网络管理（网络访问抽象） | `lib/core/services/network_manager.dart` | 无（v2 插件暂无网络能力契约） | 未实现→roadmap | |
| 开发期热重载/开发模式管理（自研包装） | `lib/core/services/hot_reload_manager.dart`、`development_hot_reload_manager.dart`、`development_mode_manager.dart` | 无；直接依赖 Flutter 原生热重载 | 有意放弃 | v1 为工具链包装层，v2 不复刻 |
| 平台适配抽象层（`platform_adapters`/`platform_api_abstraction`/`platform_core`/`cross_platform_core`/`platform_environment`/`distribution_*`/`environment_support_system`） | `lib/core/services/` | `v2/packages/platform_capabilities` 六端契约 + 宿主 `*_io.dart` 条件导出 + build-matrix 六端证据 | 有意放弃 | v2 以更薄、可静态验证的契约层替代 |
| 拼图游戏（README 内置插件表宣称「3x3 滑动拼图」） | 无对应代码（`lib/plugins/` 下不存在） | 无 | 有意放弃 | v1 README 宣称与代码不符，实无实现，无能力可消失 |
| 版本与发布体系（CHANGELOG、RELEASE_NOTES、tag 规范） | `CHANGELOG.md` + `docs/releases/` | v2 延续同一体系：`[2.0.0]` 条目 + `docs/releases/RELEASE_NOTES_v2.0.0.md` + 后续 tag | 等价实现 | 主版本号跳至 2.0.0（架构重写） |
| 插件管理/详情 UI（管理屏、详情对话框、插件卡片、UI 容器、插件主题管理器） | `lib/ui/screens/plugin_management_screen.dart` + `lib/ui/widgets/plugin_card.dart`、`plugin_details_dialog.dart`、`plugin_ui_container.dart`、`plugin_theme_manager.dart` | v2 目录页/详情页 + `plugin_flutter` 卡片/状态徽章/表单/结果渲染 + 三 preset 主题令牌 | 等价实现 | 声明式重构，样式受静态扫描测试守护 |

---

## 随旧代码删除而消失的能力（汇总）

> 本节为 F5-03 最重要的审阅材料：**删除旧实现后，下列能力在仓库中即不存在**
> （无论是否已列入 roadmap，至少在 post-2.0 交付前，本仓库不再提供）。
> 「去向」列区分：`roadmap` = 已列入文末草稿计划重建；`随架构消失` = v2 以
> 不同形态承担同等职责；`彻底消失` = 无重建计划（除非用户裁定）。

| # | 消失的能力 | 去向 |
|---|-----------|------|
| 1 | 截图区域选择（桌面级原生 overlay） | roadmap（决策 5 已登记） |
| 2 | 截图窗口捕获（窗口列表选择） | roadmap |
| 3 | 截图图片编辑/标注（矩形、画笔、撤销栈） | roadmap |
| 4 | 截图历史记录（缩略图、保留策略） | roadmap |
| 5 | 全局热键（系统级注册与回调） | roadmap |
| 6 | 循环/定时截图任务 | roadmap |
| 7 | 截图剪贴板复制（CF_DIB 图片/路径） | roadmap |
| 8 | 截图保存配置（路径占位符/文件名格式/图片格式/自动复制） | roadmap（随 1–7 一并规划） |
| 9 | 世界时钟插件（多时区 + 倒计时提醒 + 通知） | roadmap |
| 10 | 桌面宠物（透明窗口/置顶/穿透/动画/交互/设置） | roadmap（前置：窗口管理能力契约） |
| 11 | 通知服务 | roadmap（能力契约形式） |
| 12 | 音频服务 | roadmap（能力契约形式） |
| 13 | 任务调度服务 | roadmap（能力契约形式） |
| 14 | 标签管理系统（打标/过滤/颜色） | 待用户裁定（裁定前视同彻底消失） |
| 15 | JSON 配置编辑器（JsonEditorScreen + JsonValidator） | 随架构消失（声明式设置表单承担常规配置；Schema 校验、示例加载、JSON 直编不再提供） |
| 16 | 外部插件翻译注册接口（IPluginI18n） | 待用户裁定 |
| 17 | 插件 KV 数据存储抽象（`dataStorage`） | roadmap（插件持久化契约） |
| 18 | 窗口管理定制（尺寸/置顶/show/focus 监听） | roadmap（能力契约形式） |
| 19 | 系统托盘（v1 未落地，仅配置预留） | 待用户裁定 |
| 20 | 全局配置文件体系（GlobalConfig Schema/defaults） | 部分随架构消失（宿主设置页仅主题）；其余待 roadmap |
| 21 | 自动启动服务 | 待用户裁定 |
| 22 | 网络管理 | roadmap（网络能力契约） |
| 23 | 进程内插件沙盒/安全监控 | 随架构消失（sidecar 进程隔离 + SCP1 摘要承担外部插件隔离） |
| 24 | 运行时服务定位器/平台服务管理器 | 随架构消失（组装根静态注入替代） |
| 25 | 权限管理（`permission_handler` 路线） | 彻底消失（v1 中即禁用，无运行时损失） |
| 26 | 服务测试界面 | 彻底消失（随平台服务层；v2 以包级测试套件替代） |
| 27 | 开发期热重载自研包装 | 彻底消失（Flutter 原生热重载覆盖该需求） |
| 28 | 平台适配抽象层（adapters/abstraction/environment/distribution 等） | 随架构消失（`platform_capabilities` + 条件导出 + 构建矩阵替代） |
| 29 | `IPlugin`/`PluginContext` 插件开发模型 | 随架构消失（`PluginLifecycle` + 能力注入替代；旧插件不可装载） |
| 30 | JS/Java/C++ 外部插件声明与样本 | 随架构消失（sidecar 协议语言无关，但仓库仅附 Python 样本） |
| 31 | 旧 CLI 的 `build`/`test`/`publish` 命令 | `build`/`test` 彻底消失（workspace 原生命令替代）；`publish` 待用户裁定 |
| 32 | 旧 zh/en 全量翻译键（约 1167 键） | 随架构消失（v2 按现有界面按需覆盖，未覆盖界面的文案不复存在） |

---

## post-2.0 roadmap 草稿

> 本节为草稿；F5-05 将定稿为仓库根 `docs/roadmap.md`。排序即建议优先级。
> 其中 1、2 为 G4 验收明确登记项，其余来自本清单「未实现→roadmap」行。

1. **截图区域选择 overlay**——桌面级区域选择（原生 overlay 或宿主窗口方案重评估），替代 v1 `native_screenshot_window` 能力。
2. **Sidecar 动态目录发现**——安装目录扫描 + 动态注册，替代当前静态清单常量组装。
3. **截图能力补全**——窗口捕获、剪贴板复制（CF_DIB）、图片编辑/标注、历史记录、保存路径/文件名格式/图片格式配置。
4. **全局热键能力契约**（`platform_capabilities` 扩展）——支撑截图热键与宠物唤起。
5. **窗口管理能力契约**——置顶、无边框/透明、点击穿透、show/focus。
6. **世界时钟插件移植**——按 v2 契约重写（依赖第 8 项存储契约与第 11 项通知）。
7. **桌面宠物**——依赖第 5 项窗口管理契约，动画与交互按 v2 声明式 UI 重做。
8. **插件数据持久化契约**——插件级 KV/文档存储（替代 v1 `dataStorage`），世界时钟与截图历史的前置。
9. **平台服务三件以能力契约重建**——通知（`flutter_local_notifications` 路线）、音频、任务调度。
10. **网络访问能力契约**——受控的网络能力（替代 v1 `network_manager`）。
11. **外部插件翻译资源**——sidecar 插件自携带翻译的约定（视 F5-03 对 IPluginI18n 的裁定）。
12. **全局配置体系**——宿主级配置文件/Schema（视需求裁剪 v1 GlobalConfig 面）。

（待用户裁定项——标签管理、系统托盘、自动启动、CLI `publish`——不列入本
草稿，待 F5-03 裁定后由 F5-05 决定是否入正式 roadmap。）

---

## 复核口径说明（供 F5-03 使用）

- 「等价实现」行（计算器、全屏截图、描述符、外部插件链路、管理 UI、发布体系）
  的 v2 对应物均有独立验收证据（`docs/superpowers/acceptance/` 六份报告，
  0 Critical / 0 Important），删除 v1 对应代码不损失用户能力。
- 「部分实现」行意味着**覆盖面缩水是已知的、可接受的**（配置编辑器、截图设置、
  i18n、全局配置、沙盒），缩水部分已逐项进入「消失能力」汇总。
- 「待用户裁定」共 5 行（标签管理、外部插件 i18n、系统托盘、自动启动、
  CLI `publish`），请在 F5-03 逐项给出去向。
