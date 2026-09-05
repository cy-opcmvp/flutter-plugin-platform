final class PluginId {
  PluginId._(this.value);

  static final RegExp _validPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$');

  /// 经过校验的稳定插件标识。
  final String value;

  /// 解析严格的小写点分标识；格式无效时抛出 [FormatException]。
  factory PluginId.parse(String source) {
    if (!_validPattern.hasMatch(source)) {
      throw FormatException('Invalid plugin ID', source);
    }

    return PluginId._(source);
  }

  /// 尝试解析标识；仅在格式无效时返回 `null`。
  static PluginId? tryParse(String source) {
    if (!_validPattern.hasMatch(source)) {
      return null;
    }

    return PluginId._(source);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PluginId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
