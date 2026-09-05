# 平台通用服务实施计划

## 📋 项目概述

**项目名称**: Platform Common Services Implementation
**目标**: 为 Flutter Plugin Platform 实现一套完整的通用服务架构
**预计工期**: 4-6 周（分 3 个阶段）

---

## 🎯 阶段划分

### 阶段 0: 准备阶段（1-2 天）
### 阶段 1: 核心服务实现（2-3 周）
### 阶段 2: 增强服务实现（1-2 周）
### 阶段 3: 集成与优化（1 周）

---

## 📦 阶段 0: 准备阶段

### 目标
- 环境准备
- 依赖配置
- 项目结构搭建

### 任务清单

#### Task 0.1: 依赖包配置
**文件**: `pubspec.yaml`

**操作**:
```yaml
dependencies:
  # === 第一阶段：核心服务 ===
  flutter_local_notifications: ^17.2.3
  audioplayers: ^6.1.0
  permission_handler: ^11.3.1

  # === 第二阶段：增强服务 ===
  vibration: ^2.0.0
  tray_manager: ^0.2.2

  # === 现有依赖（保持不变）===
  # ... 其他依赖

dev_dependencies:
  # 测试依赖
  mockito: ^5.4.2
  build_runner: ^2.4.7
```

**验证步骤**:
1. 运行 `flutter pub get`
2. 检查无依赖冲突
3. 运行 `flutter doctor` 确保环境正常

**验收标准**:
- ✅ 所有依赖成功安装
- ✅ 无版本冲突警告
- ✅ 支持目标平台（Android/iOS/Windows/macOS/Linux）

---

#### Task 0.2: 创建项目结构
**目标**: 创建服务文件结构

**操作**:
```bash
# 创建接口目录
mkdir -p lib/core/interfaces/services

# 创建服务实现目录
mkdir -p lib/core/services/notification
mkdir -p lib/core/services/audio
mkdir -p lib/core/services/task_scheduler
mkdir -p lib/core/services/haptic
mkdir -p lib/core/services/system_tray
mkdir -p lib/core/services/permission

# 创建模型目录
mkdir -p lib/core/models
```

**验证步骤**:
1. 检查所有目录创建成功
2. 在每个目录创建 `.gitkeep` 文件

**验收标准**:
- ✅ 目录结构与设计文档一致
- ✅ 所有目录可访问

---

#### Task 0.3: 创建服务定位器基础
**文件**: `lib/core/services/service_locator.dart`

**操作**: 实现设计文档中的 `ServiceLocator` 类

**验证步骤**:
1. 创建单元测试 `test/core/services/service_locator_test.dart`
2. 测试服务注册和获取
3. 测试服务注销和释放

**验收标准**:
- ✅ 单例模式正常工作
- ✅ 服务注册和获取功能正常
- ✅ 服务释放无内存泄漏

---

## 🚀 阶段 1: 核心服务实现

### 1.1 通知服务 (INotificationService)

#### Task 1.1.1: 创建通知服务接口
**文件**: `lib/core/interfaces/services/i_notification_service.dart`

**操作**:
1. 定义 `INotificationService` 接口
2. 定义相关枚举和模型类
3. 添加详细文档注释

**验收标准**:
- ✅ 接口定义完整
- ✅ 包含所有设计方法
- ✅ 文档注释完整

---

#### Task 1.1.2: 实现通知服务基础类
**文件**: `lib/core/services/notification/notification_service.dart`

**操作**:
1. 实现 `NotificationServiceImpl` 基础类
2. 使用 `flutter_local_notifications` 包
3. 实现平台检测逻辑

**关键代码**:
```dart
class NotificationServiceImpl implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<bool> initialize() async {
    // 初始化逻辑
  }

  @override
  Future<void> showNotification({...}) async {
    // 显示通知逻辑
  }
}
```

**验收标准**:
- ✅ 类实现接口所有方法
- ✅ 平台检测正确
- ✅ 编译无错误

---

#### Task 1.1.3: 配置 Android 平台
**文件**: `android/app/src/main/AndroidManifest.xml`

**操作**:
```xml
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application ...>
        <!-- 添加通知配置 -->
    </application>
</manifest>
```

**文件**: `android/app/src/main/res/drawable/`
创建通知图标资源

**验收标准**:
- ✅ 权限配置正确
- ✅ 通知图标资源存在
- ✅ Android 编译成功

