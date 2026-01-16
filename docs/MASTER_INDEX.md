# Flutter Plugin Platform - 文档主索引

> 📚 项目文档的完整导航中心

## 🚀 快速开始

### 新用户必读
- **[项目 README](../README.md)** - 项目概述和快速入门
- **[快速开始指南](getting-started.md)** - 5分钟上手教程
- **[变更日志](../CHANGELOG.md)** - 版本更新历史

## 📂 文档目录结构

```
docs/
├── MASTER_INDEX.md                    # 📍 本文件 - 文档主索引
├── README.md                          # 📖 文档中心
├── index.md                           # 📑 详细索引
├── project-structure.md               # 🏗️ 项目结构说明
├── DOCS_REORGANIZATION.md             # 📋 文档重组记录
├── PLATFORM_DECOUPLING_DESIGN.md      # 🏗️ 平台解耦架构设计

scripts/                               # 🔧 开发脚本
├── README.md                          # 脚本说明文档
├── fix-nuget.ps1                      # NuGet 包修复脚本
└── install-cppwinrt.ps1               # CppWinRT 安装脚本
│
├── guides/                            # 📚 用户指南
│   ├── getting-started.md            # 快速开始
│   ├── internal-plugin-development.md    # 内部插件开发
│   ├── external-plugin-development.md    # 外部插件开发
│   ├── plugin-sdk-guide.md          # 插件SDK指南
│   ├── backend-integration.md       # 后端集成
│   ├── desktop-pet-guide.md         # 桌面宠物使用
│   ├── desktop-pet-platform-support.md  # 桌面宠物平台支持
│   ├── desktop-pet-usage.md         # 桌面宠物使用说明
│   └── PLATFORM_SERVICES_USER_GUIDE.md  # 平台服务用户指南
│
├── platform-services/                 # 🔧 平台服务文档
│   ├── README.md                    # 服务文档中心
│   ├── PLATFORM_SERVICES_README.md  # 快速开始
│   ├── STRUCTURE.md                 # 文档结构
│   └── DOCS_NAVIGATION.md           # 导航指南
│
├── plugins/                          # 🔌 插件文档
│   ├── screenshot/                  # 截图插件
│   │   ├── README.md                # 插件概述
│   │   ├── PLATFORM_SUPPORT_ANALYSIS.md  # 平台支持分析
│   │   └── PLATFORM_TODO.md         # 平台实现任务
│   └── world-clock/                 # 世界时钟插件
│       ├── README.md                # 插件概述
│       ├── IMPLEMENTATION.md        # 实现文档
│       └── UPDATE_v1.1.md           # 更新说明
│
├── releases/                         # 📦 发布文档
│   └── RELEASE_NOTES_v0.2.1.md     # v0.2.1 发布说明
│
├── reports/                          # 📊 实施报告
│   ├── PLATFORM_SERVICES_PHASE0_COMPLETE.md  # 阶段0完成
│   ├── PLATFORM_SERVICES_PHASE1_COMPLETE.md  # 阶段1完成
│   ├── PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md  # 实施完成
│   ├── FIXES_WORLD_CLOCK_v1.1.md    # 世界时钟修复报告
│   └── PLUGIN_ID_FIX_SUMMARY.md     # 插件ID修复报告
│
├── migration/                        # 🔄 迁移指南
│   ├── migration-guide.md           # 通用迁移指南
│   └── platform-environment-migration.md  # 平台环境迁移
│
├── examples/                         # 💡 示例文档
│   ├── built-in-plugins.md          # 内置插件示例
│   ├── dart-calculator.md           # Dart计算器
│   └── python-weather.md            # Python天气插件
│
├── tools/                            # 🛠️ 工具文档
│   └── plugin-cli.md                # 插件CLI工具
│
├── troubleshooting/                  # 🐛 故障排除
│   └── desktop-pet-fix.md           # 桌面宠物修复
│
└── reference/                        # 📋 参考文档
    └── platform-fallback-values.md  # 平台回退值

.kiro/specs/                          # 📐 技术规范
├── platform-services/                # 平台服务规范
│   ├── design.md                    # 架构设计
│   ├── implementation-plan.md       # 实施计划
│   └── testing-validation.md        # 测试验证
│
├── plugin-platform/                  # 插件平台规范
│   ├── design.md                    # 设计文档
│   ├── requirements.md              # 需求文档
│   └── tasks.md                     # 任务清单
│
├── external-plugin-system/           # 外部插件系统
│   ├── design.md                    # 设计文档
│   ├── requirements.md              # 需求文档
│   └── tasks.md                     # 任务清单
│
├── internationalization/             # 国际化
│   ├── design.md                    # 设计文档
│   ├── requirements.md              # 需求文档
│   └── tasks.md                     # 任务清单
│
└── web-platform-compatibility/      # Web平台兼容性
    ├── design.md                    # 设计文档
    ├── requirements.md              # 需求文档
    └── tasks.md                     # 任务清单
```

