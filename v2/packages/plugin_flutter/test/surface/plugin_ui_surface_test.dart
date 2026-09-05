// 覆盖场景清单（计划 F3-03 Interfaces，相似断言合并）：
// 1. surfaceUnsupported → PluginFailure('surface.unsupported')，
//    details 含 surface 与 pluginId。
// 2. PluginAction 持有 id/label/onTriggered。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

void main() {
  test('surfaceUnsupported 错误码与 details 正确', () {
    final id = PluginId.parse('dev.example.tool');
    final failure = surfaceUnsupported('page', id);
    expect(failure.code, 'surface.unsupported');
    expect(failure.details['surface'], 'page');
    expect(failure.details['pluginId'], 'dev.example.tool');
  });

  testWidgets('PluginAction 持有 id/label 且触发回调', (tester) async {
    var triggered = false;
    final action = PluginAction(
      id: 'refresh',
      label: '刷新',
      onTriggered: (context) => triggered = true,
    );

    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(action.id, 'refresh');
    expect(action.label, '刷新');
    action.onTriggered(captured);
    expect(triggered, isTrue);
  });
}
