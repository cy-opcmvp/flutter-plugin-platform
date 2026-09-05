// 覆盖场景清单（计划 F3-05 Step 2，相似断言合并）：
// 1. 五种字段全量渲染 + 空表单提交拦截（必填错误 + 不回调）。
// 2. 合法填写后一次性回填报值（文本 / 数字 / 下拉默认 / 复选 / 开关组默认）。
// 3. 数字范围越界错误（formNumberRange 文案 + 不回调）。
// 4. 英文环境提交按钮本地化。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plugin_flutter/plugin_flutter.dart';

import '../test_utils/widget_harness.dart';

FormDescriptor _fullForm() {
  return FormDescriptor(
    title: '演示表单',
    fields: <FormFieldSpec>[
      TextFieldSpec(
        key: 'name',
        label: '名称',
        isRequired: true,
        placeholder: '请输入名称',
      ),
      NumberFieldSpec(
        key: 'count',
        label: '数量',
        isRequired: true,
        min: 1,
        max: 10,
      ),
      SelectFieldSpec(
        key: 'mode',
        label: '模式',
        options: <String>['a', 'b'],
        defaultValue: 'a',
      ),
      CheckboxFieldSpec(key: 'agree', label: '同意条款', isRequired: true),
      ToggleGroupSpec(
        key: 'tags',
        label: '标签',
        options: <String>['x', 'y'],
        defaultValue: <String>['x'],
      ),
    ],
  );
}

Future<void> _pumpForm(
  WidgetTester tester,
  FormDescriptor descriptor,
  ValueChanged<Map<String, Object?>> onSubmit, {
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    buildHarness(
      FormRenderer(descriptor: descriptor, onSubmit: onSubmit),
      locale: locale,
    ),
  );
  await tester.pump();
}

void main() {
  group('FormRenderer', () {
    testWidgets('空表单提交被必填校验拦截', (tester) async {
      Map<String, Object?>? submitted;
      await _pumpForm(
        tester,
        _fullForm(),
        (Map<String, Object?> values) => submitted = values,
      );

      await tester.tap(find.widgetWithText(FilledButton, '提交'));
      await tester.pump();

      expect(find.text('请填写必填项'), findsWidgets);
      expect(submitted, isNull);
    });

    testWidgets('合法填写后按字段类型回填报值', (tester) async {
      Map<String, Object?>? submitted;
      await _pumpForm(
        tester,
        _fullForm(),
        (Map<String, Object?> values) => submitted = values,
      );

      await tester.enterText(find.byType(TextFormField).at(0), '演示');
      await tester.enterText(find.byType(TextFormField).at(1), '5');
      await tester.tap(find.byType(Checkbox));
      await tester.tap(find.widgetWithText(FilledButton, '提交'));
      await tester.pump();

      expect(submitted, <String, Object?>{
        'name': '演示',
        'count': 5,
        'mode': 'a',
        'agree': true,
        'tags': <String>['x'],
      });
    });

    testWidgets('数字越界提示范围错误且不回调', (tester) async {
      Map<String, Object?>? submitted;
      final FormDescriptor descriptor = FormDescriptor(
        title: '范围',
        fields: <FormFieldSpec>[
          NumberFieldSpec(key: 'count', label: '数量', min: 1, max: 10),
        ],
      );
      await _pumpForm(
        tester,
        descriptor,
        (Map<String, Object?> values) => submitted = values,
      );

      await tester.enterText(find.byType(TextFormField), '99');
      await tester.tap(find.widgetWithText(FilledButton, '提交'));
      await tester.pump();

      expect(find.text('请输入 1 到 10 之间的数值'), findsOneWidget);
      expect(submitted, isNull);
    });

    testWidgets('英文环境提交按钮本地化', (tester) async {
      await _pumpForm(
        tester,
        _fullForm(),
        (Map<String, Object?> values) {},
        locale: const Locale('en'),
      );

      expect(find.widgetWithText(FilledButton, 'Submit'), findsOneWidget);
    });
  });
}
