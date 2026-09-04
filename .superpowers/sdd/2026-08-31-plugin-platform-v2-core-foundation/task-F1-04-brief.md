# Task F1-04 brief — lifecycle contract and deterministic transition machine

## Outcome

Define the pure-Dart plugin lifecycle interface/state enum in `plugin_contracts`, and implement a deterministic state-only transition machine in `plugin_runtime`. Illegal transitions return an immutable structured result containing `PluginFailure`; they never throw and never mutate state. The machine must not invoke plugin code.

## Allowed authored files

- `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart`
- `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart`
- `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-04-report.md`

Dart-generated lock/cache state may be updated by verification and retained as controller-owned state, but must not be manually edited or described as authored implementation. No other file may be modified.

## Binding contracts

### `plugin_contracts`

- Public enum `PluginLifecycleState` contains exactly, in lifecycle vocabulary: `discovered`, `resolved`, `inactive`, `activating`, `active`, `deactivating`, `failed`, `disposed`.
- Public interface is exactly:

```dart
abstract interface class PluginLifecycle {
  Future<void> activate();
  Future<void> deactivate();
  Future<void> dispose();
}
```

- Do not add identity, state getters, callbacks, context parameters, error methods, install state, streams, Flutter types, or platform types to this interface.
- Export the lifecycle source from `plugin_contracts.dart` without removing accepted F1-02/F1-03 exports.

### `LifecycleMachine`

- Public immutable identity field: `PluginId pluginId`.
- Construct with a validated `PluginId`; initial state is always `PluginLifecycleState.discovered`. Do not expose a public arbitrary-initial-state shortcut.
- Public read-only current state: `PluginLifecycleState state`.
- Public synchronous method: `LifecycleTransitionResult transitionTo(PluginLifecycleState requestedState)`.
- It validates and records state only. It never receives, stores, invokes, activates, deactivates, or disposes a `PluginLifecycle` object.
- Export the machine/result from `plugin_runtime.dart`.

### `LifecycleTransitionResult`

- Public immutable result with read-only fields:
  - `PluginLifecycleState previousState`
  - `PluginLifecycleState requestedState`
  - `PluginLifecycleState state` (the machine's post-attempt state)
  - `PluginFailure? failure`
- Public `bool get succeeded` is true exactly when `failure == null`.
- Success: `state == requestedState`, machine state advances, `failure == null`.
- Rejection: `state == previousState`, machine state remains unchanged, `failure` is non-null, `succeeded == false`.
- Construction helpers may be private/internal; do not expose an unchecked result constructor unless necessary for the public contract.

## Binding transition table

Normal edges:

```text
discovered -> resolved
resolved -> inactive
inactive -> activating
activating -> active
active -> deactivating
deactivating -> inactive
inactive -> disposed
failed -> disposed
```

Failure-state edges represent a lifecycle operation failing and are allowed from every non-terminal state except `discovered`:

```text
resolved -> failed
inactive -> failed
activating -> failed
active -> failed
deactivating -> failed
```

`disposed` is terminal. No same-state transition is allowed. No other edge is allowed. In particular `discovered -> active`, `discovered -> failed`, `resolved -> active`, `active -> inactive`, and every `disposed -> *` attempt are rejected.

## Binding illegal-transition failure

- Stable failure code: `lifecycle.invalid_transition`.
- Non-empty human-readable message; do not include filesystem paths, process arguments, environment values, stack traces, timestamps, or exception text.
- Unmodifiable details must be exactly the public diagnostic facts:

```dart
<String, Object?>{
  'pluginId': pluginId.value,
  'from': previousState.name,
  'to': requestedState.name,
}
```

- An illegal attempt never throws and never changes machine state. Repeated illegal attempts return independent result/failure values and leave state unchanged.

## Required test-first coverage

Create `lifecycle_machine_test.dart` before production sources/exports. Every test name states the production break it catches and uses real code without mocks.

Cover at least:

1. Initial state is `discovered` for the provided PluginId.
2. Full activation chain: `discovered -> resolved -> inactive -> activating -> active`; assert every result field and final state.
3. Deactivation/reactivation chain: `active -> deactivating -> inactive -> activating -> active`.
4. Failure/disposal paths: at minimum `activating -> failed -> disposed`, plus table-driven checks proving `resolved`, `inactive`, `active`, and `deactivating` may each enter `failed`.
5. Direct `inactive -> disposed`.
6. Reject `discovered -> active` with exact stable code/details and no state mutation.
7. Reject `discovered -> failed`, `active -> inactive`, and same-state attempts.
8. Once disposed, attempts to every lifecycle enum value are rejected and state remains disposed.
9. Failure result semantics: previous/requested/post state, `succeeded == false`, non-null failure; success has `succeeded == true` and null failure.
10. Repeated illegal transitions produce separate result and `PluginFailure` instances while preserving state.
11. A private test fixture implementing `PluginLifecycle` compiles with exactly the three async methods; prove `LifecycleMachine` transitions do not increment its method counters or otherwise invoke it.

For success-chain assertions, expected states/codes/details must be hand-written literals/enums, not computed from the production transition table. No source grep, mocks, clock, delays, I/O, Flutter, or platform APIs.

## Strict TDD and verification sequence

1. Before creating any F1-04 production source or new export, create only `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`.
2. From `v2/packages/plugin_runtime`, run `dart test test/lifecycle/lifecycle_machine_test.dart` and record RED: non-zero caused by missing lifecycle public types/exports, not syntax/dependency/environment failure.
3. Implement the minimum contracts, machine, result, and exports.
4. From `plugin_runtime`, run the focused lifecycle test and then full `dart test`; both must pass.
5. From `plugin_contracts`, run full `dart test`; accepted 48 tests must pass.
6. From `v2`, run `dart format --output=none --set-exit-if-changed .` and `dart analyze`; both must exit 0 with pristine output.
7. Mutation-check at least: remove one allowed edge, add a forbidden edge, mutate state before validation, allow disposed transition, throw instead of return failure, wrong failure detail, or invoke plugin callbacks. Each must be caught by a named test.

If formatter reports changes, use `dart format --output=show <path>` only to inspect and apply equivalent changes with `apply_patch`; never use write-mode formatter.

## Process constraints

- Use Chinese for coordination/reporting and concise Chinese Dart doc comments only where public behavior is non-obvious.
- Windows PowerShell; all edits use `apply_patch`.
- No Git commands and no subagents.
- Do not edit progress YAML, SDD ledger, brief, baseline, or review artifacts.
- Do not implement install lifecycle, registry, capability catalog, resolver, Flutter, Sidecar, platform loading, or business plugins.
- No dependency beyond accepted `plugin_contracts`; no `dart:io`, `dart:ffi`, Flutter, win32, platform package, service locator, or global mutable state.
- If a binding requirement is internally inconsistent, return `NEEDS_CONTEXT` rather than silently changing it.

## Report contract

Write `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-04-report.md` containing implementation, exact RED/GREEN/full regression/format/analyze evidence, authored files, self-review, mutation and scope checks, and concerns.

Return only: status, one-line verification summary, concerns, and report path. AI Git operations are forbidden, so there is no commit field.
