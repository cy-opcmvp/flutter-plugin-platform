// 覆盖场景清单（计划 F3-05 Step 2，相似断言合并）：
// 1. 卡片渲染标题 / 描述 / 版本；不可用卡展示徽章与原因。
// 2. 方向差异：warm_life 版本胶囊（v 前缀），precision_tools 等宽裸版本。
// 3. dark_pro 回归：非均匀 Border 断言（2026-09-06 用户实测发现）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plugin_flutter/plugin_flutter.dart';

import '../test_utils/widget_harness.dart';

void main() {
  group('PluginCard', () {
    testWidgets('渲染标题、描述、版本与不可用原因', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          PluginCard(
            title: '欢迎',
            description: '平台内置欢迎插件',
            version: '1.0.0',
            state: StatusBadgeState.unavailable,
            reasonCode: 'resolution.unsupported_target',
            reasonText: '该插件不支持当前平台',
          ),
        ),
      );

      expect(find.text('欢迎'), findsOneWidget);
      expect(find.text('平台内置欢迎插件'), findsOneWidget);
      expect(find.text('不可用'), findsOneWidget);
      expect(find.text('该插件不支持当前平台'), findsOneWidget);
    });

    testWidgets('warm_life 版本以 v 前缀胶囊展示', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          PluginCard(
            title: '欢迎',
            description: '描述',
            version: '1.0.0',
            state: StatusBadgeState.available,
          ),
          preset: AppThemePreset.warmLife,
        ),
      );

      expect(find.text('v1.0.0'), findsOneWidget);
    });

    testWidgets('precision_tools 版本为等宽裸版本号', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          PluginCard(
            title: '欢迎',
            description: '描述',
            version: '1.0.0',
            state: StatusBadgeState.available,
          ),
          preset: AppThemePreset.precisionTools,
        ),
      );

      expect(find.text('v1.0.0'), findsNothing);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    // 回归：dark_pro 曾用非均匀 Border + 圆角触发绘制断言
    // 「A borderRadius can only be given on borders with uniform colors」。
    testWidgets('dark_pro 卡片可绘制（gutter 色条 + 均匀描边）', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          PluginCard(
            title: '欢迎',
            description: '描述',
            version: '1.0.0',
            state: StatusBadgeState.available,
          ),
          preset: AppThemePreset.darkPro,
          brightness: Brightness.dark,
        ),
      );
      // pumpAndSettle 触发完整绘制管线——断言若复发将在此抛出。
      await tester.pumpAndSettle();
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('点击卡片触发回调', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        buildHarness(
          PluginCard(
            title: '欢迎',
            description: '描述',
            version: '1.0.0',
            state: StatusBadgeState.available,
            onTap: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.text('欢迎'));
      expect(tapped, 1);
    });
  });
}
