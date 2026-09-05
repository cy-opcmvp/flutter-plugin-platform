# Flutter Plugin Platform（v2）

跨平台插件平台 SDK 与桌面工具箱宿主：微内核契约 + 能力注入 + 桌面 Sidecar 进程隔离，Windows 首发全功能。

- 版本：**2.0.0**（v1 已归档，见 [v1→v2 功能差异清单](docs/superpowers/cutover/v1-v2-feature-diff.md)）
- 技术栈：Flutter 3.38 / Dart 3.10 / pub workspace
- 发布说明：[RELEASE_NOTES_v2.0.0](docs/releases/RELEASE_NOTES_v2.0.0.md)

## 快速开始

```powershell
dart pub get
flutter run -d windows          # 宿主（apps/toolbox_host），默认 warm_life 主题
```

内置插件：**计算器**（六端）、**截图**（Windows，真实 GDI 屏幕捕获）、**Hash 工具**（Python Sidecar，经 `.scp` 包安装运行）。设置页可切换三套艺术风格 preset（精密工具 / 温暖生活 / 暗色专业）× 明暗模式。

## 架构总览

```text
（仓库根 = Dart workspace）
apps/toolbox_host/        唯一 Composition Root 的参考宿主
packages/
  plugin_contracts/       纯 Dart 契约：ID/清单/能力/生命周期/结构化失败
  plugin_runtime/         注册表、解析器、生命周期状态机（零平台依赖）
  plugin_flutter/         UI Surface 契约 + 三 preset 主题 + 基础组件
  plugin_sidecar/         SCP1 安装包、帧 JSON-RPC、进程监督、SidecarSession
  plugin_devkit/          契约测试夹具与检查（依赖 Flutter）
  platform_capabilities/  能力接口（ScreenCapture/SystemPaths）+ 六端 stub
  plugin_cli/             插件 create / validate / pack
plugins/                  builtin 插件（calculator、screenshot）
sidecars/python_sample/   Python Sidecar 样本（hash_tool）
```

依赖方向：contracts ← runtime ← devkit；插件只依赖能力**接口包**；平台真实现（如 Windows GDI 捕获）只经宿主的 `*_io.dart` 条件导出进入编译图（web 恒 stub）。

## 常用命令

```powershell
dart test     packages/plugin_contracts     # 纯 Dart 包逐包测试
flutter test  apps/toolbox_host             # Flutter 包测试
dart run plugin_cli validate plugins/calculator
powershell -File scripts/build-matrix.ps1   # 构建矩阵（windows/web/android 实构建）
```

## 文档索引

- [插件开发走查](docs/guides/v2-plugin-dev-walkthrough.md)——新开发者从零到运行的唯一入口
- [设计规格](docs/superpowers/specs/2026-08-31-plugin-platform-v2-design.md) / [Master Plan](docs/superpowers/plans/2026-08-31-plugin-platform-v2-master-plan.md)
- 验收报告：[M1](docs/superpowers/acceptance/v2-core-foundation-acceptance.md) · [M2](docs/superpowers/acceptance/v2-sidecar-framework-acceptance.md) · [M3](docs/superpowers/acceptance/v2-host-platform-cli-acceptance.md) · [M4](docs/superpowers/acceptance/v2-mvp-plugins-acceptance.md)
- [v1 归档](docs/archive/v1/)：v1 时代文档与工程说明

## 平台支持（诚实证据模型）

| 平台 | 状态 |
|---|---|
| Windows | 全功能首发（宿主 + 截图捕获 + Python Sidecar） |
| Web / Android | 宿主实构建通过，能力按 stub 语义结构化降级 |
| macOS / Linux / iOS | 编译图静态检查达标（`scripts/build-matrix.ps1`），真机构建留待 CI |
