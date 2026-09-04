# F1-03 fix round 1 review package — complete filesystem delta

Captured: 2026-08-31T21:05:00+08:00

This project forbids AI Git operations. This package is the complete fix-only delta between the initial task review snapshot and fix round 1.

## Finding under verification

> Important: attacker-controlled unknown top-level keys were interpolated verbatim into `FormatException`, potentially echoing paths, environment values, process arguments, or secrets; no regression test covered this diagnostic boundary.

## Changed files

- `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
- The existing `task-F1-03-report.md` received its required fix-round evidence append.

No other production/test file changed.

## Complete test delta

Added immediately after the existing safe `command` unknown-field test:

```dart
test('catches sensitive unknown field keys leaking into diagnostics', () {
  const sensitiveKey =
      r'C:\Users\alice\AppData\plugin.exe --token=top-secret';
  final json = _validJson()..[sensitiveKey] = true;

  expect(
    () => PluginManifestCodec.decode(json),
    throwsA(
      isA<FormatException>()
          .having(
            (error) => error.message.toString(),
            'message',
            contains('unknown field'),
          )
          .having(
            (error) => error.message.toString(),
            'message',
            isNot(contains(sensitiveKey)),
          )
          .having(
            (error) => error.message.toString(),
            'message',
            isNot(contains(r'C:\Users\alice')),
          )
          .having(
            (error) => error.message.toString(),
            'message',
            isNot(contains('top-secret')),
          ),
    ),
  );
});
```

Bugfix RED before production change: `dart test test/manifest/plugin_manifest_codec_test.dart` exited 1. The new test alone failed and the actual exception was `Invalid manifest field: C:\Users\alice\AppData\plugin.exe --token=top-secret`.

## Complete production delta

Added a private bounded diagnostic-safe field pattern:

```dart
static final RegExp _safeDiagnosticField = RegExp(
  r'^[a-z][A-Za-z0-9]{0,63}$',
);
```

Changed the unknown-key branch:

```dart
// Before
if (!_fields.contains(field)) {
  _fail(field);
}

// After
if (!_fields.contains(field)) {
  _failUnknownField(field);
}
```

Added the private diagnostic function:

```dart
static Never _failUnknownField(String field) {
  if (_safeDiagnosticField.hasMatch(field)) {
    throw FormatException('Invalid manifest unknown field: $field');
  }

  throw const FormatException('Invalid manifest: unknown field');
}
```

The existing safe-key test still requires ordinary `command` to be present in the diagnostic. Unsafe keys that are long or contain separators, whitespace, punctuation, path syntax, or arguments receive a fixed category without interpolation.

## Fresh controller verification after fix

Working directory: `v2/packages/plugin_contracts`.

1. `dart test test/manifest/plugin_manifest_codec_test.dart` — exit 0; 26/26 passed.
2. `dart test test/manifest test/capability` — exit 0; 32/32 passed.
3. `dart test` — exit 0; 47/47 passed.
4. `dart format --output=none --set-exit-if-changed .` — exit 0; 10 files checked, 0 changed.
5. `dart analyze` — exit 0; no issues found.

The appended fix report contains exact RED/GREEN evidence, commands, outputs, mutation checks, scope check, and no concerns.
