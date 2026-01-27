import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';

/// {{PLUGIN_DESCRIPTION}}
class {{PLUGIN_CLASS}}Plugin implements IPlugin {
  late PluginContext context;

  @override
  String get id => '{{PLUGIN_ID}}';

  @override
  String get name => '{{PLUGIN_NAME}}';

  @override
  String get version => '1.0.0';

  @override
  PluginType get type => PluginType.tool;

  @override
  Future<void> initialize(PluginContext context) async {
    context = context;
    
    // 加载保存的状态
    final savedState = await context.dataStorage.retrieve<Map<String, dynamic>>('{{PLUGIN_FILE_NAME}}_state');
    if (savedState != null) {
      // 恢复状态
    }

    await context.platformServices.showNotification('{{PLUGIN_NAME}} initialized');
  }

  @override
  Future<void> dispose() async {
    await saveState();
    await context.platformServices.showNotification('{{PLUGIN_NAME}} disposed');
  }

  @override
  Widget buildUI(BuildContext context) {
    return {{PLUGIN_CLASS}}Widget(
      onStateChanged: saveState,
    );
  }

  Future<void> saveState() async {
    final state = {
      'version': version,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await context.dataStorage.store('{{PLUGIN_FILE_NAME}}_state', state);
  }

  @override
  Future<void> onStateChanged(PluginState state) async {
    switch (state) {
      case PluginState.active:
        break;
      case PluginState.paused:
      case PluginState.inactive:
        await saveState();
        break;
      case PluginState.error:
        break;
      case PluginState.loading:
        break;
    }
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return {
      'version': version,
    };
  }
}

/// {{PLUGIN_NAME}} UI Widget
class {{PLUGIN_CLASS}}Widget extends StatefulWidget {
  final VoidCallback onStateChanged;

  const {{PLUGIN_CLASS}}Widget({
    super.key,
    required this.onStateChanged,
  });

  @override
  State<{{PLUGIN_CLASS}}Widget> createState() => _{{PLUGIN_CLASS}}WidgetState();
}

class _{{PLUGIN_CLASS}}WidgetState extends State<{{PLUGIN_CLASS}}Widget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{PLUGIN_NAME}}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.{{PLUGIN_ICON}}, size: 64),
            const SizedBox(height: 16),
            Text(
              '{{PLUGIN_NAME}}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('{{PLUGIN_DESCRIPTION}}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: 实现功能
                setState(() {});
                widget.onStateChanged();
              },
              child: const Text('开始使用'),
            ),
          ],
        ),
      ),
    );
  }
}
