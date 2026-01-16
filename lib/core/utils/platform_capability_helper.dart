import 'dart:io';
import '../interfaces/i_platform_plugin.dart';

/// 平台能力辅助类 - 帮助插件快速定义平台能力
class PlatformCapabilityHelper {
  /// 创建跨平台完全支持的能力配置
  static PluginPlatformCapabilities fullySupported({
    required String pluginId,
    String? description,
    bool hideIfUnsupported = false,
  }) {
    return PluginPlatformCapabilities.create(
      pluginId: pluginId,
      capabilities: {
        TargetPlatform.windows: PlatformCapability.fullSupported(
          TargetPlatform.windows,
          description ?? '完整支持',
        ),
        TargetPlatform.macos: PlatformCapability.fullSupported(
          TargetPlatform.macos,
          description ?? '完整支持',
        ),
        TargetPlatform.linux: PlatformCapability.fullSupported(
          TargetPlatform.linux,
          description ?? '完整支持',
        ),
        TargetPlatform.android: PlatformCapability.fullSupported(
          TargetPlatform.android,
          description ?? '完整支持',
        ),
        TargetPlatform.ios: PlatformCapability.fullSupported(
          TargetPlatform.ios,
          description ?? '完整支持',
        ),
        TargetPlatform.web: PlatformCapability.fullSupported(
          TargetPlatform.web,
          description ?? '完整支持',
        ),
      },
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 创建桌面平台支持的配置
  static PluginPlatformCapabilities desktopSupported({
    required String pluginId,
    String? description,
    bool hideIfUnsupported = true,
  }) {
    return PluginPlatformCapabilities.create(
      pluginId: pluginId,
      capabilities: {
        TargetPlatform.windows: PlatformCapability.fullSupported(
          TargetPlatform.windows,
          description ?? '桌面平台支持',
        ),
        TargetPlatform.macos: PlatformCapability.fullSupported(
          TargetPlatform.macos,
          description ?? '桌面平台支持',
        ),
        TargetPlatform.linux: PlatformCapability.fullSupported(
          TargetPlatform.linux,
          description ?? '桌面平台支持',
        ),
        TargetPlatform.android: PlatformCapability.unsupported(
          TargetPlatform.android,
          '仅支持桌面平台',
        ),
        TargetPlatform.ios: PlatformCapability.unsupported(
          TargetPlatform.ios,
          '仅支持桌面平台',
        ),
        TargetPlatform.web: PlatformCapability.unsupported(
          TargetPlatform.web,
          '仅支持桌面平台',
        ),
      },
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 创建移动平台支持的配置
  static PluginPlatformCapabilities mobileSupported({
    required String pluginId,
    String? description,
    bool hideIfUnsupported = true,
  }) {
    return PluginPlatformCapabilities.create(
      pluginId: pluginId,
      capabilities: {
        TargetPlatform.windows: PlatformCapability.unsupported(
          TargetPlatform.windows,
          '仅支持移动平台',
        ),
        TargetPlatform.macos: PlatformCapability.unsupported(
          TargetPlatform.macos,
          '仅支持移动平台',
        ),
        TargetPlatform.linux: PlatformCapability.unsupported(
          TargetPlatform.linux,
          '仅支持移动平台',
        ),
        TargetPlatform.android: PlatformCapability.fullSupported(
          TargetPlatform.android,
          description ?? '移动平台支持',
        ),
        TargetPlatform.ios: PlatformCapability.fullSupported(
          TargetPlatform.ios,
          description ?? '移动平台支持',
        ),
        TargetPlatform.web: PlatformCapability.unsupported(
          TargetPlatform.web,
          '仅支持移动平台',
        ),
      },
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 创建 Windows 专用配置
  static PluginPlatformCapabilities windowsOnly({
    required String pluginId,
    String? description,
    bool hideIfUnsupported = true,
  }) {
    return PluginPlatformCapabilities.create(
      pluginId: pluginId,
      capabilities: {
        TargetPlatform.windows: PlatformCapability.fullSupported(
          TargetPlatform.windows,
          description ?? 'Windows 专用功能',
        ),
        for (var platform in [
          TargetPlatform.macos,
          TargetPlatform.linux,
          TargetPlatform.android,
          TargetPlatform.ios,
          TargetPlatform.web,
        ])
          platform: PlatformCapability.unsupported(
            platform,
            '仅支持 Windows 平台',
          ),
      },
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 创建混合配置（自定义各平台能力）
  static PluginPlatformCapabilities custom({
    required String pluginId,
    required Map<TargetPlatform, PlatformCapability> capabilities,
    bool hideIfUnsupported = true,
  }) {
    return PluginPlatformCapabilities.create(
      pluginId: pluginId,
      capabilities: capabilities,
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 创建通用能力描述
  static String getFullySupportedDescription(TargetPlatform platform) {
    return '在 ${_getPlatformName(platform)} 上完整支持所有功能';
  }

  static String getPartialSupportedDescription(
    TargetPlatform platform,
    String limitations,
  ) {
    return '在 ${_getPlatformName(platform)} 上部分支持，限制: $limitations';
  }

  static String getUnsupportedDescription(TargetPlatform platform) {
    return '暂不支持 ${_getPlatformName(platform)} 平台';
  }

  static String _getPlatformName(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macos:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.ios:
        return 'iOS';
      case TargetPlatform.web:
        return 'Web';
    }
  }

  /// 获取当前平台枚举
  static TargetPlatform getCurrentPlatform() {
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macos;
    if (Platform.isLinux) return TargetPlatform.linux;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.ios;
    return TargetPlatform.web;
  }

  /// 检查是否是桌面平台
  static bool isDesktopPlatform() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 检查是否是移动平台
  static bool isMobilePlatform() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 检查是否是 Web 平台
  static bool isWebPlatform() {
    // dart:io doesn't have Platform.isWeb
    // On web, dart:io is not available, so this will return false
    // For web detection, use kIsWeb from 'package:flutter/foundation.dart'
    return false;
  }

  /// 获取平台类型名称
  static String getPlatformTypeName() {
    if (isDesktopPlatform()) return '桌面平台';
    if (isMobilePlatform()) return '移动平台';
    if (isWebPlatform()) return 'Web 平台';
    return '未知平台';
  }
}
