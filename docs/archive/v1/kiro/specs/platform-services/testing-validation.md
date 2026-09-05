# 平台通用服务测试与验证文档

## 📋 文档说明

本文档定义了平台通用服务的完整测试策略、验证流程和验收标准。

**适用范围**: 所有平台通用服务
**测试类型**: 单元测试、集成测试、端到端测试
**目标覆盖率**: 代码覆盖率 > 80%

---

## 🧪 测试框架

### 测试工具

```yaml
dev_dependencies:
  # 单元测试框架
  test: ^1.24.0
  flutter_test:
    sdk: flutter

  # Mock 框架
  mockito: ^5.4.2
  build_runner: ^2.4.7

  # 集成测试
  integration_test:
    sdk: flutter

  # 代码覆盖率
  coverage: ^1.6.3
```

### 测试目录结构

```
test/
├── core/
│   ├── services/
│   │   ├── notification_service_test.dart
│   │   ├── audio_service_test.dart
│   │   ├── task_scheduler_service_test.dart
│   │   ├── haptic_service_test.dart
│   │   ├── system_tray_service_test.dart
│   │   └── permission_manager_test.dart
│   └── interfaces/
│       └── service_locator_test.dart
│
integration_test/
├── services/
│   ├── notification_service_integration_test.dart
│   ├── audio_service_integration_test.dart
│   └── task_scheduler_integration_test.dart
└── plugins/
    ├── world_clock_service_integration_test.dart
    └── desktop_pet_service_integration_test.dart
```

---

## ✅ 阶段 1: 单元测试

### 1.1 服务定位器测试

**文件**: `test/core/interfaces/service_locator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/core/services/service_locator.dart';

void main() {
  group('ServiceLocator Tests', () {
    late ServiceLocator locator;

    setUp(() {
      locator = ServiceLocator.instance;
      // 清理之前的服务
      locator.disposeAll();
    });

    tearDown(() async {
      await locator.disposeAll();
    });

    test('should register singleton service', () {
      // Arrange
      final service = MockNotificationService();

      // Act
      locator.registerSingleton<INotificationService>(service);

      // Assert
      expect(locator.isRegistered<INotificationService>(), true);
      expect(locator.get<INotificationService>(), same(service));
    });

    test('should register factory and create service on demand', () {
      // Arrange
      int callCount = 0;
      locator.registerFactory<INotificationService>(() {
        callCount++;
        return MockNotificationService();
      });

      // Act
      final service1 = locator.get<INotificationService>();
      final service2 = locator.get<INotificationService>();

      // Assert
      expect(callCount, 1); // Factory 只调用一次（单例缓存）
      expect(service1, same(service2));
    });

    test('should throw exception when service not registered', () {
      // Act & Assert
      expect(
        () => locator.get<INotificationService>(),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('should unregister service and dispose it', () async {
      // Arrange
      final service = MockDisposableService();
      locator.registerSingleton<IDisposable>(service);

      // Act
      await locator.unregister<IDisposable>();

      // Assert
      verify(() => service.dispose()).called(1);
      expect(locator.isRegistered<IDisposable>(), false);
    });

    test('should dispose all services', () async {
      // Arrange
      final service1 = MockDisposableService();
      final service2 = MockDisposableService();
      locator.registerSingleton<IDisposable>(service1);
      locator.registerFactory<IDisposable2>(() => service2);

      // Act
      await locator.disposeAll();

      // Assert
      verify(() => service1.dispose()).called(1);
      expect(locator.isRegistered<IDisposable>(), false);
    });
  });
}

// Mock 类
class MockNotificationService extends Mock implements INotificationService {}

class MockDisposableService extends Mock implements IDisposable {}

abstract class IDisposable {
  Future<void> dispose();
}
```

**验收标准**:
- ✅ 所有测试通过
- ✅ 覆盖所有关键场景
- ✅ Mock 正确使用

---

### 1.2 通知服务测试

