# Flutter Plugin Platform - 项目概览

> 🎯 Kiro 和 AI 助手的项目理解指南

## 📋 项目基本信息

**项目名称**: Flutter Plugin Platform (插件平台)
**版本**: v1.0.0
**开发语言**: Dart (Flutter)
**目标平台**: Windows, macOS, Linux, Web, Android, iOS, Steam

## 🎯 项目定位

一个强大、可扩展的 Flutter 插件平台，支持内部和外部插件开发。该平台作为工具和迷你游戏的集成环境，具有跨平台兼容性。

## ✨ 核心特性

### 1. 插件系统
- **内部插件**: 集成在主应用中运行（高性能、深度系统集成）
- **外部插件**: 在独立进程中运行（多语言支持、沙盒安全）
- **插件类型**: 工具插件、游戏插件
- **多语言支持**: Dart, Python, JavaScript, Java, C++

### 2. 跨平台支持
- **桌面平台**: Windows, macOS, Linux（完整功能支持，包括桌面宠物）
- **移动平台**: Android, iOS（移动优化功能）
- **Web 平台**: 浏览器部署（平台兼容性考虑）
- **Steam 平台**: Steam 平台集成（仅桌面）

### 3. 平台服务
- **通知服务**: 即时通知、定时通知、权限管理
- **音频服务**: 系统音效、背景音乐、音量控制
- **任务调度服务**: 倒计时、周期性任务、任务持久化
- **配置管理**: 全局配置和插件配置的统一管理

### 4. 其他功能
- **桌面宠物**: 桌面伴侣功能（仅桌面平台）
- **安全沙盒**: 权限管理和资源限制
- **热重载**: 开发时实时更新
- **CLI 工具**: 一键创建、构建、测试

## 🏗️ 架构设计

### 核心架构

**插件系统**: 基于 `IPlugin` 和 `IPlatformPlugin` 接口的插件架构
- `initialize()` - 初始化插件
- `dispose()` - 清理资源
- `buildUI()` - 构建 UI
- `onStateChanged()` - 状态变更处理
- `getState()` - 获取状态

**服务定位器模式**: `ServiceLocator` 负责服务的注册和检索
- `PlatformServiceManager` 作为统一入口初始化所有平台服务
- `ConfigManager` 管理全局配置和插件配置

**状态管理**: `PluginStateManager` 管理插件生命周期
- 状态转换: inactive → loading → active/paused → error

### 项目结构
```
lib/
├── core/                   # 核心系统
│   ├── interfaces/        # 服务接口定义
│   ├── models/            # 数据模型
│   └── services/          # 核心服务实现
├── plugins/               # 插件目录
│   ├── calculator/        # 计算器插件
│   ├── world_clock/       # 世界时钟插件
│   └── screenshot/        # 截图插件
├── ui/                    # 用户界面
└── main.dart             # 应用入口
```

## 📚 内置插件

### 1. 计算器插件
- **位置**: `lib/plugins/calculator/`
- **功能**: 基本计算功能
- **平台**: 全平台支持

### 2. 世界时钟插件
- **位置**: `lib/plugins/world_clock/`
- **功能**: 多时区显示、倒计时提醒
- **平台**: 全平台支持

### 3. 截图插件
- **位置**: `lib/plugins/screenshot/`
- **功能**: 区域截图、全屏截图、窗口截图
- **平台**: Windows 完整支持，其他平台部分支持

## 📖 技术规范

### .kiro/specs/ 目录结构

```
.kiro/specs/
├── platform-services/         # 平台服务规范
├── plugin-platform/           # 插件平台规范
├── external-plugin-system/    # 外部插件系统
├── internationalization/      # 国际化
└── web-platform-compatibility/# Web平台兼容性
```

## 📊 当前状态

### 已完成功能 ✅
- 插件系统（内部/外部）
- 平台服务管理器
- 通知服务
- 任务调度服务
- 配置管理器
- 世界时钟插件
- 截图插件（Windows）
- 桌面宠物
- 国际化支持（中文/英文）

### 计划中 📋
- 更多平台的截图支持
- 主题自定义
- 声音提醒
- 快捷倒计时模板

## 🚀 快速命令

```bash
# 运行应用
flutter run -d windows

# 运行测试
flutter test

# 构建发布版本
flutter build windows --release

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 国际化生成
flutter gen-l10n
```

## 📞 支持资源

- **文档主索引**: [docs/MASTER_INDEX.md](../../docs/MASTER_INDEX.md)
- **技术规范**: [.kiro/specs/](../specs/)
- **编码规则**: [rules.md](rules.md)

---

**最后更新**: 2026-01-16
**维护者**: Flutter Plugin Platform Team
