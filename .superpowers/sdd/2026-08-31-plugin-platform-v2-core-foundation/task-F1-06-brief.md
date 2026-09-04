# Task F1-06 brief — pure platform/capability resolver

## Outcome

Resolve accepted manifests for an explicit host target, explain unavailable plugins, and produce a deterministic provider-before-consumer activation order. The resolver is pure and reads no runtime registry state, platform globals, environment, or filesystem.

## Allowed authored files

- `v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart`
- `v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-06-report.md`

No other file may change.

## Binding API

```dart
abstract final class PluginResolver {
  static PluginResolutionResult resolve(
    Iterable<PluginManifest> manifests,
    PluginTarget target,
  );
}
```

Inputs come from the accepted registry contract: plugin IDs and provided capability IDs are unique. Do not add registry access or a second registration model.

### Per-plugin result

Immutable `PluginResolution` exposes:

- `PluginManifest manifest`
- `bool available`
- `List<PluginFailure> failures` (unmodifiable, input/requirement-stable order)

`available` is true exactly when failures is empty.

### Aggregate result

Immutable `PluginResolutionResult` exposes:

- `Map<PluginId, PluginResolution> plugins` in manifest input order
- `List<PluginId> available` in manifest input order
- `List<PluginId> activationOrder` with providers before consumers and stable input-order tie breaking
- `Map<PluginId, List<PluginFailure>> failures`, containing only unavailable plugins

All collections, including nested failure lists and any list stored in failure details, are unmodifiable snapshots.

## Resolution rules

1. Target support is checked from `manifest.targets` against the explicit `target` argument.
2. Only target-supported manifests may provide capabilities.
3. Exact or higher provider version satisfies a requirement.
4. A provider that has any resolution failure cannot satisfy consumers; propagate unavailability until stable.
5. Detect dependency cycles among otherwise valid candidates. Mark cycle members unavailable, then propagate provider unavailability to their consumers.
6. Build activation order only from final available plugins. Independent ready nodes use manifest input order.
7. Never mutate manifests or input collections.

## Stable failures

Unsupported target:

- code `resolution.unsupported_target`
- details `{ 'pluginId': id, 'target': target.name }`

Missing capability:

- code `resolution.missing_capability`
- details `{ 'pluginId': id, 'capabilityId': capabilityId, 'requiredVersion': version }`

Insufficient provider version:

- code `resolution.capability_version_too_low`
- details include `pluginId`, `capabilityId`, `requiredVersion`, `providedVersion`, `providerId`

Unavailable provider:

- code `resolution.provider_unavailable`
- details `{ 'pluginId': consumerId, 'capabilityId': capabilityId, 'providerId': providerId }`

Dependency cycle:

- code `resolution.dependency_cycle`
- details `{ 'pluginId': id, 'cyclePluginIds': <String>[...] }`; list is input-order stable and unmodifiable.

Messages are fixed, non-empty, and contain no paths, process arguments, environment values, timestamps, or exception text.

## Minimal test scenarios

Use one compact manifest factory. Keep exactly these main/critical scenario groups; table repeated failure shapes:

1. Explicit target filtering: supported independent plugins remain available in input order; unsupported plugin has exact structured failure.
2. Dependency chain plus independent plugin: activation order is provider → consumer → downstream, with stable input-order tie behavior.
3. Parameterized missing-capability and insufficient-version cases; assert per-plugin and aggregate failure views.
4. Provider unavailable on the target propagates `provider_unavailable` to its consumer.
5. Two-plugin cycle marks both cycle members unavailable with stable cycle IDs and no activation entries.

Also assert exposed aggregate/per-plugin collections reject mutation within these scenarios; do not create separate immutability edge-test matrices.

## Execution gates

- Create the test before production source/export.
- First focused run from `plugin_runtime` must fail only for missing resolver types/exports.
- After implementation run focused test, runtime full, contracts full, workspace format, workspace analyze.
- Critical mutation checks only: reverse dependency edge/order, skip provider-unavailable propagation, or omit cycle marking.

## Global output/test rules

- No TDD-process narration; compact evidence table only.
- Main/critical scenarios only; parameterize repeated shapes.
- No redundant comments.
- Iterations change snippets only; never rewrite complete old tests/implementation for a local fix.

## Constraints

- Chinese; PowerShell; edits only through `apply_patch`; no Git/subagents.
- Do not modify accepted files other than adding the required runtime export.
- No `Platform`, environment, filesystem, I/O, Flutter, FFI, win32, service locator, registry lookup, plugin execution, or F1-07/F1-08 work.

## Report

Write `task-F1-06-report.md` with compact verification/mutation/scope tables and concerns. Do not reproduce full code or narrate TDD stages.

Return only status, one-line verification summary, concerns, report path.