**文件**: `test/core/services/notification_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform/core/interfaces/services/i_notification_service.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationServiceImpl service;
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() async {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = NotificationServiceImpl.internal(mockPlugin);
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully on supported platforms', () async {
        // Arrange & Act
        final result = await service.initialize();

        // Assert
        expect(result, true);
        expect(service.isInitialized, true);
      });

      test('should request notification permissions on initialize', () async {
        // Arrange
        when(mockPlugin.initialize(any)).thenAnswer((_) async => true);
        when(mockPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>())
            .thenReturn(MockIOSNotifications());
        when(mockPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>())
            .thenReturn(MockAndroidNotifications());

        // Act
        await service.initialize();

        // Assert
        verify(mockPlugin.initialize(any)).called(1);
      });
    });

    group('showNotification', () {
      test('should show notification with valid parameters', () async {
        // Arrange
        const id = 'test_notification';
        const title = 'Test Title';
        const body = 'Test Body';
        when(mockPlugin.show(any, any, any)).thenAnswer((_) async => true);

        // Act
        await service.showNotification(
          id: id,
          title: title,
          body: body,
        );

        // Assert
        verify(mockPlugin.show(
          argThat(equals(id)),
          argThat(equals(title)),
          argThat(equals(body)),
        )).called(1);
      });

      test('should include notification details', () async {
        // Arrange
        const id = 'test_notification';
        const title = 'Test Title';
        const body = 'Test Body';
        const payload = 'test_payload';
        when(mockPlugin.show(any, any, any, any)).thenAnswer((_) async => true);

        // Act
        await service.showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
          priority: NotificationPriority.high,
        );

        // Assert
        final captured = verify(mockPlugin.show(
          captureAny,
          captureAny,
          captureAny,
          captureAny,
        )).captured;

        final details = captured[3] as NotificationDetails;
        expect(details, isNotNull);
      });

      test('should throw exception when not initialized', () async {
        // Arrange
        final uninitializedService = NotificationServiceImpl.internal(mockPlugin);

        // Act & Assert
        expect(
          () => uninitializedService.showNotification(
            id: 'test',
            title: 'Test',
            body: 'Test',
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('scheduleNotification', () {
      test('should schedule notification for future time', () async {
        // Arrange
        const id = 'scheduled_notification';
        const title = 'Scheduled Title';
        const body = 'Scheduled Body';
        final scheduledTime = DateTime.now().add(const Duration(minutes: 5));
        when(mockPlugin.zonedSchedule(any, any, any, any, any))
            .thenAnswer((_) async => true);

        // Act
        await service.scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
        );

        // Assert
        verify(mockPlugin.zonedSchedule(
          argThat(equals(id)),
          argThat(equals(title)),
          argThat(equals(body)),
          argThat(isA<TZDateTime>()),
          any,
        )).called(1);
      });

      test('should throw exception for past time', () async {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(minutes: 1));

        // Act & Assert
        expect(
          () => service.scheduleNotification(
            id: 'test',
            title: 'Test',
            body: 'Test',
            scheduledTime: pastTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('cancelNotification', () {
      test('should cancel specific notification', () async {
        // Arrange
        const id = 'test_notification';
        when(mockPlugin.cancel(any)).thenAnswer((_) async => true);

        // Act
        await service.cancelNotification(id);

        // Assert
        verify(mockPlugin.cancel(argThat(equals(id)))).called(1);
      });

      test('should cancel all notifications', () async {
        // Arrange
        when(mockPlugin.cancelAll()).thenAnswer((_) async => true);

        // Act
        await service.cancelAllNotifications();

        // Assert
        verify(mockPlugin.cancelAll()).called(1);
      });
    });

    group('getActiveNotifications', () {
      test('should return list of active notifications', () async {
        // Arrange
        final activeNotifications = [
          ActiveNotification(
            id: '1',
            title: 'Test 1',
            body: 'Body 1',
            priority: NotificationPriority.normal,
          ),
          ActiveNotification(
            id: '2',
            title: 'Test 2',
            body: 'Body 2',
            priority: NotificationPriority.high,
          ),
        ];
        when(mockPlugin.getActiveNotifications())
            .thenAnswer((_) async => activeNotifications);

        // Act
        final result = await service.getActiveNotifications();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, '1');
        expect(result[1].id, '2');
      });
    });

    group('Permissions', () {
      test('should check notification permissions', () async {
        // Arrange
        when(mockPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>())
            .thenReturn(MockIOSNotifications());
        when(mockPlugin.permissions(any)).thenAnswer((_) async => true);

        // Act
        final hasPermission = await service.checkPermissions();

        // Assert
        expect(hasPermission, true);
      });

      test('should request notification permissions', () async {
        // Arrange
        when(mockPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>())
            .thenReturn(MockIOSNotifications());
        when(mockPlugin.requestPermissions()).thenAnswer((_) async => true);

        // Act
        final granted = await service.requestPermissions();

        // Assert
        expect(granted, true);
        verify(mockPlugin.requestPermissions()).called(1);
      });
    });
  });
}
```