## 🎯 按需求查找文档

### 我想...

#### 快速上手项目
👉 [项目 README](../README.md)
👉 [快速开始指南](guides/getting-started.md)

#### 开发插件
👉 [内部插件开发指南](guides/internal-plugin-development.md)
👉 [外部插件开发指南](guides/external-plugin-development.md)
👉 [插件SDK指南](guides/plugin-sdk-guide.md)

#### 了解平台服务
👉 [平台服务快速开始](platform-services/PLATFORM_SERVICES_README.md)
👉 [平台服务用户指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)
👉 [平台服务文档中心](platform-services/README.md)

#### 查看特定插件文档
👉 [截图插件](plugins/screenshot/README.md)
👉 [世界时钟插件](plugins/world-clock/README.md)

#### 了解技术设计
👉 [平台解耦架构设计](PLATFORM_DECOUPLING_DESIGN.md)
👉 [插件平台架构](../.kiro/specs/plugin-platform/design.md)
👉 [平台服务架构](../.kiro/specs/platform-services/design.md)
👉 [外部插件系统](../.kiro/specs/external-plugin-system/design.md)

#### 查看发布信息
👉 [变更日志](../CHANGELOG.md)
👉 [发布说明](releases/RELEASE_NOTES_v0.2.1.md)

#### 查看实施报告
👉 [平台服务实施完成](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)
👉 [世界时钟实现文档](plugins/world-clock/IMPLEMENTATION.md)

