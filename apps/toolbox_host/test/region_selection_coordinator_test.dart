/// 区域选择协调器与全局热键绑定测试（S1 批C）。
///
/// 场景清单：
/// 1. RegionHotkeyBinding：绑定成功注册固定 id、触发事件按 id 过滤；
/// 2. 重复绑定自动反绑旧的；
/// 3. 注册失败返回 false 并清理（反注册 + 取消订阅）；
/// 4. unbind 幂等；
/// 5. coordinator：无导航上下文时返回 null 且窗口 ops 进出配对；
/// 6. coordinator：overlay 推入 → Enter 确认 → 返回选区且窗口恢复。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show Rect;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:screenshot/screenshot.dart';
import 'package:toolbox_host/src/host_window.dart';
import 'package:toolbox_host/src/region_selection/region_selection_coordinator.dart';
import 'package:toolbox_host/src/generated/host_l10n.dart';
import 'package:toolbox_host/src/region_selection/region_selection_overlay.dart';

/// 1x1 透明 PNG（overlay 底图占位，避免真实解码失败）。
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// 记录型热键能力 fake：记录注册/反注册调用并支持手动发事件。
final class _FakeGlobalHotkeys implements GlobalHotkeys {
  bool registerResult = true;

  final List<String> registerIds = <String>[];

  final List<String> registerCombos = <String>[];

  final List<String> unregisterCalls = <String>[];

  final StreamController<String> _events = StreamController<String>.broadcast();

  @override
  Future<bool> register(String id, String combo) async {
    registerIds.add(id);
    registerCombos.add(combo);
    return registerResult;
  }

  @override
  Future<void> unregister(String id) async {
    unregisterCalls.add(id);
  }

  @override
  Stream<String> get hotkeyFired => _events.stream;

  void emit(String id) {
    _events.add(id);
  }
}

/// 记录型窗口形态切换 fake。
final class _RecordingWindowOps implements HostWindowOps {
  int enterCalls = 0;

  int exitCalls = 0;

  @override
  Future<void> enterSelection() async {
    enterCalls++;
  }

  @override
  Future<void> exitSelection() async {
    exitCalls++;
  }
}

