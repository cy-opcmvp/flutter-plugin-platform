// 覆盖场景清单（存储契约 Windows io 实现）：
// 1. 真临时目录 KV 往返：写读改删 + 跨实例（重开 JsonPluginStorage）持久一致。
// 2. 插件命名空间隔离：两个插件同键互不影响。
// 3. 原子写（简化为顺序）：连续多次覆盖写后终态一致，且目录内无残留 tmp。
// 4. 损坏文件：read 抛 storage.io_error（reason: read）。
// 5. 不可写根：write 抛 storage.io_error（reason: write）。
library;

import 'dart:io';

import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kv_storage_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  final PluginId calculator = PluginId.parse('tools.calculator');
  final PluginId screenshot = PluginId.parse('tools.screenshot');

  test('真临时目录 KV 往返，跨实例持久一致', () async {
    final JsonPluginStorage storage = JsonPluginStorage(rootDir: tempDir.path);

    expect(await storage.read(calculator, 'settings'), isNull);

    await storage.write(calculator, 'settings', '{"fractionDigits":3}');
    expect(await storage.read(calculator, 'settings'), '{"fractionDigits":3}');

    // 跨实例：重开实现后仍可读到（落盘而非仅内存）。
    final JsonPluginStorage reopened = JsonPluginStorage(rootDir: tempDir.path);
    expect(await reopened.read(calculator, 'settings'), '{"fractionDigits":3}');

    await reopened.delete(calculator, 'settings');
    expect(await reopened.read(calculator, 'settings'), isNull);
  });

  test('插件命名空间按目录隔离，同键互不影响', () async {
    final JsonPluginStorage storage = JsonPluginStorage(rootDir: tempDir.path);

    await storage.write(calculator, 'settings', 'calc');
    await storage.write(screenshot, 'settings', 'shot');

    expect(await storage.read(calculator, 'settings'), 'calc');
    expect(await storage.read(screenshot, 'settings'), 'shot');
    expect(Directory('${tempDir.path}/tools.calculator').existsSync(), isTrue);
  });

  test('原子写（顺序简化）：连续覆盖写终态一致且无残留临时文件', () async {
    final JsonPluginStorage storage = JsonPluginStorage(rootDir: tempDir.path);

    for (int i = 0; i < 5; i++) {
      await storage.write(calculator, 'counter', '$i');
    }
    expect(await storage.read(calculator, 'counter'), '4');

    final List<String> leftovers = Directory(
      '${tempDir.path}/tools.calculator',
    ).listSync().map((FileSystemEntity entity) => entity.path).toList();
    expect(leftovers.single, endsWith('kv.json'));
  });

  test('损坏的 KV 文件：read 抛 storage.io_error（reason: read）', () async {
    final File bad = File('${tempDir.path}/tools.calculator/kv.json');
    await bad.create(recursive: true);
    await bad.writeAsString('{not-json');

    final JsonPluginStorage storage = JsonPluginStorage(rootDir: tempDir.path);
    await expectLater(
      storage.read(calculator, 'settings'),
      throwsA(
        isA<PluginFailure>()
            .having((PluginFailure f) => f.code, 'code', 'storage.io_error')
            .having((PluginFailure f) => f.details['reason'], 'reason', 'read'),
      ),
    );
  });

  test('不可写根目录：write 抛 storage.io_error（reason: write）', () async {
    // 根路径挂在一个已有文件之下，目录创建必然失败。
    final File blocker = File('${tempDir.path}/blocker');
    await blocker.writeAsString('not a dir');

    final JsonPluginStorage storage = JsonPluginStorage(
      rootDir: '${blocker.path}/storage',
    );
    await expectLater(
      storage.write(calculator, 'settings', 'x'),
      throwsA(
        isA<PluginFailure>()
            .having((PluginFailure f) => f.code, 'code', 'storage.io_error')
            .having(
              (PluginFailure f) => f.details['reason'],
              'reason',
              'write',
            ),
      ),
    );
  });
}
