# .claude Directory

> 🤖 Claude Code 和 AI 编码助手的配置和规则目录

本目录包含 Claude Code 和其他 AI 助手所需的项目理解文档、编码规则和配置。

## 📁 目录结构

```
.claude/
├── README.md                    # 📍 本文件 - 目录说明
├── PROJECT_OVERVIEW.md          # 📖 项目概览 - AI 必读
├── rules.md                     # 📋 编码规则主入口
├── settings/                    # ⚙️ 配置文件
│   └── mcp.json                # MCP 服务器配置
└── rules/                       # 📐 详细规则
    └── FILE_ORGANIZATION_RULES.md  # 文件组织规范
```

## 🚀 AI 助手使用指南

### 第一次使用此项目

**必须按顺序阅读**:

1. **[项目概览](PROJECT_OVERVIEW.md)** ⭐⭐⭐
   - 项目定位和目标
   - 核心特性和功能
   - 架构设计
   - 技术栈
   - 当前状态

2. **[编码规则](rules.md)** ⭐⭐⭐
   - 文件组织规范
   - 代码规范
   - 插件开发规范
   - 服务开发规范
   - 测试规范
   - 文档规范

3. **[文件组织规范](rules/FILE_ORGANIZATION_RULES.md)** ⭐⭐
   - 根目录保持简洁原则
   - 文件分类规则
   - 决策树
   - 常见错误

### 执行具体任务前

根据任务类型，阅读相关文档：

#### 插件开发任务
- [插件平台设计](../.kiro/specs/plugin-platform/design.md)
- [插件 ID 规范](rules.md#插件开发规范)
- [内部插件开发指南](../docs/guides/internal-plugin-development.md)
- [外部插件开发指南](../docs/guides/external-plugin-development.md)

#### 平台服务任务
- [平台服务架构](../.kiro/specs/platform-services/design.md)
- [平台服务用户指南](../docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)
- [服务开发规范](rules.md#服务开发规范)

#### 文档任务
- [文档主索引](../docs/MASTER_INDEX.md)
- [文件组织规范](rules/FILE_ORGANIZATION_RULES.md)
- [文档规范](rules.md#文档规范)

#### 故障排除任务
- [故障排除指南](../docs/troubleshooting/)
- [Windows 构建修复](../docs/troubleshooting/WINDOWS_BUILD_FIX.md)

## 📋 核心规则摘要

### 1. 文件组织

**根目录只允许**:
- ✅ `README.md`, `CHANGELOG.md`, `pubspec.yaml`
- ✅ 用户直接运行的脚本（`setup-cli.bat`）
- ✅ 核心功能快速入口（`PLATFORM_SERVICES.md`）

**禁止在根目录**:
- ❌ 临时脚本、文档、实施报告
- ❌ 插件详细文档

**正确位置**:
- 脚本 → `scripts/`
- 文档 → `docs/{category}/`
- 技术规范 → `.kiro/specs/{feature}/`

### 2. 插件 ID 命名

```
格式: {domain}.{category}.{plugin-name}
规则: 小写字母 + 点号，禁止下划线和连字符

✅ com.example.calculator
✅ org.company.tools.texteditor
❌ com.example.text_editor (下划线)
❌ com.example.world-clock (连字符)
```

### 3. 服务开发

- 必须先定义接口 `I{ServiceName}`
- 接口 → `lib/core/interfaces/services/`
- 实现 → `lib/core/services/{service-name}/`
- 必须实现 `initialize()`, `dispose()`

### 4. 代码风格

- 遵循 Effective Dart
- 使用类型注解
- 优先使用 `const`
- 公共 API 必须有文档注释

## 🔍 快速参考

### 项目关键文件

| 文件 | 用途 |
|------|------|
| [pubspec.yaml](../pubspec.yaml) | Flutter 项目配置 |
| [lib/main.dart](../lib/main.dart) | 应用入口 |
| [lib/core/](../lib/core/) | 核心系统代码 |
| [lib/plugins/](../lib/plugins/) | 插件目录 |
| [docs/](../docs/) | 完整文档 |
| [.kiro/specs/](../.kiro/specs/) | 技术规范 |

### 常用命令

```bash
# 运行应用
flutter run -d windows

# 运行测试
flutter test

# 构建发布版
flutter build windows --release

# 清理
flutter clean && flutter pub get
```

### 关键文档链接

- **[文档主索引](../docs/MASTER_INDEX.md)** - 所有文档的导航中心
- **[项目 README](../README.md)** - 项目主文档
- **[变更日志](../CHANGELOG.md)** - 版本历史

## ⚙️ 配置说明

### MCP 配置

`settings/mcp.json` 包含 MCP (Model Context Protocol) 服务器配置：

```json
{
  "mcpServers": {
    // 添加 MCP 服务器配置
  }
}
```

当前无活动 MCP 服务器。可以添加：
- 文件系统访问
- Web 搜索
- 数据库连接等

## 🤖 AI 助手工作流程

### 接收任务后

1. **阅读项目概览** - 了解项目背景
2. **查找相关规范** - 在 `.kiro/specs/` 中查找技术规范
3. **查阅编码规则** - 确保遵循项目规范
4. **执行任务** - 按照规范开发
5. **更新文档** - 同步更新相关文档

### 创建新文件前

使用 [文件组织决策树](rules/FILE_ORGANIZATION_RULES.md#决策树) 判断文件位置。

### 提交代码前

- ✅ 遵循代码规范
- ✅ 添加文档注释
- ✅ 更新相关文档
- ✅ 运行测试通过

## 📚 相关资源

### 项目文档
- [文档主索引](../docs/MASTER_INDEX.md)
- [项目结构说明](../docs/project-structure.md)

### 技术规范
- [插件平台设计](../.kiro/specs/plugin-platform/design.md)
- [平台服务架构](../.kiro/specs/platform-services/design.md)
- [外部插件系统](../.kiro/specs/external-plugin-system/design.md)

### 开发指南
- [快速开始](../docs/guides/getting-started.md)
- [插件开发指南](../docs/guides/internal-plugin-development.md)
- [平台服务指南](../docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)

## 🔄 更新历史

- **2026-01-15**: 创建 `.claude` 目录结构
  - 添加项目概览
  - 整合编码规则
  - 集成 `.kiro/specs` 引用
  - 创建文件组织规范

## 📞 支持

如有疑问，请查阅：
1. [项目概览](PROJECT_OVERVIEW.md)
2. [编码规则](rules.md)
3. [文档主索引](../docs/MASTER_INDEX.md)
4. [故障排除](../docs/troubleshooting/)

---

**维护者**: Flutter Plugin Platform Team
**最后更新**: 2026-01-15
