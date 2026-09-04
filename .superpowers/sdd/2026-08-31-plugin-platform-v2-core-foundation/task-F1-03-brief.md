# Task F1-03 brief — strict manifest and capability contracts

## Outcome

Add immutable pure-Dart manifest, target, kind, capability descriptor/requirement, and strict JSON codec contracts to `plugin_contracts`. Tests must be written and observed failing before production implementation. Do not implement runtime registration, loading, lifecycle, Flutter, Sidecar process management, or business plugins.

## Allowed authored files

- `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart`
- `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`
- `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart`
- `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`
- `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md`

Dart-generated `v2/pubspec.lock` and `v2/**/.dart_tool/**` may be updated by verification and retained as controller-owned cache state; never manually edit or describe them as authored implementation. No other file may be modified.

## Binding public model

### Target and kind

- `PluginTarget` is an enum with exactly: `windows`, `macos`, `linux`, `android`, `ios`, `web`.
- Its JSON wire values are exactly the enum names above. Unknown or wrong-typed target values fail strict decoding with a `FormatException` whose message names `targets`.
- `PluginKind` is an enum with exactly `builtin` and `sidecar`; its JSON wire values are those names. Unknown or wrong-typed values fail with a `FormatException` naming `kind`.

### Capabilities

- Public immutable classes: `CapabilityDescriptor` and `CapabilityRequirement`.
- Each exposes read-only `String id` and `int version`.
- Capability IDs use exactly `RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$')`.
- Versions must be positive integers (`> 0`). Public constructors reject an invalid ID or version with `ArgumentError` naming `id` or `version`.
- No unchecked public constructor, mutable fields, platform types, serialization framework, global registry, or capability taxonomy.
- JSON representation for both descriptor and requirement is exactly `{ 'id': <string>, 'version': <positive int> }`; unknown or missing nested keys are rejected by the manifest codec with `FormatException` naming `provides` or `requires`.

### PluginManifest

- Public immutable `PluginManifest` with read-only fields:
  - `PluginId id`
  - `String name`
  - `String version`
  - `int apiVersion`
  - `PluginKind kind`
  - `List<PluginTarget> targets`
  - `String entrypoint`
  - `List<CapabilityDescriptor> provides`
  - `List<CapabilityRequirement> requires`
  - `List<String> surfaces`
  - `int configSchemaVersion`
  - `int dataSchemaVersion`
- Collection fields must be defensive unmodifiable snapshots preserving input order.
- `name`, `version`, and `entrypoint` are non-empty after trimming. Preserve valid original text; do not silently trim or normalize it.
- `apiVersion`, `configSchemaVersion`, and `dataSchemaVersion` are positive integers.
- `targets` must contain at least one value and contain no duplicates.
- `provides` contains no duplicate capability ID; `requires` contains no duplicate capability ID. A capability may appear once in each of the two different lists; this task does not forbid a plugin from both providing and requiring the same ID.
- `surfaces` may be empty, but every present surface is a non-empty string and duplicate surface strings are rejected.
- A `sidecar` manifest requires a non-empty `entrypoint` and at least one desktop target among `windows`, `macos`, or `linux`. Do not add executable-command fields or process behavior. A `builtin` entrypoint is the Dart symbol/name shown by the valid fixture; unknown top-level fields, including any invented command field, are rejected.
- Constructor validation may use `ArgumentError`; codec input failures must surface as `FormatException` with the relevant top-level field name in the message and must not echo full paths, environment variables, or process arguments.

## Binding codec API and strict JSON schema

- `PluginManifestCodec` exposes `PluginManifestCodec.decode(Map<String, Object?>)` and `PluginManifestCodec.encode(PluginManifest)`. Static methods are preferred so the plan's call shape works without an instance.
- The top-level accepted key set is exactly:

```text
id, name, version, apiVersion, kind, targets, entrypoint,
provides, requires, surfaces, configSchemaVersion, dataSchemaVersion
```

