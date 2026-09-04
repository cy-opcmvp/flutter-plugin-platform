// 覆盖场景清单：
// 1. 好包往返：manifest 字段与源一致、条目字节一致。
// 2. 魔数篡改 'SCP2' → badMagic。
// 3. 截断（去尾 10 字节 / 只留 6 字节）与索引长度字段超实际 → truncated。
// 4. 索引非严格 JSON / 未知字段 / 条目缺字段 → indexInvalid。
// 5. 条目 sha256 改一位 → digestMismatch；length 与实际不符 → digestMismatch
//    或 truncated。
// 6. 小 limits：条目数 / 单条字节 / 总字节 / 索引字节超限 → limitExceeded。
// 7. 缺 plugin.json 条目 → manifestMissing。
// 8. 清单 kind=builtin → indexInvalid；entrypoint 无对应条目 →
//    entrypointMissing。
// 9. 路径攻击 '../x' → PackageException 内嵌 package.path_unsafe；大小写重复
//    条目 → duplicate。
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
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

  /// 两条目的合法好包。
  Uint8List buildGoodPackage() {
    return PackageBuilder()
        .add('plugin.json', manifestBytes)
        .add('echo_sidecar.py', scriptBytes)
        .build();
  }

  int indexLengthOf(Uint8List bytes) {
    return ByteData.sublistView(bytes, 4, 8).getUint32(0, Endian.big);
  }

  /// 容器中条目字节段（索引之后的全部字节）。
  Uint8List payloadOf(Uint8List bytes) {
    return Uint8List.sublistView(bytes, 8 + indexLengthOf(bytes));
  }

  /// 解析好包的索引 JSON。
  Map<String, Object?> readIndexJson(Uint8List bytes) {
    return jsonDecode(
          utf8.decode(
            Uint8List.sublistView(bytes, 8, 8 + indexLengthOf(bytes)),
          ),
        )
        as Map<String, Object?>;
  }

  /// 保留原条目字节段，替换索引 JSON 后重拼容器。
  Uint8List withIndexJson(Uint8List goodBytes, String indexJson) {
    final payload = payloadOf(goodBytes);
    final newIndexBytes = utf8.encode(indexJson);
    final header = ByteData(8)
      ..setUint32(0, 0x53435031, Endian.big)
      ..setUint32(4, newIndexBytes.length, Endian.big);
    final out = BytesBuilder()
      ..add(header.buffer.asUint8List())
      ..add(newIndexBytes)
      ..add(payload);
    return out.takeBytes();
  }

  PluginFailure failureOf(
    Uint8List bytes, {
    PackageLimits limits = const PackageLimits(),
  }) {
    try {
      PackageReader.fromBytes(bytes, limits: limits).read();
      fail('expected PackageException');
    } on PackageException catch (e) {
      return e.failure;
    }
  }

  Uint8List manifestVariant(Map<String, Object?> overrides) {
    final json = <String, Object?>{...manifestJson, ...overrides};
    return PackageBuilder()
        .add('plugin.json', utf8.encode(jsonEncode(json)))
        .build();
  }

  group('PackageReader', () {
    test('good package round trips with identical fields', () {
      final pkg = PackageReader.fromBytes(buildGoodPackage()).read();
      expect(pkg.manifest.id.value, 'dev.example.echo');
      expect(pkg.manifest.version, '1.0.0');
      expect(pkg.manifest.apiVersion, 1);
      expect(pkg.manifest.kind, PluginKind.sidecar);
      expect(pkg.manifest.entrypoint, 'echo_sidecar.py');
      expect(pkg.manifest.surfaces, ['command']);
      expect(pkg.entries, hasLength(2));
      expect(pkg.entryByPath('plugin.json')!.bytes, manifestBytes);
      expect(pkg.entryByPath('echo_sidecar.py')!.bytes, scriptBytes);
    });

    test('corrupted magic is rejected with badMagic', () {
      final bytes = Uint8List.fromList(buildGoodPackage());
      bytes[3] = 0x32; // 'SCP1' → 'SCP2'
      expect(failureOf(bytes).details['reason'], 'badMagic');
    });

    test('truncated containers are rejected', () {
      final good = buildGoodPackage();
      expect(
        failureOf(
          Uint8List.sublistView(good, 0, good.length - 10),
        ).details['reason'],
        'truncated',
      );
      expect(
        failureOf(Uint8List.sublistView(good, 0, 6)).details['reason'],
        'truncated',
      );

      // 索引长度字段声明超出容器实际字节（声明无法被容器容纳）。
      final tampered = Uint8List.fromList(good);
      ByteData.sublistView(
        tampered,
        4,
        8,
      ).setUint32(0, good.length - 8 + 16, Endian.big);
      expect(failureOf(tampered).details['reason'], 'truncated');
    });

    test('malformed index JSON is rejected with indexInvalid', () {
      expect(
        failureOf(
          withIndexJson(buildGoodPackage(), '{"entries":['),
        ).details['reason'],
        'indexInvalid',
      );
      expect(
        failureOf(
          withIndexJson(buildGoodPackage(), '{"entries":[],"EXTRA":1}'),
        ).details['reason'],
        'indexInvalid',
      );
      expect(
        failureOf(
          withIndexJson(
            buildGoodPackage(),
            '{"entries":[{"path":"plugin.json","length":1}]}',
          ),
        ).details['reason'],
        'indexInvalid',
      );
    });

    test('entry digest mismatch and length mismatch are rejected', () {
      // sha256 改一位。
      final index = readIndexJson(buildGoodPackage());
      final first =
          (index['entries']! as List<Object?>).first as Map<String, Object?>;
      final digest = first['sha256']! as String;
      first['sha256'] =
          (digest.codeUnitAt(0) == 0x30 ? '1' : '0') + digest.substring(1);
      expect(
        failureOf(
          withIndexJson(buildGoodPackage(), jsonEncode(index)),
        ).details['reason'],
        'digestMismatch',
      );

      // length 与实际字节不符。
      final index2 = readIndexJson(buildGoodPackage());
      final first2 =
          (index2['entries']! as List<Object?>).first as Map<String, Object?>;
      first2['length'] = (first2['length']! as int) + 1;
      expect(
        failureOf(
          withIndexJson(buildGoodPackage(), jsonEncode(index2)),
        ).details['reason'],
        anyOf('digestMismatch', 'truncated'),
      );
    });

    test('limits are enforced with reason limitExceeded', () {
      final good = buildGoodPackage();
      expect(
        failureOf(
          good,
          limits: const PackageLimits(maxEntries: 1),
        ).details['reason'],
        'limitExceeded',
      );
      expect(
        failureOf(
          good,
          limits: const PackageLimits(maxEntryBytes: 2),
        ).details['reason'],
        'limitExceeded',
      );
      expect(
        failureOf(
          good,
          limits: const PackageLimits(maxTotalBytes: 5),
        ).details['reason'],
        'limitExceeded',
      );
      expect(
        failureOf(
          good,
          limits: const PackageLimits(maxIndexBytes: 4),
        ).details['reason'],
        'limitExceeded',
      );
    });

    test('missing plugin.json entry is rejected with manifestMissing', () {
      final good = buildGoodPackage();
      final payload = payloadOf(good);
      final index =
          '{"entries":[{"path":"readme.txt","length":${payload.length},'
          '"sha256":"${crypto.sha256.convert(payload)}"}]}';
      expect(
        failureOf(withIndexJson(good, index)).details['reason'],
        'manifestMissing',
      );
    });

    test('non-sidecar manifest is rejected with indexInvalid', () {
      expect(
        failureOf(manifestVariant({'kind': 'builtin'})).details['reason'],
        'indexInvalid',
      );
    });

    test('missing entrypoint entry is rejected with entrypointMissing', () {
      expect(
        failureOf(manifestVariant({'entrypoint': 'run.py'})).details['reason'],
        'entrypointMissing',
      );
    });

    test('path attacks and duplicates are rejected with path_unsafe', () {
      final traversal = failureOf(
        withIndexJson(
          buildGoodPackage(),
          '{"entries":[{"path":"../x","length":1,"sha256":"${'a' * 64}"}]}',
        ),
      );
      expect(traversal.code, 'package.path_unsafe');

      final good = buildGoodPackage();
      final payload = payloadOf(good);
      final digest = crypto.sha256.convert(payload).toString();
      final duplicate = failureOf(
        withIndexJson(
          good,
          '{"entries":['
          '{"path":"a/B.json","length":${payload.length},"sha256":"$digest"},'
          '{"path":"A/b.JSON","length":${payload.length},"sha256":"$digest"}]}',
        ),
      );
      expect(duplicate.code, 'package.path_unsafe');
      expect(duplicate.details['reason'], 'duplicate');
    });
  });
}
