# Flutter 插件平台

一个强大的、可扩展的Flutter插件平台，支持内部和外部插件开发。

## ✨ 特性

- 🔌 **插件系统**: 支持内部和外部插件
- 🌍 **多语言支持**: Dart, Python, JavaScript, Java, C++等
- 🖥️ **跨平台**: Windows, macOS, Linux, Web, Mobile
- 🔒 **安全沙盒**: 权限管理和资源限制
- 🔥 **热重载**: 开发时实时更新
- 🛠️ **CLI工具**: 一键创建、构建、测试
- 🐾 **Desktop Pet**: 桌面宠物功能

## 🚀 快速开始

### 环境准备

```bash
# Windows
setup-cli.bat

# Linux/macOS
chmod +x setup-cli.sh && ./setup-cli.sh
```

### 创建你的第一个插件

```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal --name "My Plugin" --type tool --author "Your Name"

# 运行应用
flutter run
```

## 📚 文档

完整文档请查看 [docs/README.md](docs/README.md)

### 快速链接

- [快速入门指南](docs/guides/getting-started.md)
- [内部插件开发](docs/guides/internal-plugin-development.md)
- [外部插件开发](docs/guides/external-plugin-development.md)
- [CLI工具使用](docs/tools/plugin-cli.md)
- [示例代码](docs/examples/)
- [插件模板](docs/templates/)

## 🎯 插件类型

| 类型 | 描述 | 示例 |
|------|------|------|
| **工具插件** | 实用工具和生产力应用 | 计算器、文本编辑器、文件管理器 |
| **游戏插件** | 娱乐和游戏应用 | 拼图游戏、益智游戏、小游戏 |

## 🏗️ 项目结构

```
flutter_app/
├── lib/
│   ├── core/              # 核心系统
│   │   ├── interfaces/    # 接口定义
│   │   ├── models/        # 数据模型
│   │   └── services/      # 核心服务
│   ├── plugins/           # 插件目录
│   │   ├── calculator/    # 计算器插件
│   │   ├── puzzle_game/   # 拼图游戏插件
│   │   └── ...
│   ├── ui/                # 用户界面
│   └── main.dart          # 应用入口
├── test/                  # 测试文件
├── docs/                  # 文档目录
├── tools/                 # CLI工具
└── examples/              # 示例代码
```

## 🛠️ 开发工具

### CLI工具

```bash
# 创建插件
dart tools/plugin_cli.dart create-internal --name "Plugin Name"

# 列出模板
dart tools/plugin_cli.dart list-templates

# 查看帮助
dart tools/plugin_cli.dart --help
```

### 测试

```bash
# 运行所有测试
flutter test

# 运行特定插件测试
flutter test test/plugins/my_plugin_test.dart
```

## 🤝 贡献

欢迎贡献代码、文档或报告问题！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 Apache License 2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🆘 获取帮助

- 📖 [完整文档](docs/README.md)
- 💬 [GitHub Discussions](https://github.com/flutter-platform/discussions)
- 🐛 [问题报告](https://github.com/flutter-platform/issues)

## 🌟 致谢

感谢所有为这个项目做出贡献的开发者！

---

**开始你的插件开发之旅吧！** 🚀
