// 覆盖场景清单（缺口①：宿主插件启用集合持久化焦点测试）：
// 1. 真临时目录 save→load 往返一致（集合内容不丢）。
// 2. 缺失文件 load 返回空偏好（首次启动路径）。
// 3. 损坏 JSON load 静默返回空偏好（降级约定）。
// 4. 不可写路径（含 NUL）save 静默失败不抛出。
// 5. ToolboxApp 注入 initialDisabledPluginIds 后目录页直接呈现「已停用」。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'package:toolbox_host/src/app.dart';
import 'package:toolbox_host/src/host_composition_root.dart';
import 'package:toolbox_host/src/host_preferences.dart';

void main() {
  group('HostPreferences 文件读写', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('host_prefs_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('save 后 load 往返一致（真临时目录）', () async {
      const HostPreferences prefs = HostPreferences(
        disabledPlugins: <String>{'com.toolbox.welcome', 'tools.calculator'},
      );

      await saveHostPreferences(tempDir.path, prefs);
      final HostPreferences loaded = await loadHostPreferences(tempDir.path);

      expect(loaded.disabledPlugins, prefs.disabledPlugins);
    });

    test('缺失文件 load 返回空偏好', () async {
      final HostPreferences loaded = await loadHostPreferences(tempDir.path);

      expect(loaded.disabledPlugins, isEmpty);
    });

    test('损坏 JSON load 静默返回空偏好', () async {
      final File file = File('${tempDir.path}/host-preferences.json');
      await file.writeAsString('{not-valid-json', flush: true);

      final HostPreferences loaded = await loadHostPreferences(tempDir.path);

      expect(loaded.disabledPlugins, isEmpty);
    });

    test('不可写路径 save 静默失败不抛出', () async {
      // NUL 字符在所有平台都使文件/目录操作抛 ArgumentError。
      const String unwritableRoot = '\u0000unwritable-test-root';

      await saveHostPreferences(
        unwritableRoot,
        const HostPreferences(disabledPlugins: <String>{'tools.calculator'}),
      );
    });
  });

  testWidgets('ToolboxApp 注入初始停用集合后目录页呈现已停用', (WidgetTester tester) async {
    // NUL 数据根使组装与保存路径零落盘。
    final HostCompositionRoot root = HostCompositionRoot(
      target: PluginTarget.windows,
      hostDataRoot: '\u0000unwritable-test-root/host',
    );
    await tester.pumpWidget(
      ToolboxApp(
        root: root,
        initialDisabledPluginIds: <String>{'com.toolbox.welcome'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已停用'), findsOneWidget);
    expect(find.text('欢迎使用工具箱'), findsNothing);
  });
}