- All twelve keys are required. Reject the map before model construction if any key is missing or any unknown key is present.
- Require exact JSON-compatible runtime shapes: strings where specified; integer values for versions (not doubles or strings); lists for list fields; string list entries for targets/surfaces; map entries with string keys for capability lists.
- Decode all values strictly, then construct the immutable model. Convert any model validation error into `FormatException` naming the corresponding field.
- `encode` returns a new `Map<String, Object?>` using the exact twelve keys and JSON-compatible nested maps/lists. Mutating the encoded map or lists must not mutate the manifest.
- Decode followed by encode for the valid fixture below must equal the hand-written fixture by deep collection equality. Do not implement `dart:convert` text parsing; this codec starts from and returns maps.

## Required valid fixture

```dart
final json = <String, Object?>{
  'id': 'tools.calculator',
  'name': 'Calculator',
  'version': '1.0.0',
  'apiVersion': 1,
  'kind': 'builtin',
  'targets': <Object?>['windows', 'macos', 'linux', 'android', 'ios', 'web'],
  'entrypoint': 'CalculatorPlugin',
  'provides': <Object?>[
    <String, Object?>{'id': 'math.calculate', 'version': 1},
  ],
  'requires': <Object?>[],
  'surfaces': <Object?>['page'],
  'configSchemaVersion': 1,
  'dataSchemaVersion': 1,
};
```

## Required tests

Every test name states the production break it catches and exercises real code without mocks.

### `capability_descriptor_test.dart`

Cover both descriptor and requirement:

- valid ID/version are preserved;
- invalid IDs including uppercase, path syntax, single segment, empty, and malformed dotted segments are rejected;
- zero and negative versions are rejected;
- public fields are immutable by API shape (compile-time `final`; behavioral tests need not grep source).

### `plugin_manifest_codec_test.dart`

Cover at least:

- decode the valid fixture and assert every field using hand-written literals;
- encode the decoded manifest and deep-equal the valid fixture;
- unknown top-level field;
- one missing required field;
- invalid plugin ID;
- wrong type for a scalar and wrong type for a list member;
- unknown kind and target;
- empty and duplicate targets;
- non-positive `apiVersion`, `configSchemaVersion`, and `dataSchemaVersion` (table-driven is fine when expected field names are literal);
- malformed nested capability shape, invalid capability ID, non-positive capability version, duplicate `provides`, and duplicate `requires`;
- sidecar missing/blank entrypoint and sidecar with no desktop target;
- blank name/version, blank/duplicate surfaces;
- input collection mutation after construction cannot change a manifest, exposed collections reject mutation, and mutating encoded output cannot change the manifest.

Assertions for failures must verify `FormatException` and that its message names the relevant top-level field; do not freeze complete human wording.

## Strict TDD and verification sequence

Working directory: `v2/packages/plugin_contracts`.

1. Create both test files before any F1-03 production source or new exports.
2. Run `dart test test/manifest test/capability` and record RED: non-zero caused by missing F1-03 public types/files, not syntax, dependency, or environment failure.
3. Implement the minimum production contracts and exports.
4. Run `dart test test/manifest test/capability` and record focused GREEN.
5. Run full package `dart test` so F1-02 remains green.
6. Run `dart format --output=none --set-exit-if-changed .` and `dart analyze`; both must exit 0 with pristine output.
7. Mutation-check unknown-field rejection, each positive-version guard, target non-emptiness, duplicate capabilities, sidecar desktop targeting, defensive collection copies, and encode isolation; each realistic mutation must be caught by a named test.

If formatter reports changes, use `dart format --output=show <path>` only to inspect and apply the equivalent edit with `apply_patch`; do not use a write-mode formatter.

## Process constraints

- Use Chinese for coordination/reporting and concise Chinese Dart doc comments where public behavior is non-obvious.
- Windows PowerShell only; all edits use `apply_patch`.
- No Git commands and no subagents.
- Do not edit progress YAML, SDD ledger, brief, baseline, or any review artifact; the controller owns them.
- Do not implement F1-04 or later work. If a binding requirement is internally inconsistent, return `NEEDS_CONTEXT` rather than silently changing it.

## Report contract

Write `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md` containing implementation, exact RED/GREEN/full-test/format/analyze evidence, authored files, self-review, mutation check, scope check, and concerns.

Return only: status, one-line verification summary, concerns, and report path. There is no commit field because AI Git operations are forbidden.
