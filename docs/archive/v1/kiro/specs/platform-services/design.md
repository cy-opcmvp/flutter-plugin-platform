# 平台通用服务架构设计

## 1. 概述

### 1.1 设计目标

为 Flutter Plugin Platform 设计一套可扩展、易维护的通用服务架构，满足以下目标：

- **统一性**: 所有插件通过统一接口访问平台服务
- **可扩展性**: 新服务可以轻松添加，不影响现有功能
- **平台兼容**: 自动适配不同平台（移动端/桌面端/Web端）
- **低耦合**: 服务之间相互独立，通过接口通信
- **可测试**: 每个服务都可以独立测试

### 1.2 架构原则

1. **接口优先**: 所有服务通过抽象接口定义，实现可替换
2. **单例管理**: 每个服务类型只有一个实例，通过服务定位器访问
3. **生命周期管理**: 服务有明确的初始化、使用、销毁流程
4. **平台检测**: 服务自动检测平台能力，优雅降级
5. **事件驱动**: 服务通过事件流与插件通信

### 1.3 服务分层

```
┌─────────────────────────────────────────────────────┐
│                   插件层 (Plugins)                   │
│  - Calculator, WorldClock, DesktopPet, etc.        │
└──────────────────┬──────────────────────────────────┘
                   │ 使用
┌──────────────────▼──────────────────────────────────┐
│              服务接口层 (Service Interfaces)         │
│  - INotificationService, IAudioService, etc.        │
└──────────────────┬──────────────────────────────────┘
                   │ 实现
┌──────────────────▼──────────────────────────────────┐
│           服务实现层 (Service Implementations)       │
│  - NotificationService, AudioService, etc.          │
└──────────────────┬──────────────────────────────────┘
                   │ 依赖
┌──────────────────▼──────────────────────────────────┐
│         服务定位器 (Service Locator)                │
│  - ServiceLocator: 注册、获取、管理所有服务          │
└──────────────────┬──────────────────────────────────┘
                   │ 调用
┌──────────────────▼──────────────────────────────────┐
│              平台层 (Platform Layer)                │
│  - Flutter, OS APIs, Third-party packages          │
└─────────────────────────────────────────────────────┘
```

## 2. 服务定义

### 2.1 第一阶段：核心服务（必需）

#### 2.1.1 通知服务 (INotificationService)

**职责**:
- 显示系统本地通知
- 管理通知权限
- 支持即时通知和定时通知
- 通知历史管理
- 平台适配（iOS/Android/Windows/macOS/Linux）

**接口定义**:

```dart
/// 通知服务接口
abstract class INotificationService {
  /// 初始化通知服务
  Future<bool> initialize();

  /// 检查通知权限
  Future<bool> checkPermissions();

  /// 请求通知权限
  Future<bool> requestPermissions();

  /// 显示即时通知
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? sound,
  });

  /// 显示定时通知
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? sound,
  });

  /// 取消通知
  Future<void> cancelNotification(String id);

  /// 取消所有通知
  Future<void> cancelAllNotifications();

  /// 获取活动通知列表
  Future<List<ActiveNotification>> getActiveNotifications();

  /// 通知点击事件流
  Stream<NotificationEvent> get onNotificationClick;

  /// 是否已初始化
  bool get isInitialized;
}

/// 通知优先级
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// 活动通知
class ActiveNotification {
  final String id;
  final String title;
  final String body;
  final DateTime? scheduledTime;
  final NotificationPriority priority;

  const ActiveNotification({
    required this.id,
    required this.title,
    required this.body,
    this.scheduledTime,
    required this.priority,
  });
}

/// 通知事件
class NotificationEvent {
  final String id;
  final String? payload;
  final DateTime timestamp;

  const NotificationEvent({
    required this.id,
    this.payload,
    required this.timestamp,
  });
}
```

**平台支持**:
- ✅ iOS (UNUserNotificationCenter)
- ✅ Android (NotificationManager)
- ✅ Windows (Toast notifications)
- ✅ macOS (UNUserNotificationCenter)
- ✅ Linux (libnotify)
- ⚠️ Web (Web Notifications API, 有限支持)