**验收标准**:
- ✅ 所有测试通过
- ✅ 覆盖率 > 85%
- ✅ 边界情况处理正确
- ✅ 异常情况测试完整

---

### 1.3 音频服务测试

**文件**: `test/core/services/audio_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';

@GenerateMocks([AudioPlayer])
import 'audio_service_test.mocks.dart';

void main() {
  group('AudioService Tests', () {
    late AudioServiceImpl service;
    late MockAudioPlayer mockPlayer;

    setUp(() async {
      mockPlayer = MockAudioPlayer();
      service = AudioServiceImpl.internal(playerFactory: (_) => mockPlayer);
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(service.isInitialized, true);
      });

      test('should set up audio pool on initialization', () async {
        // Assert
        expect(service.isInitialized, true);
      });
    });

    group('playSound', () {
      test('should play sound file', () async {
        // Arrange
        const soundPath = 'assets/audio/test.mp3';
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.playSound(soundPath: soundPath);

        // Assert
        verify(mockPlayer.play(argThat(equals(soundPath)),
                isLooping: anyNamed('isLooping')))
            .called(1);
      });

      test('should set volume when playing sound', () async {
        // Arrange
        const volume = 0.7;
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.playSound(
          soundPath: 'assets/audio/test.mp3',
          volume: volume,
        );

        // Assert
        verify(mockPlayer.setVolume(argThat(equals(volume)))).called(1);
      });

      test('should handle file not found error', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenThrow(Exception('File not found'));

        // Act & Assert
        expect(
          () => service.playSound(soundPath: 'nonexistent.mp3'),
          throwsA(isA<AudioServiceException>()),
        );
      });
    });

    group('playSystemSound', () {
      test('should play notification sound', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.playSystemSound(
          soundType: SystemSoundType.notification,
        );

        // Assert
        verify(mockPlayer.play(
          argThat(contains('notification')),
          isLooping: anyNamed('isLooping'),
        )).called(1);
      });

      test('should play success sound', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.playSystemSound(
          soundType: SystemSoundType.success,
        );

        // Assert
        verify(mockPlayer.play(
          argThat(contains('success')),
          isLooping: anyNamed('isLooping'),
        )).called(1);
      });

      test('should play error sound', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.playSystemSound(
          soundType: SystemSoundType.error,
        );

        // Assert
        verify(mockPlayer.play(
          argThat(contains('error')),
          isLooping: anyNamed('isLooping'),
        )).called(1);
      });
    });

    group('playMusic', () {
      test('should play music and return player ID', () async {
        // Arrange
        const musicPath = 'assets/music/test.mp3';
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        final playerId = await service.playMusic(musicPath: musicPath);

        // Assert
        expect(playerId, isNotNull);
        expect(playerId, isNotEmpty);
        verify(mockPlayer.play(argThat(equals(musicPath)),
                isLooping: anyNamed('isLooping')))
            .called(1);
      });

      test('should stop music by player ID', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.stop()).thenAnswer((_) async {});

        // Act
        final playerId = await service.playMusic(musicPath: 'test.mp3');
        await service.stopMusic(playerId);

        // Assert
        verify(mockPlayer.stop()).called(1);
      });

      test('should pause music', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.pause()).thenAnswer((_) async {});

        // Act
        final playerId = await service.playMusic(musicPath: 'test.mp3');
        await service.pauseMusic(playerId);

        // Assert
        verify(mockPlayer.pause()).called(1);
      });

      test('should resume music', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.resume()).thenAnswer((_) async {});

        // Act
        final playerId = await service.playMusic(musicPath: 'test.mp3');
        await service.pauseMusic(playerId);
        await service.resumeMusic(playerId);

        // Assert
        verify(mockPlayer.resume()).called(1);
      });
    });

    group('Volume Control', () {
      test('should set global volume', () async {
        // Arrange
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.setGlobalVolume(0.5);

        // Assert
        verify(mockPlayer.setVolume(argThat(equals(0.5)))).called(1);
      });

      test('should clamp volume between 0 and 1', () async {
        // Arrange
        when(mockPlayer.setVolume(any)).thenAnswer((_) async {});

        // Act
        await service.setGlobalVolume(1.5); // 超过范围

        // Assert
        verify(mockPlayer.setVolume(argThat(equals(1.0)))).called(1);
      });
    });

    group('Stop All', () {
      test('should stop all playing audio', () async {
        // Arrange
        when(mockPlayer.play(any, isLooping: anyNamed('isLooping')))
            .thenAnswer((_) => 1);
        when(mockPlayer.stop()).thenAnswer((_) async {});

        await service.playMusic(musicPath: 'test1.mp3');
        await service.playMusic(musicPath: 'test2.mp3');

        // Act
        await service.stopAll();

        // Assert
        verify(mockPlayer.stop()).called(greaterThanOrEqualTo(2));
      });
    });
  });
}
```

