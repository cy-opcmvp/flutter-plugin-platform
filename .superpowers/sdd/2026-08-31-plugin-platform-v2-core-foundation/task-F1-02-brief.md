# Task F1-02 brief — validated plugin identity and structured failure

## Outcome

Add the first stable public contracts to `plugin_contracts`: a strictly validated immutable `PluginId` value object and an immutable structured `PluginFailure` value. Work test-first and expose both through the package entry library.

## Allowed authored files

- `v2/packages/plugin_contracts/lib/src/identity/plugin_id.dart`
- `v2/packages/plugin_contracts/lib/src/errors/plugin_failure.dart`
- `v2/packages/plugin_contracts/test/identity/plugin_id_test.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- This task's report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-02-report.md`

Dart-generated `v2/pubspec.lock` and `v2/**/.dart_tool/**` may be created by verification and retained as recovery caches, but they must not be manually edited or described as authored implementation. No other file may be modified.

## Binding API and behavior

### `PluginId`

- Public API: `PluginId.parse(String)`, `PluginId.tryParse(String)`, and read-only `String value`.
- Validation regex is exactly `RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$')`.
- `parse` returns a value object for valid input and throws `FormatException` for invalid input.
- `tryParse` returns a value object for valid input and `null` for invalid input; it must not swallow unrelated errors.
- Instances compare by `value` and have matching `hashCode`; `toString()` must not expose any information beyond the validated ID.
- The object must not expose a public unchecked constructor.

Required cases:

```dart
expect(PluginId.parse('tools.calculator').value, 'tools.calculator');
expect(() => PluginId.parse('../escape'), throwsFormatException);
expect(() => PluginId.parse('Tools.Calculator'), throwsFormatException);
expect(() => PluginId.parse('single'), throwsFormatException);
expect(PluginId.tryParse('tools.clock'), isNotNull);
expect(PluginId.tryParse('bad/path'), isNull);
```

Also test value equality/hash consistency and at least the empty string plus malformed dotted segments (`tools.`, `tools..clock`). Every test name must state the production break it catches.

### `PluginFailure`

- Public constructor shape: `PluginFailure(String code, String message, [Map<String, Object?> details = const {}])`, or an equivalent named-argument form only if the tests clearly establish it.
- Public read-only fields: stable non-empty `code`, human-readable non-empty `message`, and `Map<String, Object?> details`.
- Validate `code` and `message` are non-empty after trimming; invalid values throw `ArgumentError` naming the field.
- Defensively copy `details` and expose an unmodifiable map, so later mutation of the input map cannot alter the failure and callers cannot mutate the exposed map.
- Do not add stack traces, timestamps, platform paths, exception swallowing, serialization or error taxonomies in this task.

Add focused tests for both defensive copy and exposed-map immutability in the same test file; these protect real public behavior.

### Exports and boundaries

- `plugin_contracts.dart` exports the two public source files.
- No Flutter, `dart:io`, `dart:ffi`, `win32`, platform package, business plugin or runtime dependency.
- Use concise Chinese Dart documentation comments for non-obvious public contracts; avoid comments that merely repeat names.

## Strict TDD sequence

Working directory: `v2/packages/plugin_contracts`.

1. Create the test file first, referencing the not-yet-existing exports/types.
2. Run `dart test test/identity/plugin_id_test.dart` and record RED: non-zero exit caused by missing public types/files, not a typo or environment failure.
3. Implement the minimum source and exports.
4. Run the same focused test and record GREEN: all tests pass.
5. Run `dart format --output=none --set-exit-if-changed .` and `dart analyze`; both exit 0 with pristine output.
6. Mentally mutation-check: relaxing the regex, removing value equality, retaining the input details map, or returning a mutable details map must each break a test.

If Dart commands hang inside the restricted sandbox, stop that command and retry the identical command outside the sandbox with the required approval. Record both attempts accurately.

## Process constraints

- Windows PowerShell only; use `apply_patch` for edits.
- No Git commands and no subagents.
- Do not edit progress.yaml or the SDD ledger; the controller owns them.
- Do not implement manifests, lifecycle, registry, resolver, Flutter, Sidecar or business code.
- If an API requirement is internally inconsistent, return NEEDS_CONTEXT instead of silently changing it.

## Report contract

Write `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-02-report.md` with implementation, exact RED/GREEN evidence, format/analyze results, authored files, self-review/mutation check, and concerns.

Return only: status, one-line test summary, concerns, and report path. There is no commit field because AI Git operations are forbidden.
