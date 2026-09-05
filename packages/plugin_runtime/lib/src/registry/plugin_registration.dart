import 'package:plugin_contracts/plugin_contracts.dart';

final class PluginRegistration {
  PluginRegistration(this.manifest);

  final PluginManifest manifest;

  PluginId get id => manifest.id;
}