---

#### Task 1.1.4: 配置 iOS 平台
**文件**: `ios/Runner/Info.plist`

**操作**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

**文件**: `ios/Runner/AppDelegate.swift`
添加通知权限请求

**验收标准**:
- ✅ 后台模式配置正确
- ✅ 通知权限请求正常
- ✅ iOS 编译成功

---

#### Task 1.1.5: 实现平台特定实现
**文件**:
- `lib/core/services/notification/notification_service_android.dart`
- `lib/core/services/notification/notification_service_ios.dart`
- `lib/core/services/notification/notification_service_desktop.dart`
- `lib/core/services/notification/notification_service_web.dart`

**操作**: 实现各平台特定的通知逻辑

**验收标准**:
- ✅ 每个平台实现完整
- ✅ 条件导入正确
- ✅ 平台特性正确使用

---

#### Task 1.1.6: 通知服务测试
**文件**: `test/core/services/notification_service_test.dart`

**测试用例**:
```dart
group('NotificationService Tests', () {
  test('should initialize successfully', () async {
    // 测试初始化
  });

  test('should show notification', () async {
    // 测试显示通知
  });

  test('should schedule notification', () async {
    // 测试定时通知
  });

  test('should cancel notification', () async {
    // 测试取消通知
  });

  test('should check permissions', () async {
    // 测试权限检查
  });
});
```

**验收标准**:
- ✅ 所有测试用例通过
- ✅ 覆盖率 > 80%
- ✅ 无 Mock 外部依赖

---

#### Task 1.1.7: 通知服务集成测试
**文件**: `integration_test/notification_service_integration_test.dart`

**测试场景**:
1. 显示即时通知
2. 显示定时通知
3. 点击通知处理
4. 权限请求流程

**验收标准**:
- ✅ 在真实设备/模拟器上通过
- ✅ 通知正确显示
- ✅ 点击事件正确触发

---

### 1.2 音频服务 (IAudioService)

#### Task 1.2.1: 创建音频服务接口
**文件**: `lib/core/interfaces/services/i_audio_service.dart`

**操作**:
1. 定义 `IAudioService` 接口
2. 定义 `SystemSoundType` 枚举
3. 定义音频相关模型

**验收标准**:
- ✅ 接口定义完整
- ✅ 文档注释完整

---

#### Task 1.2.2: 实现音频服务
**文件**: `lib/core/services/audio/audio_service.dart`

**操作**:
1. 使用 `audioplayers` 包实现音频播放
2. 实现音频池管理（避免重叠）
3. 实现音量控制

**关键代码**:
```dart
class AudioServiceImpl implements IAudioService {
  final Map<String, AudioPlayer> _players = {};
  final Map<SystemSoundType, String> _systemSounds = {};

  @override
  Future<void> playSound({required String soundPath, ...}) async {
    // 播放音效逻辑
  }

  @override
  Future<void> playSystemSound({required SystemSoundType soundType, ...}) async {
    // 播放系统音效
  }
}
```

**验收标准**:
- ✅ 音频播放正常
- ✅ 音量控制正常
- ✅ 音频池管理无泄漏

---

#### Task 1.2.3: 添加音频资源
**目录**: `assets/audio/`

**操作**:
1. 添加系统提示音文件：
   - `notification.mp3`
   - `success.mp3`
   - `error.mp3`
   - `warning.mp3`
   - `click.mp3`

2. 配置 `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
```

**验收标准**:
- ✅ 音频文件存在
- ✅ 资源路径配置正确
- ✅ 音频文件可正常播放

---

#### Task 1.2.4: 音频服务测试
**文件**: `test/core/services/audio_service_test.dart`

**测试用例**:
```dart
group('AudioService Tests', () {
  test('should play sound', () async {
    // 测试播放音效
  });

  test('should play system sound', () async {
    // 测试播放系统音效
  });

  test('should control volume', () async {
    // 测试音量控制
  });

  test('should manage audio pool', () async {
    // 测试音频池管理
  });

  test('should stop all sounds', () async {
    // 测试停止所有音频
  });
});
```

**验收标准**:
- ✅ 所有测试用例通过
- ✅ 音频播放无内存泄漏
- ✅ 音频池正确回收资源

---

### 1.3 任务调度服务 (ITaskSchedulerService)

