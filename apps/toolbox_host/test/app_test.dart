/// F3-06 宿主应用层焦点测试：目录页呈现、详情联动、语言与主题切换。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart' show AppThemePreset;

import 'package:toolbox_host/src/app.dart';
import 'package:toolbox_host/src/host_composition_root.dart';

/// 构造仅支持 android 的注入清单（用于呈现不可用原因）。
PluginManifest mobileOnlyManifest() {
  return PluginManifest(
    id: PluginId.parse('com.test.mobileonly'),
    name: 'MobileOnly',
    version: '0.1.0',
    apiVersion: 1,
    kind: PluginKind.builtin,
    targets: const <PluginTarget>[PluginTarget.android],
    entrypoint: 'builtin://com.test.mobileonly',
    provides: <CapabilityDescriptor>[
      CapabilityDescriptor('test.mobile.page', 1),
    ],
    requires: const <CapabilityRequirement>[],
    surfaces: const <String>['directory'],
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}

Future<HostCompositionRoot> pumpApp(
  WidgetTester tester, {
  List<PluginManifest> extraManifests = const <PluginManifest>[],
  Future<void> Function(AppThemePreset preset)? themePersist,
}) async {
  final HostCompositionRoot root = HostCompositionRoot(
    target: PluginTarget.windows,
    // 缺口①：路径含 NUL 在所有平台都无法创建目录/文件，使 toggle 触发的
    // 宿主偏好保存与插件设置恢复在「不可写」路径上静默降级，测试零落盘。
    hostDataRoot: '\u0000unwritable-test-root/host',
    extraManifests: extraManifests,
    themePersist: themePersist,
  );
  await tester.pumpWidget(ToolboxApp(root: root));
  await tester.pumpAndSettle();
  return root;
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('目录页展示可用徽章，注入的不可用插件展示原因文案', (WidgetTester tester) async {
    await pumpApp(
      tester,
      extraManifests: <PluginManifest>[mobileOnlyManifest()],
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('MobileOnly'), findsOneWidget);
    // F4-03：内置计算器插件已注册进目录。
    expect(find.text('计算器'), findsOneWidget);
    // F4-05：截图插件（windows 目标）也注册进目录。
    expect(find.text('截图'), findsOneWidget);
    // F4-06：hash_tool Sidecar 清单也注册进目录（第 4 张卡，可安装）。
    expect(find.text('Hash 工具'), findsOneWidget);
    // 徽章文案来自 plugin_flutter 包内 l10n（zh 模板）。
    expect(find.text('可用'), findsNWidgets(4));
    expect(find.text('不可用'), findsOneWidget);
    expect(find.text('该插件不支持当前平台'), findsOneWidget);
  });

  testWidgets('详情页停用插件后目录徽章联动为已停用', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Welcome'));
    await tester.pumpAndSettle();
    // 两次点击修复：插件页面直接内嵌详情页，一次点击即达场景。
    expect(find.text('插件页面'), findsOneWidget);
    expect(find.text('欢迎使用工具箱'), findsOneWidget);

    await tester.tap(find.text('启用插件'));
    await tester.pumpAndSettle();
    // 返回目录（Material AppBar 返回按钮）。
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('已停用'), findsOneWidget);
    // F4-03/F4-05/F4-06：计算器、截图与 hash_tool 仍保持可用（停用仅作用于
    // Welcome）。
    expect(find.text('可用'), findsNWidgets(3));
  });

  testWidgets('计算器详情页内嵌插件设置区', (WidgetTester tester) async {
    // F4-03：清单声明 settings 且宿主注册设置提供方时，详情页内嵌设置 UI。
    await pumpApp(tester);

    await tester.tap(find.text('计算器'));
    await tester.pumpAndSettle();

    // 两次点击修复：计算器场景内嵌可见（表达式输入提示随页面出现）。
    expect(find.text('输入表达式'), findsOneWidget);
    // 设置区在内嵌画布之下：从外层列表的基础信息区发起一次大幅拖动
    // （内嵌画布区域会拦截手势，拖动起点须在宿主列表自身元素上）。
    await tester.drag(find.text('基本信息'), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('插件设置'), findsOneWidget);
    expect(find.text('小数位数'), findsOneWidget);
    expect(find.text('显示历史记录'), findsOneWidget);
  });

  testWidgets('设置页切换语言后宿主文案切换为英文', (WidgetTester tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    // rail 标签 + AppBar 标题各一份。
    expect(find.text('设置'), findsNWidgets(2));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNWidgets(2));
    expect(find.text('设置'), findsNothing);
  });

  testWidgets('设置页切换主题方向触发控制器与持久化注入点', (WidgetTester tester) async {
    final List<AppThemePreset> persisted = <AppThemePreset>[];
    final HostCompositionRoot root = await pumpApp(
      tester,
      themePersist: (preset) async => persisted.add(preset),
    );
    await openSettings(tester);

    await tester.tap(find.text('极简暗色'));
    await tester.pumpAndSettle();

    expect(root.themeController.value, AppThemePreset.darkPro);
    expect(persisted, <AppThemePreset>[AppThemePreset.darkPro]);
  });
}
