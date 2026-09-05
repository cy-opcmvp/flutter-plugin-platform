// 覆盖场景清单（S1 批B焦点测试：截图保存设置持久化接线）：
// 1. 未注入 storage：loadFromStorage 为无操作，设置保持默认。
// 2. 注入 storage：改设置（目录/模板/格式/质量/自动复制）即写回；
//    新建模型 load 后恢复一致。
// 3. 持久化格式键非法：恢复时回退默认格式（模板正常恢复）。
// 4. 存储读失败（storage.io_error）：loadFromStorage 静默降级不抛出。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:screenshot/screenshot.dart';

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
    final ScreenshotModel model = ScreenshotModel();

    await model.loadFromStorage();

    expect(model.settings, ScreenshotSettings());
  });

  test('注入 storage 后改设置即写回，新建模型可恢复', () async {
    final InMemoryPluginStorage storage = InMemoryPluginStorage();
    final ScreenshotModel model = ScreenshotModel(storage: storage);

    model.updateSettings(
      model.settings.copyWith(
        saveDir: '{documents}',
        filenameTemplate: 'clip-{date}',
        format: 'jpeg',
        jpegQuality: 75,
        autoCopy: 'path',
      ),
    );
    final ScreenshotModel restored = ScreenshotModel(storage: storage);
    await restored.loadFromStorage();

    expect(
      restored.settings,
      ScreenshotSettings(
        saveDir: '{documents}',
        filenameTemplate: 'clip-{date}',
        format: 'jpeg',
        jpegQuality: 75,
        autoCopy: 'path',
      ),
    );
  });

  test('持久化格式键非法时回退默认格式，模板正常恢复', () async {
    final InMemoryPluginStorage storage = InMemoryPluginStorage();
    await storage.write(
      PluginId.parse(kScreenshotPluginId),
      'settings',
      '{"filenameTemplate":"clip","format":"webp"}',
    );

    final ScreenshotModel model = ScreenshotModel(storage: storage);
    await model.loadFromStorage();

    expect(model.settings.filenameTemplate, 'clip');
    expect(model.settings.format, 'png');
  });

  test('存储读失败时静默降级不抛出', () async {
    final ScreenshotModel model = ScreenshotModel(
      storage: _FailingPluginStorage(),
    );

    await model.loadFromStorage();

    expect(model.settings, ScreenshotSettings());
  });
}