#### Task 1.3.1: 创建任务调度服务接口
**文件**: `lib/core/interfaces/services/i_task_scheduler_service.dart`

**操作**:
1. 定义 `ITaskSchedulerService` 接口
2. 定义任务相关模型
3. 定义任务回调类型

**验收标准**:
- ✅ 接口定义完整
- ✅ 任务模型设计合理

---

#### Task 1.3.2: 实现任务调度器核心
**文件**: `lib/core/services/task_scheduler/task_scheduler_service.dart`

**操作**:
1. 使用 Dart 的 `Timer` 实现调度
2. 使用 `Isolate` 处理后台任务
3. 实现任务持久化（使用 `shared_preferences`）

**关键代码**:
```dart
class TaskSchedulerServiceImpl implements ITaskSchedulerService {
  final Map<String, ScheduledTask> _tasks = {};
  final StreamController<TaskEvent> _completeController = StreamController.broadcast();
  final StreamController<TaskEvent> _failedController = StreamController.broadcast();

  @override
  Future<String> scheduleOneShotTask({...}) async {
    // 实现一次性任务
  }

  @override
  Future<String> schedulePeriodicTask({...}) async {
    // 实现周期性任务
  }
}
```

**验收标准**:
- ✅ 任务调度准确
- ✅ 任务持久化正常
- ✅ 后台执行正常

---

#### Task 1.3.3: 实现任务持久化
**文件**: `lib/core/services/task_scheduler/task_persistence.dart`

**操作**:
1. 使用 `shared_preferences` 存储任务
2. 实现任务序列化/反序列化
3. 应用启动时恢复未完成任务

**验收标准**:
- ✅ 任务正确保存
- ✅ 应用重启后任务恢复
- ✅ 过期任务正确清理

---

#### Task 1.3.4: 任务调度服务测试
**文件**: `test/core/services/task_scheduler_service_test.dart`

**测试用例**:
```dart
group('TaskSchedulerService Tests', () {
  test('should schedule one-shot task', () async {
    // 测试一次性任务
  });

  test('should schedule periodic task', () async {
    // 测试周期性任务
  });

  test('should cancel task', () async {
    // 测试取消任务
  });

  test('should persist tasks', () async {
    // 测试任务持久化
  });

  test('should restore tasks after restart', () async {
    // 测试任务恢复
  });
});
```

**验收标准**:
- ✅ 所有测试用例通过
- ✅ 任务调度时间准确
- ✅ 持久化功能正常

---

### 1.4 服务集成

#### Task 1.4.1: 增强平台服务接口
**文件**: `lib/core/interfaces/i_platform_services.dart`

**操作**:
1. 在现有接口中添加新服务访问器
2. 添加 `isServiceAvailable<T>()` 方法

**验收标准**:
- ✅ 接口向后兼容
- ✅ 新方法定义完整

---

#### Task 1.4.2: 实现平台服务聚合器
**文件**: `lib/core/services/platform_services.dart`

**操作**:
1. 实现 `PlatformServicesImpl` 类
2. 集成所有服务
3. 实现 `isServiceAvailable<T>()` 方法

**验收标准**:
- ✅ 所有服务正确集成
- ✅ 服务获取逻辑正确
- ✅ 空值处理正确

---

#### Task 1.4.3: 注册服务到定位器
**文件**: `lib/main.dart`

**操作**:
```dart
Future<void> initializeServices() async {
  final locator = ServiceLocator.instance;

  // 注册核心服务
  locator.registerSingleton<INotificationService>(
    NotificationServiceImpl(),
  );
  locator.registerSingleton<IAudioService>(
    AudioServiceImpl(),
  );
  locator.registerSingleton<ITaskSchedulerService>(
    TaskSchedulerServiceImpl(),
  );

  // 初始化所有服务
  await locator.get<INotificationService>().initialize();
  await locator.get<IAudioService>().initialize();
  await locator.get<ITaskSchedulerService>().initialize();
}
```

**验收标准**:
- ✅ 所有服务成功注册
- ✅ 服务初始化顺序正确
- ✅ 应用启动无错误

---

#### Task 1.4.4: 更新插件接口
**文件**: `lib/core/interfaces/i_plugin.dart`

**操作**:
更新 `PluginContext` 以提供新的服务访问

**验收标准**:
- ✅ 插件可以访问新服务
- ✅ 向后兼容现有插件

---

