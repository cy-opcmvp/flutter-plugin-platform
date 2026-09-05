# plugin_flutter

`plugin_flutter` 提供插件 UI Surface 契约层（规格 §9）：插件以数据与接口声明界面，宿主负责实际渲染。

- **Surface 提供者接口族**（`src/surface/plugin_ui_surface.dart`）：
  - `PluginPageProvider`：主页面（`pluginId` + `buildPage`）。
  - `PluginSettingsProvider`：设置界面（`buildSettings`）。
  - `PluginActionProvider`：菜单/工具栏动作（`actions` → `List<PluginAction>`）。
  - `PluginAction`：`id` / `label` / `onTriggered(BuildContext)`。
  - `surfaceUnsupported(String surface, PluginId id)` → `PluginFailure('surface.unsupported', details: {surface, pluginId})`。
- **声明式表单**（`src/surface/declarative_form.dart`）：
  - `FormDescriptor`：标题 + 字段列表，字段 key 唯一。
  - `FormFieldSpec` 封闭类型族：`TextFieldSpec` / `NumberFieldSpec` / `SelectFieldSpec` / `CheckboxFieldSpec` / `ToggleGroupSpec`，均含 `key` / `label` / `isRequired` / 默认值。
  - `toJson()` / `fromJson()` 往返；未知 kind 或缺必填 JSON 键抛 `FormatException`，构造非法（空白、空 options、重复 key）抛 `ArgumentError`。
- **声明式结果**（`src/surface/declarative_result.dart`）：
  - `ResultDescriptor` 封闭类型族：`text` / `table` / `image(path)` / `fields`，配套 `ResultField`。
  - `toJson()` / `fromJson()` 往返；未知 kind 抛 `FormatException`。

依赖方向为 `plugin_contracts <- plugin_flutter`。本包依赖 Flutter（widgets）但不 import 任何平台专属包（`dart:ffi`、win32、窗口管理插件等），可在宿主任意 UI 位置组合。国际化（l10n）由后续任务接入。

## 与清单的关系

插件清单（`PluginManifest.surfaces`）声明插件支持的 surface 字面量（`page` / `settings` / `actions`）。宿主渲染前先核对声明，未声明即以 `surfaceUnsupported` 拒绝；devkit 的 `SurfaceContractChecks.checkManifestSurfaceDeclared` 可自动校验声明与实现族一致。

## 测试

```bash
flutter test
```
