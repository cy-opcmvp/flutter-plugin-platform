# F1-03 fix round 2 review package — complete filesystem delta

Captured: 2026-08-31T21:25:00+08:00

This project forbids AI Git operations. This package is the complete delta from fix round 1 to fix round 2.

## Open finding under verification

> The generic safe-shape regex still echoed alphanumeric sensitive unknown keys such as `topSecret123`; only a closed safe-name allowlist (while preserving ordinary `command` diagnostics) can prevent arbitrary caller-controlled input from entering exception messages.

## Changed files

- `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
- `task-F1-03-report.md` received the required fix-round 2 evidence append.

No other production or test file changed.

## Complete test delta

Added a second independent diagnostic regression:

```dart
test(
  'catches alphanumeric secret-shaped unknown keys leaking into diagnostics',
  () {
    const sensitiveKey = 'topSecret123';
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
              isNot(contains('Secret123')),
            ),
      ),
    );
  },
);
```

Before the production change, `dart test test/manifest/plugin_manifest_codec_test.dart` exited 1 and showed `Invalid manifest unknown field: topSecret123`.

## Complete production delta

Removed:

```dart
static final RegExp _safeDiagnosticField = RegExp(
  r'^[a-z][A-Za-z0-9]{0,63}$',
);
```

Added the closed allowlist:

```dart
static const Set<String> _diagnosticUnknownFieldAllowlist = <String>{
  'command',
};
```

Changed only the private branch predicate:

```dart
static Never _failUnknownField(String field) {
  if (_diagnosticUnknownFieldAllowlist.contains(field)) {
    throw FormatException('Invalid manifest unknown field: $field');
  }

  throw const FormatException('Invalid manifest: unknown field');
}
```

Thus only the explicitly approved literal `command` is interpolated. All other caller-controlled unknown keys, regardless of character shape or length, take the fixed anonymous diagnostic. The original safe `command` test, path/argument sensitive test, and new alphanumeric sensitive test all remain active.

## Fresh controller verification

Working directory: `v2/packages/plugin_contracts`.

1. `dart test test/manifest/plugin_manifest_codec_test.dart` — exit 0; 27/27 passed.
2. `dart test test/manifest test/capability` — exit 0; 33/33 passed.
3. `dart test` — exit 0; 48/48 passed.
4. `dart format --output=none --set-exit-if-changed .` — exit 0; 10 files checked, 0 changed.
5. `dart analyze` — exit 0; no issues found.

The appended fix report contains the exact new RED, GREEN/full verification, scope, mutation checks, and no concerns.
