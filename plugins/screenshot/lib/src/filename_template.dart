/// 文件名模板纯逻辑：token 展开、非法字符清理、同秒序号。
///
/// 模板 token：
/// - `{date}` = 当天日期（yyyyMMdd）；
/// - `{time}` = 当前时间（HHmmss）；
/// - `{seq}`  = 同秒序号（同一秒内从 1 起递增）。
///
/// 展开结果经过非法文件名字符清理（`\ / : * ? " < > |` 与控制字符替换
/// 为下划线、结尾点号剔除），保证可安全落盘。本文件零平台依赖。
library;

/// 默认文件名模板。
const String kScreenshotDefaultFilenameTemplate = 'screenshot-{date}{time}';

/// 模板 token：当天日期（yyyyMMdd）。
const String kFilenameTokenDate = '{date}';

/// 模板 token：当前时间（HHmmss）。
const String kFilenameTokenTime = '{time}';

/// 模板 token：同秒序号（同一秒内从 1 起递增）。
const String kFilenameTokenSeq = '{seq}';

/// 文件名基名中的非法字符（Windows 保留字符集）。
const String _kIllegalFilenameChars = r'\/:*?"<>|';

/// 清理后的空基名回退值。
const String _kFallbackBaseName = 'screenshot';

String _two(int value) => value.toString().padLeft(2, '0');

/// 时间 → 文件名日期段（yyyyMMdd）。
String formatFilenameDate(DateTime time) {
  return '${time.year}${_two(time.month)}${_two(time.day)}';
}

/// 时间 → 文件名时间段（HHmmss）。
String formatFilenameTime(DateTime time) {
  return '${_two(time.hour)}${_two(time.minute)}${_two(time.second)}';
}

/// 清理文件名基名：非法字符与控制字符替换为下划线，剔除结尾点号与
/// 空白；清理后为空或仅剩替换下划线时回退 `screenshot`。
String sanitizeFilenameBase(String input) {
  final StringBuffer cleaned = StringBuffer();
  for (final int codeUnit in input.codeUnits) {
    final String char = String.fromCharCode(codeUnit);
    final bool illegal =
        _kIllegalFilenameChars.contains(char) || codeUnit < 0x20;
    cleaned.write(illegal ? '_' : char);
  }
  String result = cleaned.toString().trim();
  while (result.isNotEmpty && (result.endsWith('.') || result.endsWith(' '))) {
    result = result.substring(0, result.length - 1);
  }
  if (result.isEmpty || result.replaceAll('_', '').isEmpty) {
    return _kFallbackBaseName;
  }
  return result;
}

/// 展开文件名模板为文件名基名（不含扩展名）。
///
/// [seq] 为同秒序号（[FilenameSequencer.nextFor] 产出）。
String expandFilenameTemplate(
  String template, {
  required DateTime now,
  required int seq,
}) {
  final String base =
      template //
          .replaceAll(kFilenameTokenDate, formatFilenameDate(now))
          .replaceAll(kFilenameTokenTime, formatFilenameTime(now))
          .replaceAll(kFilenameTokenSeq, seq.toString());
  return sanitizeFilenameBase(base);
}

/// 同秒序号发生器：同一秒内连续取号递增（1 起），跨秒重置为 1。
final class FilenameSequencer {
  DateTime? _lastSecond;

  int _seq = 0;

  /// 取下一个序号：[now] 与上次同一秒则递增，否则重置为 1。
  int nextFor(DateTime now) {
    final DateTime second = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    if (_lastSecond != null && second == _lastSecond) {
      _seq++;
    } else {
      _lastSecond = second;
      _seq = 1;
    }
    return _seq;
  }
}
