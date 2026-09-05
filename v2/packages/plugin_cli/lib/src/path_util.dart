/// 路径拼接与比较的小工具；零第三方依赖。
library;

import 'dart:io';

/// 以平台分隔符拼接目录与名字；目录已带分隔符时不重复。
String joinPath(String directory, String name) {
  if (directory.endsWith('/') || directory.endsWith(r'\')) {
    return '$directory$name';
  }
  return '$directory${Platform.pathSeparator}$name';
}

/// 把分隔符统一为正斜杠；可选在 Windows 上忽略大小写比较。
bool samePath(String a, String b) {
  final String normalizedA = a.replaceAll(r'\', '/');
  final String normalizedB = b.replaceAll(r'\', '/');
  if (Platform.isWindows) {
    return normalizedA.toLowerCase() == normalizedB.toLowerCase();
  }
  return normalizedA == normalizedB;
}

/// 计算 [file] 相对 [directory] 的路径，分隔符统一为正斜杠。
///
/// 调用方保证 [directory] 是 [file] 的前缀；先经 [canonicalDirectory]
/// 规整两端。
String relativePathOf(File file, String directory) {
  final String base = canonicalDirectory(directory);
  final String absolute = file.absolute.path.replaceAll(r'\', '/');
  return absolute.substring(base.length + 1);
}

/// 绝对化目录路径并去掉尾部斜杠（分隔符统一为正斜杠）。
String canonicalDirectory(String directory) {
  final String absolute = Directory(
    directory,
  ).absolute.path.replaceAll(r'\', '/');
  if (absolute.endsWith('/')) {
    return absolute.substring(0, absolute.length - 1);
  }
  return absolute;
}
