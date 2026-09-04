# Task F1-05 brief — atomic plugin registry and capability catalog

## Outcome

Implement an in-memory registry whose plugin registrations and derived capability catalog update atomically. Keep the runtime pure Dart and state-only; do not load plugins or call lifecycle code.

## Allowed authored files

- `v2/packages/plugin_runtime/lib/src/registry/plugin_registration.dart`
- `v2/packages/plugin_runtime/lib/src/registry/plugin_registry.dart`
- `v2/packages/plugin_runtime/lib/src/capability/capability_catalog.dart`
- `v2/packages/plugin_runtime/test/registry/plugin_registry_test.dart`
- `v2/packages/plugin_runtime/test/capability/capability_catalog_test.dart`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-05-report.md`

Generated lock/cache state is controller-owned. No other file may change.

## Binding API

### Registration

```dart
final class PluginRegistration {
  PluginRegistration(this.manifest);
  final PluginManifest manifest;
  PluginId get id;
}
```

No plugin instance, widget, callback, process, platform handle, or lifecycle object.

### Registry mutation result

Immutable `RegistryMutationResult` exposes `bool succeeded` and `PluginFailure? failure`; construction is internal/private. Success has null failure; rejection has non-null failure.

### Registry

- `PluginRegistry()` starts empty.
- Read-only `Map<PluginId, PluginRegistration> get registrations` returns an unmodifiable snapshot.
- `PluginRegistration? lookup(PluginId id)`.
- Read-only `CapabilityCatalog get capabilityCatalog`.
- `RegistryMutationResult register(PluginRegistration registration)`.
- `RegistryMutationResult unregister(PluginId id)`.
- Duplicate ID: reject with code `registry.duplicate_plugin`, details exactly `{ 'pluginId': id.value }`.
- Unknown unregister: reject with code `registry.plugin_not_found`, same details shape.
- Registration validates the full candidate registry and candidate catalog before assigning either. Any duplicate capability provider leaves registrations and catalog unchanged.
- Successful unregister removes the registration and all capabilities it owned in the same mutation.

### Catalog build/result

- `CapabilityCatalog.build(Iterable<PluginRegistration>)` returns immutable `CapabilityCatalogBuildResult` with `bool succeeded`, `CapabilityCatalog? catalog`, `PluginFailure? failure`.
- Build success has catalog/non-null and failure/null. Build failure has catalog/null and failure/non-null.
- Duplicate provider for the same capability ID fails with code `capability.duplicate_provider`; details exactly:

```dart
{
  'capabilityId': capabilityId,
  'existingProvider': existingPluginId.value,
  'conflictingProvider': conflictingPluginId.value,
}
```

- Preserve registration iteration order when deciding existing/conflicting provider; never keep a partial catalog.

### Capability resolution

`CapabilityCatalog.resolve(CapabilityRequirement requirement)` returns immutable `CapabilityResolution` with:

- `CapabilityRequirement requirement`
- `PluginId? providerId`
- `CapabilityDescriptor? descriptor`
- `PluginFailure? failure`
- `bool get available` exactly when failure is null.

Success returns the single provider and descriptor when provided version is at least required version.

Missing capability failure:

- code `capability.missing`
- details `{ 'capabilityId': id, 'requiredVersion': version }`

Insufficient version failure:

- code `capability.version_too_low`
- details `{ 'capabilityId': id, 'requiredVersion': required, 'providedVersion': provided, 'providerId': owner.value }`

Failure resolutions expose null provider/descriptor. Catalog/result fields and internal maps are immutable; no public mutation methods.

## Minimal test scenarios

Use parameterized/table-driven cases where shapes repeat. Keep only these main and critical exception paths:

### `plugin_registry_test.dart`

1. Register two non-conflicting manifests, query immutable registrations, and resolve their capabilities.
2. Parameterized mutation rejection: duplicate plugin ID and unknown unregister; assert stable code/details and unchanged state.
3. Provider conflict is atomic: failed second registration leaves only the first registration/provider.
4. Successful unregister removes both registration and owned capability.

### `capability_catalog_test.dart`

1. Build and resolve exact/higher provider version successfully.
2. Parameterized resolution failures: missing capability and insufficient version; assert result fields, code, details.
3. Duplicate provider build failure returns no partial catalog and exact provider-order details.

Use a compact manifest factory in test code only. Do not test every manifest field again. No mocks, source inspection, delays, I/O, Flutter, platform code, or duplicate standalone tests for values that fit one table.

## Execution gates

- Create both tests before the three production sources/new exports.
- From `v2/packages/plugin_runtime`, first run `dart test test/registry test/capability`; record the expected type/export failure.
- After implementation: run the same focused command, then runtime `dart test`.
- From `v2/packages/plugin_contracts`, run `dart test`.
- From `v2`, run workspace format check and analyze; both exit 0.
- Mutation check only critical invariants: partial state after conflict, stale capability after unregister, or version comparison direction.

If format differs, inspect with `--output=show` and edit through `apply_patch`; never write-mode format.

## Global output/test rules

- No TDD-process narration. Report command/evidence in compact tables.
- Main paths and critical exceptions only; no automatically expanded edge-case matrix.
- Prefer parameterized cases over repeated independent tests.
- No redundant comments.
- Iterations change only the necessary snippets; never rewrite whole existing files to make a small fix.

## Process constraints

- Chinese; Windows PowerShell; edits only through `apply_patch`.
- No Git and no subagents.
- Do not edit progress, ledger, brief, baseline, review artifacts, accepted contracts/lifecycle files, or other packages.
- No registry singleton, service locator, Flutter, `dart:io`, `dart:ffi`, win32, platform dependency, plugin execution, or F1-06 resolver.

## Report contract

Write `task-F1-05-report.md` with compact command/exit/result tables, authored files, mutation/scope check, and concerns. Do not explain TDD stages or repeat old code/tests.

Return only status, one-line verification summary, concerns, and report path.
