# calculator（六端 builtin 计算器）

M4 内置插件：表达式求值、历史记录与可配置呈现。目标平台 `windows/macos/linux/android/ios/web`。

## 结构

```
calculator/
├── plugin.json    # 插件清单（kind=builtin，surfaces=[page, settings]）
├── pubspec.yaml   # 纯 Dart 模型包：仅依赖 flutter sdk + plugin_contracts + plugin_flutter
├── lib/           # 求值器、历史模型、设置模型与文案解析
└── test/          # 模型/文案/清单一致性测试
```

宿主接线在 `apps/toolbox_host/lib/src/plugins/calculator_plugin.dart`：`calculatorManifest()` 内存镜像清单，`CalculatorPageProvider` / `CalculatorSettingsProvider` 以声明式组件组合模型与宿主文案。**修改 `plugin.json` 必须同步镜像**。

## 验证

```bash
cd v2/plugins/calculator && flutter test
cd v2/packages/plugin_cli && dart run plugin_cli validate ../../plugins/calculator
```

错误码：`calc.invalid_expression`（表达式为空/未知符号/括号未闭合/除零，details 携带位置与种类）。
