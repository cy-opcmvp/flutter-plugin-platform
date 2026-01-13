import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/plugins/world_clock/world_clock_plugin.dart';
import 'package:plugin_platform/plugins/world_clock/models/world_clock_models.dart';
import 'package:plugin_platform/core/models/plugin_models.dart';
import 'package:plugin_platform/core/models/platform_models.dart';
import 'package:plugin_platform/core/interfaces/i_plugin.dart';
import 'package:plugin_platform/core/interfaces/i_platform_services.dart';

// Mock 实现
class MockPlatformServices implements IPlatformServices {
  final List<String> notifications = [];
  
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> showNotification(String message) async {
    notifications.add(message);
  }
  
  @override
  Future<void> requestPermission(Permission permission) async {}
  
  @override
  Future<bool> hasPermission(Permission permission) async => true;
  
  @override
  Future<void> openExternalUrl(String url) async {}
  
  @override
  Stream<PlatformEvent> get eventStream => const Stream.empty();
  
  @override
  PlatformInfo get platformInfo => const PlatformInfo(
    type: PlatformType.desktop,
    version: '1.0.0',
    capabilities: {},
  );
}

class MockDataStorage implements IDataStorage {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> store(String key, dynamic value) async {
    _storage[key] = value;
  }
  
  @override
  Future<T?> retrieve<T>(String key) async {
    return _storage[key] as T?;
  }
  
  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

class MockNetworkAccess implements INetworkAccess {
  @override
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    return {'status': 'success', 'data': 'mock data'};
  }
  
  @override
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    return {'status': 'success'};
  }
  
  @override
  Future<bool> isConnected() async => true;
}

