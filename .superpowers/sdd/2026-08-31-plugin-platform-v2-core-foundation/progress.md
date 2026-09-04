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
| F1-02 | accepted | `/root/f1_02_green_impl` (Sol xhigh) | `/root/f1_02_review` (Sol xhigh): Approved after fix 1 | `task-F1-02-report.md` | `task-F1-02-review.md`, `task-F1-02-re-review-1.md` |
| F1-03 | accepted | `/root/f1_03_manifest_impl` (Sol xhigh) | `/root/f1_03_review` (Sol xhigh): Approved after fix 2 | `task-F1-03-report.md` | `task-F1-03-review.md`, `task-F1-03-re-review-1.md`, `task-F1-03-re-review-2.md` |
| F1-04 | accepted | `/root/f1_04_lifecycle_impl` (Sol xhigh) | `/root/f1_04_review` (Sol xhigh): Approved after fix 1 | `task-F1-04-report.md` | `task-F1-04-review.md`, `task-F1-04-re-review-1.md` |
| F1-05 | accepted | `/root/f1_05_registry_impl` (Sol high) | `/root/f1_05_review` (Sol xhigh): Approved | `task-F1-05-report.md` | `task-F1-05-review.md` |
| F1-06 | accepted | `/root/f1_06_resolver_impl` (Sol high) | `/root/f1_06_review` (Sol xhigh): Approved | `task-F1-06-report.md` | `task-F1-06-review.md` |
| F1-07 | accepted | `/root/f1_07_devkit_impl` (Luna high) | `/root/f1_07_review` (Sol high): Approved | `task-F1-07-report.md` | `task-F1-07-review.md` |
| F1-08 | accepted | `/root/f1_08_docs_impl` (Luna high) | `/root/g1_core_acceptance` (Sol xhigh): Approved | `task-F1-08-report.md` | `docs/superpowers/acceptance/v2-core-foundation-acceptance.md` |

## Decisions and anomalies