**依赖包**:
```yaml
flutter_local_notifications: ^17.2.3
permission_handler: ^11.3.1
```

---

#### 2.1.2 音频服务 (IAudioService)

**职责**:
- 播放短音效（提示音）
- 播放长音频（背景音乐）
- 音量控制
- 音频池管理（避免音频重叠）
- 平台音频能力适配

**接口定义**:

```dart
/// 音频服务接口
abstract class IAudioService {
  /// 初始化音频服务
  Future<bool> initialize();

  /// 播放短音效（适合提示音）
  Future<void> playSound({
    required String soundPath,
    double volume = 1.0,
    bool loop = false,
  });

  /// 播放系统提示音
  Future<void> playSystemSound({
    required SystemSoundType soundType,
    double volume = 1.0,
  });

  /// 播放长音频（适合背景音乐）
  Future<String> playMusic({
    required String musicPath,
    double volume = 1.0,
    bool loop = false,
  });

  /// 停止音乐播放
  Future<void> stopMusic(String playerId);

  /// 暂停音乐播放
  Future<void> pauseMusic(String playerId);

  /// 恢复音乐播放
  Future<void> resumeMusic(String playerId);

  /// 设置全局音量
  Future<void> setGlobalVolume(double volume);

  /// 停止所有音频
  Future<void> stopAll();

  /// 释放音频资源
  Future<void> dispose();

  /// 是否已初始化
  bool get isInitialized;
}

/// 系统提示音类型
enum SystemSoundType {
  notification,       // 通知提示音
  alarm,             // 闹钟
  click,             // 点击音
  success,           // 成功音
  error,             // 错误音
  warning,           // 警告音
}

/// 音频播放状态
enum AudioPlaybackState {
  playing,
  paused,
  stopped,
  completed,
  error,
}
```

**平台支持**:
- ✅ 全平台支持

**依赖包**:
```yaml
audioplayers: ^6.1.0
# 或
just_audio: ^0.9.36  # 更强大但更复杂
```

---

#### 2.1.3 任务调度服务 (ITaskSchedulerService)

**职责**:
- 管理定时任务（倒计时、闹钟等）
- 任务持久化
- 任务优先级管理
- 任务超时处理
- 与通知服务集成

**接口定义**:

```dart
/// 任务调度服务接口
abstract class ITaskSchedulerService {
  /// 初始化任务调度器
  Future<bool> initialize();

  /// 调度一次性任务
  Future<String> scheduleOneShotTask({
    required String taskId,
    required DateTime scheduledTime,
    required TaskCallback callback,
    Map<String, dynamic>? data,
    bool showNotification = false,
    String? notificationTitle,
    String? notificationBody,
  });

  /// 调度周期性任务
  Future<String> schedulePeriodicTask({
    required String taskId,
    required Duration interval,
    required TaskCallback callback,
    Map<String, dynamic>? data,
  });

  /// 取消任务
  Future<void> cancelTask(String taskId);

  /// 取消所有任务
  Future<void> cancelAllTasks();

  /// 获取活动任务列表
  Future<List<ScheduledTask>> getActiveTasks();

  /// 暂停任务
  Future<void> pauseTask(String taskId);

  /// 恢复任务
  Future<void> resumeTask(String taskId);

  /// 任务完成事件流
  Stream<TaskEvent> get onTaskComplete;

  /// 任务失败事件流
  Stream<TaskEvent> get onTaskFailed;

  /// 是否已初始化
  bool get isInitialized;
}

/// 任务回调函数类型
typedef TaskCallback = Future<void> Function(Map<String, dynamic>? data);

/// 计划任务
class ScheduledTask {
  final String id;
  final String type; // 'one_shot' or 'periodic'
  final DateTime? scheduledTime;
  final Duration? interval;
  final Map<String, dynamic>? data;
  final bool isActive;
  final bool isPaused;

  const ScheduledTask({
    required this.id,
    required this.type,
    this.scheduledTime,
    this.interval,
    this.data,
    required this.isActive,
    required this.isPaused,
  });
}

/// 任务事件
class TaskEvent {
  final String taskId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final String? error;

  const TaskEvent({
    required this.taskId,
    this.data,
    required this.timestamp,
    this.error,
  });
}
```

