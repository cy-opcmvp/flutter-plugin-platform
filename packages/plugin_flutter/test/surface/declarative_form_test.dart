// 覆盖场景清单（计划 F3-03 Step 2，相似断言合并）：
// 1. 构造校验：空/空白 title、key、label 拒绝（ArgumentError）。
// 2. selectField / toggleGroup 空 options 拒绝。
// 3. FormDescriptor 重复字段 key 拒绝。
// 4. toJson/fromJson 往返：五种字段规格逐类验证往返等值。
// 5. FormDescriptor 往返。
// 6. fromJson 未知 kind 抛 FormatException。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

void main() {
  group('字段构造校验', () {
    test('空白 key / label / title 拒绝', () {
      expect(() => TextFieldSpec(key: ' ', label: '名称'), throwsArgumentError);
      expect(() => TextFieldSpec(key: 'k', label: ''), throwsArgumentError);
      expect(
        () => FormDescriptor(title: '', fields: const []),
        throwsArgumentError,
      );
    });

    test('selectField / toggleGroup 空 options 拒绝', () {
      expect(
        () => SelectFieldSpec(key: 'k', label: '选择', options: const []),
        throwsArgumentError,
      );
      expect(
        () => ToggleGroupSpec(key: 'k', label: '开关组', options: const []),
        throwsArgumentError,
      );
    });

    test('FormDescriptor 重复字段 key 拒绝', () {
      expect(
        () => FormDescriptor(
          title: '表单',
          fields: <FormFieldSpec>[
            CheckboxFieldSpec(key: 'same', label: 'A'),
            CheckboxFieldSpec(key: 'same', label: 'B'),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('toJson/fromJson 往返', () {
    final specs = <FormFieldSpec>{
      TextFieldSpec(
        key: 'name',
        label: '名称',
        isRequired: true,
        defaultValue: 'demo',
        placeholder: '输入名称',
      ),
      NumberFieldSpec(
        key: 'count',
        label: '数量',
        isRequired: true,
        defaultValue: 3,
        min: 0,
        max: 10,
      ),
      SelectFieldSpec(
        key: 'mode',
        label: '模式',
        options: <String>['fast', 'slow'],
        defaultValue: 'fast',
      ),
      CheckboxFieldSpec(key: 'enabled', label: '启用', defaultValue: true),
      ToggleGroupSpec(
        key: 'flags',
        label: '开关组',
        options: <String>['a', 'b'],
        isRequired: true,
        defaultValue: <String>['a'],
      ),
    };

    test('五种字段规格逐类往返等值', () {
      for (final spec in specs) {
        final json = spec.toJson();
        final restored = FormFieldSpec.fromJson(json);
        expect(restored, spec, reason: 'kind=${spec.kind}');
      }
    });

    test('FormDescriptor 往返等值', () {
      final descriptor = FormDescriptor(
        title: '插件设置',
        fields: <FormFieldSpec>[
          TextFieldSpec(key: 'name', label: '名称'),
          NumberFieldSpec(key: 'count', label: '数量'),
        ],
      );
      final restored = FormDescriptor.fromJson(descriptor.toJson());
      expect(restored, descriptor);
    });
  });

  group('fromJson 非法输入', () {
    test('未知 kind 抛 FormatException', () {
      expect(
        () => FormFieldSpec.fromJson(<String, Object?>{
          'kind': 'magicField',
          'key': 'k',
          'label': 'l',
        }),
        throwsFormatException,
      );
    });

    test('缺失必填 JSON 键抛 FormatException', () {
      expect(
        () => FormFieldSpec.fromJson(<String, Object?>{
          'kind': 'textField',
          'key': 'k',
        }),
        throwsFormatException,
      );
    });
  });
}
