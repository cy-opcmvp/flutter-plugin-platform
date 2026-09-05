/// 插件脚手架 CLI：`create` / `validate` / `pack` 三个子命令。
///
/// 纯 Dart 实现且零 Flutter 依赖；在 workspace 内经
/// `dart run plugin_cli <command>` 调用。清单校验复用
/// `plugin_contracts` 的严格解码，打包复用 `plugin_sidecar`
/// 的 SCP1 构建与读取器。
library;

export 'src/cli_runner.dart';