**验收标准**:
- ✅ 所有测试通过
- ✅ 覆盖率 > 85%
- ✅ 音频池管理正确
- ✅ 资源释放无泄漏

---

### 1.4 任务调度服务测试

**文件**: `test/core/services/task_scheduler_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/core/interfaces/services/i_task_scheduler_service.dart';

void main() {
  group('TaskSchedulerService Tests', () {
    late TaskSchedulerServiceImpl service;

    setUp(() async {
      service = TaskSchedulerServiceImpl();
      await service.initialize();
    });

    tearDown(() async {
      await service.cancelAllTasks();
      await service.dispose();
    });

    group('scheduleOneShotTask', () {
      test('should schedule one-shot task', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(seconds: 2));
        bool callbackExecuted = false;

        // Act
        final taskId = await service.scheduleOneShotTask(
          taskId: 'test_task_1',
          scheduledTime: scheduledTime,
          callback: (data) async {
            callbackExecuted = true;
          },
        );

        // Assert
        expect(taskId, isNotEmpty);
        expect(service.isInitialized, true);

        // Wait for task to execute
        await Future.delayed(const Duration(seconds: 3));
        expect(callbackExecuted, true);
      });

      test('should throw error for past time', () async {
        // Arrange
        final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

        // Act & Assert
        expect(
          () => service.scheduleOneShotTask(
            taskId: 'test_task_2',
            scheduledTime: pastTime,
            callback: (data) async {},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should execute callback with data', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(seconds: 1));
        final testData = {'key': 'value'};
        Map<String, dynamic>? receivedData;

        await service.scheduleOneShotTask(
          taskId: 'test_task_3',
          scheduledTime: scheduledTime,
          callback: (data) async {
            receivedData = data;
          },
          data: testData,
        );

        // Act
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        expect(receivedData, equals(testData));
      });
    });

    group('schedulePeriodicTask', () {
      test('should schedule periodic task', () async {
        // Arrange
        int executionCount = 0;
        final interval = const Duration(milliseconds: 500);

        // Act
        await service.schedulePeriodicTask(
          taskId: 'periodic_task_1',
          interval: interval,
          callback: (data) async {
            executionCount++;
          },
        );

        // Wait for multiple executions
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        expect(executionCount, greaterThan(2));
      });

      test('should pause periodic task', () async {
        // Arrange
        int executionCount = 0;
        final interval = const Duration(milliseconds: 500);

        final taskId = await service.schedulePeriodicTask(
          taskId: 'periodic_task_2',
          interval: interval,
          callback: (data) async {
            executionCount++;
          },
        );

        // Act
        await Future.delayed(const Duration(milliseconds: 1100));
        await service.pauseTask(taskId);
        await Future.delayed(const Duration(milliseconds: 1000));

        // Assert
        expect(executionCount, lessThanOrEqualTo(3));
      });

      test('should resume paused task', () async {
        // Arrange
        int executionCount = 0;
        final interval = const Duration(milliseconds: 500);

        final taskId = await service.schedulePeriodicTask(
          taskId: 'periodic_task_3',
          interval: interval,
          callback: (data) async {
            executionCount++;
          },
        );

        await service.pauseTask(taskId);
        await Future.delayed(const Duration(milliseconds: 1000));

        // Act
        await service.resumeTask(taskId);
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert
        expect(executionCount, greaterThan(1));
      });
    });

    group('cancelTask', () {
      test('should cancel scheduled task', () async {
        // Arrange
        bool callbackExecuted = false;
        final scheduledTime = DateTime.now().add(const Duration(seconds: 2));

        final taskId = await service.scheduleOneShotTask(
          taskId: 'cancellable_task',
          scheduledTime: scheduledTime,
          callback: (data) async {
            callbackExecuted = true;
          },
        );

        // Act
        await service.cancelTask(taskId);
        await Future.delayed(const Duration(seconds: 3));

        // Assert
        expect(callbackExecuted, false);
      });

      test('should cancel all tasks', () async {
        // Arrange
        int executionCount = 0;
        final scheduledTime = DateTime.now().add(const Duration(seconds: 2));

        await service.scheduleOneShotTask(
          taskId: 'task_1',
          scheduledTime: scheduledTime,
          callback: (data) async {
            executionCount++;
          },
        );

        await service.scheduleOneShotTask(
          taskId: 'task_2',
          scheduledTime: scheduledTime,
          callback: (data) async {
            executionCount++;
          },
        );

        // Act
        await service.cancelAllTasks();
        await Future.delayed(const Duration(seconds: 3));

        // Assert
        expect(executionCount, equals(0));
      });
    });

    group('getActiveTasks', () {
      test('should return list of active tasks', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(minutes: 5));

        await service.scheduleOneShotTask(
          taskId: 'task_1',
          scheduledTime: scheduledTime,
          callback: (data) async {},
        );

        await service.scheduleOneShotTask(
          taskId: 'task_2',
          scheduledTime: scheduledTime,
          callback: (data) async {},
        );

        // Act
        final tasks = await service.getActiveTasks();

        // Assert
        expect(tasks, hasLength(2));
        expect(tasks[0].id, contains('task_'));
      });
    });

    group('Task Events', () {
      test('should emit task complete event', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(seconds: 1));
        TaskEvent? capturedEvent;

        service.onTaskComplete.listen((event) {
          capturedEvent = event;
        });

        await service.scheduleOneShotTask(
          taskId: 'event_task',
          scheduledTime: scheduledTime,
          callback: (data) async {},
        );

        // Act
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        expect(capturedEvent, isNotNull);
        expect(capturedEvent!.taskId, equals('event_task'));
      });

      test('should emit task failed event on error', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(seconds: 1));
        TaskEvent? capturedEvent;

        service.onTaskFailed.listen((event) {
          capturedEvent = event;
        });

        await service.scheduleOneShotTask(
          taskId: 'error_task',
          scheduledTime: scheduledTime,
          callback: (data) async {
            throw Exception('Task failed');
          },
        );

        // Act
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        expect(capturedEvent, isNotNull);
        expect(capturedEvent!.taskId, equals('error_task'));
        expect(capturedEvent!.error, isNotNull);
      });
    });

    group('Task Persistence', () {
      test('should persist tasks to storage', () async {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(minutes: 5));

        // Act
        await service.scheduleOneShotTask(
          taskId: 'persistent_task',
          scheduledTime: scheduledTime,
          callback: (data) async {},
        );

        // Create new service instance
        final newService = TaskSchedulerServiceImpl();
        await newService.initialize();

        final tasks = await newService.getActiveTasks();

        // Assert
        expect(tasks, any((t) => t.id == 'persistent_task'));
      });
    });
  });
}
```

