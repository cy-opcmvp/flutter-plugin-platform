/// 宿主系统路径能力接口与默认不支持实现（规格 §10 平台策略）。
///
/// 路径解析为纯字符串操作，不创建目录、不依赖 `dart:io`，
/// 因此六端（含 Web）可共享同一接口。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 宿主数据路径能力接口。
abstract interface class SystemPaths {
  /// 宿主数据根目录。
  String hostDataRoot();

  /// 按 [id] 隔离的插件数据目录（纯路径解析，不建目录）。
  String pluginDataDir(PluginId id);
}

/// 各端默认实现：一律抛 `capability.unsupported`。
///
/// 方法签名要求返回 [String]，失败只能以抛出表达；异常值为
/// [PluginFailure]，调用方按结构化失败处理（详见批次报告偏差记录）。
final class UnsupportedSystemPaths implements SystemPaths {
  /// 创建不支持实现；[platform] 为平台标签（windows/macos/…）。
  const UnsupportedSystemPaths(this.platform);

  /// 平台标签，写入失败 details 便于定位来源端。
  final String platform;

  PluginFailure _failure() {
    return PluginFailure(
      'capability.unsupported',
      '当前平台不提供宿主系统路径',
      <String, Object?>{'capability': 'systemPaths', 'platform': platform},
    );
  }

  @override
  String hostDataRoot() => throw _failure();

  @override
  String pluginDataDir(PluginId id) => throw _failure();
}

/// 参考实现：构造注入宿主数据根目录，插件目录按 `<root>/<pluginId>` 拼接。
///
/// [PluginId] 已验证为反向域格式（仅小写字母、数字与点），不含路径分隔符，
/// 因此拼接结果无路径穿越空间。分隔符统一为 `/`。
final class ResolvedSystemPaths implements SystemPaths {
  /// 创建参考实现；为支持 const 构造，[hostDataRoot] 不做运行时校验。
  const ResolvedSystemPaths({required String hostDataRoot})
    : _hostDataRoot = hostDataRoot;

  final String _hostDataRoot;

  @override
  String hostDataRoot() => _hostDataRoot;

  @override
  String pluginDataDir(PluginId id) => '$_hostDataRoot/${id.value}';
}
