# Flutter 插件平台

> 一个功能强大、可扩展的跨平台插件系统，支持内部插件（Dart）和外部插件（Python, JS, Java, C++）开发，提供统一的平台服务层和完整的开发工具链。

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## ✨ 核心特性

### 🔌 插件系统
- **内部插件**: 使用 Dart/Flutter 开发，直接访问平台服务
- **外部插件**: 支持 Python, JavaScript, Java, C++ 等多种语言
- **热重载**: 开发时实时更新，无需重启应用
- **沙盒隔离**: 每个插件运行在独立的沙盒环境中

### 🛠️ 平台服务
- **通知服务**: 跨平台系统通知（Windows, macOS, Linux, Web）
- **任务调度**: 定时任务和后台调度
- **音频服务**: 音频播放和录制（开发中）
- **文件系统**: 统一的文件访问抽象层
- **配置管理**: JSON 配置文件管理和验证

### 🖥️ 跨平台支持
- **桌面平台**: Windows, macOS, Linux（完整功能）
- **Web 平台**: 浏览器支持（功能适配）
- **移动平台**: Android, iOS（计划中）
- **Steam 集成**: Steam 平台特定功能

### 🌐 国际化
- **多语言**: 完整的中文/英文双语支持
- **本地化**: 所有用户界面文本可本地化
- **时区支持**: IANA 时区标识符

### 🎨 特色功能
- **Desktop Pet**: 桌面宠物小组件（仅桌面平台）
- **标签管理**: 插件分类和组织
- **主题系统**: Material Design 3，支持亮/暗主题
- **响应式布局**: 适配不同屏幕尺寸

## 🎯 内置插件

| 插件 | 类型 | 功能描述 | 状态 |
|------|------|---------|------|
| **计算器** | 工具 | 基本算术运算、百分比、历史记录 | ✅ 完整实现 |
| **世界时钟** | 工具 | 多时区显示、倒计时提醒 | ✅ 完整实现 |
| **截图** | 工具 | 全屏截图、区域截图（桌面级） | ✅ 完整实现 |
| **拼图游戏** | 游戏 | 3x3 滑动拼图、计时器 | ✅ 完整实现 |
| **Desktop Pet** | 工具 | 桌面宠物小组件 | ✅ 完整实现（桌面） |

## 📦 当前版本

**版本**: v0.4.1
**发布日期**: 2026-01-20
**详细变更**: 查看 [CHANGELOG.md](CHANGELOG.md)

### 最新更新
- ✨ 新增完整的开发规范体系（11 个规范文档）
- 📚 文档全部中文化并重组（17 个核心文档）
- 🔧 配置管理系统（JSON 编辑器 + 可视化界面）
- 🏷️ 标签管理系统
- 🎨 文档命名规范化

## 🚀 快速开始

### 环境要求

- **Flutter SDK**: 3.0 或更高版本
- **Dart SDK**: 3.0 或更高版本
- **平台要求**:
  - Windows: Windows 10 或更高版本
  - macOS: macOS 10.14 或更高版本
  - Linux: 主流发行版（Ubuntu, Fedora, Debian 等）
  - Web: 现代浏览器（Chrome, Firefox, Safari, Edge）

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/your-org/flutter-plugins-platform.git
cd flutter-plugins-platform

# 2. 安装依赖
flutter pub get

# 3. 运行应用
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web
flutter run -d chrome
```

### 创建你的第一个插件

```bash
# 使用 CLI 工具创建内部插件
dart tools/plugin_cli.dart create-internal \
  --name "我的插件" \
  --type tool \
  --author "你的名字"

