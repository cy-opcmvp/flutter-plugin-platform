# 平台通用服务 - 用户使用指南

## 📖 概述

平台通用服务为 Flutter Plugin Platform 提供了一套跨平台的核心功能，包括通知、音频播放和任务调度。所有插件都可以通过统一接口访问这些服务。

## 🚀 快速开始

### 1. 启动应用

应用启动时会自动初始化所有平台服务：

```dart
// 在 main.dart 中
final servicesInitialized = await PlatformServiceManager.initialize();
```

### 2. 访问测试界面

在主界面右上角，点击 **🔬 科学实验** 图标，进入服务测试界面。

## 🧪 测试界面功能

测试界面包含三个标签页，每个标签页对应一个核心服务：

### 🔔 通知服务测试

**功能**:
- 检查通知权限状态
- 请求通知权限
- 显示即时通知
- 显示定时通知（5秒后）
- 取消所有通知

**测试步骤**:
1. 查看"通知权限"状态卡片
2. 如果未授权，点击"请求权限"按钮
3. 在输入框中自定义通知标题和内容
4. 点击"显示立即"查看即时通知
5. 点击"计划(5s)"设置5秒后的通知
6. 点击"取消全部"清除所有通知

**验证要点**:
- ✅ 通知权限正确授予
- ✅ 通知正确显示
- ✅ 定时通知准时触发
- ✅ 通知点击事件响应

### 🔊 音频服务测试

**功能**:
- 测试各种系统提示音
  - 通知音
  - 成功音
  - 错误音
  - 警告音
  - 点击音
- 调节全局音量
- 停止所有音频播放

**测试步骤**:
1. 点击任意系统音效按钮
2. 验证声音正确播放
3. 调节音量滑块
4. 再次播放音效验证音量变化
5. 点击"停止所有音频"停止播放

**验证要点**:
- ✅ 所有音效正确播放
- ✅ 音量调节生效
- ✅ 音频播放流畅无卡顿
- ✅ 停止功能正常工作

**注意事项**:
⚠️ 音频文件需要放在 `assets/audio/` 目录：
- `notification.mp3`
- `alarm.mp3`
- `click.mp3`
- `success.mp3`
- `error.mp3`
- `warning.mp3`

如果音频文件缺失，播放会报错。

### ⏰ 任务调度测试

**功能**:
- 倒计时定时器
- 周期性任务
- 查看活动任务列表
- 取消任务

**倒计时测试**:
1. 在"倒计时定时器"卡片中输入秒数（默认10秒）
2. 点击"开始"按钮
3. 观察倒计时显示
4. 倒计时结束时：
   - 播放提示音
   - 显示通知
   - 日志记录完成事件

**周期性任务测试**:
1. 在"周期性任务"卡片中输入间隔秒数（默认5秒）
2. 点击"开始"按钮
3. 观察日志中周期性任务执行记录
4. 点击"停止"按钮取消任务

**活动任务管理**:
- 在"活动任务"卡片中查看所有活动任务
- 点击任务右侧的取消按钮可单独取消
- 实时更新任务列表

## 📊 活动日志

测试界面底部有一个活动日志面板，实时显示所有操作和事件：

- ✅ 绿色日志：成功操作
- ❌ 红色日志：错误信息
- 🔄 蓝色日志：周期性事件

点击"清除"按钮可清空日志。

## 🔧 开发者使用

### 在插件中使用服务

#### 1. 访问服务管理器

```dart
import 'package:plugin_platform/core/services/platform_service_manager.dart';

// 获取通知服务
final notification = PlatformServiceManager.notification;

// 获取音频服务
final audio = PlatformServiceManager.audio;

// 获取任务调度服务
final taskScheduler = PlatformServiceManager.taskScheduler;
```

#### 2. 发送通知

```dart
await PlatformServiceManager.notification.showNotification(
  id: 'unique_notification_id',
  title: '任务完成',
  body: '您的任务已成功完成',
  priority: NotificationPriority.high,
);
```

#### 3. 播放音效

```dart
// 播放系统音效
await PlatformServiceManager.audio.playSystemSound(
  soundType: SystemSoundType.success,
);

// 播放自定义音效
await PlatformServiceManager.audio.playSound(
  soundPath: 'assets/audio/custom.mp3',
  volume: 0.8,
);
```

#### 4. 创建倒计时

```dart
await PlatformServiceManager.taskScheduler.scheduleOneShotTask(
  taskId: 'countdown_${DateTime.now().millisecondsSinceEpoch}',
  scheduledTime: DateTime.now().add(Duration(minutes: 5)),
  callback: (data) async {
    // 倒计时完成时的操作
    await PlatformServiceManager.audio
        .playSystemSound(soundType: SystemSoundType.notification);

    await PlatformServiceManager.notification.showNotification(
      id: 'countdown_complete',
      title: '倒计时完成',
      body: '您的5分钟倒计时已结束',
    );
  },
);
```

#### 5. 创建周期性任务

```dart
await PlatformServiceManager.taskScheduler.schedulePeriodicTask(
  taskId: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
  interval: Duration(minutes: 15),
  callback: (data) async {
    // 每15分钟执行一次
    await PlatformServiceManager.audio
        .playSystemSound(soundType: SystemSoundType.click);
  },
);
```

### 服务初始化检查

```dart
// 检查服务是否可用
if (PlatformServiceManager.isServiceAvailable<INotificationService>()) {
  // 服务可用
  final notification = PlatformServiceManager.notification;
  // 使用服务...
}
```

## 🐛 故障排除

### 通知不显示

**可能原因**:
1. 通知权限未授予
2. 应用被系统限制后台通知

**解决方法**:
1. 在测试界面检查通知权限状态
2. 进入系统设置，允许应用发送通知
3. 检查系统的"勿扰模式"

