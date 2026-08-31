# SDD ledger — plan: docs/superpowers/plans/2026-08-31-plugin-platform-v2-core-foundation.md

## Execution rules

- Persistent Goal is active for the full v2 implementation.
- At most one subagent may run at a time; nested delegation is forbidden.
- Implementation and review use different agents.
- The AI performs no Git operations. Review packages use filesystem baselines and complete task snapshots instead of Git diffs.
- New work is isolated under `v2/`; the legacy project stays untouched until M5 and a fresh user confirmation.
- F1-01 is configuration-only scaffolding. Its TDD exception is command-driven schema validation (`dart pub get`, `dart pub workspace list`, `dart analyze`) because there is no production behavior to test yet.

## Preflight scan

| Task | Interfaces/files consumed | Interfaces/files produced | Potential conflict | Ruling |
|---|---|---|---|---|
| F1-01 | Dart SDK `^3.10.0` | Workspace plus three package shells | Later tasks modify shell exports/pubspecs | Create only the exact planned skeleton; empty export libraries are valid until later tasks populate them. |
| F1-02 | F1-01 contracts package | `PluginId`, `PluginFailure` | Error details mutability could leak state | Copy details into an unmodifiable map at construction. |
| F1-03 | `PluginId`, `PluginFailure` | Manifest, target and capability contracts | Manifest fields are public and feed F1-05/F1-06 | The specification and tests are the source of truth; unknown fields are rejected. |
| F1-04 | `PluginId`, `PluginFailure` | Lifecycle interface and state machine | Plan says illegal transitions return a failure result but does not name the result type | Introduce a small immutable `LifecycleTransitionResult` with success/failure factories; never use nullable failure or exceptions for an illegal transition. |
| F1-05 | Manifest and capability contracts | Registry and capability catalog | Registration and capability publication share state | Validate the complete candidate state before mutating either structure; failure leaves both unchanged. |
| F1-06 | Manifest, target and capability requirements | Pure platform/capability resolver | Dependency order and capability graph can be conflated | Resolver receives all manifests and an explicit target, builds a deterministic graph, and returns per-plugin structured failures plus stable topological order. |
| F1-07 | Contracts/runtime | Test-only fakes and matcher | Test utility could leak into runtime | `plugin_devkit` may depend on runtime; runtime must never depend on devkit. |
| F1-08 | F1-01..F1-07 | README and G1 evidence | Implementer could self-accept | Documentation/verification agent prepares evidence; a fresh Sol xhigh agent issues the read-only G1 verdict. |

## Shared interface pairs

| Producer | Consumer | Contract checkpoint |
|---|---|---|
| F1-02 `PluginId`/`PluginFailure` | F1-03..F1-07 | Value equality, strict validation and stable error codes are frozen after task review. |
| F1-03 manifest/capability model | F1-05/F1-06 | Serialization and version semantics are frozen after task review. |
| F1-04 lifecycle contract | F1-07 fake plugin | Async lifecycle methods and transition result must agree before F1-07 starts. |
| F1-05 capability catalog | F1-06 resolver | Resolver may consume descriptors/requirements but must not read mutable registry internals. |

## Task ledger

| Task | Status | Implementer | Reviewer | Report | Review |
|---|---|---|---|---|---|
| F1-01 | accepted | `/root/f1_01_workspace` (Sol xhigh) | `/root/f1_01_review` (Sol xhigh): Approved | `task-F1-01-report.md` | `task-F1-01-review.md` |
| F1-02 | paused_red_verified | `/root/f1_02_identity` interrupted after RED | pending | not created | `task-F1-02-review.md` |
| F1-03 | pending | — | — | — | — |
| F1-04 | pending | — | — | — | — |
| F1-05 | pending | — | — | — | — |
| F1-06 | pending | — | — | — | — |
| F1-07 | pending | — | — | — | — |
| F1-08 | pending | — | — | — | — |

## Decisions and anomalies

- 2026-08-31: The user explicitly requested Goal execution and start.
- 2026-08-31: Git worktrees are not used because the user's global rule forbids AI Git operations. Directory-level isolation under `v2/` is the approved substitute.
- 2026-08-31: `dart` resolves to `E:\Develop\flutter_app\flutter_windows_3.38.1-stable\flutter\bin\dart.bat`.
- 2026-08-31: F1-01 controller verification passed with `dart pub get --offline`, `dart pub workspace list`, and `dart analyze`; all exit codes were 0. Verification-generated lock and `.dart_tool` artifacts were removed after exact path checks.
- 2026-08-31: F1-01 independent review returned Approved with no findings.
- 2026-08-31: From F1-02 onward, Dart-generated `.dart_tool` state and `v2/pubspec.lock` may remain as controller-owned verification/recovery artifacts during M1 to avoid repeated dependency downloads. They are outside each task's authored file scope and will receive an explicit retention decision at F1-08.
- 2026-08-31: User requested an immediate pause. `/root/f1_02_identity` was interrupted. The only F1-02 authored file is `test/identity/plugin_id_test.dart`; the controller independently confirmed RED (exit 1) because `PluginId` and `PluginFailure` do not exist. No F1-02 production file or report exists. Resume at GREEN implementation without rewriting the test or repeating dependency resolution.
