// 覆盖场景清单（计算器设置持久化接线，缺口②焦点测试）：
// 1. 未注入 storage：loadFromStorage 为无操作，设置保持默认。
// 2. 注入 storage：改设置即写回；新建模型 loadFromStorage 后设置恢复一致。
// 3. 持久化值损坏（非 JSON）：loadFromStorage 静默保持当前设置。
// 4. 存储读失败（storage.io_error）：loadFromStorage 静默降级不抛出。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

/// 只在 read 抛 read 失败的降级测试实现。
final class _FailingPluginStorage implements PluginStorage {
  @override
  Future<String?> read(PluginId plugin, String key) {
    throw storageIoFailure('read', '注入的读取失败');
  }

  @override
  Future<void> write(PluginId plugin, String key, String value) async {}

  @override
  Future<void> delete(PluginId plugin, String key) async {}
}

void main() {
  test('未注入 storage 时 loadFromStorage 为无操作', () async {
    final CalculatorModel model = CalculatorModel();

    await model.loadFromStorage();

    expect(model.settings, const CalculatorSettings());
  });

  test('注入 storage 后改设置即写回，新建模型可恢复', () async {
    final InMemoryPluginStorage storage = InMemoryPluginStorage();
    final CalculatorModel model = CalculatorModel(storage: storage);

    model.updateSettings(
      const CalculatorSettings(fractionDigits: 7, showHistory: false),
    );
    // 恢复入口：新建模型共享同一存储，加载后设置一致。
    final CalculatorModel restored = CalculatorModel(storage: storage);
    await restored.loadFromStorage();

    expect(
      restored.settings,
      const CalculatorSettings(fractionDigits: 7, showHistory: false),
    );
  });

  test('持久化值损坏时静默保持当前设置', () async {
    final InMemoryPluginStorage storage = InMemoryPluginStorage();
    await storage.write(
      PluginId.parse(kCalculatorPluginId),
      'settings',
      '{bad',
    );

    final CalculatorModel model = CalculatorModel(storage: storage);
    await model.loadFromStorage();

    expect(model.settings, const CalculatorSettings());
  });

  test('存储读失败时静默降级不抛出', () async {
    final CalculatorModel model = CalculatorModel(
      storage: _FailingPluginStorage(),
    );

    await model.loadFromStorage();

    expect(model.settings, const CalculatorSettings());
  });
}
