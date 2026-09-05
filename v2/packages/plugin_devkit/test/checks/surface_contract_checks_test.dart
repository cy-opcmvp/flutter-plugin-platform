// 覆盖场景清单（计划 F3-03 devkit 扩展，相似断言合并）：
// 1. checkPageProviderBuilds / checkSettingsProviderBuilds：
//    正常构建通过；build 抛异常时检查失败。
// 2. checkManifestSurfaceDeclared：声明与实现一致通过；
//    缺声明 / 多声明均失败。
// 3. checkActionsNonEmpty：非空通过；空列表失败。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_devkit/plugin_devkit.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

Future<BuildContext> _pumpCapture(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      },
    ),
  );
  return captured;
}

void main() {
  group('SurfaceContractChecks', () {
    testWidgets('checkPageProviderBuilds 正常构建通过', (tester) async {
      final context = await _pumpCapture(tester);
      SurfaceContractChecks.checkPageProviderBuilds(
        context,
        const _StubPageProvider(),
      );
    });

    testWidgets('checkPageProviderBuilds 构建抛异常时检查失败', (tester) async {
      final context = await _pumpCapture(tester);
      expect(
        () => SurfaceContractChecks.checkPageProviderBuilds(
          context,
          const _StubPageProvider(throwOnBuild: true),
        ),
        throwsA(isA<Error>()),
      );
    });

    testWidgets('checkSettingsProviderBuilds 正常构建通过', (tester) async {
      final context = await _pumpCapture(tester);
      SurfaceContractChecks.checkSettingsProviderBuilds(
        context,
        const _StubSettingsProvider(),
      );
    });

    test('checkManifestSurfaceDeclared 声明与实现一致通过', () {
      SurfaceContractChecks.checkManifestSurfaceDeclared(
        _manifest(<String>['page', 'settings']),
        page: true,
        settings: true,
      );
      SurfaceContractChecks.checkManifestSurfaceDeclared(_manifest(<String>[]));
    });

    test('checkManifestSurfaceDeclared 缺声明 / 多声明失败', () {
      expect(
        () => SurfaceContractChecks.checkManifestSurfaceDeclared(
          _manifest(<String>[]),
          page: true,
        ),
        throwsA(isA<Error>()),
        reason: '实现族提供 page 但清单未声明',
      );
      expect(
        () => SurfaceContractChecks.checkManifestSurfaceDeclared(
          _manifest(<String>['actions']),
        ),
        throwsA(isA<Error>()),
        reason: '清单声明 actions 但实现族未提供',
      );
    });

    testWidgets('checkActionsNonEmpty 非空通过 / 空列表失败', (tester) async {
      final context = await _pumpCapture(tester);
      SurfaceContractChecks.checkActionsNonEmpty(
        const _StubActionProvider(),
        context,
      );
      expect(
        () => SurfaceContractChecks.checkActionsNonEmpty(
          const _StubActionProvider(count: 0),
          context,
        ),
        throwsA(isA<Error>()),
      );
    });
  });
}

PluginManifest _manifest(List<String> surfaces) {
  return PluginManifest(
    id: PluginId.parse('dev.example.tool'),
    name: '示例插件',
    version: '1.0.0',
    apiVersion: 1,
    kind: PluginKind.builtin,
    targets: <PluginTarget>[PluginTarget.windows],
    entrypoint: 'builtin:dev.example.tool',
    provides: <CapabilityDescriptor>[],
    requires: <CapabilityRequirement>[],
    surfaces: surfaces,
    configSchemaVersion: 1,
    dataSchemaVersion: 1,
  );
}

final class _StubPageProvider implements PluginPageProvider {
  const _StubPageProvider({this.throwOnBuild = false});

  final bool throwOnBuild;

  @override
  PluginId get pluginId => PluginId.parse('dev.example.tool');

  @override
  Widget buildPage(BuildContext context) {
    if (throwOnBuild) {
      throw StateError('构建失败');
    }
    return const Text('page');
  }
}

final class _StubSettingsProvider implements PluginSettingsProvider {
  const _StubSettingsProvider();

  @override
  Widget buildSettings(BuildContext context) => const Text('settings');
}

final class _StubActionProvider implements PluginActionProvider {
  const _StubActionProvider({this.count = 1});

  final int count;

  @override
  List<PluginAction> actions(BuildContext context) {
    return List<PluginAction>.generate(
      count,
      (i) => PluginAction(id: 'action-$i', label: '动作 $i', onTriggered: (_) {}),
    );
  }
}
