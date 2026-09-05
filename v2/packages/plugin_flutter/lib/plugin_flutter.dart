/// plugin_flutter：插件 UI Surface 契约层与主题组件库（规格 §9 + M3）。
///
/// 提供三类 surface 提供者接口（页面/设置/动作）、声明式表单与结果模型、
/// `surface.unsupported` 失败工厂；M3 追加设计令牌、三方向主题预设、
/// 主题控制器与目录页基础组件，以及包内固定文案的本地化。
library;

export 'src/generated/plugin_flutter_l10n.dart';
export 'src/surface/declarative_form.dart';
export 'src/surface/declarative_result.dart';
export 'src/surface/plugin_ui_surface.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/presets/dark_pro.dart';
export 'src/theme/presets/precision_tools.dart';
export 'src/theme/presets/warm_life.dart';
export 'src/theme/theme_controller.dart';
export 'src/theme/tokens.dart';
export 'src/widgets/form_renderer.dart';
export 'src/widgets/plugin_card.dart';
export 'src/widgets/result_renderer.dart';
export 'src/widgets/status_badge.dart';