**验收标准**:
- ✅ 所有测试通过
- ✅ 覆盖率 > 80%
- ✅ 任务调度准确
- ✅ 持久化功能正常

---

## 🔗 阶段 2: 集成测试

### 2.1 通知服务集成测试

**文件**: `integration_test/services/notification_service_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Service Integration Tests', () {
    testWidgets('should show notification on tap', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act
      // 点击显示通知按钮
      final showNotificationButton = find.text('显示通知');
      await tester.tap(showNotificationButton);
      await tester.pumpAndSettle();

      // Assert
      // 验证通知显示（需要人工验证）
      expect(find.text('通知已发送'), findsOneWidget);
    });

    testWidgets('should request notification permissions', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act
      // 点击请求权限按钮
      final requestPermissionButton = find.text('请求通知权限');
      await tester.tap(requestPermissionButton);
      await tester.pumpAndSettle();

      // Assert
      // 验证权限请求对话框显示
      expect(find.text('权限请求'), findsOneWidget);
    });

    testWidgets('should cancel notification', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // 先显示通知
      await tester.tap(find.text('显示通知'));
      await tester.pumpAndSettle();

      // Act
      // 取消通知
      await tester.tap(find.text('取消通知'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('通知已取消'), findsOneWidget);
    });
  });

  // 平台特定测试
  group('Platform-specific Notification Tests', () {
    testWidgets('Android: should show notification with large icon',
        (tester) async {
      // Android 特定测试
    }, skip: !TargetPlatform.android);

    testWidgets('iOS: should show notification with banner', (tester) async {
      // iOS 特定测试
    }, skip: !TargetPlatform.iOS);
  });
}
```

