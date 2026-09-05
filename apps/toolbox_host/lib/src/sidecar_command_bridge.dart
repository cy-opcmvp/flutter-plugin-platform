/// Sidecar 命令桥（F4-06）：tools.hashtool 的安装/会话/RPC 编排。
///
/// 桥把 `SidecarInstaller` 的安装面与 `SidecarSession` 的会话面收敛为
/// hash_tool 专用 API：
/// - [SidecarCommandBridge.installFromBytes] 委托 `installBytes`，包解析
///   异常（`PackageException`）转为结构化失败而非抛出；
/// - [SidecarCommandBridge.start]/[SidecarCommandBridge.stop] 经注入的
///   [SidecarSessionFactory] 管理当前会话（重复 start 先 stop 旧会话）；
/// - [SidecarCommandBridge.run] 把声明式表单值映射为 `hash.compute`
///   RPC 调用，远端结果映射为声明式 [FieldsResultDescriptor]；
/// - 未安装调用命令 → `bridge.not_installed`；命令失败 →
///   `bridge.command_failed`（details 透传底层原码与上下文）。
///
/// 本文件零 `dart:io`：解释器探测与真实会话工厂经条件导出注入
/// （io 目标探测 python/python3/py -3，web 目标恒不支持）。
library;

import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';

/// hash_tool 命令方法名（清单 provides 声明的能力 ID）。
const String kHashToolCommandMethod = 'hash.compute';

/// hash_tool 表单文本字段的键。
const String kHashToolTextFormFieldKey = 'text';

/// 会话句柄抽象：桥与包内 `SidecarSession` 解耦，测试注入 fake。
abstract interface class SidecarSessionHandle {
  /// 就绪后的 RPC 通道；会话未就绪时为 null。
  RpcChannel? get channel;

  /// 停止会话；返回 null 表示成功，否则为结构化失败。
  Future<PluginFailure?> stop();
}

/// 会话工厂签名：给定已安装包内的入口脚本路径，返回就绪会话。
///
/// 工厂内部负责解释器探测与进程启动；失败抛
/// [SidecarSessionFactoryException]。
typedef SidecarSessionFactory =
    Future<SidecarSessionHandle> Function(String scriptPath);

/// 会话工厂失败：携带结构化失败（桥转为 command_failed 的 cause 透传）。
final class SidecarSessionFactoryException implements Exception {
  /// 创建工厂异常；[failure] 为底层结构化失败。
  const SidecarSessionFactoryException(this.failure);

  /// 底层结构化失败（如 `session.start_failed`）。
  final PluginFailure failure;
}

/// hash_tool 桥文案载体：表单与结果标签由宿主 l10n 注入。
final class HashToolStrings {
  /// 创建文案载体；各字段与宿主 arb 的 hash* 键一一对应。
  const HashToolStrings({
    required this.formTitle,
    required this.textLabel,
    required this.textPlaceholder,
    required this.md5Label,
    required this.sha1Label,
    required this.sha256Label,
  });

  /// 表单标题。
  final String formTitle;

  /// 文本输入字段标签。
  final String textLabel;

  /// 文本输入占位提示。
  final String textPlaceholder;

  /// 结果摘要 MD5 的标签。
  final String md5Label;

  /// 结果摘要 SHA-1 的标签。
  final String sha1Label;

  /// 结果摘要 SHA-256 的标签。
  final String sha256Label;
}

/// 构建 hash_tool 声明式表单描述（单 text 字段）。
FormDescriptor hashToolFormDescriptor(HashToolStrings strings) {
  return FormDescriptor(
    title: strings.formTitle,
    fields: <TextFieldSpec>[
      TextFieldSpec(
        key: kHashToolTextFormFieldKey,
        label: strings.textLabel,
        isRequired: true,
        placeholder: strings.textPlaceholder,
      ),
    ],
  );
}

