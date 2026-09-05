/// 宿主组装根：整个应用唯一的依赖组装点。
///
/// 计划 F3-06 约定 `main.dart` 只做引导，全部服务在此装配：
/// - 内置欢迎插件清单注册进 [PluginRegistry]；
/// - 以 [PluginResolver] 按 main 显式传入的目标平台做静态解析，产出目录页
///   数据与不可用原因；
/// - 数据目录经 `ResolvedSystemPaths` 以纯字符串拼接（不创建目录，包内无
///   `dart:io`）；真实数据根经异步工厂 [HostCompositionRoot.create] 由
///   path_provider 解析（web 分支使用占位常量，F4-02）；
/// - Sidecar 安装器以 `IoPackageFileSystem` 挂 `hostDataRoot` 下的
///   `sidecar-packages` 目录（构造不触发 I/O，落盘动作留给后续阶段）；
/// - [ThemeController] 初始 warm_life，持久化回调留作注入点；
/// - 图片字节加载器、截图写文件缝、数据根解析与屏幕捕获均经条件导出
///   接线（io 目标接真实实现、web 目标取 stub，F4-02/F4-05/F4-07）；
/// - 计算器（F4-03）与截图（F4-05）插件：共享模型 + 宿主文案解析器，
///   截图捕获注入 Windows GDI 真实现（F4-04）。
library;

import 'package:calculator/calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:screenshot/screenshot.dart';

import 'host_bytes_loader.dart';
import 'host_data_root.dart';
import 'host_file_saver.dart';
import 'host_screen_capture.dart';
import 'plugins/calculator_plugin.dart';
import 'plugins/hash_tool_plugin.dart';
import 'plugins/screenshot_plugin.dart';
import 'plugins/welcome_plugin.dart';
import 'sidecar_command_bridge.dart';
import 'sidecar_session_factory.dart';

/// 宿主组装根。
final class HostCompositionRoot {
  /// 异步创建组装根（F4-02 真实数据根接线）。
  ///
  /// [target] 为解析目标平台；[extraManifests] 与 [themePersist] 语义同
  /// 同步构造；[dataRootResolver] 为数据根解析注入缝（测试替换，默认经
  /// path_provider 的 getApplicationSupportDirectory）。web 目标（kIsWeb）
  /// 无文件系统，直接使用占位常量 [kWebHostDataRoot]。
  static Future<HostCompositionRoot> create({
    required PluginTarget target,
    List<PluginManifest> extraManifests = const <PluginManifest>[],
    Future<void> Function(AppThemePreset preset)? themePersist,
    Future<String> Function()? dataRootResolver,
  }) async {
    if (kIsWeb) {
      return HostCompositionRoot(
        target: target,
        hostDataRoot: kWebHostDataRoot,
        extraManifests: extraManifests,
        themePersist: themePersist,
      );
    }
    final Future<String> Function() resolve =
        dataRootResolver ?? resolveApplicationSupportRoot;
    return HostCompositionRoot(
      target: target,
      hostDataRoot: await resolve(),
      extraManifests: extraManifests,
      themePersist: themePersist,
    );
  }

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
    // 屏幕捕获经条件导出接线（F4-07）：io 目标注入 Windows GDI 真实现
    // （F4-04），web 目标注入 unsupported stub，保证 web 编译图零 ffi。
    screenCapture = hostScreenCapture;
    sidecarInstaller = SidecarInstaller(
      fs: const IoPackageFileSystem(),
      rootDir: '$hostDataRoot/sidecar-packages',
    );
    // hash_tool 命令桥（F4-06）：复用同一安装器根目录；会话工厂经条件
    // 导出注入（io 目标探测 Python，web 目标恒不支持）。
    sidecarBridge = SidecarCommandBridge(
      installer: sidecarInstaller,
      pluginId: PluginId.parse(kHashToolPluginId),
      entrypointFileName: kHashToolEntrypointFileName,
      sessionFactory: createHashToolSessionFactory(),
    );