## 🔧 阶段 2: 增强服务实现

### 2.1 震动反馈服务 (IHapticService)

#### Task 2.1.1: 创建震动服务接口
**文件**: `lib/core/interfaces/services/i_haptic_service.dart`

**操作**: 定义震动服务接口

**验收标准**:
- ✅ 接口定义完整
- ✅ 包含所有震动类型

---

#### Task 2.1.2: 实现震动服务
**文件**: `lib/core/services/haptic/haptic_service.dart`

**操作**:
1. 使用 `vibration` 包实现
2. 实现平台检测（仅移动端）

**验收标准**:
- ✅ Android 震动正常
- ✅ iOS 触觉反馈正常
- ✅ 桌面平台优雅降级

---

#### Task 2.1.3: 震动服务测试
**文件**: `test/core/services/haptic_service_test.dart`

**验收标准**:
- ✅ 移动端测试通过
- ✅ 桌面端降级测试通过

---

### 2.2 系统托盘服务 (ISystemTrayService)

#### Task 2.2.1: 创建系统托盘接口
**文件**: `lib/core/interfaces/services/i_system_tray_service.dart`

**操作**: 定义系统托盘服务接口

**验收标准**:
- ✅ 接口定义完整
- ✅ 包含托盘菜单功能

---

#### Task 2.2.2: 实现系统托盘服务
**文件**: `lib/core/services/system_tray/system_tray_service.dart`

**操作**:
1. 使用 `tray_manager` 包实现
2. 实现各平台特定逻辑

**验收标准**:
- ✅ Windows 托盘正常
- ✅ macOS 托盘正常
- ✅ Linux 托盘正常
- ✅ 移动平台优雅降级

---

#### Task 2.2.3: 添加托盘图标资源
**目录**: `assets/icons/tray/`

**操作**:
1. 添加各平台托盘图标
2. 配置 `pubspec.yaml`

**验收标准**:
- ✅ 图标资源完整
- ✅ 各平台图标显示正常

---

#### Task 2.2.4: 系统托盘服务测试
**文件**: `test/core/services/system_tray_service_test.dart`

**验收标准**:
- ✅ 桌面端测试通过
- ✅ 移动端降级测试通过

---

### 2.3 权限管理服务增强 (IPermissionManager)

#### Task 2.3.1: 增强权限管理接口
**文件**: `lib/core/interfaces/services/i_permission_manager.dart`

**操作**:
1. 扩展现有权限接口
2. 添加新权限类型
3. 添加权限状态枚举

**验收标准**:
- ✅ 接口向后兼容
- ✅ 新功能定义完整

---

#### Task 2.3.2: 实现权限管理服务
**文件**: `lib/core/services/permission/permission_manager.dart`

**操作**:
1. 使用 `permission_handler` 包
2. 实现真实的权限请求
3. 实现权限状态持久化

**验收标准**:
- ✅ 权限请求正常
- ✅ 权限状态正确
- ✅ 权限被拒处理正确

---

#### Task 2.3.3: 创建权限请求 UI
**文件**: `lib/ui/widgets/permission_request_dialog.dart`

**操作**:
创建统一的权限请求对话框

**验收标准**:
- ✅ UI 友好
- ✅ 说明清晰
- ✅ 支持跳转到设置

---

## ✅ 阶段 3: 集成与优化

### 3.1 世界时钟插件集成

#### Task 3.1.1: 世界时钟倒计时通知
**文件**: `lib/plugins/world_clock/world_clock_plugin.dart`

**操作**:
1. 使用 `TaskSchedulerService` 管理倒计时
2. 倒计时结束时触发通知
3. 播放提示音

**验收标准**:
- ✅ 倒计时准确
- ✅ 通知正常显示
- ✅ 提示音正常播放
- ✅ 震动反馈（移动端）

---

#### Task 3.1.2: 世界时钟闹钟功能
**文件**: `lib/plugins/world_clock/world_clock_plugin.dart`

**操作**:
1. 实现闹钟功能
2. 使用 `TaskSchedulerService` 调度
3. 闹钟触发时显示通知

**验收标准**:
- ✅ 闹钟准时触发
- ✅ 通知正常显示
- ✅ 支持多个闹钟

---

### 3.2 桌面宠物插件集成

#### Task 3.2.1: 桌面宠物系统托盘集成
**文件**: `lib/core/services/desktop_pet_manager.dart`