/// 安装结果（包装安装器的 `InstallOutcome` 与包解析异常）。
final class BridgeInstallResult {
  /// 创建安装结果；[failure] 为 null 表示成功。
  const BridgeInstallResult({required this.succeeded, this.failure});

  /// 安装是否成功。
  final bool succeeded;

  /// 失败原因；成功时为 null。
  final PluginFailure? failure;
}

/// 启动结果：[failure] 为 null 表示会话已就绪。
final class BridgeStartOutcome {
  /// 创建启动结果。
  const BridgeStartOutcome(this.failure);

  /// 失败原因；成功时为 null。
  final PluginFailure? failure;

  /// 启动是否成功。
  bool get succeeded => failure == null;
}

/// 命令运行结果：成功时 [result] 非空，失败时 [failure] 非空。
final class BridgeRunResult {
  /// 创建命令运行结果。
  const BridgeRunResult(this.result, this.failure);

  /// 声明式结果描述；失败时为 null。
  final ResultDescriptor? result;

  /// 失败原因；成功时为 null。
  final PluginFailure? failure;

  /// 运行是否成功。
  bool get succeeded => failure == null;
}

/// hash_tool Sidecar 命令桥。
final class SidecarCommandBridge {
  /// 创建命令桥。
  ///
  /// [installer] 为 sidecar 包安装器；[pluginId] 为 hash_tool 的插件 ID；
  /// [entrypointFileName] 为已安装包内的入口脚本文件名；
  /// [sessionFactory] 为会话工厂注入缝。
  SidecarCommandBridge({
    required SidecarInstaller installer,
    required this.pluginId,
    required this.entrypointFileName,
    required SidecarSessionFactory sessionFactory,
  }) : _installer = installer,
       _sessionFactory = sessionFactory;

  final SidecarInstaller _installer;

  /// hash_tool 的插件 ID。
  final PluginId pluginId;

  /// 已安装包内的入口脚本文件名。
  final String entrypointFileName;

  final SidecarSessionFactory _sessionFactory;

  SidecarSessionHandle? _handle;

  /// 当前会话是否存活（有句柄且通道未关闭）。
  bool get isSessionLive {
    final RpcChannel? channel = _handle?.channel;
    if (channel == null || channel.isClosed) {
      return false;
    }
    return true;
  }

  /// 查询 hash_tool 是否已安装。
  Future<bool> isInstalled() {
    return _installer.isInstalled(pluginId);
  }

  /// hash_tool 的声明式表单描述（单 text 字段，宿主文案注入）。
  FormDescriptor formDescriptor(HashToolStrings strings) {
    return hashToolFormDescriptor(strings);
  }

  /// 从 .scp 字节安装 hash_tool 包。
  ///
  /// 包解析失败（`PackageException`）转为结构化失败（保留
  /// `package.bad_format` 等原码）；安装器已安装冲突等返回
  /// `sidecar.install_failed`。
  Future<BridgeInstallResult> installFromBytes(Uint8List bytes) async {
    try {
      final InstallOutcome outcome = await _installer.installBytes(bytes);
      return BridgeInstallResult(
        succeeded: outcome.succeeded,
        failure: outcome.failure,
      );
    } on PackageException catch (error) {
      return BridgeInstallResult(succeeded: false, failure: error.failure);
    }
  }

  /// 卸载 hash_tool 包（先停止活动会话）。
  ///
  /// 返回 null 表示成功；失败为 `sidecar.uninstall_failed`。
  Future<PluginFailure?> uninstall() async {
    await stop();
    final InstallOutcome outcome = await _installer.uninstall(pluginId);
    return outcome.failure;
  }