    final List<PluginManifest> manifests = <PluginManifest>[
      welcomeManifest(),
      calculatorManifest(),
      screenshotManifest(),
      hashToolManifest(),
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
    // 字节加载器先于页面提供方赋值（截图页面构造注入该函数引用）。
    bytesLoader = loadHostImageBytes;
    // 计算器插件（F4-03）：共享模型 + 宿主文案解析器，页面与设置共用。
    final CalculatorModel calculatorModel = CalculatorModel();
    final CalculatorStringsResolver calculatorResolver =
        hostCalculatorStringsResolver();
    // 截图插件（F4-05）：捕获能力注入 Windows GDI 真实现（F4-04），
    // 写文件缝落盘到插件数据目录；包内零 dart:io。
    final ScreenshotModel screenshotModel = ScreenshotModel();
    final CaptureController screenshotController = CaptureController(
      screenCapture: screenCapture,
      saveFile: (Uint8List bytes, String filename) => saveHostScreenshotFile(
        rootDir: systemPaths.pluginDataDir(PluginId.parse(kScreenshotPluginId)),
        bytes: bytes,
        filename: filename,
      ),
      model: screenshotModel,
    );
    final ScreenshotStringsResolver screenshotResolver =
        hostScreenshotStringsResolver();
    pageProviders = <PluginPageProvider>[
      const WelcomePlugin(),
      CalculatorPageProvider(
        model: calculatorModel,
        stringsResolver: calculatorResolver,
      ),
      ScreenshotPageProvider(
        controller: screenshotController,
        stringsResolver: screenshotResolver,
        bytesLoader: bytesLoader,
      ),
    ];
    settingsProviders = <String, PluginSettingsProvider>{
      kCalculatorPluginId: CalculatorSettingsProvider(
        model: calculatorModel,
        stringsResolver: calculatorResolver,
      ),
      kScreenshotPluginId: ScreenshotSettingsProvider(
        model: screenshotModel,
        stringsResolver: screenshotResolver,
      ),
    };

    // 呈现面程序化校验：清单声明 page/settings 但宿主未注册对应提供方时，
    // 经 surfaceUnsupported 产生结构化失败（G3-A minor 2 的正式接线）。
    final Map<String, PluginFailure> unsupportedSurfaces =
        <String, PluginFailure>{};
    for (final PluginManifest manifest in manifests) {
      if (manifest.surfaces.contains('page') &&
          pageProviderFor(manifest.id) == null) {
        unsupportedSurfaces[manifest.id.value] = surfaceUnsupported(
          'page',
          manifest.id,
        );
      }
      if (manifest.surfaces.contains('settings') &&
          settingsProviderFor(manifest.id) == null) {
        unsupportedSurfaces[manifest.id.value] = surfaceUnsupported(
          'settings',
          manifest.id,
        );
      }
    }
    surfaceFailures = Map<String, PluginFailure>.unmodifiable(
      unsupportedSurfaces,
    );
  }

  /// 插件注册表（含内置欢迎插件与注入的额外清单）。
  late final PluginRegistry registry;

  /// 以 main 显式传入的目标平台完成的静态解析结果。
  late final PluginResolutionResult resolution;

  /// 宿主数据目录能力（纯字符串拼接实现）。
  late final SystemPaths systemPaths;

  /// 屏幕捕获能力（Windows GDI 真实现，F4-04；其他目标为 stub）。
  late final ScreenCapture screenCapture;

  /// Sidecar 包安装器（构造不触发 I/O）。
  late final SidecarInstaller sidecarInstaller;

  /// hash_tool Sidecar 命令桥（F4-06）。
  ///
  /// 详情页 sidecar 面板经此完成安装/启动/停止与 hash.compute 命令。
  late final SidecarCommandBridge sidecarBridge;

  /// 主题方向控制器（初始 warm_life）。
  late final ThemeController themeController;

  /// 内置插件页面提供方列表。
  late final List<PluginPageProvider> pageProviders;

  /// 内置插件设置提供方（键为插件 ID 字符串）。
  ///
  /// [PluginSettingsProvider] 接口不带 pluginId，宿主以注册表形式补齐
  /// ID 到提供方的映射。
  late final Map<String, PluginSettingsProvider> settingsProviders;

  /// 图片字节加载器（按条件导出接线：io 目标读文件、web 目标恒空）。
  ///
  /// 供宿主内全部 ResultRenderer 使用点注入，真实解码 image 类结果。
  late final Future<Uint8List?> Function(String path) bytesLoader;

  /// 声明了宿主未实现呈现面的插件（键为插件 ID 字符串）。
  ///
  /// 目录页据此以「不可用 + 结构化原因」呈现，替代纯禁用按钮兜底。
  late final Map<String, PluginFailure> surfaceFailures;

  /// 按 ID 查找页面提供方；不存在时返回 null。
  PluginPageProvider? pageProviderFor(PluginId id) {
    for (final PluginPageProvider provider in pageProviders) {
      if (provider.pluginId == id) {
        return provider;
      }
    }
    return null;
  }

  /// 按 ID 查找设置提供方；不存在时返回 null。
  PluginSettingsProvider? settingsProviderFor(PluginId id) {
    return settingsProviders[id.value];
  }
}