**平台支持**:
- ✅ 全平台支持
- ⚠️ 后台执行受平台限制（移动端需配置后台模式）

**依赖包**:
```yaml
# 使用 Flutter 原生 Timer + Isolate
# 无需额外依赖
```

---

### 2.2 第二阶段：增强服务

#### 2.2.1 震动反馈服务 (IHapticService)

**职责**:
- 触觉反馈
- 震动模式管理
- 仅限移动平台

**接口定义**:

```dart
/// 震动反馈服务接口
abstract class IHapticService {
  /// 初始化震动服务
  Future<bool> initialize();

  /// 轻触震动
  Future<void> lightImpact();

  /// 中等震动
  Future<void> mediumImpact();

  /// 重度震动
  Future<void> heavyImpact();

  /// 成功震动
  Future<void> notificationSuccess();

  /// 警告震动
  Future<void> notificationWarning();

  /// 错误震动
  Future<void> notificationError();

  /// 自定义震动模式
  Future<void> vibrate({
    required Duration duration,
    List<Duration>? pattern,
  });

  /// 停止震动
  Future<void> stop();

  /// 是否支持震动
  bool get hasVibrator;

  /// 是否已初始化
  bool get isInitialized;
}
```

**平台支持**:
- ✅ Android (Vibrator)
- ✅ iOS (UIImpactFeedbackGenerator)
- ❌ Desktop/Web (无震动硬件)

**依赖包**:
```yaml
vibration: ^2.0.0
```

---

#### 2.2.2 系统托盘服务 (ISystemTrayService)

**职责**:
- 系统托盘图标管理
- 托盘菜单
- 未读消息计数
- 仅限桌面平台

**接口定义**:

```dart
/// 系统托盘服务接口
abstract class ISystemTrayService {
  /// 初始化系统托盘
  Future<bool> initialize({
    required String iconPath,
    String tooltip = 'Plugin Platform',
  });

  /// 设置托盘图标
  Future<void> setIcon(String iconPath);

  /// 设置托盘提示文本
  Future<void> setTooltip(String tooltip);

  /// 显示托盘菜单
  Future<void> showMenu(List<TrayMenuItem> items);

  /// 显示气泡通知
  Future<void> showBalloon({
    required String title,
    required String content,
    Duration duration = const Duration(seconds: 3),
  });

  /// 设置未读计数
  Future<void> setBadge(int count);

  /// 清除未读计数
  Future<void> clearBadge();

  /// 托盘图标点击事件流
  Stream<void> get onTrayIconClick;

  /// 托盘菜单点击事件流
  Stream<TrayMenuEvent> get onMenuClick;

  /// 是否支持系统托盘
  bool get isSupported;

  /// 是否已初始化
  bool get isInitialized;
}

/// 托盘菜单项
class TrayMenuItem {
  final String id;
  final String label;
  final String? iconPath;
  final bool isSeparator;
  final List<TrayMenuItem>? subMenu;

  const TrayMenuItem({
    required this.id,
    required this.label,
    this.iconPath,
    this.isSeparator = false,
    this.subMenu,
  });
}

/// 托盘菜单事件
class TrayMenuEvent {
  final String menuItemId;
  final DateTime timestamp;

  const TrayMenuEvent({
    required this.menuItemId,
    required this.timestamp,
  });
}
```

**平台支持**:
- ✅ Windows (System Tray)
- ✅ macOS (NSStatusBar)
- ✅ Linux (AppIndicator)
- ❌ Mobile/Web (无系统托盘)

**依赖包**:
```yaml
system_tray: ^2.0.2
# 或
tray_manager: ^0.2.2  # 更现代的实现
```

---

### 2.3 现有服务增强

#### 2.3.1 权限管理服务 (IPermissionManager)

**现有问题**:
- 当前实现只是模拟，未调用真实系统权限
- 缺少权限持久化
- 缺少权限请求UI

**增强接口**:

