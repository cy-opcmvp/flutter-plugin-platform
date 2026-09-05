/// 宿主组装根：整个应用唯一的依赖组装点。
///
/// 计划 F3-06 约定 `main.dart` 只做引导，全部服务在此装配：
/// - 内置欢迎插件清单注册进 [PluginRegistry]；
/// - 以 [PluginResolver] 按 main 显式传入的目标平台做静态解析，产出目录页
///   数据与不可用原因；
/// - 数据目录经 `ResolvedSystemPaths` 以纯字符串拼接（不创建目录，包内无
///   `dart:io`）；
/// - Sidecar 安装器以 `IoPackageFileSystem` 挂 `hostDataRoot` 下的
///   `sidecar-packages` 目录（构造不触发 I/O，落盘动作留给后续阶段）；
/// - [ThemeController] 初始 warm_life，持久化回调留作注入点。
library;

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';

import 'plugins/welcome_plugin.dart';

/// 宿主组装根。
final class HostCompositionRoot {
  /// 创建组装根并完成静态组装。
  ///
  /// [target] 为解析目标平台（由 main 显式传入）；[hostDataRoot] 为宿主数据
  /// 根目录字符串（仅参与拼接、不创建目录）；[extraManifests] 允许注入额外
  /// 清单（测试与后续阶段的 sidecar 目录发现共用此入口，默认为空）；
  /// [themePersist] 为主题方向持久化回调注入点（默认不持久化）。
  HostCompositionRoot({
    required PluginTarget target,
    required String hostDataRoot,
    List<PluginManifest> extraManifests = const <PluginManifest>[],
    Future<void> Function(AppThemePreset preset)? themePersist,
  }) {
    systemPaths = ResolvedSystemPaths(hostDataRoot: hostDataRoot);
    screenCapture = windowsScreenCapture;
    sidecarInstaller = SidecarInstaller(
      fs: const IoPackageFileSystem(),
      rootDir: '$hostDataRoot/sidecar-packages',
    );

    final List<PluginManifest> manifests = <PluginManifest>[
      welcomeManifest(),
      ...extraManifests,
    ];
    registry = PluginRegistry();
    for (final PluginManifest manifest in manifests) {
      registry.register(PluginRegistration(manifest));
    }
    resolution = PluginResolver.resolve(manifests, target);

    themeController = ThemeController(
      AppThemePreset.warmLife,
      persist: themePersist,
    );
    pageProviders = <PluginPageProvider>[const WelcomePlugin()];
  }

  /// 插件注册表（含内置欢迎插件与注入的额外清单）。
  late final PluginRegistry registry;

  /// 以 main 显式传入的目标平台完成的静态解析结果。
  late final PluginResolutionResult resolution;

  /// 宿主数据目录能力（纯字符串拼接实现）。
  late final SystemPaths systemPaths;

  /// 屏幕捕获能力（Windows stub，仅传递引用；M3 阶段不调用）。
  late final ScreenCapture screenCapture;

  /// Sidecar 包安装器（构造不触发 I/O）。
  late final SidecarInstaller sidecarInstaller;

  /// 主题方向控制器（初始 warm_life）。
  late final ThemeController themeController;

  /// 内置插件页面提供方列表。
  late final List<PluginPageProvider> pageProviders;

  /// 按 ID 查找页面提供方；不存在时返回 null。
  PluginPageProvider? pageProviderFor(PluginId id) {
    for (final PluginPageProvider provider in pageProviders) {
      if (provider.pluginId == id) {
        return provider;
      }
    }
    return null;
  }
}
