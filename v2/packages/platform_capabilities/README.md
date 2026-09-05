# platform_capabilities

平台能力接口包：提供端中立的宿主能力契约与统一的"不支持"默认实现，供各端 stub 包与参考宿主复用（规格 §10 平台策略）。

- `ScreenCapture` / `captureRegion(Rect)`：区域截图。不支持的平台返回 `CaptureResult.failure(PluginFailure('capability.unsupported', …))` 结构化失败值而非抛异常。
- `SystemPaths` / `hostDataRoot()` + `pluginDataDir(PluginId)`：宿主数据根目录与按插件隔离的数据目录，纯路径解析、不建目录、不依赖 `dart:io`（因此 Web 可共享同一接口）。
- 默认实现：`UnsupportedScreenCapture(platform)` / `UnsupportedSystemPaths(platform)`，一律携带 `capability='screenCapture'|'systemPaths'` 与平台标签的 `capability.unsupported` 失败。
- 参考实现：`ResolvedSystemPaths`（按 `<root>/<pluginId>` 拼接，`PluginId` 反向域格式保证无路径穿越）。
- 值类型：`Rect`（虚拟屏幕坐标矩形，宽高非负）、`CaptureResult`（success/failure）。

依赖方向：`plugin_contracts <- platform_capabilities <- platform_capabilities_{windows,macos,linux,android,ios,web}`。

## 测试

```bash
dart test
dart analyze
```
