// 覆盖场景清单（存储契约最小版，设计 §2.6）：
// 1. InMemoryPluginStorage KV 往返：无值读 null → 写入可读 → 覆盖写生效
//    → 删除后回到 null；插件命名空间互不串扰。
// 2. storageIoFailure：code == storage.io_error 且 details 携带 reason。
// 3. 接口包边界扫描：lib/ 全部源码零 dart:io / dart:ffi import（六端可编译）。
library;

import 'dart:io';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  final PluginId calculator = PluginId.parse('tools.calculator');
  final PluginId screenshot = PluginId.parse('tools.screenshot');

  group('InMemoryPluginStorage', () {
    late InMemoryPluginStorage storage;

    setUp(() {
      storage = InMemoryPluginStorage();
    });

    test('KV 往返：写读改删，无值返回 null', () async {
      expect(await storage.read(calculator, 'settings'), isNull);

      await storage.write(calculator, 'settings', '{"a":1}');
      expect(await storage.read(calculator, 'settings'), '{"a":1}');

      await storage.write(calculator, 'settings', '{"a":2}');
      expect(await storage.read(calculator, 'settings'), '{"a":2}');

      await storage.delete(calculator, 'settings');
      expect(await storage.read(calculator, 'settings'), isNull);
    });

    test('删除不存在的键为无操作，命名空间按插件隔离', () async {
      await storage.delete(calculator, 'missing');

      await storage.write(calculator, 'settings', 'calc');
      await storage.write(screenshot, 'settings', 'shot');

      expect(await storage.read(calculator, 'settings'), 'calc');
      expect(await storage.read(screenshot, 'settings'), 'shot');
    });
  });

  test('storageIoFailure 携带 reason 与补充上下文', () {
    final PluginFailure failure = storageIoFailure(
      'write',
      '磁盘不可写',
      <String, Object?>{'path': '/x/kv.json'},
    );
    expect(failure.code, 'storage.io_error');
    expect(failure.details['reason'], 'write');
    expect(failure.details['path'], '/x/kv.json');
  });

  test('接口包边界扫描：lib 源码零 dart:io / dart:ffi import', () {
    final List<String> offenders = <String>[];
    for (final File file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final String source = file.readAsStringSync();
      if (source.contains("import 'dart:io'") ||
          source.contains('import "dart:io"') ||
          source.contains("import 'dart:ffi'") ||
          source.contains('import "dart:ffi"')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: '接口包必须保持六端零平台依赖');
  });
}