void main() {
  group('WorldClockPlugin Tests', () {
    late WorldClockPlugin plugin;
    late MockPlatformServices mockPlatformServices;
    late MockDataStorage mockDataStorage;
    late MockNetworkAccess mockNetworkAccess;
    late PluginContext context;

    setUp(() {
      plugin = WorldClockPlugin();
      mockPlatformServices = MockPlatformServices();
      mockDataStorage = MockDataStorage();
      mockNetworkAccess = MockNetworkAccess();
      
      context = PluginContext(
        platformServices: mockPlatformServices,
        dataStorage: mockDataStorage,
        networkAccess: mockNetworkAccess,
        configuration: {},
      );
    });

    test('Plugin properties should be correct', () {
      expect(plugin.id, 'com.example.worldclock');
      expect(plugin.name, '世界时钟');
      expect(plugin.version, '1.0.0');
      expect(plugin.type, PluginType.tool);
    });

    test('Plugin should initialize successfully', () async {
      await plugin.initialize(context);
      
      // 验证初始化通知
      expect(mockPlatformServices.notifications, contains('世界时钟 插件已成功初始化'));
    });

    test('Plugin should handle state changes', () async {
      await plugin.initialize(context);
      
      // 测试状态变化
      await plugin.onStateChanged(PluginState.active);
      await plugin.onStateChanged(PluginState.paused);
      await plugin.onStateChanged(PluginState.inactive);
    });

    test('Plugin should save and restore state', () async {
      await plugin.initialize(context);
      
      // 获取初始状态
      final initialState = await plugin.getState();
      expect(initialState, isA<Map<String, dynamic>>());
      expect(initialState['version'], '1.0.0');
      expect(initialState['isInitialized'], true);
    });

    test('Plugin should dispose cleanly', () async {
      await plugin.initialize(context);
      await plugin.dispose();
      
      // 验证没有抛出异常
    });
  });

  group('WorldClockItem Tests', () {
    test('WorldClockItem should create correctly', () {
      final clock = WorldClockItem(
        id: 'test',
        cityName: '北京',
        timeZone: 'Asia/Shanghai',
        isDefault: true,
      );

      expect(clock.id, 'test');
      expect(clock.cityName, '北京');
      expect(clock.timeZone, 'Asia/Shanghai');
      expect(clock.isDefault, true);
    });

    test('WorldClockItem should format time correctly', () {
      final clock = WorldClockItem(
        id: 'test',
        cityName: '北京',
        timeZone: 'Asia/Shanghai',
        isDefault: true,
      );

      // 验证时间格式
      expect(clock.formattedTime, matches(r'^\d{2}:\d{2}:\d{2}$'));
      expect(clock.formattedDate, isNotEmpty);
    });

    test('WorldClockItem should serialize/deserialize correctly', () {
      final original = WorldClockItem(
        id: 'test',
        cityName: '北京',
        timeZone: 'Asia/Shanghai',
        isDefault: true,
      );

      final json = original.toJson();
      final restored = WorldClockItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.cityName, original.cityName);
      expect(restored.timeZone, original.timeZone);
      expect(restored.isDefault, original.isDefault);
    });
  });

  group('CountdownTimer Tests', () {
    test('CountdownTimer should create correctly', () {
      final endTime = DateTime.now().add(const Duration(minutes: 5));
      final timer = CountdownTimer(
        id: 'test',
        title: '测试倒计时',
        endTime: endTime,
        isCompleted: false,
      );

      expect(timer.id, 'test');
      expect(timer.title, '测试倒计时');
      expect(timer.endTime, endTime);
      expect(timer.isCompleted, false);
    });

    test('CountdownTimer should calculate remaining time correctly', () {
      final endTime = DateTime.now().add(const Duration(minutes: 5));
      final timer = CountdownTimer(
        id: 'test',
        title: '测试倒计时',
        endTime: endTime,
        isCompleted: false,
      );

      final remaining = timer.remainingTime;
      expect(remaining.inMinutes, greaterThanOrEqualTo(4));
      expect(remaining.inMinutes, lessThanOrEqualTo(5));
    });

    test('CountdownTimer should format remaining time correctly', () {
      final endTime = DateTime.now().add(const Duration(hours: 1, minutes: 30, seconds: 45));
      final timer = CountdownTimer(
        id: 'test',
        title: '测试倒计时',
        endTime: endTime,
        isCompleted: false,
      );

      expect(timer.formattedRemainingTime, matches(r'^\d{2}:\d{2}:\d{2}$'));
    });

    test('CountdownTimer should handle completed state', () {
      final endTime = DateTime.now().subtract(const Duration(minutes: 1));
      final timer = CountdownTimer(
        id: 'test',
        title: '测试倒计时',
        endTime: endTime,
        isCompleted: true,
      );

      expect(timer.remainingTime, Duration.zero);
      expect(timer.formattedRemainingTime, '00:00:00');
    });

    test('CountdownTimer should serialize/deserialize correctly', () {
      final endTime = DateTime.now().add(const Duration(minutes: 5));
      final original = CountdownTimer(
        id: 'test',
        title: '测试倒计时',
        endTime: endTime,
        isCompleted: false,
      );

      final json = original.toJson();
      final restored = CountdownTimer.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.endTime, original.endTime);
      expect(restored.isCompleted, original.isCompleted);
    });
  });

  group('TimeZoneInfo Tests', () {
    test('TimeZoneInfo should find predefined timezones', () {
      final beijing = TimeZoneInfo.findByTimeZoneId('Asia/Shanghai');
      expect(beijing, isNotNull);
      expect(beijing!.displayName, '北京');
      expect(beijing.offsetHours, 8);

      final tokyo = TimeZoneInfo.findByTimeZoneId('Asia/Tokyo');
      expect(tokyo, isNotNull);
      expect(tokyo!.displayName, '东京');
      expect(tokyo.offsetHours, 9);
    });

    test('TimeZoneInfo should return null for unknown timezone', () {
      final unknown = TimeZoneInfo.findByTimeZoneId('Unknown/Timezone');
      expect(unknown, isNull);
    });

    test('TimeZoneInfo should have predefined timezones', () {
      expect(TimeZoneInfo.predefinedTimeZones, isNotEmpty);
      expect(TimeZoneInfo.predefinedTimeZones.length, greaterThanOrEqualTo(10));
    });
  });
}