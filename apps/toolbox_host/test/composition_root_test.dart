/// F3-06 组装根焦点测试：注册、解析、路径拼接、页面提供方与主题注入点。
/// F4-02 追加：异步工厂 create（数据根注入缝）与图片字节加载器接线。
/// F4-03 追加：计算器插件注册、设置提供方查找与 plugin.json 一致性。
/// F4-05 追加：截图插件注册、提供方查找与 plugin.json 一致性。
library;

import 'dart:convert';
import 'dart:io';

import 'package:calculator/calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:screenshot/screenshot.dart';

import 'package:toolbox_host/src/host_composition_root.dart';
import 'package:toolbox_host/src/plugins/welcome_plugin.dart';

/// 仓库根绝对路径（CWD 无关）：从当前目录逐级向上找「workspace 根 + 宿主
/// 目录」同时存在的祖先——测试可在仓库内任意目录作为 CWD 运行（G5 Important
/// 修复；不使用 Isolate.resolvePackageUri，它在根 CWD 的 flutter test 下不受
/// 支持）。
String _repoRoot() {
  for (Directory d = Directory.current; d.parent.path != d.path; d = d.parent) {
    if (File('${d.path}/pubspec.yaml').existsSync() &&
        Directory('${d.path}/apps/toolbox_host').existsSync()) {
      return d.path;
    }
  }
  fail('未能在 ${Directory.current.path} 及其祖先中定位仓库根');
}

void main() {
  const String hostDataRoot = '%TESTDATA%/host';
  final PluginId welcomeId = PluginId.parse(kWelcomePluginId);
  final PluginId calculatorId = PluginId.parse(kCalculatorPluginId);
  final PluginId screenshotId = PluginId.parse(kScreenshotPluginId);

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

    test('声明 page 呈现面但无提供方时程序化给出 surface.unsupported', () {
      final PluginManifest orphan = PluginManifest(
        id: PluginId.parse('com.test.orphan'),
        name: 'Orphan',
        version: '0.1.0',
        apiVersion: 1,
        kind: PluginKind.builtin,
        targets: const <PluginTarget>[PluginTarget.windows],
        entrypoint: 'builtin://com.test.orphan',
        provides: const <CapabilityDescriptor>[],
        requires: const <CapabilityRequirement>[],
        surfaces: const <String>['page'],
        configSchemaVersion: 1,
        dataSchemaVersion: 1,
      );
      final HostCompositionRoot root = buildRoot(
        extraManifests: <PluginManifest>[orphan],
      );
      expect(root.surfaceFailures, contains(orphan.id.value));
      final PluginFailure failure = root.surfaceFailures[orphan.id.value]!;
      expect(failure.code, 'surface.unsupported');
      expect(failure.details['surface'], 'page');
      expect(failure.details['pluginId'], orphan.id.value);
      // 欢迎插件有已注册提供方，不产生 surface 失败。
      expect(root.surfaceFailures, isNot(contains(welcomeId.value)));
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

    test('计算器插件已注册、页面与设置提供方就位且无 surface 失败', () {
      final HostCompositionRoot root = buildRoot();
      expect(root.resolution.available, contains(calculatorId));
      expect(root.registry.registrations, contains(calculatorId));
      expect(root.pageProviderFor(calculatorId), isNotNull);
      expect(root.settingsProviderFor(calculatorId), isNotNull);
      expect(root.pageProviderFor(PluginId.parse('com.test.none')), isNull);
      expect(root.settingsProviderFor(PluginId.parse('com.test.none')), isNull);
      expect(root.surfaceFailures, isNot(contains(calculatorId.value)));
    });

    test('calculatorManifest 与 plugin.json 声明一致', () async {
      final String repoRoot = _repoRoot();
      final Map<String, Object?> json =
          jsonDecode(
                File(
                  '$repoRoot/plugins/calculator/plugin.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final PluginManifest manifest = calculatorManifest();
      expect(manifest.id.value, json['id']);
      expect(manifest.name, json['name']);
      expect(manifest.version, json['version']);
      expect(manifest.entrypoint, json['entrypoint']);
      expect(manifest.surfaces, <String>[
        ...(json['surfaces']! as List<Object?>).cast<String>(),
      ]);
      expect(
        manifest.targets.length,
        (json['targets']! as List<Object?>).length,
      );
      expect(
        manifest.provides.map((CapabilityDescriptor c) => c.id),
        (json['provides']! as List<Object?>).map(
          (Object? e) => (e! as Map<String, Object?>)['id'],
        ),
      );
    });

    test('截图插件已注册、页面与设置提供方就位且无 surface 失败', () {
      // F4-05：windows 目标下截图解析为可用，目录页应显示「可用」卡片。
      final HostCompositionRoot root = buildRoot();
      expect(root.resolution.available, contains(screenshotId));
      expect(root.registry.registrations, contains(screenshotId));
      expect(root.pageProviderFor(screenshotId), isNotNull);
      expect(root.settingsProviderFor(screenshotId), isNotNull);
      expect(root.surfaceFailures, isNot(contains(screenshotId.value)));
      // 数据目录按纯字符串拼接：{hostDataRoot}/tools.screenshot。
      expect(
        root.systemPaths.pluginDataDir(screenshotId),
        '$hostDataRoot/tools.screenshot',
      );
    });

    test('screenshotManifest 与 plugin.json 声明一致', () async {
      final String repoRoot = _repoRoot();
      final Map<String, Object?> json =
          jsonDecode(
                File(
                  '$repoRoot/plugins/screenshot/plugin.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final PluginManifest manifest = screenshotManifest();
      expect(manifest.id.value, json['id']);
      expect(manifest.name, json['name']);
      expect(manifest.version, json['version']);
      expect(manifest.entrypoint, json['entrypoint']);
      expect(manifest.surfaces, <String>[
        ...(json['surfaces']! as List<Object?>).cast<String>(),
      ]);
      expect(
        manifest.targets.length,
        (json['targets']! as List<Object?>).length,
      );
      expect(
        manifest.provides.map((CapabilityDescriptor c) => c.id),
        (json['provides']! as List<Object?>).map(
          (Object? e) => (e! as Map<String, Object?>)['id'],
        ),
      );
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

    test('create 工厂经注入解析器取得数据根并完成既有组装', () async {
      final HostCompositionRoot root = await HostCompositionRoot.create(
        target: PluginTarget.windows,
        dataRootResolver: () async => '%TESTDATA%/injected',
      );
      expect(
        root.systemPaths.pluginDataDir(welcomeId),
        '%TESTDATA%/injected/com.toolbox.welcome',
      );
      expect(
        root.sidecarInstaller.rootDir,
        '%TESTDATA%/injected/sidecar-packages',
      );
      expect(root.resolution.available, contains(welcomeId));
    });

    test('bytesLoader 读取存在的文件返回字节、缺失路径返回 null', () async {
      final HostCompositionRoot root = buildRoot();
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'toolbox_host_loader_test',
      );
      final File imageFile = File('${tempDir.path}/shot.png');
      await imageFile.writeAsBytes(<int>[1, 2, 3, 250]);
      try {
        expect(await root.bytesLoader(imageFile.path), <int>[1, 2, 3, 250]);
        expect(await root.bytesLoader('${tempDir.path}/missing.png'), isNull);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
