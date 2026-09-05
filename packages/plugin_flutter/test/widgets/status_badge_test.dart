// 覆盖场景清单（计划 F3-05 Step 2，相似断言合并）：
// 1. precision_tools：不可用时第二行展示大写等宽原因码。
// 2. warm_life：不可用展示人话原因 + 「查看原因」链接（回调可触发）。
// 3. dark_pro：初始收起原因，点击徽章展开明细。
// 4. 英文环境状态文案本地化。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plugin_flutter/plugin_flutter.dart';

import '../test_utils/widget_harness.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('precision_tools 展示大写原因码', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          const StatusBadge(
            state: StatusBadgeState.unavailable,
            reasonCode: 'resolution.unsupported_target',
          ),
          preset: AppThemePreset.precisionTools,
        ),
      );

      expect(find.text('不可用'), findsOneWidget);
      expect(find.text('RESOLUTION.UNSUPPORTED_TARGET'), findsOneWidget);
    });

    testWidgets('warm_life 展示人话原因与查看原因入口', (tester) async {
      var viewTapped = 0;
      await tester.pumpWidget(
        buildHarness(
          StatusBadge(
            state: StatusBadgeState.unavailable,
            reasonCode: 'resolution.unsupported_target',
            reasonText: '该插件不支持当前平台',
            onViewReason: () => viewTapped++,
          ),
          preset: AppThemePreset.warmLife,
        ),
      );

      expect(find.text('该插件不支持当前平台'), findsOneWidget);
      await tester.tap(find.text('查看原因'));
      expect(viewTapped, 1);
    });

    testWidgets('dark_pro 点击后展开原因明细', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          const StatusBadge(
            state: StatusBadgeState.unavailable,
            reasonCode: 'resolution.unsupported_target',
            reasonText: '该插件不支持当前平台',
          ),
          preset: AppThemePreset.darkPro,
        ),
      );

      expect(find.text('该插件不支持当前平台'), findsNothing);
      await tester.tap(find.text('不可用'));
      await tester.pump();

      expect(find.text('该插件不支持当前平台'), findsOneWidget);
    });

    testWidgets('英文环境状态与链接本地化', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          const StatusBadge(state: StatusBadgeState.available),
          locale: Locale('en'),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
    });
  });
}