```dart
/// 权限管理服务接口（增强版）
abstract class IPermissionManager {
  /// 初始化权限管理器
  Future<bool> initialize();

  /// 检查权限状态
  Future<PermissionStatus> checkPermission(PermissionType permission);

  /// 请求权限
  Future<PermissionStatus> requestPermission(PermissionType permission);

  /// 请求多个权限
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> permissions,
  );

  /// 打开系统设置页面
  Future<void> openAppSettings();

  /// 权限状态变化事件流
  Stream<PermissionChangeEvent> get onPermissionChange;

  /// 是否已初始化
  bool get isInitialized;
}

/// 权限类型
enum PermissionType {
  notification,        // 通知权限
  camera,              // 相机权限
  microphone,          // 麦克风权限
  location,            // 位置权限
  storage,             // 存储权限
  calendar,            // 日历权限
  reminder,            // 提醒权限
}

/// 权限状态
enum PermissionStatus {
  denied,              // 拒绝
  granted,             // 已授予
  permanentlyDenied,   // 永久拒绝（需要用户手动在设置中开启）
  notDetermined,       // 未请求
  limited,             // 有限授予（如照片访问）
}

/// 权限变化事件
class PermissionChangeEvent {
  final PermissionType permission;
  final PermissionStatus status;
  final DateTime timestamp;

  const PermissionChangeEvent({
    required this.permission,
    required this.status,
    required this.timestamp,
  });
}
```

**依赖包**:
```yaml
permission_handler: ^11.3.1
```

---

## 3. 服务定位器架构

### 3.1 服务定位器设计

**职责**:
- 注册所有服务实例
- 提供服务访问接口
- 管理服务生命周期
- 处理服务依赖关系

**核心实现**:

```dart
/// 服务定位器
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  // 服务注册表
  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic> _factories = {};

  /// 注册单例服务
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// 注册工厂函数（延迟创建）
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// 获取服务
  T get<T>() {
    // 先查找已注册的单例
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // 再查找工厂函数
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      final service = factory();
      _services[T] = service;
      return service;
    }

    throw ServiceNotFoundException('Service $T is not registered');
  }

  /// 检查服务是否已注册
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// 注销服务
  Future<void> unregister<T>() async {
    final service = _services.remove(T);
    if (service is Disposable) {
      await service.dispose();
    }
  }

  /// 释放所有服务
  Future<void> disposeAll() async {
    for (final service in _services.values) {
      if (service is Disposable) {
        await service.dispose();
      }
    }
    _services.clear();
    _factories.clear();
  }
}

/// 可释放对象接口
abstract class Disposable {
  Future<void> dispose();
}

/// 服务未找到异常
class ServiceNotFoundException implements Exception {
  final String message;
  ServiceNotFoundException(this.message);

  @override
  String toString() => 'ServiceNotFoundException: $message';
}
```

### 3.2 平台服务聚合器

增强现有的 `IPlatformServices` 接口：

```dart
/// 平台服务接口（增强版）
abstract class IPlatformServices {
  // === 现有接口 ===
  Future<void> initialize();
  Future<void> showNotification(String message);
  Future<void> requestPermission(Permission permission);
  Future<void> openExternalUrl(String url);
  Stream<PlatformEvent> get eventStream;
  PlatformInfo get platformInfo;
  Future<bool> hasPermission(Permission permission);

  // === 新增服务访问接口 ===

  /// 通知服务
  INotificationService get notification;

  /// 音频服务
  IAudioService get audio;

  /// 任务调度服务
  ITaskSchedulerService get taskScheduler;

  /// 震动反馈服务（仅移动端）
  IHapticService? get haptic;

  /// 系统托盘服务（仅桌面端）
  ISystemTrayService? get systemTray;

  /// 权限管理服务
  IPermissionManager get permissionManager;

  /// 检查服务可用性
  bool isServiceAvailable<T>();
}

/// 平台服务实现
class PlatformServicesImpl implements IPlatformServices {
  // 现有实现...

  @override
  INotificationService get notification => ServiceLocator.instance.get<INotificationService>();

  @override
  IAudioService get audio => ServiceLocator.instance.get<IAudioService>();

  @override
  ITaskSchedulerService get taskScheduler => ServiceLocator.instance.get<ITaskSchedulerService>();

  @override
  IHapticService? get haptic {
    if (!isServiceAvailable<IHapticService>()) return null;
    return ServiceLocator.instance.get<IHapticService>();
  }

  @override
  ISystemTrayService? get systemTray {
    if (!isServiceAvailable<ISystemTrayService>()) return null;
    return ServiceLocator.instance.get<ISystemTrayService>();
  }

  @override
  IPermissionManager get permissionManager => ServiceLocator.instance.get<IPermissionManager>();

  @override
  bool isServiceAvailable<T>() {
    return ServiceLocator.instance.isRegistered<T>();
  }
}
```