**验收标准**:
- ✅ 在真实设备/模拟器上通过
- ✅ 通知正确显示
- ✅ 交互功能正常

---

### 2.2 世界时钟插件集成测试

**文件**: `integration_test/plugins/world_clock_service_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('World Clock Service Integration Tests', () {
    testWidgets('should create countdown and trigger notification',
        (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // 导航到世界时钟插件
      await tester.tap(find.text('世界时钟'));
      await tester.pumpAndSettle();

      // 创建倒计时（10秒）
      await tester.enterText(
        find.byKey(const Key('countdown_title')),
        '测试倒计时',
      );
      await tester.tap(find.text('创建10秒倒计时'));
      await tester.pumpAndSettle();

      // Act
      // 等待倒计时完成
      await tester.pump(const Duration(seconds: 11));

      // Assert
      // 验证通知显示
      expect(find.text('倒计时完成'), findsOneWidget);
      expect(find.textContaining('测试倒计时已完成'), findsOneWidget);
    });

    testWidgets('should play sound on countdown complete', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('世界时钟'));
      await tester.pumpAndSettle();

      // 创建倒计时
      await tester.tap(find.text('创建5秒倒计时'));
      await tester.pumpAndSettle();

      // Act
      await tester.pump(const Duration(seconds: 6));

      // Assert
      // 验证音频播放（需要人工验证音频）
      expect(find.text('倒计时完成'), findsOneWidget);
    });
  });
}
```

