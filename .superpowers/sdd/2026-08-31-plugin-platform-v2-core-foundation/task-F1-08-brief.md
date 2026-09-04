# Task F1-08 brief — M1 boundary docs and integration evidence

## Outcome

Document the accepted core packages and collect reproducible M1 verification evidence. Do not change production code, tests, package manifests, lockfiles manually, or acceptance status.

## Implementer-owned files

- `v2/README.md`
- `v2/packages/plugin_contracts/README.md`
- `v2/packages/plugin_runtime/README.md`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-08-report.md`

Reserved for the independent G1 reviewer, not the implementer:

- `docs/superpowers/acceptance/v2-core-foundation-acceptance.md`

## Required documentation

Keep docs concise and consistent with current accepted public APIs.

### `v2/README.md`

- M1 scope and package responsibilities: contracts, runtime, devkit.
- Dependency direction: `plugin_contracts <- plugin_runtime <- plugin_devkit`; runtime never depends on devkit.
- Explicit target is supplied by the host to `PluginResolver`; core never reads platform globals.
- Plugins depend on capability contracts, not other plugin implementations.
- Builtin/Sidecar manifests share contracts, but M1 contains no Flutter host, platform adapter, Sidecar installer/process/RPC, CLI, or business plugin.
- Six-target vocabulary exists in pure Dart contracts; Windows-first end-to-end work begins in later milestones.
- Minimal commands for workspace list, three package tests, format, analyze.

### Contracts README

- Public responsibilities: identity/failure, manifest codec, target/kind, capability descriptor/requirement, lifecycle interface/state.
- Strict validation, immutable snapshots, unknown-field rejection, safe diagnostics.
- No runtime registry/resolution behavior and no platform/Flutter dependencies.

### Runtime README

- State-only lifecycle machine, atomic registry/catalog, pure resolver.
- Resolver target passed explicitly; provider-before-consumer order and structured unavailability.
- Runtime does not invoke plugin lifecycle objects, load code/processes, access filesystem/environment, or depend on devkit.
- Point testing consumers to `plugin_devkit` without adding a runtime dependency.

Do not paste large API listings or duplicate the design spec.

## Verification evidence

Run from `v2` unless a package directory is specified:

1. `dart pub get --offline`
2. `dart pub workspace list`
3. `dart test` in `packages/plugin_contracts`
4. `dart test` in `packages/plugin_runtime`
5. `dart test` in `packages/plugin_devkit`
6. `dart format --output=none --set-exit-if-changed .`
7. `dart analyze`
8. `dart pub deps --style=compact`
9. Focused forbidden-boundary scan for Flutter, `dart:io`, `dart:ffi`, win32, and platform globals in M1 package lib sources.

Record exact exit codes and concise results. Expected current test totals are contracts 48, runtime 26, devkit 8; report actual results without forcing counts.

## Global output rules

- Compact tables; no TDD-process narration.
- No full source/test reproduction.
- No redundant comments or duplicated prose.
- Local edits only; do not rewrite accepted artifacts.

## Constraints

- Chinese, PowerShell, apply_patch only; no Git/subagents.
- Do not modify source, tests, pubspecs, accepted task reports/reviews, progress, ledger, brief, baseline, or the reserved acceptance report.
- Do not fix the historical F1-07 report count; note that controller fresh evidence is 48/48 and the minor is deferred to G1 triage.

## Report

Write `task-F1-08-report.md` with docs summary, compact command/result table, dependency/boundary evidence, authored files, and concerns.

Return only status, one-line verification summary, concerns, report path.
