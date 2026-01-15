/// Platform Service Manager
///
/// Centralized service initialization and access point.
library;

import 'package:flutter/foundation.dart';
import 'package:plugin_platform/core/services/service_locator.dart';
import 'package:plugin_platform/core/interfaces/services/i_notification_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_audio_service.dart';
import 'package:plugin_platform/core/interfaces/services/i_task_scheduler_service.dart';
import 'package:plugin_platform/core/services/notification/notification_service.dart';
import 'package:plugin_platform/core/services/audio/audio_service.dart';
import 'package:plugin_platform/core/services/task_scheduler/task_scheduler_service.dart';

/// Platform Service Manager
///
/// Provides a centralized way to initialize and access all platform services.
class PlatformServiceManager {
  static const String _tag = 'PlatformServiceManager';

  /// Initialize all platform services
  ///
  /// This should be called during app startup.
  /// Returns true if all services initialized successfully.
  static Future<bool> initialize() async {
    try {
      final locator = ServiceLocator.instance;

      // Register services
      _registerServices(locator);

      // Initialize services
      await _initializeServices(locator);

      if (kDebugMode) {
        print('$_tag: All services initialized successfully');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('$_tag: Initialization failed: $e');
        print(stackTrace);
      }
      return false;
    }
  }

  /// Register all services with the service locator
  static void _registerServices(ServiceLocator locator) {
    if (kDebugMode) {
      print('$_tag: Registering services...');
    }

    // Register notification service
    locator.registerSingleton<INotificationService>(
      NotificationServiceImpl(),
    );

    // Register audio service
    locator.registerSingleton<IAudioService>(
      AudioServiceImpl(),
    );

    // Register task scheduler service
    locator.registerSingleton<ITaskSchedulerService>(
      TaskSchedulerServiceImpl(),
    );

    if (kDebugMode) {
      print('$_tag: Services registered');
    }
  }

  /// Initialize all services
  static Future<void> _initializeServices(ServiceLocator locator) async {
    if (kDebugMode) {
      print('$_tag: Initializing services...');
    }

    // Initialize notification service
    final notificationService = locator.get<INotificationService>();
    final notificationInitialized = await notificationService.initialize();
    if (kDebugMode) {
      print('$_tag: Notification service initialized: $notificationInitialized');
    }

    // Initialize audio service
    final audioService = locator.get<IAudioService>();
    final audioInitialized = await audioService.initialize();
    if (kDebugMode) {
      print('$_tag: Audio service initialized: $audioInitialized');
    }

    // Initialize task scheduler service
    final taskSchedulerService = locator.get<ITaskSchedulerService>();
    final taskSchedulerInitialized = await taskSchedulerService.initialize();
    if (kDebugMode) {
      print('$_tag: Task scheduler service initialized: $taskSchedulerInitialized');
    }
  }

  /// Get the notification service
  static INotificationService get notification {
    return ServiceLocator.instance.get<INotificationService>();
  }

  /// Get the audio service
  static IAudioService get audio {
    return ServiceLocator.instance.get<IAudioService>();
  }

  /// Get the task scheduler service
  static ITaskSchedulerService get taskScheduler {
    return ServiceLocator.instance.get<ITaskSchedulerService>();
  }

  /// Check if a service is available
  static bool isServiceAvailable<T>() {
    return ServiceLocator.instance.isRegistered<T>();
  }

  /// Dispose all services
  ///
  /// This should be called during app shutdown.
  static Future<void> dispose() async {
    if (kDebugMode) {
      print('$_tag: Disposing all services...');
    }

    await ServiceLocator.instance.disposeAll();

    if (kDebugMode) {
      print('$_tag: All services disposed');
    }
  }
}
