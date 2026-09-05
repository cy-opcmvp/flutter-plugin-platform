// 覆盖场景清单：
// 1. build → reader.read 往返：清单字段与条目一致，entryByPath 命中且字节一致。
// 2. 索引中每个条目的 sha256 为 64 位小写 hex。
// 3. 条目按加入顺序写入（索引顺序稳定）。
// 4. 缺少 plugin.json 条目时 build 抛 PackageException(manifestMissing)。
// 5. add 非法路径立即抛 PackageException(package.path_unsafe)。
import 'dart:convert';
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

void main() {
  final manifestJson = <String, Object?>{
    'id': 'dev.example.echo',
    'name': 'Echo',
    'version': '1.0.0',
    'apiVersion': 1,
    'kind': 'sidecar',
    'targets': ['windows'],
    'entrypoint': 'echo_sidecar.py',
    'provides': <Object?>[],
    'requires': <Object?>[],
    'surfaces': ['command'],
    'configSchemaVersion': 1,
    'dataSchemaVersion': 1,
  };
  final manifestBytes = utf8.encode(jsonEncode(manifestJson));
  final scriptBytes = utf8.encode('print("echo")\n');

  Uint8List readIndexLengthIsAt(Uint8List bytes) {
    final indexLength = ByteData.sublistView(
      bytes,
      4,
      8,
    ).getUint32(0, Endian.big);
    return Uint8List.sublistView(bytes, 8, 8 + indexLength);
  }

  group('PackageBuilder', () {
    test('round trip preserves manifest and entries', () {
      final bytes = PackageBuilder()
          .add('plugin.json', manifestBytes)
          .add('echo_sidecar.py', scriptBytes)
          .build();

      final pkg = PackageReader.fromBytes(bytes).read();
      expect(pkg.manifest.id.value, 'dev.example.echo');
      expect(pkg.manifest.name, 'Echo');
      expect(pkg.manifest.kind, PluginKind.sidecar);
      expect(pkg.manifest.entrypoint, 'echo_sidecar.py');
      expect(pkg.manifest.targets, contains(PluginTarget.windows));
      expect(pkg.entries.length, 2);
      expect(pkg.entryByPath('plugin.json')!.bytes, manifestBytes);
      expect(pkg.entryByPath('echo_sidecar.py')!.bytes, scriptBytes);
      expect(pkg.entryByPath('missing.txt'), isNull);
    });

    test('index digests are 64 lowercase hex characters', () {
      final bytes = PackageBuilder()
          .add('plugin.json', manifestBytes)
          .add('echo_sidecar.py', scriptBytes)
          .build();

      final index =
          jsonDecode(utf8.decode(readIndexLengthIsAt(bytes)))
              as Map<String, Object?>;
      final entries = index['entries']! as List<Object?>;
      expect(entries, hasLength(2));
      for (final entry in entries) {
        expect(
          (entry! as Map<String, Object?>)['sha256'] as String,
          matches(RegExp(r'^[0-9a-f]{64}$')),
        );
      }
    });

    test('entries are written in insertion order', () {
      final bytes = PackageBuilder()
          .add('plugin.json', manifestBytes)
          .add('echo_sidecar.py', scriptBytes)
          .build();

      final pkg = PackageReader.fromBytes(bytes).read();
      expect(pkg.entries[0].path, 'plugin.json');
      expect(pkg.entries[1].path, 'echo_sidecar.py');
    });

    test('build without plugin.json fails with manifestMissing', () {
      final builder = PackageBuilder().add('echo_sidecar.py', scriptBytes);
      try {
        builder.build();
        fail('expected PackageException');
      } on PackageException catch (e) {
        expect(e.failure.code, 'package.bad_format');
        expect(e.failure.details['reason'], 'manifestMissing');
      }
    });

    test('add rejects unsafe paths immediately', () {
      expect(
        () => PackageBuilder().add('../x', scriptBytes),
        throwsA(
          isA<PackageException>().having(
            (e) => e.failure.code,
            'code',
            'package.path_unsafe',
          ),
        ),
      );
    });
  });
}
