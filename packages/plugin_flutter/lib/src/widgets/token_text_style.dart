/// 令牌字体规格转 [TextStyle] 的组件层入口。
///
/// 实现转发至 presets 内的唯一转换工厂（样式字面量仅允许出现在
/// presets/ 目录，见 no_hardcoded_style_test 静态扫描）。
library;

export '../theme/presets/token_text_style.dart';
