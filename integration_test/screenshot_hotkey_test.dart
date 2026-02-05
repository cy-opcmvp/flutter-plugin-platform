import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_plugins_platform/main.dart' as app;

/// 截图热键功能的集成测试
///
/// 注意：此测试只能覆盖按钮触发的场景
/// 热键触发、原生窗口交互（ESC、拖拽）需要手动测试
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('截图功能集成测试', () {
    testWidgets('用例4：按钮触发 + 正常截图', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      print('===== 测试开始：按钮触发截图 =====');

      // 1. 查找并点击区域截图按钮
      final button = find.text('区域截图');
      expect(button, findsOneWidget, reason: '未找到区域截图按钮');

      print('✅ 找到区域截图按钮');

      // 点击按钮
      await tester.tap(button);
      await tester.pumpAndSettle();

      print('✅ 已点击区域截图按钮');
      print('⚠️ 原生窗口已打开，请手动操作：');
      print('   1. 选择区域');
      print('   2. 点击 √ 确认');
      print('   3. 等待截图完成');

      // 等待用户手动操作（30秒）
      await Future.delayed(const Duration(seconds: 30));

      print('===== 测试结束 =====');
    });

    testWidgets('用例5：按钮触发 + ESC取消', (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      print('===== 测试开始：按钮触发 + ESC取消 =====');

      // 查找并点击区域截图按钮
      final button = find.text('区域截图');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      print('✅ 已点击区域截图按钮');
      print('⚠️ 原生窗口已打开，请手动操作：');
      print('   1. 按 ESC 取消');
      print('   2. 观察控制台日志');

      // 等待用户手动操作（10秒）
      await Future.delayed(const Duration(seconds: 10));

      print('===== 测试结束 =====');
    });
  });
}
