# toolbox_host

Toolbox 桌面宿主应用（v2 计划 F3-06 的宿主组装参考实现）。

## 结构

- `lib/main.dart` — 仅引导：显式传入解析目标平台与宿主数据根字符串。
- `lib/src/host_composition_root.dart` — 全应用唯一组装点（注册表、解析、
  Sidecar 安装器、数据目录、主题控制器、页面提供方）。
- `lib/src/app.dart` — 应用壳：语言/明暗模式状态 + MaterialApp + 导航外壳。
- `lib/src/pages/` — 插件目录页、插件详情页、设置页。
- `lib/src/plugins/welcome_plugin.dart` — 内置欢迎插件（最小 builtin 清单 +
  PluginPageProvider 实现 + 演示表单）。

## 运行

```bash
flutter pub get
flutter run -d windows
```

宿主 lib 不引入 `dart:io` 与平台专属通道；数据目录仅做字符串拼接，Sidecar
安装落盘与真实系统能力在后续阶段接入。
