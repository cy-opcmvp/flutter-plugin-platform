// 覆盖场景清单（S1 批C：全局热键能力接口与默认不支持实现）：
// 1. hotkeyRegisterFailedFailure：code == hotkey.register_failed 且
//    details['reason'] 原样透传（conflict/invalid/unsupported）。
// 2. UnsupportedGlobalHotkeys.register 一律 false、unregister 无操作、
//    hotkeyFired 为空流（订阅后不产出事件）。
library;

import 'dart:async';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('hotkeyRegisterFailedFailure', () {
    test('结构化失败码与 reason 原样透传', () {
      for (final String reason in const <String>[
        'conflict',
        'invalid',
        'unsupported',
      ]) {
        final PluginFailure failure =
            hotkeyRegisterFailedFailure(reason, 'msg $reason');
        expect(failure.code, 'hotkey.register_failed');
        expect(failure.details['reason'], reason);
      }
    });
  });

  group('UnsupportedGlobalHotkeys', () {
    test('register 返回 false，unregister 无操作', () async {
      const hotkeys = UnsupportedGlobalHotkeys('test-platform');

      expect(await hotkeys.register('shot', 'Ctrl+Shift+A'), isFalse);
      await hotkeys.unregister('shot');
    });

    test('hotkeyFired 为空流，订阅后不产出事件', () async {
      const hotkeys = UnsupportedGlobalHotkeys('test-platform');

      final Completer<String> fired = Completer<String>();
      final StreamSubscription<String> sub = hotkeys.hotkeyFired.listen(
        fired.complete,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(fired.isCompleted, isFalse);
    });
  });
}