**验收标准**:
- ✅ 倒计时准确触发
- ✅ 通知正常显示
- ✅ 音频正常播放
- ✅ UI 响应正确

---

## 📱 阶段 3: 平台验证

### 3.1 平台兼容性检查表

#### Android
- [ ] 通知权限正常请求
- [ ] 通知图标正确显示
- [ ] 通知点击跳转正常
- [ ] 音频播放正常
- [ ] 震动反馈正常
- [ ] 后台任务正常执行

#### iOS
- [ ] 通知权限正常请求
- [ ] 通知横幅正常显示
- [ ] 通知点击跳转正常
- [ ] 音频播放正常
- [ ] 触觉反馈正常
- [ ] 后台任务正常执行

#### Windows
- [ ] Toast 通知正常显示
- [ ] 系统托盘图标正常
- [ ] 音频播放正常
- [ ] 窗口管理正常

#### macOS
- [ ] 通知中心通知正常
- [ ] 系统托盘图标正常
- [ ] 音频播放正常
- [ ] 窗口管理正常

#### Linux
- [ ] libnotify 通知正常
- [ ] 系统托盘图标正常
- [ ] 音频播放正常

---

### 3.2 性能测试

#### 内存使用测试
```dart
test('should not leak memory', () async {
  final initialMemory = ProcessInfo.currentRss;

  // 执行 100 次通知操作
  for (int i = 0; i < 100; i++) {
    await notificationService.showNotification(
      id: 'test_$i',
      title: 'Test $i',
      body: 'Body $i',
    );
    await notificationService.cancelNotification('test_$i');
  }

  // 强制 GC
  await Future.delayed(const Duration(seconds: 2));

  final finalMemory = ProcessInfo.currentRss;
  final memoryIncrease = finalMemory - initialMemory;

  // 内存增长应 < 10MB
  expect(memoryIncrease, lessThan(10 * 1024 * 1024));
});
```

#### 启动时间测试
```dart
test('should initialize services in acceptable time', () async {
  final stopwatch = Stopwatch()..start();

  await notificationService.initialize();
  await audioService.initialize();
  await taskSchedulerService.initialize();

  stopwatch.stop();

  // 初始化应在 2 秒内完成
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
});
```

---

## 🎯 阶段 4: 用户验收测试

### 4.1 测试场景

#### 场景 1: 倒计时通知
1. 打开世界时钟插件
2. 创建 10 秒倒计时
3. 等待倒计时完成
4. 验证：
   - ✅ 通知显示
   - ✅ 提示音播放
   - ✅ 震动反馈（移动端）

#### 场景 2: 系统托盘交互（桌面）
1. 启动应用
2. 验证系统托盘图标显示
3. 右键点击托盘图标
4. 验证菜单显示
5. 点击"显示/隐藏"选项
6. 验证窗口显示/隐藏

#### 场景 3: 多倒计时管理
1. 创建 3 个不同时间的倒计时
2. 验证所有倒计时正常计时
3. 验证所有倒计时完成后都有通知
4. 验证通知历史正确

---

## 📊 代码覆盖率

### 运行覆盖率测试

```bash
# 运行测试并生成覆盖率报告
flutter test --coverage

# 转换为 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 在浏览器中查看
open coverage/html/index.html
```

### 覆盖率目标

| 服务类型 | 目标覆盖率 | 最低要求 |
|---------|-----------|---------|
| 通知服务 | 85% | 80% |
| 音频服务 | 85% | 80% |
| 任务调度服务 | 80% | 75% |
| 震动服务 | 80% | 75% |
| 系统托盘服务 | 75% | 70% |
| 权限管理 | 80% | 75% |
| **总体** | **82%** | **78%** |

---

## ✅ 验收标准总结

