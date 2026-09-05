/// 计算器插件公共 API（六端 builtin）。
///
/// 对外导出求值器、历史记录、清单构建器与 UI 提供方；宿主接线时组装
/// [CalculatorPageProvider] / [CalculatorSettingsProvider] 与共享模型，
/// 并经 [CalculatorStringsResolver] 注入宿主语言文案。
library;

export 'src/calculator_manifest.dart';
export 'src/logic/calculator_history.dart';
export 'src/logic/expression_parser.dart';
export 'src/ui/calculator_model.dart';
export 'src/ui/calculator_page.dart';
export 'src/ui/calculator_settings_screen.dart';
export 'src/ui/calculator_strings.dart';
