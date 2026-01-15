/// Service Locator for managing platform services
///
/// This service locator provides a centralized way to register, retrieve,
/// and manage all platform services. It implements the Singleton pattern
/// to ensure a single instance throughout the application lifecycle.
library;

import 'dart:async';
import 'disposable.dart';

/// Exception thrown when a requested service is not registered
class ServiceNotFoundException implements Exception {
  final String message;

  const ServiceNotFoundException(this.message);

  @override
  String toString() => 'ServiceNotFoundException: $message';
}

/// Service Locator for managing platform services
///
/// The ServiceLocator is responsible for:
/// - Registering service instances (singletons and factories)
/// - Retrieving registered services
/// - Managing service lifecycle (initialization and disposal)
/// - Handling service dependencies
///
/// Example usage:
/// ```dart
/// // Register a singleton service
/// ServiceLocator.instance.registerSingleton<INotificationService>(
///   NotificationServiceImpl(),
/// );
///
/// // Retrieve a service
/// final notificationService = ServiceLocator.instance.get<INotificationService>();
///
/// // Check if a service is registered
/// if (ServiceLocator.instance.isRegistered<INotificationService>()) {
///   // Service is available
/// }
/// ```
class ServiceLocator {
  // Private constructor for Singleton pattern
  ServiceLocator._();

  // Singleton instance
  static ServiceLocator? _instance;

  /// Get the singleton instance of ServiceLocator
  static ServiceLocator get instance {
    _instance ??= ServiceLocator._();
    return _instance!;
  }

  /// Service registry for singleton instances
  final Map<Type, dynamic> _services = {};

  /// Service registry for factory functions
  final Map<Type, dynamic> _factories = {};

  /// Register a singleton service instance
  ///
  /// A singleton service is created once and reused for all subsequent requests.
  /// This is suitable for services that maintain state or are expensive to create.
  ///
  /// Example:
  /// ```dart
  /// locator.registerSingleton<INotificationService>(
  ///   NotificationServiceImpl(),
  /// );
  /// ```
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// Register a factory function for deferred service creation
  ///
  /// The factory function is called on the first request for the service,
  /// and the result is cached for subsequent requests. This is useful for
  /// services that should be created lazily or have complex initialization.
  ///
  /// Example:
  /// ```dart
  /// locator.registerFactory<INotificationService>(() {
  ///   return NotificationServiceImpl();
  /// });
  /// ```
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Retrieve a registered service
  ///
  /// Throws [ServiceNotFoundException] if the service is not registered.
  ///
  /// Example:
  /// ```dart
  /// final notificationService = locator.get<INotificationService>();
  /// ```
  T get<T>() {
    // First, check if we have a singleton instance
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Next, check if we have a factory function
    if (_factories.containsKey(T)) {
      final factory = _factories[T] as T Function();
      final service = factory();

      // Cache the created service as a singleton
      _services[T] = service;

      return service;
    }

    // Service not found
    throw ServiceNotFoundException(
      'Service $T is not registered. '
      'Make sure to register the service before attempting to retrieve it.',
    );
  }

  /// Check if a service is registered
  ///
  /// Returns true if either a singleton instance or a factory function
  /// is registered for the given type.
  ///
  /// Example:
  /// ```dart
  /// if (locator.isRegistered<INotificationService>()) {
  ///   // Service is available
  /// }
  /// ```
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregister a service and dispose it if it implements [Disposable]
  ///
  /// This removes the service from the registry and calls its dispose method
  /// if it implements the [Disposable] interface.
  ///
  /// Example:
  /// ```dart
  /// await locator.unregister<INotificationService>();
  /// ```
  Future<void> unregister<T>() async {
    final service = _services.remove(T);

    if (service is Disposable) {
      await service.dispose();
    }
  }

  /// Dispose all registered services
  ///
  /// This calls the dispose method on all services that implement [Disposable]
  /// and clears all registrations. This should be called when the application
  /// is shutting down.
  ///
  /// Example:
  /// ```dart
  /// await locator.disposeAll();
  /// ```
  Future<void> disposeAll() async {
    // Dispose all services in reverse order (LIFO)
    final services = _services.values.toList();
    for (final service in services.reversed) {
      if (service is Disposable) {
        try {
          await service.dispose();
        } catch (e) {
          // Log error but continue disposing other services
          print('Error disposing service: $e');
        }
      }
    }

    // Clear all registrations
    _services.clear();
    _factories.clear();

    // NOTE: Don't reset _instance to null here.
    // This allows the service locator to be reused if needed,
    // and prevents LateInitializationError when accessed after disposal.
  }

  /// Get all registered service types
  ///
  /// Returns a list of all service types that are currently registered
  /// (either as singletons or factories).
  List<Type> get registeredTypes {
    return [
      ..._services.keys,
      ..._factories.keys,
    ];
  }

  /// Get the count of registered services
  ///
  /// Returns the total number of unique service types registered.
  int get serviceCount {
    final types = <Type>{};
    types.addAll(_services.keys);
    types.addAll(_factories.keys);
    return types.length;
  }

  /// Clear all registrations without disposing services
  ///
  /// This is useful for testing or when you want to reset the service locator
  /// without calling dispose methods. For normal shutdown, use [disposeAll].
  ///
  /// Warning: This does not dispose any services. Use with caution.
  void clear() {
    _services.clear();
    _factories.clear();
  }
}
