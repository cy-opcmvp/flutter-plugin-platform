final class PluginFailure {
  /// 创建稳定、可安全共享的结构化失败值。
  PluginFailure(
    String code,
    String message, [
    Map<String, Object?> details = const {},
  ]) : code = _requireNonEmpty(code, 'code'),
       message = _requireNonEmpty(message, 'message'),
       details = Map<String, Object?>.unmodifiable(details);

  final String code;
  final String message;

  /// 调用方不可修改的失败上下文快照。
  final Map<String, Object?> details;

  static String _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }

    return value;
  }
}
