/// 极简命令行参数扫描（刻意不引入 `args` 包）。
///
/// 支持 `--name value`、`--name=value`、短选项 `-o value` 与位置参数；
/// 选项缺值时记录为空字符串，由调用方按用法错误处理。
library;

/// 手写解析结果：命名选项表 + 位置参数表。
final class ParsedArgs {
  ParsedArgs._(this._options, this.positionals);

  /// 扫描 [arguments]；重复选项以后出现者为准。
  factory ParsedArgs.parse(List<String> arguments) {
    final Map<String, String> options = <String, String>{};
    final List<String> positionals = <String>[];
    var index = 0;
    while (index < arguments.length) {
      final String token = arguments[index];
      final bool isOption = token.startsWith('--') || token == '-o';
      if (!isOption) {
        positionals.add(token);
        index++;
        continue;
      }

      final int equals = token.indexOf('=');
      if (equals >= 0) {
        options[token.substring(0, equals)] = token.substring(equals + 1);
        index++;
        continue;
      }

      if (index + 1 < arguments.length) {
        options[token] = arguments[index + 1];
        index += 2;
        continue;
      }

      options[token] = '';
      index++;
    }
    return ParsedArgs._(options, positionals);
  }

  final Map<String, String> _options;

  /// 位置参数（不含任何选项与选项值）。
  final List<String> positionals;

  /// 读取选项值；未提供返回 `null`，`--name` 后缺值返回空字符串。
  String? option(String name) => _options[name];
}