---

## 4. 插件使用服务的示例

### 4.1 世界时钟插件使用倒计时通知

```dart
class WorldClockPlugin implements IPlugin {
  late ITaskSchedulerService _taskScheduler;
  late INotificationService _notification;
  late IAudioService _audio;

  @override
  Future<void> initialize(PluginContext context) async {
    // 从平台服务获取需要的服务
    _taskScheduler = context.platformServices.taskScheduler;
    _notification = context.platformServices.notification;
    _audio = context.platformServices.audio;
  }

  // 创建倒计时
  Future<void> createCountdown(CountdownTimer countdown) async {
    await _taskScheduler.scheduleOneShotTask(
      taskId: 'countdown_${countdown.id}',
      scheduledTime: countdown.targetTime,
      callback: (data) async {
        // 倒计时完成时的回调
        await _onCountdownComplete(countdown);
      },
      showNotification: true,
      notificationTitle: '倒计时完成',
      notificationBody: '${countdown.title} 已完成',
    );
  }

  Future<void> _onCountdownComplete(CountdownTimer countdown) async {
    // 播放提示音
    await _audio.playSystemSound(soundType: SystemSoundType.notification);

    // 显示通知（即使 showNotification=true 也额外显示一个）
    await _notification.showNotification(
      id: 'countdown_${countdown.id}',
      title: '倒计时完成',
      body: '${countdown.title} 已于 ${DateTime.now()} 完成',
      priority: NotificationPriority.high,
    );

    // 如果支持震动，添加震动反馈
    if (context.platformServices.haptic != null) {
      await context.platformServices.haptic!.notificationSuccess();
    }
  }
}
```

### 4.2 桌面宠物使用系统托盘

```dart
class DesktopPetPlugin implements IPlugin {
  ISystemTrayService? _tray;

  @override
  Future<void> initialize(PluginContext context) async {
    _tray = context.platformServices.systemTray;

    if (_tray != null && _tray!.isSupported) {
      await _tray!.initialize(
        iconPath: 'assets/icons/pet_icon.png',
        tooltip: 'Desktop Pet',
      );

      // 设置托盘菜单
      _tray!.onTrayIconClick.listen((_) {
        // 点击托盘图标显示/隐藏宠物
      });

      _tray!.onMenuClick.listen((event) {
        if (event.menuItemId == 'show') {
          // 显示宠物
        } else if (event.menuItemId == 'hide') {
          // 隐藏宠物
        } else if (event.menuItemId == 'quit') {
          // 退出
        }
      });
    }
  }

  Future<void> showTrayNotification(String message) async {
    if (_tray != null) {
      await _tray!.showBalloon(
        title: 'Desktop Pet',
        content: message,
      );
    }
  }
}
```

---

## 5. 平台兼容性处理

### 5.1 平台检测策略

```dart
/// 平台能力检测
class PlatformCapabilities {
  static bool get supportsNotification {
    // 使用 kIsWeb 检查
    if (kIsWeb) return true; // Web Notifications API
    return true; // 所有原生平台都支持
  }

  static bool get supportsSystemTray {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get supportsHaptic {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool get supportsBackgroundTasks {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
```

### 5.2 服务优雅降级

```dart
/// 通知服务实现（带平台适配）
class NotificationServiceImpl implements INotificationService {
  @override
  Future<bool> initialize() async {
    if (!PlatformCapabilities.supportsNotification) {
      print('Notifications not supported on this platform');
      return false;
    }

    // 平台特定初始化
    if (kIsWeb) {
      return await _initializeWeb();
    } else if (Platform.isAndroid) {
      return await _initializeAndroid();
    } else if (Platform.isIOS) {
      return await _initializeIOS();
    } else {
      return await _initializeDesktop();
    }
  }

  // 平台特定实现...
}
```

