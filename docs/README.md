# 插件平台文档

欢迎来到Flutter插件平台文档中心！这里包含了开发、部署和管理插件所需的所有信息。

📋 **快速导航**:
- 📍 [文档主索引](MASTER_INDEX.md) - **推荐从这里开始** - 完整的文档导航中心
- 🤖 [AI 编码规则](../.claude/rules.md) - Claude Code 和其他 AI 助手必须遵守的编码规范
- 🚀 [快速入门](guides/getting-started.md)
- 🛠️ [CLI工具](tools/plugin-cli.md)

## � 文档结构(

### 📚 开发指南 (guides/)
- [快速入门](guides/getting-started.md) - 5分钟创建你的第一个插件
- [内部插件开发](guides/internal-plugin-development.md) - 完整的内部插件开发指南
- [外部插件开发](guides/external-plugin-development.md) - 外部插件开发标准规范
- [Plugin SDK指南](guides/plugin-sdk-guide.md) - SDK使用详细说明
- [桌面宠物功能](guides/desktop-pet-guide.md) - Desktop Pet功能开发指南
- [桌面宠物平台支持](guides/desktop-pet-platform-support.md) - 桌面宠物跨平台兼容性指南
- [后端集成](guides/backend-integration.md) - 后端服务器集成指南

### 🌐 Web平台兼容性
- [Web平台兼容性](web-platform-compatibility.md) - Web平台兼容性完整指南

### �️ 工具文档 (tools/)
- [CLI工具使用说明](tools/plugin-cli.md) - 命令行工具完整指南

### 🎯 示例代码 (examples/)
- [Dart计算器插件](examples/dart-calculator.md) - Dart/Flutter插件示例
- [Python天气插件](examples/python-weather.md) - Python插件示例
- [内置插件示例](examples/built-in-plugins.md) - 平台内置插件说明

### 📐 架构文档
- [项目结构说明](project-structure.md) - 核心项目结构和接口说明

### 📋 模板库 (templates/)
- [插件模板说明](templates/README.md) - 各种插件开发模板

### 🔄 迁移指南 (migration/)
- [文档迁移指南](migration/migration-guide.md) - 从旧版本迁移的完整指南
- [Platform.environment迁移指南](migration/platform-environment-migration.md) - 环境变量访问迁移指南

### 📖 参考文档 (reference/)
- [平台回退值参考](reference/platform-fallback-values.md) - 环境变量和路径的回退值完整参考

### 🔧 故障排除 (troubleshooting/)
- [Desktop Pet修复说明](troubleshooting/desktop-pet-fix.md) - Desktop Pet功能问题解决方案

### 🔌 插件文档 (plugins/)
- [世界时钟插件](plugins/world-clock/README.md) - 世界时钟插件完整文档
  - [实现文档](plugins/world-clock/implementation.md)
  - [更新说明 v1.1](plugins/world-clock/UPDATE_v1.1.md)

### 📦 发布文档 (releases/)
- [v0.2.1 发布说明](releases/RELEASE_NOTES_v0.2.1.md) - 世界时钟插件发布说明

### 📊 实施报告 (reports/)
- [平台服务阶段0完成](reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md)
- [平台服务阶段1完成](reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md)
- [平台服务实施完成](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)
- [世界时钟修复报告](reports/FIXES_WORLD_CLOCK_v1.1.md)
- [插件ID修复报告](reports/PLUGIN_ID_FIX_SUMMARY.md)

### 🔧 平台服务 (platform-services/)
- [平台服务文档中心](platform-services/README.md) - 平台通用服务文档
- [快速开始](platform-services/PLATFORM_SERVICES_README.md)
- [用户指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)
- [文档结构](platform-services/STRUCTURE.md)
- [导航指南](platform-services/DOCS_NAVIGATION.md)

## 🚀 快速开始

### 1. 环境准备
```bash
# Windows
setup-cli.bat

# Linux/macOS  
chmod +x setup-cli.sh && ./setup-cli.sh
```

### 2. 创建插件
```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal --name "My Plugin" --type tool

# 创建外部插件 (开发中)
dart tools/plugin_cli.dart create-external --name "External Plugin" --language dart
```

### 3. 运行测试
```bash
flutter test test/plugins/
flutter run
```

## 📋 插件类型

| 类型 | 描述 | 适用场景 |
|------|------|----------|
| **内部插件** | 集成在主应用中运行 | 高性能要求、深度系统集成 |
| **外部插件** | 独立进程运行 | 多语言支持、沙盒安全 |
| **工具插件** | 实用工具类 | 计算器、编辑器、文件管理 |
| **游戏插件** | 娱乐游戏类 | 拼图、益智、小游戏 |

## 🌟 主要特性

- ✅ **多语言支持**: Dart, Python, JavaScript, Java, C++等
- ✅ **跨平台**: Windows, macOS, Linux, Web, Mobile
- ✅ **Web平台兼容**: 完整的Web浏览器支持
- ✅ **安全沙盒**: 权限管理和资源限制
- ✅ **热重载**: 开发时实时更新
- ✅ **CLI工具**: 一键创建、构建、测试
- ✅ **模板系统**: 快速开始开发
- ✅ **Desktop Pet**: 桌面宠物功能(桌面平台)

## 📊 开发流程

```mermaid
graph LR
    A[创建插件] --> B[开发功能]
    B --> C[编写测试]
    C --> D[本地测试]
    D --> E[注册插件]
    E --> F[部署发布]
```

## 🎯 最佳实践

1. **遵循命名规范**: 使用描述性的插件名称
2. **权限最小化**: 只请求必要的权限
3. **错误处理**: 实现完善的错误处理机制
4. **性能优化**: 注意内存和CPU使用
5. **测试覆盖**: 编写全面的单元测试
6. **文档完整**: 提供清晰的使用说明

## 🆘 获取帮助

- 📖 **文档**: 查看相应的指南文档
- 💬 **社区**: [GitHub Discussions](https://github.com/flutter-platform/discussions)
- 🐛 **问题报告**: [GitHub Issues](https://github.com/flutter-platform/issues)
- 📧 **联系我们**: support@flutter-platform.com

## 🔄 最近更新

- ✅ **2024.12.18**: 添加Web平台兼容性完整文档
- ✅ **2024.12.18**: 整合文档结构，统一放置到docs目录
- ✅ **2024.12.17**: 修复Desktop Pet功能问题
- ✅ **2024.12.16**: 添加外部插件开发标准规范
- ✅ **2024.12.15**: 完善CLI工具功能
- ✅ **2024.12.14**: 添加插件模板系统

## 📈 贡献指南

欢迎为文档做出贡献：

1. Fork 项目仓库
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

---

**开始你的插件开发之旅吧！** 🚀