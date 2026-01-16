import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plugin_models.dart';
import 'i_plugin.dart';

/// 平台枚举
enum TargetPlatform {
  windows,
  macos,
  linux,
  android,
  ios,
  web,
}

/// 功能能力类型
enum CapabilityType {
  /// 完整支持
  full,
  /// 部分支持（有限制）
  partial,
  /// 不支持
  unsupported,
  /// 计划中
  planned,
}

/// 平台能力描述
class PlatformCapability {
  /// 目标平台
  final TargetPlatform platform;

  /// 能力类型
  final CapabilityType type;

  /// 能力描述
  final String description;

  /// 限制说明（如果 type 为 partial）
  final String? limitations;

  /// 实现状态
  final String? implementationStatus;

  const PlatformCapability({
    required this.platform,
    required this.type,
    required this.description,
    this.limitations,
    this.implementationStatus,
  });

  /// 是否支持该功能
  bool get isSupported => type == CapabilityType.full || type == CapabilityType.partial;

  /// 是否完全支持
  bool get isFullySupported => type == CapabilityType.full;

  /// 创建完整支持的能力
  factory PlatformCapability.fullSupported(TargetPlatform platform, String description) {
    return PlatformCapability(
      platform: platform,
      type: CapabilityType.full,
      description: description,
      implementationStatus: '已实现',
    );
  }

  /// 创建部分支持的能力
  factory PlatformCapability.partialSupported(
    TargetPlatform platform,
    String description,
    String limitations,
  ) {
    return PlatformCapability(
      platform: platform,
      type: CapabilityType.partial,
      description: description,
      limitations: limitations,
      implementationStatus: '部分实现',
    );
  }

  /// 创建不支持的能力
  factory PlatformCapability.unsupported(
    TargetPlatform platform,
    String reason,
  ) {
    return PlatformCapability(
      platform: platform,
      type: CapabilityType.unsupported,
      description: reason,
      implementationStatus: '不支持',
    );
  }

  /// 创建计划中的能力
  factory PlatformCapability.planned(
    TargetPlatform platform,
    String description,
  ) {
    return PlatformCapability(
      platform: platform,
      type: CapabilityType.planned,
      description: description,
      implementationStatus: '计划中',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'platform': platform.name,
      'type': type.name,
      'description': description,
      if (limitations != null) 'limitations': limitations,
      if (implementationStatus != null) 'implementationStatus': implementationStatus,
    };
  }

  /// 从 JSON 创建
  factory PlatformCapability.fromJson(Map<String, dynamic> json) {
    return PlatformCapability(
      platform: TargetPlatform.values.firstWhere((p) => p.name == json['platform']),
      type: CapabilityType.values.firstWhere((t) => t.name == json['type']),
      description: json['description'],
      limitations: json['limitations'],
      implementationStatus: json['implementationStatus'],
    );
  }
}

/// 插件平台能力配置
class PluginPlatformCapabilities {
  /// 插件 ID
  final String pluginId;

  /// 各平台的能力列表
  final Map<TargetPlatform, PlatformCapability> capabilities;

  /// 是否在应用中显示此插件（如果不支持则隐藏）
  final bool hideIfUnsupported;

  const PluginPlatformCapabilities({
    required this.pluginId,
    required this.capabilities,
    this.hideIfUnsupported = true,
  });

  /// 获取当前平台的能力
  PlatformCapability get currentPlatformCapability {
    final currentPlatform = _getCurrentPlatform();
    return capabilities[currentPlatform] ??
        PlatformCapability.unsupported(
          currentPlatform,
          '未在此平台实现',
        );
  }

  /// 当前平台是否支持
  bool get isCurrentPlatformSupported => currentPlatformCapability.isSupported;

  /// 当前平台是否完全支持
  bool get isCurrentPlatformFullySupported => currentPlatformCapability.isFullySupported;

  /// 获取当前平台
  TargetPlatform _getCurrentPlatform() {
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macos;
    if (Platform.isLinux) return TargetPlatform.linux;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.ios;
    if (Platform.isWeb) return TargetPlatform.web;
    throw UnsupportedError('Unknown platform');
  }