---

## 6. 文件结构

```
lib/core/
├── interfaces/
│   ├── services/
│   │   ├── i_notification_service.dart          # 通知服务接口
│   │   ├── i_audio_service.dart                 # 音频服务接口
│   │   ├── i_task_scheduler_service.dart        # 任务调度服务接口
│   │   ├── i_haptic_service.dart                # 震动服务接口
│   │   ├── i_system_tray_service.dart           # 系统托盘服务接口
│   │   └── i_permission_manager.dart            # 权限管理服务接口
│   ├── i_platform_services.dart                 # 平台服务聚合接口（增强）
│   └── i_service_locator.dart                   # 服务定位器接口
│
├── services/
│   ├── notification/
│   │   ├── notification_service.dart            # 通知服务实现
│   │   ├── notification_service_android.dart    # Android 实现
│   │   ├── notification_service_ios.dart        # iOS 实现
│   │   ├── notification_service_desktop.dart    # Desktop 实现
│   │   └── notification_service_web.dart        # Web 实现
│   │
│   ├── audio/
│   │   ├── audio_service.dart                   # 音频服务实现
│   │   └── audio_pool.dart                      # 音频池管理
│   │
│   ├── task_scheduler/
│   │   ├── task_scheduler_service.dart          # 任务调度实现
│   │   ├── task_persistence.dart                # 任务持久化
│   │   └── task_executor.dart                   # 任务执行器
│   │
│   ├── haptic/
│   │   ├── haptic_service.dart                  # 震动服务实现
│   │   ├── haptic_service_android.dart          # Android 实现
│   │   └── haptic_service_ios.dart              # iOS 实现
│   │
│   ├── system_tray/
│   │   ├── system_tray_service.dart             # 系统托盘服务实现
│   │   ├── system_tray_service_windows.dart     # Windows 实现
│   │   ├── system_tray_service_macos.dart       # macOS 实现
│   │   └── system_tray_service_linux.dart       # Linux 实现
│   │
│   ├── permission/
│   │   ├── permission_manager.dart              # 权限管理实现
│   │   └── permission_ui.dart                   # 权限请求 UI
│   │
│   ├── service_locator.dart                     # 服务定位器实现
│   ├── platform_services.dart                   # 平台服务聚合实现（增强）
│   ├── desktop_pet_manager.dart                 # 现有服务
│   └── locale_provider.dart                     # 现有服务
│
└── models/
    ├── notification_models.dart                 # 通知相关模型
    ├── audio_models.dart                        # 音频相关模型
    ├── task_models.dart                         # 任务相关模型
    └── service_models.dart                      # 通用服务模型
```

---

## 7. 依赖关系图

```
┌─────────────────────────────────────────────────────────┐
│                      插件层                              │
│  (WorldClock, Calculator, DesktopPet, etc.)             │
└────────────────────┬────────────────────────────────────┘
                     │ 使用
┌────────────────────▼────────────────────────────────────┐
│              IPlatformServices (聚合器)                  │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │  Notification│  Audio       │TaskScheduler │        │
│  │  Service     │  Service     │  Service     │        │
│  └──────────────┴──────────────┴──────────────┘        │
│  ┌──────────────┬──────────────┬──────────────┐        │
│  │  Haptic      │  SystemTray  │  Permission  │        │
│  │  Service     │  Service     │  Manager     │        │
│  └──────────────┴──────────────┴──────────────┘        │
└────────────────────┬────────────────────────────────────┘
                     │ 通过 ServiceLocator 管理
┌────────────────────▼────────────────────────────────────┐
│              ServiceLocator (单例)                       │
│  - 服务注册表                                            │
│  - 服务生命周期管理                                      │
│  - 服务依赖解析                                          │
└────────────────────┬────────────────────────────────────┘
                     │ 依赖
┌────────────────────▼────────────────────────────────────┐
│                  第三方包                                │
│  flutter_local_notifications, audioplayers,             │
│  system_tray, vibration, permission_handler             │
└─────────────────────────────────────────────────────────┘
```

---

## 8. 技术要点

### 8.1 异步初始化

