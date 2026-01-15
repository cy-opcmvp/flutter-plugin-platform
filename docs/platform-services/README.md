# 平台通用服务文档

## 📚 文档索引

### 快速开始
- **[快速开始指南](PLATFORM_SERVICES_README.md)** - 5分钟快速上手

### 使用指南
- **[用户使用指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)** - 完整的功能说明和使用教程

### 技术文档
- **[设计文档](../.kiro/specs/platform-services/design.md)** - 服务架构设计和接口定义
- **[实施计划](../.kiro/specs/platform-services/implementation-plan.md)** - 分阶段实施计划和任务清单
- **[测试文档](../.kiro/specs/platform-services/testing-validation.md)** - 测试策略和验收标准

### 实施报告
- **[阶段0完成总结](reports/PLATFORM_SERVICES_PHASE0_COMPLETE.md)** - 准备阶段完成情况
- **[阶段1完成总结](reports/PLATFORM_SERVICES_PHASE1_COMPLETE.md)** - 核心服务实施总结
- **[实施完成报告](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)** - 完整实施报告

## 🚀 快速导航

### 我想...

#### 快速上手使用
👉 [快速开始指南](PLATFORM_SERVICES_README.md)

#### 了解如何使用服务
👉 [用户使用指南](guides/PLATFORM_SERVICES_USER_GUIDE.md)

#### 了解技术设计
👉 [设计文档](../.kiro/specs/platform-services/design.md)

#### 查看实施进度
👉 [实施完成报告](reports/PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)

#### 在插件中使用服务
👉 [用户使用指南 - 开发者使用](guides/PLATFORM_SERVICES_USER_GUIDE.md#🧑-💻-开发者使用)

## 📂 代码位置

### 服务实现
- `lib/core/interfaces/services/` - 服务接口定义
- `lib/core/services/` - 服务实现代码

### 测试代码
- `test/core/interfaces/` - 单元测试
- `lib/ui/screens/service_test_screen.dart` - 手动测试界面

## 🎯 核心服务

### 1. 通知服务
**接口**: [INotificationService](../../lib/core/interfaces/services/i_notification_service.dart)
**实现**: [NotificationService](../../lib/core/services/notification/notification_service.dart)

功能：即时通知、定时通知、权限管理

### 2. 音频服务
**接口**: [IAudioService](../../lib/core/interfaces/services/i_audio_service.dart)
**实现**: [AudioService](../../lib/core/services/audio/audio_service.dart)

功能：音效播放、音乐播放、音量控制

### 3. 任务调度服务
**接口**: [ITaskSchedulerService](../../lib/core/interfaces/services/i_task_scheduler_service.dart)
**实现**: [TaskSchedulerService](../../lib/core/services/task_scheduler/task_scheduler_service.dart)

功能：倒计时、周期性任务、任务持久化

## 🧪 测试服务

### 方法1：使用测试界面
1. 启动应用：`flutter run`
2. 点击右上角 🔬 图标
3. 进入服务测试界面

### 方法2：运行单元测试
```bash
flutter test test/core/interfaces/service_locator_test.dart
```

## 📖 更多信息

- [项目主 README](../../README.md)
- [插件开发指南](../guides/plugin-development.md)
- [API 文档](../api/)

---

**版本**: v1.0.0
**最后更新**: 2026-01-15
