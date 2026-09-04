# F1-02 fix round 1 review package — filesystem delta

Captured: 2026-08-31T19:42:00+08:00

This project forbids AI Git operations. This package is the complete fix-only delta between the task review snapshot and fix round 1.

## Finding under verification

> Important: `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart` was not formatter-clean, so the brief's required `dart format --output=none --set-exit-if-changed .` gate exited 1.

## Fix scope

Only `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart` changed. Production source files and exports retain the hashes from the original review package. The test changed from LF-normalized SHA-256 `1BC3F1840D71FAFD8EB3A99FB7869469E050ED59F876CF19B649F3E9F16E3B44` to `EE8056FC987554D6F37F273DD5C1D4FA8B32A0FB8B962D59A5535209F6B59A89`.

## Complete semantic/layout delta

### Hunk 1 — formatter collapsed one `expect`

Before:

```dart
expect(
  () => PluginId.parse('Tools.Calculator'),
  throwsFormatException,
);
```

After:

```dart
expect(() => PluginId.parse('Tools.Calculator'), throwsFormatException);
```

### Hunk 2 — formatter collapsed one `having` call

Before:

```dart
isA<ArgumentError>().having(
  (error) => error.name,
  'name',
  'message',
),
```

After:

```dart
isA<ArgumentError>().having((error) => error.name, 'name', 'message'),
```

### Hunk 3 — formatter expanded one constructor call

Before:

```dart
final failure = PluginFailure('plugin.invalid', 'Plugin is invalid', input);
```

After:

```dart
final failure = PluginFailure(
  'plugin.invalid',
  'Plugin is invalid',
  input,
);
```

### Line-ending normalization

The same file was normalized from CRLF to LF. No string literal, test name, assertion, matcher, assignment, call argument, order, or behavior changed. Counts remain 15 `test(...)` calls and 21 `expect(...)` calls.

## Fresh controller verification after fix

Working directory: `v2/packages/plugin_contracts`.

1. `dart test test/identity/plugin_id_test.dart` — exit 0; the same 15 named tests ran in the same order and ended with `+15: All tests passed!`.
2. `dart format --output=none --set-exit-if-changed .` — exit 0; `Formatted 4 files (0 changed) in 0.01 seconds.`
3. `dart analyze` — exit 0; `No issues found!`.

## Report evidence

The implementer appended `## Fix round 1` to `task-F1-02-report.md`, including the allowed controller ruling, precise layout changes, all three commands and outputs, new hash, unchanged test/expect counts, and no concerns.