所有服务的初始化都是异步的，需要确保在使用前完成初始化：

```dart
// 应用启动时初始化所有服务
Future<void> initializePlatformServices() async {
  final locator = ServiceLocator.instance;

  // 按依赖顺序初始化
  await locator.get<INotificationService>().initialize();
  await locator.get<IAudioService>().initialize();
  await locator.get<ITaskSchedulerService>().initialize();

  // 可选服务
  if (PlatformCapabilities.supportsHaptic) {
    await locator.get<IHapticService>()?.initialize();
  }

  if (PlatformCapabilities.supportsSystemTray) {
    await locator.get<ISystemTrayService>()?.initialize();
  }
}
```

### 8.2 错误处理

服务应该优雅地处理错误，而不是抛出异常导致应用崩溃：

```dart
try {
  await notification.showNotification(...);
} on ServiceNotFoundException catch (e) {
  // 服务未注册，记录日志但不崩溃
  logger.error('Notification service not available: $e');
} on PlatformException catch (e) {
  // 平台特定错误
  logger.error('Platform error: $e');
}
```

### 8.3 资源释放

应用退出时释放所有服务资源：

```dart
@override
void dispose() {
  ServiceLocator.instance.disposeAll();
}
```

---

## 9. 测试策略

### 9.1 单元测试

每个服务都应该有独立的单元测试：

```dart
test('NotificationService should show notification', () async {
  final service = MockNotificationService();
  await service.showNotification(
    id: 'test',
    title: 'Test',
    body: 'Test notification',
  );

  verify(() => service.showNotification(...)).called(1);
});
```

### 9.2 Mock 服务

为测试提供 Mock 实现：

```dart
class MockNotificationService implements INotificationService {
  // 实现用于测试的 Mock 逻辑
}
```

---

## 10. 性能考虑

### 10.1 延迟加载

使用工厂函数延迟创建服务，只在需要时才初始化：

```dart
locator.registerFactory<INotificationService>(() => NotificationServiceImpl());
```

### 10.2 资源池

音频服务使用对象池管理音频播放器，避免频繁创建销毁：

```dart
class AudioPool {
  final List<AudioPlayer> _pool = [];
  AudioPlayer acquire() { /* ... */ }
  void release(AudioPlayer player) { /* ... */ }
}
```

---

## 11. 安全性

### 11.1 权限检查

在执行需要权限的操作前，先检查权限状态：

```dart
if (await permissionManager.checkPermission(PermissionType.notification)
    != PermissionStatus.granted) {
  // 请求权限或显示提示
}
```

### 11.2 服务隔离

每个插件的数据和资源相互隔离，避免互相干扰：

```dart
class PluginContext {
  final String pluginId;
  // 插件特定的数据隔离
}
```

---

## 12. 未来扩展

### 12.1 可添加的服务

- **位置服务** (ILocationService) - GPS 位置获取和地理围栏
- **蓝牙服务** (IBluetoothService) - 蓝牙设备连接
- **网络服务增强** (INetworkService) - HTTP 请求、WebSocket
- **文件服务** (IFileService) - 文件选择、上传、下载
- **分享服务** (IShareService) - 分享内容到其他应用
- **支付服务** (IPaymentService) - 应用内购买
- **分析服务** (IAnalyticsService) - 用户行为分析

### 12.2 扩展点

服务架构设计时考虑了以下扩展点：

1. **新服务类型**: 通过实现接口即可添加新服务
2. **新平台支持**: 通过平台检测和条件导入支持新平台
3. **自定义实现**: 插件可以提供自己的服务实现
4. **服务替换**: 运行时替换服务实现（用于测试或调试）

---

## 13. 总结

本设计文档定义了一套完整的平台通用服务架构，具有以下特点：

✅ **模块化**: 每个服务职责单一，相互独立
✅ **可扩展**: 新服务可以轻松添加
✅ **平台兼容**: 自动适配不同平台
✅ **易测试**: 服务可以独立测试和 Mock
✅ **高性能**: 延迟加载和资源池优化
✅ **安全性**: 权限检查和资源隔离

通过这套架构，所有插件都可以方便地使用平台能力，而无需关心底层实现细节。
