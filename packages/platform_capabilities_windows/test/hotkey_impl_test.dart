// 真机烟囱测试（本机即 Windows，直接 dart test）+ combo 解析表驱动。
//
// 覆盖场景清单（S1 批C：全局热键）：
// 1. parseHotkeyCombo 合法表：修饰键组合（Ctrl/Alt/Shift/Win）、大小写
//    与空白容错、主键字母/数字/F1-F12 → (修饰键掩码, VK)；
// 2. parseHotkeyCombo 非法表：空串、仅主键、仅修饰键、重复修饰键、
//    越界 F13、未知主键、多主键 → null；
// 3. 真机注册：Ctrl+Alt+F12 成功；同组合二次注册 false（conflict）；
//    反注册后重注册成功；combo 非法 false（invalid）；
// 4. 触发路径：debugTrigger 注入事件流 → 广播携带 id；反注册后不再
//    广播（真按键无法在测试内合成）。
library;

import 'dart:async';

import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:platform_capabilities_windows/src/hotkey_ff.dart';
import 'package:test/test.dart';

void main() {
  group('parseHotkeyCombo 合法表', () {
    final Map<String, (int, int)> cases = <String, (int, int)>{
      'Ctrl+Shift+A': (modControl | modShift, 0x41),
      'ctrl+alt+f12': (modControl | modAlt, 0x7B),
      ' Shift + F5 ': (modShift, 0x74),
      'Win+1': (modWin, 0x31),
      'Control+Z': (modControl, 0x5A),
      'Ctrl+Alt+Shift+Win+F1': (modControl | modAlt | modShift | modWin, 0x70),
    };
    cases.forEach((String combo, (int, int) expected) {
      test('$combo → ${expected.$1}/${expected.$2}', () {
        expect(parseHotkeyCombo(combo), expected);
      });
    });
  });

  group('parseHotkeyCombo 非法表', () {
    for (final String combo in const <String>[
      '',
      'A',
      'Ctrl',
      'Ctrl+F13',
      'Ctrl+Foo',
      'Ctrl+Ctrl+A',
      'Ctrl+A+B',
    ]) {
      test('"$combo" → null', () {
        expect(parseHotkeyCombo(combo), isNull);
      });
    }
  });

  group('WindowsGlobalHotkeys 真机', () {
    late WindowsGlobalHotkeys hotkeys;

    setUp(() {
      hotkeys = WindowsGlobalHotkeys();
    });

    tearDown(() {
      hotkeys.dispose();
    });

    test('Ctrl+Alt+F12 注册成功；同组合二次注册 conflict；反注册后重注册成功',
        () async {
      expect(await hotkeys.register('shot', 'Ctrl+Alt+F12'), isTrue);

      // 同一组合换 id 再注册：底层 RegisterHotKey 返回 FALSE。
      expect(await hotkeys.register('shot2', 'Ctrl+Alt+F12'), isFalse);
      expect(hotkeys.lastFailureReason, 'conflict');

      await hotkeys.unregister('shot');
      expect(await hotkeys.register('shot2', 'Ctrl+Alt+F12'), isTrue);
    });

    test('combo 非法返回 false（invalid）', () async {
      expect(await hotkeys.register('bad', 'Ctrl'), isFalse);
      expect(hotkeys.lastFailureReason, 'invalid');
    });

    test('debugTrigger 注入触发流：已注册广播携带 id；反注册后不广播',
        () async {
      final List<String> fired = <String>[];
      final StreamSubscription<String> sub = hotkeys.hotkeyFired.listen(
        fired.add,
      );
      addTearDown(sub.cancel);

      expect(await hotkeys.register('shot', 'Ctrl+Shift+A'), isTrue);
      hotkeys.debugTrigger('shot');
      await Future<void>.delayed(Duration.zero);
      expect(fired, <String>['shot']);

      // 未注册 id 不广播。
      hotkeys.debugTrigger('ghost');
      await Future<void>.delayed(Duration.zero);
      expect(fired, <String>['shot']);

      await hotkeys.unregister('shot');
      hotkeys.debugTrigger('shot');
      await Future<void>.delayed(Duration.zero);
      expect(fired, <String>['shot']);
    });
  });
}
