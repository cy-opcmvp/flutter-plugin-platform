# 快速入门指南

> 欢迎使用 Flutter Plugin Platform - 可扩展的跨平台插件系统

## 📋 前置要求

在开始之前，请确保您的开发环境满足以下要求：

### 必需环境

- **Flutter SDK**: 3.16.0 或更高版本
- **Dart SDK**: 3.2.0 或更高版本（随 Flutter 安装）
- **开发工具**:
  - Visual Studio Code / Android Studio / IntelliJ IDEA
  - 推荐安装 Flutter 和 Dart 插件

### 平台特定要求

#### Windows 开发
- **操作系统**: Windows 10 或更高版本
- **Visual Studio 2022**（包含 C++ 桌面开发工具）
- **Windows SDK**: 10.0.19041.0 或更高版本

#### macOS 开发
- **操作系统**: macOS 10.14 或更高版本
- **Xcode**: 12.0 或更高版本
- **CocoaPods**: 1.11.0 或更高版本

#### Linux 开发
- **操作系统**: Ubuntu 18.04 或更高版本（或等效发行版）
- **构建依赖**: `clang cmake ninja-build pkg-config libgtk-3-dev`

#### Web 开发
- **Chrome 浏览器**: 最新版本

## 🚀 快速安装

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/flutter-plugins-platform.git
cd flutter-plugins-platform
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 生成国际化文件

```bash
flutter gen-l10n
```

### 4. 运行应用

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

#### Web
```bash
flutter run -d chrome
```

## 🎯 5分钟快速体验

### 第一步：启动应用

运行应用后，您将看到主界面：

```
┌─────────────────────────────────────┐
│  Flutter Plugin Platform            │
│                                     │
│  🔌 插件列表                        │
│                                     │
│  • 🖥️  截图插件                     │
│  • ⏰ 世界时钟                       │
│  • 🧮 计算器                         │
│                                     │
│  🔬 服务测试 | ⚙️  设置             │
└─────────────────────────────────────┘
```

### 第二步：体验插件功能

1. **截图插件**: 点击"截图插件"卡片，尝试区域截图功能
2. **世界时钟**: 添加几个时区，查看不同时区的当前时间
3. **计算器**: 进行简单的数学计算

### 第三步：探索平台服务

点击右上角的 🔬 图标，进入服务测试界面：

- **通知服务**: 发送测试通知
- **音频服务**: 播放系统音效
- **任务调度**: 创建倒计时任务

## 💻 开发你的第一个插件

### 创建内部插件

使用提供的 CLI 工具创建新插件：

```bash
dart tools/plugin_cli.dart create-internal \
  --name "My Plugin" \
  --type tool \
  --author "Your Name"
```

### 插件基本结构

```dart
library;

import 'package:plugin_platform/core/interfaces/i_plugin.dart';

class MyPlugin extends IPlugin {
  @override
  String get id => 'com.example.myplugin';

  @override
  String get name => 'My Plugin';

  @override
  String get version => '1.0.0';

  @override
  Future<void> initialize(PluginContext context) async {
    // 初始化逻辑
  }

  @override
  Widget buildUI(BuildContext context) {
    // 返回 UI 组件
    return MyPluginWidget();
  }

  @override
  Future<void> dispose() async {
    // 清理资源
  }
}
```

## 📚 接下来的学习路径

### 路径1：插件开发
1. 阅读 [内部插件开发指南](./internal-plugin-development.md)
2. 了解 [插件配置规范](../../.claude/rules/PLUGIN_CONFIG_SPEC.md)
3. 查看 [示例插件](../examples/built-in-plugins.md)

### 路径2：平台服务
1. 阅读 [平台服务用户指南](./platform-services-user-guide.md)
2. 了解 [服务架构设计](../.kiro/specs/platform-services/design.md)
3. 查看 [服务测试界面](../../lib/ui/screens/service_test_screen.dart)

### 路径3：外部插件
1. 阅读 [外部插件开发指南](./external-plugin-development.md)
2. 了解 [外部插件系统](../.kiro/specs/external-plugin-system/)
3. 尝试创建 Python/JS 插件

## 🔧 常用命令

### 开发命令

```bash
# 运行应用（指定平台）
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d chrome     # Web

# 获取依赖
flutter pub get

# 运行测试
flutter test                              # 所有测试
flutter test test/plugins/world_clock_test.dart  # 单个测试文件

# 构建应用
flutter build windows --release
flutter build macos --release
flutter build web --release

# 清理构建
flutter clean

# 代码格式化
flutter format .

# 静态分析
flutter analyze

# 生成国际化文件
flutter gen-l10n
```

### 创建插件

```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal \
  --name "Plugin Name" \
  --type tool \
  --author "Author"

# 创建外部插件（未来功能）
dart tools/plugin_cli.dart create-external \
  --name "Plugin Name" \
  --language python
```

## 🐛 遇到问题？

### 常见问题

#### 1. Windows 构建失败
**问题**: NuGet 包冲突或 CppWinRT 错误

**解决方案**:
```bash
# 运行修复脚本
powershell -ExecutionPolicy Bypass -File scripts/setup/fix-nuget.ps1
powershell -ExecutionPolicy Bypass -File scripts/setup/install-cppwinrt.ps1
```

详细说明：[Windows 构建修复指南](../troubleshooting/WINDOWS_BUILD_FIX.md)

#### 2. 依赖安装失败
**问题**: `flutter pub get` 报错

**解决方案**:
```bash
# 清理并重新获取
flutter clean
flutter pub get
```

#### 3. 国际化文件未生成
**问题**: 运行时找不到 `AppLocalizations`

**解决方案**:
```bash
# 生成国际化文件
flutter gen-l10n

# 或使用脚本
scripts/update-i18n.bat
```

### 获取帮助

1. **查看文档**: [文档主索引](../MASTER_INDEX.md)
2. **查看故障排除**: [故障排除指南](../troubleshooting/)
3. **查看示例**: [示例代码](../examples/)
4. **提交问题**: GitHub Issues

## 📖 推荐阅读顺序

### 新手入门
1. ✅ 本文档（快速入门）
2. [项目结构说明](../project-structure.md)
3. [内置插件示例](../examples/built-in-plugins.md)

### 插件开发者
1. [内部插件开发指南](./internal-plugin-development.md)
2. [插件配置规范](../../.claude/rules/PLUGIN_CONFIG_SPEC.md)
3. [代码风格规范](../../.claude/rules/CODE_STYLE_RULES.md)

### 平台开发者
1. [平台服务用户指南](./platform-services-user-guide.md)
2. [平台服务设计文档](../.kiro/specs/platform-services/design.md)
3. [错误处理规范](../../.claude/rules/ERROR_HANDLING_RULES.md)

### 架构师
1. [插件平台架构设计](../.kiro/specs/plugin-platform/design.md)
2. [外部插件系统设计](../.kiro/specs/external-plugin-system/design.md)
3. [国际化和本地化设计](../.kiro/specs/internationalization/design.md)

## 🎓 下一步

现在您已经完成了快速入门，接下来可以：

1. **深入学习**: 阅读详细的开发指南
2. **实践开发**: 创建自己的插件
3. **贡献代码**: 查看贡献指南，参与项目开发
4. **探索高级功能**: 了解外部插件、平台服务等高级特性

---

**恭喜！** 您已经成功入门 Flutter Plugin Platform。

如有任何问题，请查看 [完整文档](../MASTER_INDEX.md) 或提交 Issue。

---

**版本**: v0.4.1
**最后更新**: 2026-01-21
**反馈**: [提交问题](https://github.com/yourusername/flutter-plugins-platform/issues)
