# Release Notes - v2.0.0

**发布日期**: 2026-09-05
**上一个版本**: v0.4.4（v1 时代最后一个 tag）
**版本类型**: Major（架构重写）

---

## 📦 版本概述

Plugin Platform v2 是一次彻底的架构重写：从「单体 Flutter 应用 + 接口插件」
演进为「微内核契约 + 能力注入 + 声明式 UI」的插件平台。插件以标准
`plugin.json` 清单描述自己，宿主按目标平台静态解析能力依赖，UI 由声明式
表单/结果组件呈现；外部插件走 Sidecar 框架（SCP1 安装包 + 进程监督 +
stdio 帧化 JSON-RPC）。

> ⚠️ **破坏性变更**：v1 插件与 v1 平台服务在本版本中不可装载、不可复用。
> 逐特性差异见 `docs/superpowers/cutover/v1-v2-feature-diff.md`。

---

## ✨ 亮点

### 三个开箱即用的插件

| 插件 | 类型 | 说明 |
|------|------|------|
| **计算器** | 内置（builtin） | 六端通用的表达式计算器，求值与历史记录在纯 Dart 模型层，错误带位置定位（除零/语法/括号） |
| **截图** | 内置（builtin） | Windows 全屏捕获（GDI），捕获结果直接保存/预览，文件名前缀与图片质量可配置 |
| **hash_tool** | Python Sidecar | 仅用标准库 hashlib 的哈希工具，演示外部插件全链路：打包 → 安装 → 启动 → 命令调用 → 结果渲染 → 停止/卸载 |

### 三套预设主题 × 明暗两向

`precision_tools`（精密工具）、`warm_life`（温暖生活）、`dark_pro`（暗色专业）
三套设计令牌预设，每套均含明/暗两个方向，宿主设置页一键切换；
样式值被静态扫描测试守护，杜绝散落的魔法数字。

### Python Sidecar 全链路

外部插件不再是概念：`plugin_cli pack` 打出 SCP1 安装包，宿主内原子安装、
进程监督（崩溃可观测）、4 字节大端长度前缀的 stdio JSON-RPC 2.0 会话、
声明式命令表单与结果渲染。样本 `hash_tool.py` 零 pip 依赖。

### 六端证据模型（不伪造跳过端）

`scripts/v2/build-matrix.ps1` 对宿主产出六端构建证据：windows/web 实构建，
android 探测到 SDK 才实构建，macos/linux/ios 以「六端编译图静态检查 +
`flutter analyze`」作替代证据——每一端的结论都可复核。

---

## 🖥️ 平台支持矩阵

| 平台 | 状态 | 说明 |
|------|------|------|
| **Windows** | ✅ 首发全功能 | 宿主 + 全部三插件 + GDI 截图能力 |
| **Web** | ✅ 宿主可构建 | 宿主与 builtin 计算器可用（平台专属实现经条件导出取 stub 分支） |
| **Android** | ✅ 宿主可构建* | 探测到 Android SDK 即实构建；本地无 SDK 时矩阵如实输出 `SKIPPED-LOCAL-UNAVAILABLE` |
| **macOS** | ◐ 编译图达标 | 非本机 OS 无法实构建；编译图静态检查通过，在对应 runner 上可实构建 |
| **Linux** | ◐ 编译图达标 | 同上 |
| **iOS** | ◐ 编译图达标 | 同上 |

> \* 「可构建」指宿主应用层面的构建证据；Sidecar 外部插件当前仅面向桌面
> （Windows 已验证）。

---

## ⚠️ 已知限制（post-2.0 roadmap）

以下 v1 能力未随本次重写迁移，已登记 post-2.0 roadmap（草稿见
`docs/superpowers/cutover/v1-v2-feature-diff.md`，正式版将落于 `docs/roadmap.md`）：

- **截图进阶能力**：区域选择（桌面级 overlay）、窗口捕获、图片编辑/标注、
  历史记录、全局热键、循环截图任务、剪贴板复制——v2 仅全屏捕获；
- **世界时钟插件**（多时区 + 倒计时提醒）：未迁移；
- **桌面宠物**（窗口化、动画、交互）：未迁移；
- **平台服务三件**（通知 / 音频 / 任务调度）：v2 暂无对应服务层，
  将以能力契约形式规划。

---

## 🚀 安装与运行

### 环境要求

- Flutter SDK（stable，版本以 `v2/pubspec.lock` 解析为准）
- Python 3（可选，仅运行 Sidecar 样本；缺失时相关功能与测试自动跳过）

### 运行宿主

```bash
cd v2/apps/toolbox_host
flutter pub get
flutter run -d windows        # Windows 首发全功能
flutter run -d chrome         # Web 宿主
```

### 运行测试与静态检查（在 `v2/` 下）

```bash
dart pub get --offline
dart test packages/plugin_contracts   # 各纯 Dart 包同理
flutter test apps/toolbox_host
dart format --output=none --set-exit-if-changed .
flutter analyze
```

### 开发自己的插件

从走查文档开始：`docs/guides/v2-plugin-dev-walkthrough.md`；
或直接用 CLI 生成骨架：

```bash
dart run plugin_cli create --id tools.demo --name Demo --kind builtin <dir>
dart run plugin_cli validate <dir>
dart run plugin_cli pack <dir> -o out.scp
```

---

## 📝 完整变更

见 [`CHANGELOG.md`](../../CHANGELOG.md) 的 `[2.0.0]` 节。
