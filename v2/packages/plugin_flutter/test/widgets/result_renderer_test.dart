// 覆盖场景清单（计划 F3-05 Step 2，相似断言合并）：
// 1. 四类结果（text / table / image / fields）各自渲染关键内容。
// 2. 表格空态文案。
// 3. 图片结果因包内无文件能力渲染为占位框（路径 + 说明文案）。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:plugin_flutter/plugin_flutter.dart';

import '../test_utils/widget_harness.dart';

void main() {
  group('ResultRenderer', () {
    testWidgets('文本结果渲染内容', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          ResultRenderer(descriptor: TextResultDescriptor(text: '执行完成')),
        ),
      );

      expect(find.text('执行完成'), findsOneWidget);
    });

    testWidgets('表格结果渲染表头与数据行', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          ResultRenderer(
            descriptor: TableResultDescriptor(
              columns: <String>['名称', '数量'],
              rows: <List<String>>[
                <String>['苹果', '3'],
              ],
            ),
          ),
        ),
      );

      expect(find.text('名称'), findsOneWidget);
      expect(find.text('苹果'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('空表格显示空态文案', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          ResultRenderer(
            descriptor: TableResultDescriptor(
              columns: <String>['列'],
              rows: const <List<String>>[],
            ),
          ),
        ),
      );

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('图片结果渲染占位框：路径与说明', (tester) async {
      const String path = r'C:\tmp\shot.png';
      await tester.pumpWidget(
        buildHarness(
          ResultRenderer(descriptor: ImageResultDescriptor(path: path)),
        ),
      );

      expect(find.text(path), findsOneWidget);
      expect(find.text('图片路径：$path（宿主暂未提供文件读取能力）'), findsOneWidget);
    });

    testWidgets('字段列表结果渲染标签与值', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          ResultRenderer(
            descriptor: FieldsResultDescriptor(
              fields: <ResultField>[ResultField(label: '耗时', value: '1.2s')],
            ),
          ),
        ),
      );

      expect(find.text('耗时'), findsOneWidget);
      expect(find.text('1.2s'), findsOneWidget);
    });
  });
}