  /// 启动 hash_tool sidecar 会话（重复调用先停止旧会话）。
  ///
  /// 未安装 → `bridge.not_installed`；会话工厂失败 →
  /// `bridge.command_failed`（details.cause 透传底层原码）。
  Future<BridgeStartOutcome> start() async {
    if (!await isInstalled()) {
      return BridgeStartOutcome(_notInstalledFailure());
    }
    await _stopCurrentHandle();
    final String scriptPath =
        '${_installer.rootDir}/${pluginId.value}/$entrypointFileName';
    try {
      _handle = await _sessionFactory(scriptPath);
    } on SidecarSessionFactoryException catch (error) {
      return BridgeStartOutcome(
        _commandFailure(error.failure.code, error.failure.details),
      );
    } on Object catch (error) {
      return BridgeStartOutcome(
        _commandFailure('session.start_failed', <String, Object?>{
          'error': error.toString(),
        }),
      );
    }
    return const BridgeStartOutcome(null);
  }

  /// 停止当前会话；无活动会话时幂等返回 null。
  Future<PluginFailure?> stop() async {
    return _stopCurrentHandle();
  }

  /// 运行 hash.compute 命令：表单值 → RPC → 声明式结果。
  ///
  /// - 未安装 → `bridge.not_installed`；
  /// - 无活动会话时自动 [start]，启动失败透传其失败；
  /// - RPC 失败（远端错误/超时/通道关闭）→ `bridge.command_failed`
  ///   （details.cause 为原码、details.causeDetails 为原 details）。
  Future<BridgeRunResult> run(
    Map<String, Object?> formValues, {
    required HashToolStrings strings,
  }) async {
    if (!await isInstalled()) {
      return BridgeRunResult(null, _notInstalledFailure());
    }
    if (!isSessionLive) {
      final BridgeStartOutcome outcome = await start();
      if (!outcome.succeeded) {
        return BridgeRunResult(null, outcome.failure);
      }
    }
    final Object? text = formValues[kHashToolTextFormFieldKey];
    final RpcCallResult callResult = await _handle!.channel!.call(
      kHashToolCommandMethod,
      <String, Object?>{kHashToolTextFormFieldKey: text?.toString() ?? ''},
    );
    final PluginFailure? callFailure = callResult.failure;
    if (callFailure != null) {
      return BridgeRunResult(
        null,
        _commandFailure(callFailure.code, callFailure.details),
      );
    }
    final Object? value = callResult.value;
    if (value is! Map) {
      return BridgeRunResult(
        null,
        _commandFailure('rpc.remote_error', <String, Object?>{
          'error': 'unexpected result type: ${value.runtimeType}',
        }),
      );
    }
    final Map<Object?, Object?> summary = Map<Object?, Object?>.of(value);
    return BridgeRunResult(
      FieldsResultDescriptor(
        fields: <ResultField>[
          ResultField(
            label: strings.md5Label,
            value: _summaryOf(summary, 'md5'),
          ),
          ResultField(
            label: strings.sha1Label,
            value: _summaryOf(summary, 'sha1'),
          ),
          ResultField(
            label: strings.sha256Label,
            value: _summaryOf(summary, 'sha256'),
          ),
        ],
      ),
      null,
    );
  }

  /// 从远端结果 Map 取字符串摘要字段（防御非字符串值）。
  static String _summaryOf(Map<Object?, Object?> value, String key) {
    final Object? raw = value[key];
    return raw?.toString() ?? '';
  }

  PluginFailure _notInstalledFailure() {
    return PluginFailure(
      'bridge.not_installed',
      'sidecar plugin is not installed',
      <String, Object?>{'pluginId': pluginId.value},
    );
  }

  PluginFailure _commandFailure(
    String cause,
    Map<String, Object?> causeDetails,
  ) {
    return PluginFailure(
      'bridge.command_failed',
      'hash command failed',
      <String, Object?>{
        'pluginId': pluginId.value,
        'cause': cause,
        'causeDetails': Map<String, Object?>.of(causeDetails),
      },
    );
  }

  Future<PluginFailure?> _stopCurrentHandle() {
    final SidecarSessionHandle? handle = _handle;
    _handle = null;
    if (handle == null) {
      return Future<PluginFailure?>.value();
    }
    return handle.stop();
  }
}