  /// 获取所有支持的平台列表
  List<TargetPlatform> get supportedPlatforms {
    return capabilities.entries
        .where((entry) => entry.value.isSupported)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取所有完全支持的平台列表
  List<TargetPlatform> get fullySupportedPlatforms {
    return capabilities.entries
        .where((entry) => entry.value.isFullySupported)
        .map((entry) => entry.key)
        .toList();
  }

  /// 创建能力配置
  factory PluginPlatformCapabilities.create({
    required String pluginId,
    required Map<TargetPlatform, PlatformCapability> capabilities,
    bool hideIfUnsupported = true,
  }) {
    return PluginPlatformCapabilities(
      pluginId: pluginId,
      capabilities: capabilities,
      hideIfUnsupported: hideIfUnsupported,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'capabilities': capabilities.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
      'hideIfUnsupported': hideIfUnsupported,
    };
  }

  /// 从 JSON 创建
  factory PluginPlatformCapabilities.fromJson(Map<String, dynamic> json) {
    return PluginPlatformCapabilities(
      pluginId: json['pluginId'],
      capabilities: (json['capabilities'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          TargetPlatform.values.firstWhere((p) => p.name == key),
          PlatformCapability.fromJson(value),
        ),
      ),
      hideIfUnsupported: json['hideIfUnsupported'] ?? true,
    );
  }
}

/// 平台插件接口 - 扩展 IPlugin，添加平台能力支持
abstract class IPlatformPlugin extends IPlugin {
  /// 获取平台能力配置
  PluginPlatformCapabilities get platformCapabilities;

  /// 检查当前平台是否支持
  bool get isCurrentPlatformSupported => platformCapabilities.isCurrentPlatformSupported;

  /// 检查当前平台是否完全支持
  bool get isCurrentPlatformFullySupported =>
      platformCapabilities.isCurrentPlatformFullySupported;

  /// 是否应该在应用中显示此插件
  bool get shouldBeVisible {
    if (platformCapabilities.hideIfUnsupported) {
      return isCurrentPlatformSupported;
    }
    return true; // 即使不支持也显示（例如显示"此平台暂不支持"）
  }

  /// 获取当前平台的能力描述
  PlatformCapability get currentCapability => platformCapabilities.currentPlatformCapability;

  /// 构建不支持的平台 UI（可选）
  Widget buildUnsupportedPlatformUI(BuildContext context) {
    final capability = currentCapability;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                capability.type == CapabilityType.planned
                    ? Icons.upcoming_outlined
                    : Icons.block_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                capability.type == CapabilityType.planned
                    ? '功能开发中'
                    : '暂不支持',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                capability.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (capability.limitations != null) ...[
                const SizedBox(height: 12),
                Text(
                  '限制: ${capability.limitations}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                ),
              ],
              const SizedBox(height: 24),
              if (capability.type == CapabilityType.partial)
                ElevatedButton.icon(
                  onPressed: () {
                    // 尝试以受限模式启动
                  },
                  icon: const Icon(Icons.warning_outlined),
                  label: const Text('以受限模式继续'),
                )
              else if (capability.type == CapabilityType.planned)
                OutlinedButton.icon(
                  onPressed: () {
                    // 查看路线图
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('查看开发计划'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 UI（自动处理平台支持）
  Widget buildUIWithContext(BuildContext context) {
    if (isCurrentPlatformSupported) {
      return buildUI(context);
    } else {
      return buildUnsupportedPlatformUI(context);
    }
  }
}

/// 平台服务工厂接口
abstract class PlatformServiceFactory<T> {
  /// 创建平台特定的服务实例
  T createService();

  /// 检查当前平台是否支持
  bool get isSupported;
}

/// 平台特定实现的基础接口
abstract class PlatformSpecificImplementation<T> {
  /// 平台类型
  TargetPlatform get platform;

  /// 实现实例
  T get implementation;

  /// 是否可用
  bool get isAvailable;
}