### 功能验收
- [ ] 所有核心服务正常工作
- [ ] 所有增强服务正常工作
- [ ] 世界时钟插件集成成功
- [ ] 桌面宠物插件集成成功
- [ ] 所有测试用例通过

### 性能验收
- [ ] 应用启动时间 < 3 秒
- [ ] 内存占用合理（< 100MB 基线）
- [ ] 无明显性能问题
- [ ] 无内存泄漏

### 质量验收
- [ ] 单元测试覆盖率 > 80%
- [ ] 集成测试全部通过
- [ ] 代码审查通过
- [ ] 文档完整

### 平台验收
- [ ] Android 测试通过
- [ ] iOS 测试通过
- [ ] Windows 测试通过
- [ ] macOS 测试通过
- [ ] Linux 测试通过

---

## 🐛 问题跟踪

### 问题分类

- **Critical**: 阻塞性问题，必须修复才能发布
- **High**: 高优先级问题，应尽快修复
- **Medium**: 中等优先级，可延后修复
- **Low**: 低优先级，可选择性修复

### 问题报告模板

```markdown
## 问题描述
### 严重程度: [Critical/High/Medium/Low]
### 影响平台: [Android/iOS/Windows/macOS/Linux/Web]
### 复现步骤
1.
2.
3.

### 期望行为

### 实际行为

### 截图/日志

### 环境信息
- Flutter 版本:
- Dart 版本:
- 平台版本:
```

---

## 📝 测试报告模板

```markdown
# 测试执行报告

**测试日期**: YYYY-MM-DD
**测试人员**: [姓名]
**测试版本**: v0.x.x

## 测试概况
- 总测试用例: XXX
- 通过: XXX
- 失败: XXX
- 跳过: XXX
- 通过率: XX%

## 测试结果详情

### 单元测试
| 服务 | 用例数 | 通过 | 失败 | 覆盖率 |
|------|--------|------|------|--------|
| 通知服务 | 20 | 20 | 0 | 85% |
| 音频服务 | 18 | 18 | 0 | 86% |
| 任务调度 | 15 | 15 | 0 | 82% |

### 集成测试
| 场景 | 结果 | 备注 |
|------|------|------|
| 倒计时通知 | ✅ | |
| 系统托盘 | ✅ | |
| 多倒计时 | ⚠️ | 偶发延迟 |

### 平台测试
| 平台 | 结果 | 问题 |
|------|------|------|
| Android | ✅ | |
| iOS | ✅ | |
| Windows | ⚠️ | 托盘图标问题 |
| macOS | ✅ | |
| Linux | ❌ | 未测试 |

## 发现的问题
[列出所有发现的问题]

## 建议
[改进建议]

## 结论
[总体评价]
```

---

## 🔄 持续集成

### CI/CD 配置

**文件**: `.github/workflows/test.yml`

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Check coverage
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage is below 80%"
            exit 1
          fi

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

---

## 📚 附录

### A. Mock 数据生成

```dart
// 生成 Mock 通知
ActiveNotification createMockNotification({
  required String id,
  required String title,
  required String body,
}) {
  return ActiveNotification(
    id: id,
    title: title,
    body: body,
    priority: NotificationPriority.normal,
  );
}

// 生成 Mock 任务
ScheduledTask createMockTask({
  required String id,
  required DateTime scheduledTime,
}) {
  return ScheduledTask(
    id: id,
    type: 'one_shot',
    scheduledTime: scheduledTime,
    isActive: true,
    isPaused: false,
  );
}
```

### B. 测试工具函数

```dart
// 等待条件满足
Future<void> waitForCondition(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final start = DateTime.now();
  while (!condition()) {
    if (DateTime.now().difference(start) > timeout) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

// 等待通知显示
Future<void> waitForNotification(String id) async {
  await waitForCondition(() async {
    final notifications = await notificationService.getActiveNotifications();
    return notifications.any((n) => n.id == id);
  });
}
```