### 音频无法播放

**可能原因**:
1. 音频文件不存在
2. 音频文件格式不支持
3. 设备音量为静音

**解决方法**:
1. 确认 `assets/audio/` 目录中有所需的音频文件
2. 检查 `pubspec.yaml` 中资源配置是否正确
3. 检查设备音量和应用音量设置
4. 查看活动日志中的错误信息

### 任务不执行

**可能原因**:
1. 任务时间已过期
2. 任务调度器未正确初始化

**解决方法**:
1. 确保设置的未来时间有效
2. 查看活动日志中的任务执行记录
3. 检查任务是否在"活动任务"列表中

## 📝 实际应用示例

### 世界时钟倒计时

```dart
// 在世界时钟插件中
Future<void> createCountdown(Duration duration) async {
  final targetTime = DateTime.now().add(duration);

  await PlatformServiceManager.taskScheduler.scheduleOneShotTask(
    taskId: 'countdown_${clockId}_${DateTime.now().millisecondsSinceEpoch}',
    scheduledTime: targetTime,
    callback: (data) async {
      // 倒计时完成
      await PlatformServiceManager.audio
          .playSystemSound(soundType: SystemSoundType.notification);

      await PlatformServiceManager.notification.showNotification(
        id: 'countdown_complete',
        title: '倒计时完成',
        body: '时钟 $clockId 的倒计时已结束',
        priority: NotificationPriority.high,
      );
    },
  );
}
```

### 提醒事项

```dart
// 创建提醒
Future<void> createReminder(String title, DateTime when) async {
  await PlatformServiceManager.notification.scheduleNotification(
    id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    body: '您有一个提醒',
    scheduledTime: when,
    priority: NotificationPriority.high,
  );

  await PlatformServiceManager.audio.playSystemSound(
    soundType: SystemSoundType.success,
  );
}
```

### 操作反馈

```dart
// 用户操作成功时
Future<void> showSuccessFeedback() async {
  await PlatformServiceManager.audio.playSystemSound(
    soundType: SystemSoundType.success,
  );

  await PlatformServiceManager.notification.showNotification(
    id: 'operation_success',
    title: '操作成功',
    body: '您的操作已成功完成',
    priority: NotificationPriority.low,
  );
}

// 用户操作失败时
Future<void> showErrorFeedback(String error) async {
  await PlatformServiceManager.audio.playSystemSound(
    soundType: SystemSoundType.error,
  );

  await PlatformServiceManager.notification.showNotification(
    id: 'operation_error',
    title: '操作失败',
    body: error,
    priority: NotificationPriority.high,
  );
}
```

## 🎯 最佳实践

### 1. 权限管理

在需要通知的功能前，先检查并请求权限：

```dart
final hasPermission = await PlatformServiceManager.notification.checkPermissions();
if (!hasPermission) {
  final granted = await PlatformServiceManager.notification.requestPermissions();
  if (!granted) {
    // 处理权限被拒绝的情况
    return;
  }
}
```

### 2. 错误处理

所有服务调用都应包含错误处理：

```dart
try {
  await PlatformServiceManager.notification.showNotification(...);
} catch (e) {
  // 优雅地处理错误
  debugPrint('Error showing notification: $e');
}
```

### 3. 资源清理

周期性任务和长时间运行的音频应在适当时机清理：

```dart
// 在插件 dispose 时
@override
Future<void> dispose() async {
  // 取消所有相关任务
  for (final taskId in myTaskIds) {
    await PlatformServiceManager.taskScheduler.cancelTask(taskId);
  }

  // 停止所有音频
  await PlatformServiceManager.audio.stopAll();

  super.dispose();
}
```

### 4. 用户体验

- 使用合适的优先级（避免所有通知都是高优先级）
- 提供有意义的标题和内容
- 考虑添加音效但不滥用
- 允许用户自定义通知设置

## 📚 API 参考

### INotificationService

| 方法 | 说明 |
|------|------|
| `initialize()` | 初始化服务 |
| `checkPermissions()` | 检查权限 |
| `requestPermissions()` | 请求权限 |
| `showNotification(...)` | 显示即时通知 |
| `scheduleNotification(...)` | 显示定时通知 |
| `cancelNotification(id)` | 取消通知 |
| `cancelAllNotifications()` | 取消所有通知 |

### IAudioService

| 方法 | 说明 |
|------|------|
| `initialize()` | 初始化服务 |
| `playSound(...)` | 播放音效 |
| `playSystemSound(...)` | 播放系统音效 |
| `playMusic(...)` | 播放音乐 |
| `stopMusic(playerId)` | 停止音乐 |
| `setGlobalVolume(volume)` | 设置全局音量 |
| `stopAll()` | 停止所有音频 |

### ITaskSchedulerService

| 方法 | 说明 |
|------|------|
| `initialize()` | 初始化服务 |
| `scheduleOneShotTask(...)` | 调度一次性任务 |
| `schedulePeriodicTask(...)` | 调度周期性任务 |
| `cancelTask(taskId)` | 取消任务 |
| `cancelAllTasks()` | 取消所有任务 |
| `getActiveTasks()` | 获取活动任务 |
| `pauseTask(taskId)` | 暂停任务 |
| `resumeTask(taskId)` | 恢复任务 |

## 🔗 相关文档

- [设计文档](.kiro/specs/platform-services/design.md)
- [实施计划](.kiro/specs/platform-services/implementation-plan.md)
- [测试文档](.kiro/specs/platform-services/testing-validation.md)

## 💡 提示

- 测试界面非常适合快速验证服务功能
- 查看活动日志可以帮助调试问题
- 所有操作都有日志记录，便于追踪
- 服务是跨平台的，代码在不同平台上表现一致
