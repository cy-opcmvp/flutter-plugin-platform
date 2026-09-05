# plugin_devkit

`plugin_devkit` 是插件作者的测试工具包：提供可复用的测试替身、失败断言 matcher 与 surface 契约自检入口。仅用于测试，不进入宿主生产依赖。

- `FakePlugin`：实现 `Plugin` 契约的测试替身，可注入各生命周期阶段的成功/失败行为。
- `failureCode(String code)`：断言 `PluginFailure.code` 的 matcher，错误码或类型不符时给出差异描述。
- `SurfaceContractChecks`（UI surface 契约自检，失败抛 `StateError`）：
  - `checkPageProviderBuilds(context, provider)`：`buildPage` 不抛异常且返回 Widget。
  - `checkSettingsProviderBuilds(context, provider)`：`buildSettings` 不抛异常且返回 Widget。
  - `checkManifestSurfaceDeclared(manifest, page:/settings:/actions:)`：清单 `surfaces` 声明与实现族双向一致（`page` / `settings` / `actions`）。
  - `checkActionsNonEmpty(provider, context)`：动作列表非空。

依赖 `plugin_contracts`、`plugin_flutter`（surface 契约）与 `plugin_runtime`；因 surface 检查需要 `BuildContext`，本包依赖 Flutter，测试统一用 `flutter test` 运行。

## 用法

```dart
testWidgets('插件 surface 契约自检', (tester) async {
  // pump 后捕获 BuildContext …
  SurfaceContractChecks.checkPageProviderBuilds(context, myPageProvider);
  SurfaceContractChecks.checkManifestSurfaceDeclared(
    myManifest,
    page: true,
    settings: true,
    actions: false,
  );
});
```

## 测试

```bash
flutter test
```
