// 覆盖场景清单：
// 1. 合法 posix 相对路径原样返回且 failure 为 null。
// 2. 攻击矩阵逐一拒绝并断言 reason：empty / nulCharacter / device（设备路径
//    与 Windows 保留名，含去扩展名与子目录位置） / absolute（盘符、正斜杠
//    根、UNC） / backslash / tooLong（总长与段长） / trailingSeparator /
//    blankSegment / traversal（含单独 '.' 段）。
// 3. 非法路径 normalized 为空、code == package.path_unsafe。
// 4. detectDuplicatePaths 大小写折叠查重：冲突返回 duplicate failure，无冲突
//    返回 null。
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

void main() {
  // 提取非法路径的 PluginFailure，并断言 normalized 为空。
  PluginFailure failureOf(String rawPath) {
    final result = validatePackagePath(rawPath);
    expect(result.normalized, isEmpty);
    expect(result.failure, isNotNull);
    return result.failure!;
  }

  group('validatePackagePath', () {
    test('valid posix relative paths pass through unchanged', () {
      const paths = ['plugin.json', 'a/b.py', 'assets/data/x.json', 'main.py'];
      for (final path in paths) {
        final result = validatePackagePath(path);
        expect(result.failure, isNull, reason: path);
        expect(result.normalized, path);
      }
    });

    test('attack matrix is rejected with exact reasons', () {
      expect(failureOf('').details['reason'], 'empty');

      expect(failureOf('a\x00b').details['reason'], 'nulCharacter');

      // 设备路径前缀与 Windows 保留名（含子目录与扩展名折叠）。
      expect(failureOf(r'\\.\x').details['reason'], 'device');
      expect(failureOf(r'\\?\C:\x').details['reason'], 'device');
      expect(failureOf('CON').details['reason'], 'device');
      expect(failureOf('NUL').details['reason'], 'device');
      expect(failureOf('COM1').details['reason'], 'device');
      expect(failureOf('LPT9').details['reason'], 'device');
      expect(failureOf('con.txt').details['reason'], 'device');
      expect(failureOf('assets/con.txt').details['reason'], 'device');

      // 绝对路径：盘符、正斜杠根、UNC。
      expect(failureOf('C:/x').details['reason'], 'absolute');
      expect(failureOf(r'c:\x').details['reason'], 'absolute');
      expect(failureOf('/abs').details['reason'], 'absolute');
      expect(failureOf('/a').details['reason'], 'absolute');
      expect(failureOf(r'\\server\share').details['reason'], 'absolute');

      // 反斜杠分隔符。
      expect(failureOf(r'a\b').details['reason'], 'backslash');

      // 长度限制：总路径长与单段长。
      expect(failureOf('a' * 1025).details['reason'], 'tooLong');
      expect(failureOf("a/${'b' * 256}").details['reason'], 'tooLong');

      // 尾随分隔符与空段。
      expect(failureOf('a/').details['reason'], 'trailingSeparator');
      expect(failureOf('a//b').details['reason'], 'blankSegment');

      // 目录穿越（含单独 '.' 段）。
      expect(failureOf('../x').details['reason'], 'traversal');
      expect(failureOf('a/../../x').details['reason'], 'traversal');
      expect(failureOf('..').details['reason'], 'traversal');
      expect(failureOf('a/./b').details['reason'], 'traversal');
    });

    test('failures carry the unified error code', () {
      expect(failureOf('../x').code, 'package.path_unsafe');
    });
  });

  group('detectDuplicatePaths', () {
    test('conflicts are detected after case folding', () {
      final failure = detectDuplicatePaths([
        'plugin.json',
        'a/B.json',
        'A/b.JSON',
      ]);
      expect(failure, isNotNull);
      expect(failure!.code, 'package.path_unsafe');
      expect(failure.details['reason'], 'duplicate');
    });

    test('distinct paths return null', () {
      expect(detectDuplicatePaths(['a/b', 'c/b']), isNull);
    });
  });
}
