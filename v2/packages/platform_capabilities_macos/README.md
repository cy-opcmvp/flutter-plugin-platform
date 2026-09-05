# platform_capabilities_macos

macos 端平台能力绑定（stub）： `platform_capabilities` 接口在本端的占位实现，全部能力返回 `capability.unsupported`（details 携带 `platform: 'macos'`）。

导出常量：

- `macosScreenCapture` — `ScreenCapture` stub，区域截图一律返回结构化失败。
- `macosSystemPaths` — `SystemPaths` stub，路径查询一律抛 `capability.unsupported`。

本包零 `dart:io` / Flutter 依赖，六端可编译；真实实现交由后续端绑定任务落地。

## 测试

```bash
dart test
dart analyze
```
