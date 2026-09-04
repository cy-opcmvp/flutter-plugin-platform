# F1-02 review package — filesystem baseline-to-head snapshot

Captured: 2026-08-31T19:16:00+08:00

This project forbids AI Git operations. This package replaces a Git diff with the complete task-scoped baseline, final files, hashes, and fresh controller verification. Generated `v2/pubspec.lock` and `.dart_tool` state are excluded from authored implementation.

## Baseline-to-head summary

| File | Baseline | Head SHA-256 |
|---|---|---|
| `v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart` | absent | `9336D098F21E2B7D408939304D08FC9F1C7F6777595B33F63C8058AE75657318` |
| `v2/packages/plugin_contracts/lib/src/errors/plugin_failure.dart` | absent | `EDFAB778F724579895D86C8BA654246061FA6047DC013E5B4B361D16BEEBAEB2` |
| `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart` | absent at task baseline; authored RED before pause | LF-normalized `1BC3F1840D71FAFD8EB3A99FB7869469E050ED59F876CF19B649F3E9F16E3B44`, unchanged from pause handoff |
| `v2/packages/plugin_contracts/lib/plugin_contracts.dart` | present, empty | `4314FFEC086F31DD47AFAA565F523A8FBEB4F638C684393DCB3F22AF37A27E5F` |

## Complete task snapshot

### `v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart`

```dart
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
```

### `v2/packages/plugin_contracts/lib/src/errors/plugin_failure.dart`

```dart
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
```

### `v2/packages/plugin_contracts/lib/plugin_contracts.dart`

```dart
export 'src/errors/plugin_failure.dart';
export 'src/identity/plugin_id.dart';
```

### `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('PluginId', () {
    test('catches valid dotted lowercase IDs being rejected', () {
      expect(PluginId.parse('tools.calculator').value, 'tools.calculator');
    });

    test('catches path traversal being accepted as an ID', () {
      expect(() => PluginId.parse('../escape'), throwsFormatException);
    });

    test('catches uppercase characters bypassing validation', () {
      expect(
        () => PluginId.parse('Tools.Calculator'),
        throwsFormatException,
      );
    });

    test('catches a single segment being accepted as an ID', () {
      expect(() => PluginId.parse('single'), throwsFormatException);
    });

    test('catches an empty string being accepted as an ID', () {
      expect(() => PluginId.parse(''), throwsFormatException);
    });

    test('catches malformed dotted segments bypassing validation', () {
      expect(() => PluginId.parse('tools.'), throwsFormatException);
      expect(() => PluginId.parse('tools..clock'), throwsFormatException);
    });

    test('catches tryParse rejecting a valid ID', () {
      expect(PluginId.tryParse('tools.clock')?.value, 'tools.clock');
    });

    test('catches tryParse throwing instead of returning null', () {
      expect(PluginId.tryParse('bad/path'), isNull);
    });

    test('catches equality or hash code drifting from the ID value', () {
      final first = PluginId.parse('tools.calculator');
      final same = PluginId.parse('tools.calculator');
      final different = PluginId.parse('tools.clock');

      expect(first, equals(same));
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(equals(different)));
    });

    test('catches toString exposing data beyond the validated ID', () {
      expect(PluginId.parse('tools.calculator').toString(), 'tools.calculator');
    });
  });

  group('PluginFailure', () {
    test('catches constructor fields not preserving valid failure data', () {
      final failure = PluginFailure(
        'plugin.invalid',
        'Plugin is invalid',
        <String, Object?>{'pluginId': 'tools.calculator'},
      );

      expect(failure.code, 'plugin.invalid');
      expect(failure.message, 'Plugin is invalid');
      expect(failure.details, <String, Object?>{
        'pluginId': 'tools.calculator',
      });
    });

    test('catches blank failure codes bypassing validation', () {
      expect(
        () => PluginFailure('  ', 'Plugin is invalid'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'code'),
        ),
      );
    });

    test('catches blank failure messages bypassing validation', () {
      expect(
        () => PluginFailure('plugin.invalid', '\t'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'message',
          ),
        ),
      );
    });

    test('catches later input-map mutation changing failure details', () {
      final input = <String, Object?>{'attempt': 1};
      final failure = PluginFailure('plugin.invalid', 'Plugin is invalid', input);

      input['attempt'] = 2;
      input['new'] = true;

      expect(failure.details, <String, Object?>{'attempt': 1});
    });

    test('catches callers mutating exposed failure details', () {
      final failure = PluginFailure(
        'plugin.invalid',
        'Plugin is invalid',
        <String, Object?>{'attempt': 1},
      );

      expect(() => failure.details['attempt'] = 2, throwsUnsupportedError);
      expect(failure.details, <String, Object?>{'attempt': 1});
    });
  });
}
```

## Fresh controller verification

Working directory: `v2/packages/plugin_contracts`.

1. `dart test test/identity/plugin_id_test.dart` — exit 0; `+15: All tests passed!`.
2. `dart format --output=none --set-exit-if-changed .` — exit 1; only `test\identity\plugin_id_test.dart` would change; `Formatted 4 files (1 changed)`.
3. `dart format --output=none --set-exit-if-changed lib` — exit 0; `Formatted 3 files (0 changed)`.
4. `dart analyze` — exit 0; `No issues found!`.

The test file is byte-for-byte behaviorally unchanged from the preserved RED when line endings are normalized. The implementer was explicitly forbidden to rewrite it during resume. The reviewer should judge this reported format-gate conflict normally; the controller has not pre-classified it.

## Scope and boundary check

- Authored production changes are exactly the two new source files and the package export above.
- The existing RED test is unchanged from the pause handoff after LF normalization.
- The task report is `task-F1-02-report.md`.
- No Flutter, `dart:io`, `dart:ffi`, `win32`, platform, runtime, business, serialization, timestamp, stack trace, or error-taxonomy code appears in the task snapshot.
- `v2/pubspec.lock` was regenerated/updated by Dart on this computer and remains controller-owned cache state, not authored implementation.