- 2026-08-31: The user explicitly requested Goal execution and start.
- 2026-08-31: Git worktrees are not used because the user's global rule forbids AI Git operations. Directory-level isolation under `v2/` is the approved substitute.
- 2026-08-31: `dart` resolves to `E:\Develop\flutter_app\flutter_windows_3.38.1-stable\flutter\bin\dart.bat`.
- 2026-08-31: F1-01 controller verification passed with `dart pub get --offline`, `dart pub workspace list`, and `dart analyze`; all exit codes were 0. Verification-generated lock and `.dart_tool` artifacts were removed after exact path checks.
- 2026-08-31: F1-01 independent review returned Approved with no findings.
- 2026-08-31: From F1-02 onward, Dart-generated `.dart_tool` state and `v2/pubspec.lock` may remain as controller-owned verification/recovery artifacts during M1 to avoid repeated dependency downloads. They are outside each task's authored file scope and will receive an explicit retention decision at F1-08.
- 2026-08-31: User requested an immediate pause. `/root/f1_02_identity` was interrupted. The only F1-02 authored file is `test/identity/plugin_id_test.dart`; the controller independently confirmed RED (exit 1) because `PluginId` and `PluginFailure` do not exist. No F1-02 production file or report exists. Resume at GREEN implementation without rewriting the test or repeating dependency resolution.
- 2026-08-31: Resume audit on the second computer confirmed the test's LF-normalized SHA-256 is still `1BC3F1840D71FAFD8EB3A99FB7869469E050ED59F876CF19B649F3E9F16E3B44`; its raw hash and the lockfile raw hash differ only because this checkout uses CRLF. Both production files remain absent, the export remains zero bytes, and the report remains absent.
- Ruling: Continue in the current checkout without Git worktree commands — the project-level prohibition on AI Git operations overrides the generic isolation workflow, while all new implementation remains directory-isolated under `v2/` — if wrong, the cost is losing Git-level isolation for M1 edits, but no legacy files are in task scope.
- 2026-08-31: F1-02 controller verification after implementation: focused test 15/15 exit 0; `dart analyze` exit 0; production `lib` format check exit 0. The full-package format check exits 1 only because the preserved RED test needs Dart 3.10.7 formatter reflow. The conflict is included unclassified in the independent review package.
- 2026-08-31: F1-02 task review found no Critical or Minor issues and one Important issue: the required full-package format gate exits 1, so task quality is Needs fixes.
- Ruling: The resume instruction not to rewrite the test prohibits replacing its behavior or repeating RED, but permits formatter-equivalent reflow by the original implementer — the task brief independently requires the full-package format gate to exit 0, and pure formatting preserves all 15 assertions — if wrong, the cost is losing byte-for-byte continuity with the paused test hash while retaining behavior and TDD evidence.
- Task F1-02: fix round 1/5 (1 addressed, 0 open — full-package format gate; filesystem delta only, no Git commits by policy).
- Task F1-02: complete (filesystem baseline-to-head review, review clean after fix round 1; suggested commit `feat(core): add validated plugin identity`).
- 2026-08-31: F1-03 controller verification after implementation: focused manifest/capability tests 31/31 exit 0; full package tests 46/46 exit 0; full format gate exit 0; analyze exit 0; forbidden dependency scan found zero matches. The RED process emitted its complete expected failure before the login shell required termination; no-profile GREEN verification exited normally.
- 2026-08-31: F1-03 task review found no Critical or Minor issues and one Important issue: an attacker-controlled unknown top-level key is interpolated verbatim into `FormatException`, violating the diagnostic redaction boundary and lacking a regression test.
- Task F1-03: fix round 1/5 (0 addressed, 1 open — generic safe-shape regex still echoes alphanumeric secrets; filesystem delta only, no Git commits by policy).
- Task F1-03: fix round 2/5 (1 addressed, 0 open — closed diagnostic allowlist; filesystem delta only, no Git commits by policy).
- Task F1-03: complete (filesystem baseline-to-head review, review clean after fix round 2; suggested commit `feat(core): define strict plugin manifest contract`).
- 2026-08-31: F1-04 implementation reached focused/runtime 15/15, contracts 48/48 and analyze clean, but requested context because workspace format also selected the pre-existing zero-byte `plugin_devkit.dart`, which belongs to F1-07 and was outside F1-04 authored scope.
- Ruling: Permit the original F1-04 implementer to apply only Dart formatter's blank LF output to the zero-byte `plugin_devkit.dart` as cross-task baseline maintenance — this is required for the plan-mandated workspace format gate and adds no declaration or F1-07 behavior — if wrong, the cost is touching an accepted F1-01/F1-07-owned stub one task early, though its Dart semantics remain empty.
- 2026-08-31: F1-04 task review found one Important test-quality issue (a detached lifecycle fixture's zero counters cannot detect machine callback coupling) and one Minor issue (an `isA` assertion adds no information beyond compilation). Production code and the remaining transition tests were accepted as correct.
- Ruling: Remove both tautological tests and the detached fixture; enforce the state-only/no-plugin boundary through independent structural review of the machine API and fields — a causal runtime test would require passing or storing a plugin, which the binding design explicitly forbids — if wrong, the cost is no automated unit-test failure for a future optional plugin/callback parameter, so subsequent task and final reviewers must continue checking this boundary explicitly.
- Task F1-04: fix round 1/5 (2 addressed, 0 open — removed tautological callback/API tests under controller ruling; filesystem delta only, no Git commits by policy).
- Task F1-04: complete (filesystem baseline-to-head review, review clean after fix round 1; suggested commit `feat(runtime): add deterministic plugin lifecycle`).
- 2026-08-31: The user added global TDD output rules in `C:\Users\Administrator\.codex\AGENTS.md`: no TDD-process narration, main/critical scenarios only, parameterize repeated cases, minimal comments, change snippets only during iteration, and minimal necessary test output unless a full suite is explicitly requested. New task briefs and dispatches must follow them.
- Task F1-05: complete (filesystem baseline-to-head review, review clean; suggested commit `feat(runtime): add plugin registry and capability catalog`).
- Task F1-06: complete (filesystem baseline-to-head review, review clean; suggested commit `feat(runtime): resolve plugins by platform and capability`).
- Ruling: F1-07 may add `matcher: ^0.12.20` as a direct production dependency of the testing-only `plugin_devkit` package and include its pubspec in task scope — the planned public matcher lives under `lib/` and must not rely on a transitive or dev-only `test` dependency — if wrong, the cost is one small direct dependency in devkit, while runtime and contracts remain unaffected.
- Task F1-07: minor (deferred): `task-F1-07-report.md` says contracts 49/49; fresh controller evidence and accepted baseline are 48/48. Final review must triage this report-only discrepancy.
- Task F1-07: complete (filesystem baseline-to-head review, Approved with one deferred report-count minor; suggested commit `test(core): add deterministic plugin devkit`).
- Task F1-08: complete (3 boundary READMEs, full integration evidence, G1 Approved; suggested commit `feat(core): complete plugin platform v2 core foundation`).
- Milestone M1 / Gate G1: accepted (Critical 0, Important 0, Minor 1 report-count typo triaged as non-blocking). Proceed to freeze the M2 detailed plan; no legacy code was deleted.
