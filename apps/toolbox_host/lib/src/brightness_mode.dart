/// 明暗模式设置项（宿主设置页状态，独立成文件避免 app/页面 循环 import）。
library;

/// 明暗模式：system 表示跟随系统。
enum BrightnessMode { system, light, dark }
