# 文档导航指南

## 📚 平台通用服务文档导航

### 🚀 快速入口

#### 最快上手
**文件**: [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md)
- 项目概览
- 核心功能
- 快速代码示例
- 文档导航

#### 文档中心
**目录**: [docs/platform-services/](docs/platform-services/)
- 完整文档索引
- 分类导航
- 快速查找

---

## 📂 文档组织结构

```
flutter-plugin-platform/
│
├── PLATFORM_SERVICES.md              ⭐ 根目录快速入口
│
├── docs/
│   ├── platform-services/           📚 文档中心
│   │   ├── README.md                #   文档索引
│   │   ├── PLATFORM_SERVICES_README.md  #   快速开始
│   │   └── STRUCTURE.md            #   文档结构说明
│   │
│   ├── guides/                      📖 使用指南
│   │   └── PLATFORM_SERVICES_USER_GUIDE.md  #   完整指南
│   │
│   └── reports/                     📊 实施报告
│       ├── PLATFORM_SERVICES_PHASE0_COMPLETE.md
│       ├── PLATFORM_SERVICES_PHASE1_COMPLETE.md
│       └── PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md
│
└── .kiro/specs/platform-services/   🔧 技术规范
    ├── design.md                   #   架构设计
    ├── implementation-plan.md      #   实施计划
    └── testing-validation.md       #   测试文档
```

---

## 🎯 按场景查找文档

### 场景1: 我是新用户，想快速了解
👉 **步骤1**: 阅读 [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md)  
👉 **步骤2**: 查看 [快速开始指南](docs/platform-services/PLATFORM_SERVICES_README.md)  
👉 **步骤3**: 启动应用，使用测试界面体验功能

### 场景2: 我想在插件中使用服务
👉 **步骤1**: 阅读 [用户使用指南 - 开发者部分](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md#🧑-💻-开发者使用)  
👉 **步骤2**: 查看代码示例  
👉 **步骤3**: 参考 API 文档

### 场景3: 我想了解技术设计
👉 **步骤1**: 查看 [架构设计文档](.kiro/specs/platform-services/design.md)  
👉 **步骤2**: 阅读 [实施计划](.kiro/specs/platform-services/implementation-plan.md)  
👉 **步骤3**: 了解 [接口定义](lib/core/interfaces/services/)

### 场景4: 我想查看实施进度
👉 **步骤1**: 查看 [实施完成报告](docs/reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)  
👉 **步骤2**: 阅读 [阶段总结](docs/reports/)  
👉 **步骤3**: 了解测试结果

### 场景5: 我遇到了问题
👉 **步骤1**: 查看 [用户指南 - 故障排除](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md#🐛-故障排除)  
👉 **步骤2**: 检查活动日志  
👉 **步骤3**: 查看技术文档

---

## 📖 文档类型说明

### ⭐ 快速参考文档

**特点**: 简洁、快速、实用
- [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md) - 项目概览和快速入口
- [PLATFORM_SERVICES_README.md](docs/platform-services/PLATFORM_SERVICES_README.md) - 5分钟上手指南

### 📚 用户文档

**特点**: 详细、全面、易懂
- [用户使用指南](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md) - 完整的功能说明和教程

### 🔧 技术文档

**特点**: 专业、深入、全面
- [架构设计](.kiro/specs/platform-services/design.md) - 服务设计和接口定义
- [实施计划](.kiro/specs/platform-services/implementation-plan.md) - 实施细节和任务清单
- [测试文档](.kiro/specs/platform-services/testing-validation.md) - 测试策略和用例

### 📊 报告文档

**特点**: 总结性、成果展示
- [阶段0完成总结](docs/reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md) - 准备阶段报告
- [阶段1完成总结](docs/reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md) - 核心服务报告
- [实施完成报告](docs/reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md) - 完整实施报告

---

## 🗂️ 建议的阅读顺序

### 对于新用户
1. [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md) - 了解项目
2. [快速开始指南](docs/platform-services/PLATFORM_SERVICES_README.md) - 快速上手
3. [用户使用指南](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md) - 深入学习

### 对于开发者
1. [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md) - 项目概览
2. [架构设计](.kiro/specs/platform-services/design.md) - 理解设计
3. [用户使用指南 - 开发者部分](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md#🧑-💻-开发者使用) - 学习使用
4. [实施计划](.kiro/specs/platform-services/implementation-plan.md) - 了解实现

### 对于架构师
1. [架构设计](.kiro/specs/platform-services/design.md) - 理解架构
2. [实施计划](.kiro/specs/platform-services/implementation-plan.md) - 查看规划
3. [测试文档](.kiro/specs/platform-services/testing-validation.md) - 了解测试
4. [实施完成报告](docs/reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md) - 查看成果

---

## 🔍 快速查找技巧

### 使用 IDE 搜索
在 IDE 中按 `Ctrl+Shift+F` 搜索关键词：
- 搜索 "NotificationService" 查找通知服务相关文档
- 搜索 "快速开始" 找到快速入门指南
- 搜索 "故障排除" 找到问题解决方案

### 按文件类型查找
- 接口定义: `lib/core/interfaces/services/*.dart`
- 服务实现: `lib/core/services/*/*.dart`
- 用户指南: `docs/guides/*_GUIDE.md`
- 技术规范: `.kiro/specs/platform-services/*.md`

---

## 📞 获取帮助

### 文档问题
如果发现文档错误或需要改进，请查看：
- [文档结构说明](docs/platform-services/STRUCTURE.md)

### 技术问题
1. 查看 [用户使用指南](docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)
2. 检查活动日志
3. 查看测试界面

### 反馈渠道
- 查看项目主 README
- 提交 Issue 或 PR

---

**最后更新**: 2026-01-15
**文档版本**: v1.0.0
