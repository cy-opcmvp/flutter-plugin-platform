# Task F1-07 brief — deterministic plugin devkit fixtures

## Outcome

Add a deterministic `PluginLifecycle` fake and a public `PluginFailure` code matcher for package consumers' tests. No real delays, processes, I/O, platform APIs, or runtime mutation.

## Allowed files

- `v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart`
- `v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart`
- `v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart`
- `v2/packages/plugin_devkit/lib/plugin_devkit.dart`
- `v2/packages/plugin_devkit/pubspec.yaml`
- Report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-07-report.md`

Generated lock/cache state may change through pub resolution and is controller-owned.

## Dependency ruling

Add `matcher: ^0.12.20` as a direct normal dependency of `plugin_devkit`. The public matcher under `lib/` must import `package:matcher/matcher.dart`, never `package:test` and never a transitive-only package.

## Binding fake API

```dart
enum FakePluginOperation { activate, deactivate, dispose }

final class FakePlugin implements PluginLifecycle {
  FakePlugin({
    Map<FakePluginOperation, PluginFailure> failures = const {},
  });

  int get activateCalls;
  int get deactivateCalls;
  int get disposeCalls;
  Future<void> activate();
  Future<void> deactivate();
  Future<void> dispose();
}
```

- Defensively copy failures into an unmodifiable snapshot.
- Each method increments its own count exactly once per attempt.
- If configured for that operation, throw the exact configured `PluginFailure` object after incrementing.
- No delay, timer, process, callback, lifecycle machine, registry/catalog mutation, or extra public controls/reset methods.

## Binding matcher API

```dart
Matcher hasPluginFailureCode(String code)
```

- Reject blank expected code with `ArgumentError` naming `code`.
- Match only `PluginFailure` whose `code` equals the expected code; ignore message/details.
- Mismatch description must distinguish wrong type from wrong failure code and include the actual code for the latter.
- Keep matcher implementation private; export only the factory function.

## Minimal tests

One test file, four groups/functions maximum; parameterize operation shapes:

1. Parameterized success operations: call each operation, assert only its counter increments.
2. Parameterized injected failures: exact failure object is thrown and attempted operation count becomes one.
3. Matcher table: matching code succeeds; wrong code and wrong type fail.
4. Matcher validation/mismatch description: blank expected code rejected; wrong-code description includes actual code.

No extra edge matrix, mocks, delays, source inspection, or duplicated standalone operation tests.

## Gates

- Create test before source/export/dependency change; first focused run fails only for missing devkit types/export.
- Add dependency, run `dart pub get --offline` from `v2`.
- Run devkit focused/full, runtime full, contracts full, workspace format, workspace analyze.
- Critical mutation checks only: skip attempt counter before throw; matcher compares message instead of code.

## Global rules

- No TDD-process narration; compact evidence tables.
- Main/critical cases only; parameterize repeated operations.
- No redundant comments.
- Local iteration changes snippets only; no full-file rewrite for a small fix.

## Constraints

- Chinese, PowerShell, apply_patch only; no Git/subagents.
- Do not modify accepted contracts/runtime source, other tests, progress, ledger, brief, baseline, or review files.
- No Flutter, I/O, FFI, win32, actual plugin behavior, business plugins, service locator, or hidden global state.

## Report

Write `task-F1-07-report.md` with compact command/mutation/scope tables and concerns; no full code or process narration.

Return only status, one-line verification summary, concerns, report path.
