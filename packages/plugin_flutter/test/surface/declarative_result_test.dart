// 覆盖场景清单（计划 F3-03 Step 2，相似断言合并）：
// 1. 构造校验：text 空/空白文本拒绝、table 空 columns 拒绝、
//    image 空 path 拒绝、fields 空 label/value 拒绝。
// 2. toJson/fromJson 往返：四种结果描述符逐类验证往返等值。
// 3. fromJson 未知 kind 抛 FormatException。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

void main() {
  group('构造校验', () {
    test('空白 text / columns / path / field 拒绝', () {
      expect(() => TextResultDescriptor(text: ''), throwsArgumentError);
      expect(
        () => TableResultDescriptor(columns: const [], rows: const []),
        throwsArgumentError,
      );
      expect(() => ImageResultDescriptor(path: ' '), throwsArgumentError);
      expect(() => ResultField(label: 'a', value: ''), throwsArgumentError);
    });
  });

  group('toJson/fromJson 往返', () {
    final descriptors = <ResultDescriptor>{
      TextResultDescriptor(text: '处理完成'),
      TableResultDescriptor(
        columns: <String>['名称', '值'],
        rows: <List<String>>[
          <String>['a', '1'],
          <String>['b', '2'],
        ],
      ),
      ImageResultDescriptor(path: 'screenshots/demo.png'),
      FieldsResultDescriptor(
        fields: <ResultField>[
          ResultField(label: '耗时', value: '1.2s'),
          ResultField(label: '条目', value: '42'),
        ],
      ),
    };

    test('四种结果描述符逐类往返等值', () {
      for (final descriptor in descriptors) {
        final json = descriptor.toJson();
        final restored = ResultDescriptor.fromJson(json);
        expect(restored, descriptor, reason: 'kind=${descriptor.kind}');
      }
    });
  });

  test('fromJson 未知 kind 抛 FormatException', () {
    expect(
      () => ResultDescriptor.fromJson(<String, Object?>{
        'kind': 'audio',
        'text': 'x',
      }),
      throwsFormatException,
    );
  });
}
