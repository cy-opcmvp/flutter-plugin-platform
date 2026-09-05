# screenshot（Windows builtin 截图插件）

M4 内置插件：主屏捕获、PNG 保存与可配置文件名。目标平台 `windows`。

## 结构

```
screenshot/
├── plugin.json    # 插件清单（kind=builtin，surfaces=[page, settings]，requires 屏幕捕获能力）
├── pubspec.yaml   # 依赖 flutter sdk + plugin_contracts + plugin_flutter + platform_capabilities（接口）
├── lib/           # 捕获编排、保存参数模型、设置模型与文案解析
└── test/          # 模型/文案/清单一致性测试
```

平台实现经 `platform_capabilities` 接口注入，实际 GDI 捕获在 `packages/platform_capabilities_windows`（`dart:ffi` 仅限其 `gdi_capture.dart`）；插件包自身零平台通道依赖，便于在非 Windows 目标上保持可编译。宿主接线镜像 `screenshotManifest()`，与 `plugin.json` 必须逐一致。

## 验证

```bash
cd v2/plugins/screenshot && flutter test
cd v2/packages/plugin_cli && dart run plugin_cli validate ../../plugins/screenshot
```

错误码：`capture.failed`（屏幕捕获能力调用失败）。
