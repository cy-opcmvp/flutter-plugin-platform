/// screenshot：截图插件（Windows builtin）公共 API。
///
/// 提供 [screenshotManifest] 清单构建器、[CaptureController] 捕获编排、
/// 页面/设置两类 surface 提供方与文案载体；插件包零平台依赖、零 dart:io。
library;

export 'src/capture_controller.dart';
export 'src/filename_template.dart';
export 'src/region_selection.dart';
export 'src/screenshot_codec.dart';
export 'src/screenshot_manifest.dart';
export 'src/screenshot_model.dart';
export 'src/screenshot_page.dart';
export 'src/screenshot_settings.dart';
export 'src/screenshot_strings.dart';
