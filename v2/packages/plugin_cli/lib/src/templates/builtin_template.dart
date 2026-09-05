/// builtin 插件骨架模板：入口 Dart 文件内容内嵌为常量渲染函数。
///
/// 生成的骨架实现 `plugin_contracts` 的 `PluginLifecycle`，是可编译的
/// 最小起点；UI surface（page/settings/actions）由插件作者按需在
/// `plugin_flutter` 契约上补齐。
library;

/// builtin 清单声明的 surface 字面量。
const String builtinSurface = 'page';

/// 由插件标识派生入口文件名：`tools.demo` → `tools_demo_plugin.dart`。
String builtinFileName(String pluginId) {
  return '${snakeFromId(pluginId)}_plugin.dart';
}

/// 由插件标识派生骨架类名：`tools.demo` → `ToolsDemoPlugin`。
String builtinClassName(String pluginId) {
  return '${pascalFromId(pluginId)}Plugin';
}

/// 标识转 snake_case：各段转小写后用下划线连接。
String snakeFromId(String pluginId) {
  return pluginId
      .split('.')
      .map((String segment) => segment.toLowerCase())
      .join('_');
}

/// 标识转 PascalCase：各段转小写后首字母大写再连接。
String pascalFromId(String pluginId) {
  final StringBuffer buffer = StringBuffer();
  for (final String segment in pluginId.split('.')) {
    final String lowered = segment.toLowerCase();
    if (lowered.isEmpty) {
      continue;
    }
    buffer
      ..write(lowered.substring(0, 1).toUpperCase())
      ..write(lowered.substring(1));
  }
  return buffer.toString();
}

/// 渲染 builtin 骨架源码；[className] 来自 [builtinClassName]。
String renderBuiltinTemplate({
  required String pluginId,
  required String pluginName,
  required String className,
}) {
  return '''
// 由 plugin_cli 生成的 builtin 插件骨架：$pluginId。
//
// 生命周期契约见 package:plugin_contracts 的 PluginLifecycle；
// UI surface（page/settings/actions）见 package:plugin_flutter。
// 后续实现提示：
//   1. 在宿主组装点（Composition Root）注册本插件类；
//   2. 按需实现 PluginPageProvider / PluginSettingsProvider /
//      PluginActionProvider 等 surface 接口；
//   3. 同步更新清单 surfaces 声明并跑 plugin_devkit 契约检查。
import 'package:plugin_contracts/plugin_contracts.dart';

/// $pluginName 的最小插件骨架：只维持生命周期，不承载业务。
final class $className implements PluginLifecycle {
  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dispose() async {}
}
''';
}