#### 排除问题
👉 [故障排除指南](troubleshooting/)
👉 [平台服务故障排除](guides/PLATFORM_SERVICES_USER_GUIDE.md#🐛-故障排除)

#### 迁移升级
👉 [通用迁移指南](migration/migration-guide.md)
👉 [平台环境迁移](migration/platform-environment-migration.md)

#### 查看示例
👉 [内置插件示例](examples/built-in-plugins.md)
👉 [Dart计算器示例](examples/dart-calculator.md)
👉 [Python天气插件示例](examples/python-weather.md)

#### 使用桌面宠物
👉 [桌面宠物使用指南](guides/desktop-pet-usage.md)
👉 [桌面宠物平台支持](guides/desktop-pet-platform-support.md)

#### 集成后端
👉 [后端集成指南](guides/backend-integration.md)

#### 使用CLI工具
👉 [插件CLI工具](tools/plugin-cli.md)

## 📖 文档分类

### 1. 入门文档
**适合**: 新用户、快速了解项目
- [项目 README](../README.md)
- [快速开始指南](guides/getting-started.md)
- [项目结构说明](project-structure.md)

### 2. 开发指南
**适合**: 插件开发者、平台开发者
- [内部插件开发指南](guides/internal-plugin-development.md)
- [外部插件开发指南](guides/external-plugin-development.md)
- [插件SDK指南](guides/plugin-sdk-guide.md)
- [平台服务用户指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)

### 3. 技术规范
**适合**: 架构师、高级开发者
- [平台解耦架构设计](PLATFORM_DECOUPLING_DESIGN.md)
- [插件平台架构](../.kiro/specs/plugin-platform/design.md)
- [平台服务架构](../.kiro/specs/platform-services/design.md)
- [外部插件系统](../.kiro/specs/external-plugin-system/design.md)
- [国际化设计](../.kiro/specs/internationalization/design.md)
- [Web兼容性](../.kiro/specs/web-platform-compatibility/design.md)

### 4. 实施报告
**适合**: 项目经理、技术审查
- [平台服务阶段0](reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md)
- [平台服务阶段1](reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md)
- [平台服务实施完成](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)
- [世界时钟实现](plugins/world-clock/IMPLEMENTATION.md)
- [世界时钟更新](plugins/world-clock/UPDATE_v1.1.md)
- [修复报告](reports/FIXES_WORLD_CLOCK_v1.1.md)
- [插件ID修复](reports/PLUGIN_ID_FIX_SUMMARY.md)

### 5. 发布文档
**适合**: 所有用户、版本管理
- [变更日志](../CHANGELOG.md)
- [发布说明](releases/RELEASE_NOTES_v0.2.1.md)

### 6. 参考文档
**适合**: 查阅具体信息
- [平台回退值](reference/platform-fallback-values.md)
- [内置插件示例](examples/built-in-plugins.md)

### 7. 迁移指南
**适合**: 版本升级、平台迁移
- [通用迁移指南](migration/migration-guide.md)
- [平台环境迁移](migration/platform-environment-migration.md)

### 8. 故障排除
**适合**: 遇到问题时
- [桌面宠物修复](troubleshooting/desktop-pet-fix.md)

### 9. 工具文档
**适合**: 使用开发工具
- [插件CLI工具](tools/plugin-cli.md)

## 🔍 特殊功能文档

### 平台服务
**位置**: [platform-services/](platform-services/)

核心功能：
- ✅ 通知服务
- 🔊 音频服务
- ⏰ 任务调度服务

**快速链接**:
- [快速开始](platform-services/PLATFORM_SERVICES_README.md)
- [用户指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)
- [文档中心](platform-services/README.md)

### 插件系统
**位置**: [guides/](guides/)

插件类型：
- 🔌 内部插件（Dart）
- 🌐 外部插件（Python, JS, Java, C++）
- 📱 移动端插件
- 🖥️ 桌面端插件

**快速链接**:
- [内部插件开发](guides/internal-plugin-development.md)
- [外部插件开发](guides/external-plugin-development.md)

### 桌面宠物
**位置**: [guides/desktop-pet-*.md](guides/)

支持平台：
- ✅ Windows
- ✅ macOS
- ✅ Linux

**快速链接**:
- [使用指南](guides/desktop-pet-usage.md)
- [平台支持](guides/desktop-pet-platform-support.md)

### 截图插件
**位置**: [plugins/screenshot/](plugins/screenshot/)

支持平台：
- ✅ Windows (完整支持)
- 🔴 Linux (待实现)
- 🔴 macOS (待实现)
- 🟡 Android/iOS (受限支持)
- ❌ Web (不支持)

**快速链接**:
- [插件概述](plugins/screenshot/README.md)
- [平台支持分析](plugins/screenshot/PLATFORM_SUPPORT_ANALYSIS.md)
- [实现任务](plugins/screenshot/PLATFORM_TODO.md)

## 📊 文档统计

### 按类型
- **用户指南**: 8个文档
- **技术规范**: 16个文档（新增平台解耦架构设计）
- **实施报告**: 7个文档
- **插件文档**: 6个文档
- **平台服务文档**: 4个文档
- **发布文档**: 2个文档
- **其他**: 9个文档

### 按语言
- **中文**: 主导语言
- **英文**: 部分示例和API文档

## 🔄 文档维护

### 更新原则
1. **代码变更同步**: 代码变更时及时更新相关文档
2. **版本标记**: 重大更新时更新版本号和日期
3. **交叉引用**: 保持文档间的交叉引用准确
4. **示例更新**: 确保代码示例可以运行

### 文档审查清单
- [ ] 目录结构正确
- [ ] 文件位置合理
- [ ] 交叉引用准确
- [ ] 示例代码有效
- [ ] 版本信息更新

## 🔗 相关链接

- **项目仓库**: [GitHub](https://github.com/your-repo)
- **问题反馈**: [Issues](https://github.com/your-repo/issues)
- **变更日志**: [CHANGELOG.md](../CHANGELOG.md)

## 💡 文档使用建议

### 新手路线
1. 阅读 [项目 README](../README.md)
2. 跟随 [快速开始指南](guides/getting-started.md)
3. 查看 [项目结构说明](project-structure.md)
4. 尝试 [内置插件示例](examples/built-in-plugins.md)

### 开发者路线
1. 阅读 [内部插件开发指南](guides/internal-plugin-development.md)
2. 了解 [插件SDK](guides/plugin-sdk-guide.md)
3. 查看 [技术规范](../.kiro/specs/plugin-platform/design.md)
4. 参考 [示例代码](examples/)

### 平台服务路线
1. 阅读 [平台服务快速开始](platform-services/PLATFORM_SERVICES_README.md)
2. 学习 [用户指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)
3. 了解 [架构设计](../.kiro/specs/platform-services/design.md)
4. 查看 [实施报告](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)

---

**文档版本**: v1.2.0
**最后更新**: 2026-01-16
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 使用 Ctrl+F (Cmd+F) 在页面中搜索关键词快速找到所需文档。
