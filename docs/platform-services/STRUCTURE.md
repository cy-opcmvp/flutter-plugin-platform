# 文档目录结构

## 📂 Platform Services 文档组织

本文档说明平台通用服务相关文档的组织结构。

## 目录结构

```
docs/
├── platform-services/              # 平台服务文档中心
│   ├── README.md                   # 📚 文档索引和导航
│   └── PLATFORM_SERVICES_README.md  # 🚀 快速开始指南
│
├── guides/                         # 用户指南
│   ├── PLATFORM_SERVICES_USER_GUIDE.md  # 完整使用指南
│   ├── desktop-pet-guide.md       # 桌面宠物使用
│   ├── external-plugin-development.md  # 外部插件开发
│   └── ...
│
└── reports/                        # 实施报告
    ├── PLATFORM_SERVICES_PHASE0_COMPLETE.md   # 阶段0总结
    ├── PLATFORM_SERVICES_PHASE1_COMPLETE.md   # 阶段1总结
    └── PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md  # 完整报告

.kiro/specs/platform-services/     # 技术规范
├── design.md                      # 架构设计
├── implementation-plan.md          # 实施计划
└── testing-validation.md          # 测试文档
```

## 📖 文档分类

### 1. 快速参考
**位置**: 根目录 `PLATFORM_SERVICES.md`

适合：快速了解项目、快速开始使用

### 2. 文档中心
**位置**: `docs/platform-services/README.md`

适合：查找所有相关文档、文档索引

### 3. 快速开始
**位置**: `docs/platform-services/PLATFORM_SERVICES_README.md`

适合：5分钟快速上手、基本使用

### 4. 用户指南
**位置**: `docs/guides/PLATFORM_SERVICES_USER_GUIDE.md`

适合：完整功能说明、API使用、故障排除

### 5. 技术文档
**位置**: `.kiro/specs/platform-services/`

适合：架构设计、接口定义、实施细节

### 6. 实施报告
**位置**: `docs/reports/`

适合：了解实施过程、验收标准、技术决策

## 🎯 按需求查找文档

### 我想...

#### 快速上手
👉 [根目录 PLATFORM_SERVICES.md](../../PLATFORM_SERVICES.md)
👉 [快速开始指南](platform-services/PLATFORM_SERVICES_README.md)

#### 了解所有可用文档
👉 [文档中心](platform-services/README.md)

#### 学习如何使用服务
👉 [用户使用指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)

#### 了解技术设计
👉 [架构设计文档](../../.kiro/specs/platform-services/design.md)
👉 [实施计划](../../.kiro/specs/platform-services/implementation-plan.md)

#### 查看实施进度
👉 [阶段0完成总结](reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md)
👉 [阶段1完成总结](reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md)
👉 [实施完成报告](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)

#### 在插件中使用服务
👉 [用户指南 - 开发者使用](guides/PLATFORM_SERVICES_USER_GUIDE.md#🧑-💻-开发者使用)

#### 测试服务
👉 [测试文档](../../.kiro/specs/platform-services/testing-validation.md)
👉 使用测试界面（应用中的 🔬 图标）

#### 排除问题
👉 [用户指南 - 故障排除](guides/PLATFORM_SERVICES_USER_GUIDE.md#🐛-故障排除)

## 📂 技术规范目录

### `.kiro/specs/platform-services/`

这个目录包含技术规范和实施细节：

- **design.md**: 服务架构设计
  - 服务接口定义
  - 架构模式
  - 平台兼容性
  - 文件结构

- **implementation-plan.md**: 分阶段实施计划
  - 任务清单
  - 验收标准
  - 进度跟踪
  - 风险管理

- **testing-validation.md**: 测试和验证
  - 测试策略
  - 测试用例
  - 覆盖率要求
  - 验收流程

## 🔄 文档维护

### 文档更新原则

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

## 📞 文档反馈

如果发现文档问题或有改进建议，请：

1. 检查文档目录结构是否合理
2. 确认文档是否在正确位置
3. 验证交叉引用是否有效
4. 提供具体的改进建议

---

**最后更新**: 2026-01-15
**维护者**: 平台服务团队