**操作**:
1. 使用 `SystemTrayService` 添加托盘图标
2. 实现托盘菜单（显示/隐藏/退出）
3. 托盘气泡通知

**验收标准**:
- ✅ 托盘图标显示正常
- ✅ 菜单功能正常
- ✅ 气泡通知正常

---

### 3.3 性能优化

#### Task 3.3.1: 服务初始化优化
**目标**: 优化应用启动时间

**操作**:
1. 实现服务延迟初始化
2. 非关键服务后台加载
3. 添加初始化进度指示

**验收标准**:
- ✅ 启动时间 < 3 秒
- ✅ 用户体验流畅

---

#### Task 3.3.2: 内存优化
**目标**: 减少内存占用

**操作**:
1. 音频池大小限制
2. 任务历史自动清理
3. 通知历史限制

**验收标准**:
- ✅ 内存占用合理
- ✅ 无内存泄漏
- ✅ 长时间运行稳定

---

### 3.4 文档完善

#### Task 3.4.1: API 文档生成
**操作**:
1. 为所有公共接口添加文档注释
2. 运行 `dart doc` 生成文档
3. 发布到 GitHub Pages

**验收标准**:
- ✅ 文档完整
- ✅ 示例代码清晰
- ✅ 可在线访问

---

#### Task 3.4.2: 使用指南
**文件**: `docs/guides/platform-services-usage.md`

**操作**:
创建服务使用指南，包含：
1. 快速开始
2. 服务示例
3. 最佳实践
4. 故障排除

**验收标准**:
- ✅ 内容完整
- ✅ 示例可运行
- ✅ 易于理解

---

## 🧪 测试策略

### 单元测试
- 每个服务的独立测试
- Mock 所有外部依赖
- 目标覆盖率：> 80%

### 集成测试
- 服务间协作测试
- 真实依赖测试
- 主要平台测试

### 端到端测试
- 完整场景测试
- 真实设备测试
- 用户体验测试

---

## 📊 进度跟踪

### 每周检查点

**第 1 周**:
- ✅ Task 0.1 - 0.3 完成
- ✅ Task 1.1.1 - 1.1.3 完成

**第 2 周**:
- ✅ Task 1.1.4 - 1.1.7 完成
- ✅ Task 1.2.1 - 1.2.3 完成

**第 3 周**:
- ✅ Task 1.2.4 - 1.3.3 完成
- ✅ Task 1.3.4 - 1.4.2 完成

**第 4 周**:
- ✅ Task 1.4.3 - 1.4.4 完成
- ✅ Task 2.1.1 - 2.1.3 完成
- ✅ Task 2.2.1 - 2.2.2 完成

**第 5 周**:
- ✅ Task 2.2.3 - 2.3.3 完成
- ✅ Task 3.1.1 - 3.2.1 完成

**第 6 周**:
- ✅ Task 3.3.1 - 3.4.2 完成
- ✅ 所有测试通过
- ✅ 文档完善

---

## 🎯 验收标准

### 功能验收
- ✅ 所有核心服务正常工作
- ✅ 所有增强服务正常工作
- ✅ 世界时钟插件集成成功
- ✅ 桌面宠物插件集成成功

### 性能验收
- ✅ 应用启动时间 < 3 秒
- ✅ 内存占用合理
- ✅ 无明显性能问题

### 质量验收
- ✅ 单元测试覆盖率 > 80%
- ✅ 所有测试用例通过
- ✅ 代码审查通过
- ✅ 文档完整

---

## 🚨 风险管理

### 已知风险

**风险 1**: 第三方包兼容性问题
- **缓解**: 使用稳定版本，充分测试
- **备选**: 准备多个备选包

**风险 2**: 平台特定功能差异
- **缓解**: 早期测试各平台，提供优雅降级
- **备选**: 平台限制文档化

**风险 3**: 后台任务限制
- **缓解**: 明确文档说明，提供替代方案
- **备选**: 使用本地通知替代

---

## 📝 备注

### 开发规范
- 遵循 Flutter/Dart 代码规范
- 所有公共 API 必须有文档注释
- 提交前必须运行测试和格式化

### 协作约定
- 每个任务完成后更新状态
- 遇到问题及时沟通
- 定期代码审查

### 变更管理
- 重大变更需团队讨论
- 保持向后兼容
- 记录所有变更日志
