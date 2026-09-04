import 'package:plugin_contracts/plugin_contracts.dart';

/// 包内条目路径最大长度。
const int maxEntryPathLength = 1024;

/// 单个路径段最大长度（Windows MAX_PATH 分量语义）。
const int _maxSegmentLength = 255;

/// Windows 保留设备名（比对时去除扩展名并忽略大小写）。
const Set<String> _reservedNames = {
  'CON', 'PRN', 'AUX', 'NUL', //
  'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
  'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
};

final RegExp _drivePrefix = RegExp(r'^[a-zA-Z]:');

/// 校验安装包内单条相对路径并返回规范化结果。
///
/// 合法时规范化即原样返回且 [PluginFailure] 为 null；非法时 normalized
/// 为空字符串，failure.code 固定为 `package.path_unsafe`，details 携带
/// `reason` 与脱敏后的段位置，不携带宿主文件系统路径。
({String normalized, PluginFailure? failure}) validatePackagePath(
  String rawPath,
) {
  final failure = _validate(rawPath);
  if (failure != null) {
    return (normalized: '', failure: failure);
  }
  return (normalized: rawPath, failure: null);
}

/// 对整包路径集合做重复检测（大小写折叠）。
///
/// 存在冲突时返回首个冲突的 [PluginFailure]（details.reason 为
/// `duplicate`，details.path 为折叠后的包内路径）；否则返回 null。
PluginFailure? detectDuplicatePaths(Iterable<String> normalizedPaths) {
  final seen = <String>{};
  for (final path in normalizedPaths) {
    final key = path.toLowerCase();
    if (!seen.add(key)) {
      return PluginFailure(
        'package.path_unsafe',
        'package contains duplicate paths after case folding',
        <String, Object?>{'reason': 'duplicate', 'path': key},
      );
    }
  }
  return null;
}

/// 按固定顺序执行安全校验；合法时返回 null。
PluginFailure? _validate(String rawPath) {
  if (rawPath.isEmpty) {
    return _unsafe('empty');
  }
  if (rawPath.contains('\x00')) {
    return _unsafe('nulCharacter');
  }
  if (rawPath.startsWith(r'\\.\') || rawPath.startsWith(r'\\?\')) {
    return _unsafe('device');
  }
  if (rawPath.startsWith('/') ||
      rawPath.startsWith(r'\\') ||
      _drivePrefix.hasMatch(rawPath)) {
    return _unsafe('absolute');
  }
  if (rawPath.contains(r'\')) {
    return _unsafe('backslash');
  }
  if (rawPath.length > maxEntryPathLength) {
    return _unsafe('tooLong', <String, Object?>{'length': rawPath.length});
  }
  if (rawPath.endsWith('/')) {
    return _unsafe('trailingSeparator');
  }

  final segments = rawPath.split('/');
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    if (segment.isEmpty) {
      return _unsafe('blankSegment', <String, Object?>{'segmentIndex': i});
    }
    if (segment == '.' || segment == '..') {
      return _unsafe('traversal', <String, Object?>{'segmentIndex': i});
    }
    if (segment.length > _maxSegmentLength) {
      return _unsafe('tooLong', <String, Object?>{
        'segmentIndex': i,
        'length': segment.length,
      });
    }
    if (_isReservedName(segment)) {
      return _unsafe('device', <String, Object?>{'segmentIndex': i});
    }
  }
  return null;
}

/// 判断段名去除扩展名后是否为 Windows 保留设备名（大小写不敏感）。
bool _isReservedName(String segment) {
  final dot = segment.lastIndexOf('.');
  final base = dot > 0 ? segment.substring(0, dot) : segment;
  return _reservedNames.contains(base.toUpperCase());
}

PluginFailure _unsafe(String reason, [Map<String, Object?>? extra]) {
  return PluginFailure(
    'package.path_unsafe',
    'package path is unsafe (reason: $reason)',
    <String, Object?>{'reason': reason, ...?extra},
  );
}