# 插件将创建在 lib/plugins/my_plugin/ 目录
```

## 📚 文档导航

### 🚀 入门指南
- [快速入门指南](docs/guides/getting-started.md) - 5分钟上手
- [项目结构说明](docs/project-structure.md) - 了解项目组织

### 👨‍💻 开发者指南
- [内部插件开发](docs/guides/developer/internal-plugin-development.md) - Dart 插件完整教程
- [外部插件开发](docs/guides/developer/external-plugin-development.md) - Python/JS 插件开发
- [插件 SDK 指南](docs/guides/developer/plugin-sdk-guide.md) - SDK API 参考
- [图标生成指南](docs/guides/developer/icon-generation-guide.md) - 插件图标制作

### 🔧 技术文档
- [Desktop Pet 平台支持](docs/guides/technical/desktop-pet-platform-support.md) - 平台兼容性详情
- [Web 平台兼容性](docs/web-platform-compatibility.md) - Web 功能说明
- [Platform.environment 迁移](docs/migration/platform-environment-migration.md) - 迁移指南
- [Platform Fallback Values](docs/reference/platform-fallback-values.md) - 环境变量参考

### 👤 用户指南
- [Desktop Pet 使用说明](docs/guides/user/desktop-pet-usage.md) - 桌面宠物功能
- [平台服务用户指南](docs/guides/user/platform-services-user-guide.md) - 平台服务使用

### 🛠️ 工具和参考
- [CLI 工具使用](docs/tools/plugin-cli.md) - 命令行工具文档
- [示例插件](docs/examples/) - 内置插件示例
- [变更日志](CHANGELOG.md) - 版本更新记录

**📋 [完整文档索引](docs/MASTER_INDEX.md)** | **📖 [文档中心](docs/README.md)**

## 🏗️ 项目结构

```
flutter-plugins-platform/
├── lib/
│   ├── core/                           # 核心系统
│   │   ├── interfaces/                 # 接口定义（IPlugin, 服务接口）
│   │   ├── models/                     # 数据模型
│   │   ├── services/                   # 核心服务实现
│   │   │   ├── service_locator.dart    # 服务定位器（单例模式）
│   │   │   ├── platform_service_manager.dart  # 服务管理器
│   │   │   ├── notification/           # 通知服务
│   │   │   ├── task_scheduler/         # 任务调度
│   │   │   └── audio/                  # 音频服务（开发中）
│   │   └── utils/                      # 工具类
│   ├── plugins/                        # 内置插件
│   │   ├── calculator/                 # 计算器插件
│   │   ├── world_clock/                # 世界时钟插件
│   │   ├── screenshot/                 # 截图插件
│   │   ├── puzzle_game/                # 拼图游戏插件
│   │   └── desktop_pet/                # Desktop Pet
│   ├── ui/                             # 用户界面
│   │   ├── screens/                    # 页面
│   │   ├── widgets/                    # 通用组件
│   │   └── theme/                      # 主题配置
│   └── l10n/                           # 国际化
│       ├── app_zh.arb                  # 中文翻译
│       └── app_en.arb                  # 英文翻译
├── docs/                               # 文档目录
│   ├── guides/                         # 指南文档
│   │   ├── developer/                  # 开发者指南
│   │   ├── technical/                  # 技术文档
│   │   └── user/                       # 用户指南
│   ├── plugins/                       # 插件详细文档
│   ├── platform-services/             # 平台服务文档
│   ├── migration/                     # 迁移指南
│   └── reference/                     # 参考手册
├── test/                              # 测试文件
│   ├── unit/                          # 单元测试
│   ├── widget/                        # Widget 测试
│   └── test_utils/                    # 测试工具
├── tools/                             # 开发工具
│   └── plugin_cli.dart                # CLI 工具
├── scripts/                           # 脚本文件
├── .claude/                           # AI 编码规则
└── pubspec.yaml                       # 项目配置
```

## 🛠️ 开发工具

### CLI 工具

```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal --name "插件名称" --type tool

# 查看所有可用模板
dart tools/plugin_cli.dart list-templates

# 查看帮助
dart tools/plugin_cli.dart --help
```

### 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/plugins/calculator/calculator_plugin_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

### 代码质量

```bash
# 格式化代码
dart format .

# 静态分析
dart analyze

# 运行所有检查
flutter test && dart analyze && dart format --output=none --set-exit-if-changed .
```

## 📖 开发规范

项目遵循严格的开发规范，确保代码质量和一致性：

- **代码风格**: [代码风格规范](.claude/rules/CODE_STYLE_RULES.md)
- **测试规范**: [测试规范](.claude/rules/TESTING_RULES.md)
- **提交规范**: [Git 提交规范](.claude/rules/GIT_COMMIT_RULES.md)
- **错误处理**: [错误处理规范](.claude/rules/ERROR_HANDLING_RULES.md)
- **文件组织**: [文件组织规范](.claude/rules/FILE_ORGANIZATION_RULES.md)
- **文档命名**: [文档命名规范](.claude/rules/DOCUMENTATION_NAMING_RULES.md)
- **插件配置**: [插件配置规范](.claude/rules/PLUGIN_CONFIG_SPEC.md)

**查看所有规范**: [.claude/rules/README.md](.claude/rules/README.md)

## 🤝 贡献指南

我们欢迎各种形式的贡献！

### 贡献方式

1. **报告 Bug**: 在 [Issues](https://github.com/your-org/flutter-plugins-platform/issues) 中报告问题
2. **提出建议**: 在 [Discussions](https://github.com/your-org/flutter-plugins-platform/discussions) 中讨论新功能
3. **提交代码**:
   - Fork 项目
   - 创建功能分支 (`git checkout -b feature/AmazingFeature`)
   - 提交更改 (`git commit -m 'feat: 添加某个功能'`)
   - 推送到分支 (`git push origin feature/AmazingFeature`)
   - 开启 Pull Request
4. **改进文档**: 帮助完善文档和示例

### 代码审查流程

- 所有 PR 必须通过 CI 检查
- 代码必须符合项目规范
- 测试覆盖率不能低于 80%
- 需要至少一位维护者批准

## 📄 开源许可

本项目采用 Apache License 2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🆘 获取帮助

- 📖 [完整文档](docs/MASTER_INDEX.md) - 查看所有文档
- 🐛 [问题报告](https://github.com/your-org/flutter-plugins-platform/issues) - 报告 Bug
- 💡 [功能请求](https://github.com/your-org/flutter-plugins-platform/discussions) - 讨论新功能
- 📧 联系我们: support@example.com

## 🌟 致谢

感谢所有为这个项目做出贡献的开发者！

特别感谢：
- Flutter 团队提供优秀的跨平台框架
- 所有贡献者和用户的反馈和建议

---

<div align="center">

**[开始使用](docs/guides/getting-started.md)** •
**[查看文档](docs/MASTER_INDEX.md)** •
**[报告问题](https://github.com/your-org/flutter-plugins-platform/issues)**

Made with ❤️ by the Flutter Plugin Platform team

</div>