void main() {
  group('RegionHotkeyBinding', () {
    test('绑定成功：注册固定 id，触发事件按 id 过滤', () async {
      // Arrange
      final _FakeGlobalHotkeys hotkeys = _FakeGlobalHotkeys();
      final RegionHotkeyBinding binding = RegionHotkeyBinding(hotkeys: hotkeys);
      int fired = 0;

      // Act
      final bool ok = await binding.bind('Ctrl+Shift+A', () {
        fired++;
      });
      hotkeys.emit('screenshot.region');
      hotkeys.emit('other.id');
      await Future<void>.delayed(Duration.zero);

      // Assert：注册调用带固定能力 id 与原样 combo；无关 id 不过滤进回调。
      expect(ok, isTrue);
      expect(hotkeys.registerIds, <String>['screenshot.region']);
      expect(hotkeys.registerCombos, <String>['Ctrl+Shift+A']);
      expect(fired, 1);
      await binding.unbind('Ctrl+Shift+A');
    });

    test('重复绑定自动反绑旧的', () async {
      // Arrange
      final _FakeGlobalHotkeys hotkeys = _FakeGlobalHotkeys();
      final RegionHotkeyBinding binding = RegionHotkeyBinding(hotkeys: hotkeys);
      int fired = 0;

      // Act：先后绑定两组回调。
      await binding.bind('Ctrl+Shift+A', () {
        fired += 1;
      });
      await binding.bind('Ctrl+Alt+Z', () {
        fired += 10;
      });
      hotkeys.emit('screenshot.region');
      await Future<void>.delayed(Duration.zero);

      // Assert：每次 bind 先 unbind 旧绑（含首次绑定前的幂等反绑），
      // 共两次反注册；仅第二组回调生效。
      expect(hotkeys.registerIds.length, 2);
      expect(hotkeys.unregisterCalls.length, 2);
      expect(fired, 10);
      await binding.unbind('Ctrl+Alt+Z');
    });

    test('注册失败：返回 false 且清理订阅与注册', () async {
      // Arrange
      final _FakeGlobalHotkeys hotkeys = _FakeGlobalHotkeys()
        ..registerResult = false;
      final RegionHotkeyBinding binding = RegionHotkeyBinding(hotkeys: hotkeys);
      int fired = 0;

      // Act
      final bool ok = await binding.bind('Ctrl+Shift+A', () {
        fired++;
      });
      hotkeys.emit('screenshot.region');
      await Future<void>.delayed(Duration.zero);

      // Assert：失败即反注册（bind 前置幂等 unbind + 失败清理各一次），
      // 事件不再进回调。
      expect(ok, isFalse);
      expect(hotkeys.unregisterCalls.length, 2);
      expect(
        hotkeys.unregisterCalls.every((String id) => id == 'screenshot.region'),
        isTrue,
      );
      expect(fired, 0);
    });

    test('unbind 幂等', () async {
      // Arrange
      final _FakeGlobalHotkeys hotkeys = _FakeGlobalHotkeys();
      final RegionHotkeyBinding binding = RegionHotkeyBinding(hotkeys: hotkeys);
      await binding.bind('Ctrl+Shift+A', () {});

      // Act：连续两次反绑。
      await binding.unbind('Ctrl+Shift+A');
      await binding.unbind('Ctrl+Shift+A');

      // Assert：bind 前置幂等 unbind 一次 + 显式两次 = 三次反注册，无异常。
      expect(hotkeys.unregisterCalls.length, 3);
    });
  });

  group('HostRegionSelectionCoordinator', () {
    test('无导航上下文：返回 null 且窗口 ops 进出配对', () async {
      // Arrange：navigatorKey 未挂载。
      final _RecordingWindowOps ops = _RecordingWindowOps();
      final HostRegionSelectionCoordinator coordinator =
          HostRegionSelectionCoordinator(
            navigatorKey: GlobalKey<NavigatorState>(),
            windowOps: ops,
            restoreDelay: Duration.zero,
          );

      // Act
      final ScreenRegion? region = await coordinator.select(
        _tinyPng,
        ui.Rect.fromLTWH(0, 0, 8, 8),
      );

      // Assert
      expect(region, isNull);
      expect(ops.enterCalls, 1);
      expect(ops.exitCalls, 1);
    });

    testWidgets('overlay 推入 → Enter 确认 → 返回选区且窗口恢复', (
      WidgetTester tester,
    ) async {
      // Arrange：navigatorKey 挂 MaterialApp，页面按钮拉起 select。
      final _RecordingWindowOps ops = _RecordingWindowOps();
      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();
      final HostRegionSelectionCoordinator coordinator =
          HostRegionSelectionCoordinator(
            navigatorKey: navigatorKey,
            windowOps: ops,
            restoreDelay: Duration.zero,
          );
      final Completer<ScreenRegion?> done = Completer<ScreenRegion?>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: HostL10n.localizationsDelegates,
          supportedLocales: HostL10n.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  coordinator
                      .select(_tinyPng, ui.Rect.fromLTWH(0, 0, 800, 600))
                      .then(done.complete);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      // Act：打开 overlay → 框选 → Enter。
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(RegionSelectionOverlay), findsOneWidget);
      await tester.dragFrom(const Offset(100, 100), const Offset(120, 80));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      final ScreenRegion? region = await done.future.timeout(
        const Duration(seconds: 5),
      );

      // Assert：视口 800x600 与底图同尺寸（比例 1:1），物理矩形等于
      // 逻辑矩形；窗口 ops 进出配对。
      expect(region, isNotNull);
      expect(region!.action, ScreenRegionAction.save);
      expect(region.logicalRect, ui.Rect.fromLTWH(100, 100, 120, 80));
      expect(region.physicalRect, ui.Rect.fromLTWH(100, 100, 120, 80));
      expect(ops.enterCalls, 1);
      expect(ops.exitCalls, 1);
    });
  });
}
