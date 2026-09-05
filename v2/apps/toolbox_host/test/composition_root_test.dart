/// F3-06 组装根焦点测试：注册、解析、路径拼接、页面提供方与主题注入点。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'package:toolbox_host/src/host_composition_root.dart';
import 'package:toolbox_host/src/plugins/welcome_plugin.dart';

void main() {
  const String hostDataRoot = '%TESTDATA%/host';
  final PluginId welcomeId = PluginId.parse(kWelcomePluginId);

  HostCompositionRoot buildRoot({
    List<PluginManifest> extraManifests = const <PluginManifest>[],
    Future<void> Function(AppThemePreset preset)? themePersist,
  }) {
    return HostCompositionRoot(
      target: PluginTarget.windows,
      hostDataRoot: hostDataRoot,
      extraManifests: extraManifests,
      themePersist: themePersist,
    );
  }

  group('HostCompositionRoot', () {
    test('以 windows 目标解析出可用的欢迎插件，主题初始为 warm_life', () {
      final HostCompositionRoot root = buildRoot();
      expect(root.resolution.available, contains(welcomeId));
      expect(root.resolution.plugins[welcomeId]!.available, isTrue);
      expect(root.registry.registrations, contains(welcomeId));
      expect(root.themeController.value, AppThemePreset.warmLife);
    });

    test('注入不支持当前平台的清单时给出结构化原因', () {
      final PluginManifest mobileOnly = PluginManifest(
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
      final PluginId mobileId = mobileOnly.id;
      final HostCompositionRoot root = buildRoot(
        extraManifests: <PluginManifest>[mobileOnly],
      );
      expect(root.resolution.available, isNot(contains(mobileId)));
      final List<PluginFailure> failures =
          root.resolution.plugins[mobileId]!.failures;
      expect(failures, isNotEmpty);
      expect(failures.first.code, 'resolution.unsupported_target');
    });

    test('数据目录与 sidecar 包目录按字符串拼接、不触碰文件系统', () {
      final HostCompositionRoot root = buildRoot();
      expect(root.sidecarInstaller.rootDir, '$hostDataRoot/sidecar-packages');
      expect(
        root.systemPaths.pluginDataDir(welcomeId),
        '$hostDataRoot/com.toolbox.welcome',
      );
    });

    test('欢迎页面提供方已注册且 ID 匹配', () {
      final HostCompositionRoot root = buildRoot();
      final PluginPageProvider? provider = root.pageProviderFor(welcomeId);
      expect(provider, isNotNull);
      expect(provider!.pluginId.value, kWelcomePluginId);
      expect(root.pageProviderFor(PluginId.parse('com.test.none')), isNull);
    });

    test('主题持久化注入点随方向切换触发', () async {
      final List<AppThemePreset> persisted = <AppThemePreset>[];
      final HostCompositionRoot root = buildRoot(
        themePersist: (AppThemePreset preset) async => persisted.add(preset),
      );
      root.themeController.select(AppThemePreset.darkPro);
      await Future<void>.delayed(Duration.zero);
      expect(root.themeController.value, AppThemePreset.darkPro);
      expect(persisted, <AppThemePreset>[AppThemePreset.darkPro]);
    });
  });
}
