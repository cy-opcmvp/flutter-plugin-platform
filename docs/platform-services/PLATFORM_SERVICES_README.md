# 平台通用服务 - 快速开始

## 🚀 快速启动

### 1. 运行应用
```bash
flutter run
```

### 2. 访问服务测试界面

在主界面右上角，点击 **🔬 科学实验** 图标进入服务测试界面。

## 🧪 测试功能

### 通知服务
- ✅ 显示即时通知
- ✅ 设置定时通知（5秒后）
- ✅ 权限管理

### 音频服务
- ✅ 6种系统音效
- ✅ 音量调节
- ✅ 停止所有音频

### 任务调度
- ✅ 倒计时定时器
- ✅ 周期性任务
- ✅ 活动任务管理

## 📚 详细文档

- **[用户使用指南](PLATFORM_SERVICES_USER_GUIDE.md)** - 完整的使用说明和API文档
- **[实施完成报告](PLATFORM_SERVICES_IMPLEMENTATION_COMPLETE.md)** - 技术实施总结

## 💡 开发者快速使用

```dart
import 'package:plugin_platform/core/services/platform_service_manager.dart';

// 发送通知
await PlatformServiceManager.notification.showNotification(
  id: 'test',
  title: 'Hello',
  body: 'World',
);

// 播放音效
await PlatformServiceManager.audio.playSystemSound(
  soundType: SystemSoundType.success,
);

// 创建倒计时
await PlatformServiceManager.taskScheduler.scheduleOneShotTask(
  taskId: 'countdown',
  scheduledTime: DateTime.now().add(Duration(seconds: 10)),
  callback: (data) async {
    print('Countdown complete!');
  },
);
```

## ⚠️ 注意事项

### 音频文件
当前音频文件为占位符。要使用真实音频，请在 `assets/audio/` 目录添加：
- notification.mp3
- alarm.mp3
- click.mp3
- success.mp3
- error.mp3
- warning.mp3

### 通知权限
首次使用通知功能前，需要在测试界面中点击"请求权限"。

## 📞 支持

如有问题，请查阅详细文档或查看活动日志。

---

**版本**: v1.0.0
**状态**: ✅ 生产就绪
**日期**: 2026-01-15
