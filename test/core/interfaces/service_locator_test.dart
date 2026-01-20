import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/core/services/disposable.dart';
import 'package:plugin_platform/core/services/service_locator.dart';

// Test interfaces and classes
class TestInterface {}

class TestService implements TestInterface {
  final String id;

  TestService(this.id);
}

class DisposableService implements TestInterface, Disposable {
  final String id;
  bool disposed = false;

  DisposableService(this.id);

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FailingDisposableService implements TestInterface, Disposable {
  @override
  Future<void> dispose() async {
    throw Exception('Dispose failed');
  }
}

void main() {
  group('ServiceLocator Tests', () {
    late ServiceLocator locator;

    setUp(() {
      // Create a fresh instance for each test
      locator = ServiceLocator.instance;
      locator.clear();
    });

    tearDown(() async {
      // Clean up after each test
      await locator.disposeAll();
    });

    group('Singleton Registration', () {
      test('should register singleton service', () {
        // Arrange
        final service = TestService('test-1');

        // Act
        locator.registerSingleton<TestInterface>(service);

        // Assert
        expect(locator.isRegistered<TestInterface>(), true);
        expect(locator.get<TestInterface>(), same(service));
      });

      test('should return same instance for singleton', () {
        // Arrange
        final service = TestService('test-2');
        locator.registerSingleton<TestInterface>(service);

        // Act
        final instance1 = locator.get<TestInterface>();
        final instance2 = locator.get<TestInterface>();

        // Assert
        expect(identical(instance1, instance2), true);
        expect((instance1 as TestService).id, 'test-2');
      });

      test('should overwrite existing singleton', () {
        // Arrange
        final service1 = TestService('test-3');
        final service2 = TestService('test-4');

        locator.registerSingleton<TestInterface>(service1);

        // Act
        locator.registerSingleton<TestInterface>(service2);

        // Assert
        expect((locator.get<TestInterface>() as TestService).id, 'test-4');
      });
    });

    group('Factory Registration', () {
      test('should register factory function', () {
        // Arrange
        int callCount = 0;
        TestService factory() {
          callCount++;
          return TestService('factory-$callCount');
        }

        // Act
        locator.registerFactory<TestInterface>(factory);

        // Assert
        expect(locator.isRegistered<TestInterface>(), true);
      });

      test('should create service on first get', () {
        // Arrange
        locator.registerFactory<TestInterface>(() => TestService('factory-1'));

        // Act
        final service = locator.get<TestInterface>();

        // Assert
        expect(service, isA<TestService>());
        expect((service as TestService).id, 'factory-1');
      });

      test('should cache factory-created service', () {
        // Arrange
        int callCount = 0;
        locator.registerFactory<TestInterface>(() {
          callCount++;
          return TestService('factory-$callCount');
        });

        // Act
        final service1 = locator.get<TestInterface>();
        final service2 = locator.get<TestInterface>();

        // Assert
        expect(callCount, 1); // Factory called only once
        expect(identical(service1, service2), true);
      });
    });

    group('Service Retrieval', () {
      test('should throw exception when service not registered', () {
        // Act & Assert
        expect(
          () => locator.get<TestInterface>(),
          throwsA(isA<ServiceNotFoundException>()),
        );
      });

      test('should provide helpful error message', () {
        // Act & Assert
        try {
          locator.get<TestInterface>();
          fail('Should have thrown exception');
        } on ServiceNotFoundException catch (e) {
          expect(e.message, contains('TestInterface'));
          expect(e.message, contains('not registered'));
        }
      });

      test('should prioritize singleton over factory', () {
        // Arrange
        final singleton = TestService('singleton');
        locator.registerSingleton<TestInterface>(singleton);
        locator.registerFactory<TestInterface>(() => TestService('factory'));

        // Act
        final service = locator.get<TestInterface>();

        // Assert
        expect((service as TestService).id, 'singleton');
      });
    });

    group('Service Registration Check', () {
      test('should return false when service not registered', () {
        // Act & Assert
        expect(locator.isRegistered<TestInterface>(), false);
      });

      test('should return true when singleton registered', () {
        // Arrange
        locator.registerSingleton<TestInterface>(TestService('test'));

        // Act & Assert
        expect(locator.isRegistered<TestInterface>(), true);
      });

      test('should return true when factory registered', () {
        // Arrange
        locator.registerFactory<TestInterface>(() => TestService('test'));

        // Act & Assert
        expect(locator.isRegistered<TestInterface>(), true);
      });
    });

    group('Service Unregistration', () {
      test('should unregister singleton service', () async {
        // Arrange
        final service = TestService('test');
        locator.registerSingleton<TestInterface>(service);

        // Act
        await locator.unregister<TestInterface>();

        // Assert
        expect(locator.isRegistered<TestInterface>(), false);
      });

      test('should call dispose on disposable service', () async {
        // Arrange
        final service = DisposableService('disposable-1');
        locator.registerSingleton<TestInterface>(service);

        // Act
        await locator.unregister<TestInterface>();

        // Assert
        expect(service.disposed, true);
      });

      test('should handle unregistering non-existent service', () async {
        // Act & Assert (should not throw)
        await locator.unregister<TestInterface>();
        expect(locator.isRegistered<TestInterface>(), false);
      });

      test('should handle unregistering non-disposable service', () async {
        // Arrange
        final service = TestService('non-disposable');
        locator.registerSingleton<TestInterface>(service);

        // Act & Assert (should not throw)
        await locator.unregister<TestInterface>();
        expect(locator.isRegistered<TestInterface>(), false);
      });
    });

    group('Dispose All', () {
      test('should dispose all disposable services', () async {
        // Arrange
        final service1 = DisposableService('disposable-1');
        final service2 = TestService('non-disposable');

        locator.registerSingleton<DisposableService>(service1);
        locator.registerSingleton<TestService>(service2);

        // Act
        await locator.disposeAll();

        // Assert
        expect(service1.disposed, true);
      });

      test('should clear all registrations', () async {
        // Arrange
        locator.registerSingleton<TestService>(TestService('test-1'));
        locator.registerFactory<TestService>(() => TestService('test-2'));

        // Act
        await locator.disposeAll();

        // Assert
        expect(locator.isRegistered<TestService>(), false);
        expect(locator.serviceCount, 0);
      });

      test('should handle dispose errors gracefully', () async {
        // Arrange
        final service1 = FailingDisposableService();
        final service2 = DisposableService('ok');

        locator.registerSingleton<TestInterface>(service1);
        locator.registerSingleton<DisposableService>(service2);

        // Act & Assert (should not throw)
        await locator.disposeAll();
        expect(service2.disposed, true);
      });

      test('should reset singleton instance', () async {
        // Arrange
        final instance1 = ServiceLocator.instance;

        // Act
        await locator.disposeAll();
        final instance2 = ServiceLocator.instance;

        // Assert
        expect(identical(instance1, instance2), false);
      });
    });

    group('Service Information', () {
      test('should return registered types', () {
        // Arrange
        locator.registerSingleton<TestService>(TestService('test'));
        locator.registerSingleton<DisposableService>(DisposableService('test'));

        // Act
        final types = locator.registeredTypes;

        // Assert
        expect(types, contains(TestService));
        expect(types, contains(DisposableService));
      });

      test('should return correct service count', () {
        // Arrange
        locator.registerSingleton<TestService>(TestService('test-1'));
        locator.registerSingleton<TestService>(TestService('test-2'));
        locator.registerFactory<DisposableService>(
          () => DisposableService('test'),
        );

        // Act
        final count = locator.serviceCount;

        // Assert
        expect(count, 2); // TestService and DisposableService
      });
    });

    group('Clear', () {
      test('should clear all registrations without disposing', () async {
        // Arrange
        final service = DisposableService('test');
        locator.registerSingleton<TestInterface>(service);

        // Act
        locator.clear();

        // Assert
        expect(locator.isRegistered<TestInterface>(), false);
        expect(service.disposed, false); // Not disposed
      });

      test('should clear both singletons and factories', () {
        // Arrange
        locator.registerSingleton<TestService>(TestService('singleton'));
        locator.registerFactory<DisposableService>(
          () => DisposableService('factory'),
        );

        // Act
        locator.clear();

        // Assert
        expect(locator.serviceCount, 0);
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance across multiple calls', () {
        // Act
        final instance1 = ServiceLocator.instance;
        final instance2 = ServiceLocator.instance;

        // Assert
        expect(identical(instance1, instance2), true);
      });

      test('should maintain state across tests', () {
        // Arrange
        ServiceLocator.instance.registerSingleton<TestService>(
          TestService('global'),
        );

        // Act
        final locator2 = ServiceLocator.instance;

        // Assert
        expect(locator2.isRegistered<TestService>(), true);
      });
    });

    group('Edge Cases', () {
      test('should handle registering null service', () {
        // Act & Assert
        locator.registerSingleton<TestInterface?>(null);
        expect(locator.isRegistered<TestInterface?>(), true);
      });

      test('should handle multiple gets of factory service', () {
        // Arrange
        int creationCount = 0;
        locator.registerFactory<TestInterface>(() {
          creationCount++;
          return TestService('service-$creationCount');
        });

        // Act
        locator.get<TestInterface>();
        locator.get<TestInterface>();
        locator.get<TestInterface>();

        // Assert
        expect(creationCount, 1); // Created once and cached
      });

      test('should allow overriding factory with singleton', () {
        // Arrange
        locator.registerFactory<TestInterface>(() => TestService('factory'));
        final singleton = TestService('singleton');

        // Act
        locator.registerSingleton<TestInterface>(singleton);
        final service = locator.get<TestInterface>();

        // Assert
        expect((service as TestService).id, 'singleton');
      });
    });
  });
}
