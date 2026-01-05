import 'dart:io';
import 'dart:async';
import '../models/external_plugin_models.dart';

/// Configuration for launching external plugins
abstract class PluginLaunchConfig {
  final String pluginId;
  final PluginRuntimeType pluginRuntimeType;
  final Map<String, dynamic> configuration;
  
  const PluginLaunchConfig({
    required this.pluginId,
    required this.pluginRuntimeType,
    required this.configuration,
  });
}

/// Configuration for executable plugins
class ExecutableConfig extends PluginLaunchConfig {
  final String executablePath;
  final List<String> arguments;
  final Map<String, String> environment;
  
  const ExecutableConfig({
    required super.pluginId,
    required this.executablePath,
    required this.arguments,
    required this.environment,
    super.configuration = const {},
  }) : super(pluginRuntimeType: PluginRuntimeType.executable);
}

/// Configuration for web plugins
class WebConfig extends PluginLaunchConfig {
  final String entryUrl;
  final Map<String, dynamic> webViewConfig;
  final SecurityRequirements securityPolicy;
  
  const WebConfig({
    required super.pluginId,
    required this.entryUrl,
    required this.webViewConfig,
    required this.securityPolicy,
    super.configuration = const {},
  }) : super(pluginRuntimeType: PluginRuntimeType.webApp);
}

/// Configuration for container plugins
class ContainerConfig extends PluginLaunchConfig {
  final String imageName;
  final Map<String, dynamic> containerSettings;
  final Map<String, dynamic> networkConfig;
  
  const ContainerConfig({
    required super.pluginId,
    required this.imageName,
    required this.containerSettings,
    required this.networkConfig,
    super.configuration = const {},
  }) : super(pluginRuntimeType: PluginRuntimeType.container);
}

/// Launcher for external plugins
abstract class ExternalPluginLauncher {
  /// Launch a plugin with the given configuration
  Future<int> launchPlugin(PluginLaunchConfig config);
  
  /// Terminate a plugin process
  Future<void> terminatePlugin(int processId);
  
  /// Check if a plugin process is running
  Future<bool> isPluginRunning(int processId);
  
  /// Monitor plugin process health
  Future<PluginProcessStatus> getProcessStatus(int processId);
}

/// Status of a plugin process
class PluginProcessStatus {
  final int processId;
  final bool isRunning;
  final DateTime startTime;
  final Duration uptime;
  final Map<String, dynamic> metrics;
  
  const PluginProcessStatus({
    required this.processId,
    required this.isRunning,
    required this.startTime,
    required this.uptime,
    required this.metrics,
  });
}

/// Launcher for executable plugins
class ExecutablePluginLauncher extends ExternalPluginLauncher {
  final Map<int, Process> _processes = {};
  final Map<int, DateTime> _startTimes = {};
  
  @override
  Future<int> launchPlugin(PluginLaunchConfig config) async {
    if (config is! ExecutableConfig) {
      throw ArgumentError('Expected ExecutableConfig');
    }
    
    try {
      // Validate executable exists
      final executable = File(config.executablePath);
      if (!await executable.exists()) {
        throw StateError('Executable not found: ${config.executablePath}');
      }
      
      // Launch the process
      final process = await Process.start(
        config.executablePath,
        config.arguments,
        environment: config.environment,
        workingDirectory: config.configuration['workingDirectory'] as String?,
      );
      
      final processId = process.pid;
      _processes[processId] = process;
      _startTimes[processId] = DateTime.now();
      
      // Monitor process exit
      process.exitCode.then((exitCode) {
        _processes.remove(processId);
        _startTimes.remove(processId);
      });
      
      return processId;
    } catch (e) {
      throw StateError('Failed to launch executable plugin: $e');
    }
  }
  
  @override
  Future<void> terminatePlugin(int processId) async {
    final process = _processes[processId];
    if (process != null) {
      process.kill();
      _processes.remove(processId);
      _startTimes.remove(processId);
    }
  }
  
  @override
  Future<bool> isPluginRunning(int processId) async {
    final process = _processes[processId];
    if (process == null) return false;
    
    // Check if process is still alive
    try {
      // On some platforms, we can check if process is still running
      return !await process.exitCode.timeout(
        const Duration(milliseconds: 1),
        onTimeout: () => throw TimeoutException('Process still running'),
      ).then((_) => true).catchError((_) => false);
    } catch (e) {
      // If timeout or other error, assume process is still running
      return true;
    }
  }
  
  @override
  Future<PluginProcessStatus> getProcessStatus(int processId) async {
    final process = _processes[processId];
    final startTime = _startTimes[processId];
    
    if (process == null || startTime == null) {
      throw StateError('Process $processId not found');
    }
    
    final isRunning = await isPluginRunning(processId);
    final uptime = DateTime.now().difference(startTime);
    
    return PluginProcessStatus(
      processId: processId,
      isRunning: isRunning,
      startTime: startTime,
      uptime: uptime,
      metrics: {
        'pid': processId,
        'startTime': startTime.toIso8601String(),
        'uptime': uptime.inSeconds,
      },
    );
  }
}

/// Launcher for web plugins
class WebPluginLauncher extends ExternalPluginLauncher {
  final Map<int, WebPluginInstance> _webInstances = {};
  int _nextInstanceId = 1000; // Start web instances at 1000 to avoid conflicts
  
  @override
  Future<int> launchPlugin(PluginLaunchConfig config) async {
    if (config is! WebConfig) {
      throw ArgumentError('Expected WebConfig');
    }
    
    try {
      // Validate URL
      final uri = Uri.tryParse(config.entryUrl);
      if (uri == null || (!uri.hasScheme || !['http', 'https', 'file'].contains(uri.scheme))) {
        throw ArgumentError('Invalid entry URL: ${config.entryUrl}');
      }
      
      // Create web plugin instance
      final instanceId = _nextInstanceId++;
      final instance = WebPluginInstance(
        instanceId: instanceId,
        entryUrl: config.entryUrl,
        webViewConfig: config.webViewConfig,
        securityPolicy: config.securityPolicy,
        startTime: DateTime.now(),
      );
      
      _webInstances[instanceId] = instance;
      
      // In a real implementation, this would initialize a WebView
      // For now, we simulate the web plugin being "launched"
      instance.isRunning = true;
      
      return instanceId;
    } catch (e) {
      throw StateError('Failed to launch web plugin: $e');
    }
  }
  
  @override
  Future<void> terminatePlugin(int processId) async {
    final instance = _webInstances[processId];
    if (instance != null) {
      instance.isRunning = false;
      _webInstances.remove(processId);
    }
  }
  
  @override
  Future<bool> isPluginRunning(int processId) async {
    final instance = _webInstances[processId];
    return instance?.isRunning ?? false;
  }
  
  @override
  Future<PluginProcessStatus> getProcessStatus(int processId) async {
    final instance = _webInstances[processId];
    if (instance == null) {
      throw StateError('Web plugin instance $processId not found');
    }
    
    final uptime = DateTime.now().difference(instance.startTime);
    
    return PluginProcessStatus(
      processId: processId,
      isRunning: instance.isRunning,
      startTime: instance.startTime,
      uptime: uptime,
      metrics: {
        'instanceId': processId,
        'entryUrl': instance.entryUrl,
        'startTime': instance.startTime.toIso8601String(),
        'uptime': uptime.inSeconds,
        'webViewConfig': instance.webViewConfig,
      },
    );
  }
}

/// Represents a web plugin instance
class WebPluginInstance {
  final int instanceId;
  final String entryUrl;
  final Map<String, dynamic> webViewConfig;
  final SecurityRequirements securityPolicy;
  final DateTime startTime;
  bool isRunning;
  
  WebPluginInstance({
    required this.instanceId,
    required this.entryUrl,
    required this.webViewConfig,
    required this.securityPolicy,
    required this.startTime,
    this.isRunning = false,
  });
}

/// Launcher for container plugins
class ContainerPluginLauncher extends ExternalPluginLauncher {
  final Map<int, ContainerInstance> _containers = {};
  int _nextContainerId = 2000; // Start container instances at 2000
  
  @override
  Future<int> launchPlugin(PluginLaunchConfig config) async {
    if (config is! ContainerConfig) {
      throw ArgumentError('Expected ContainerConfig');
    }
    
    try {
      // Validate image name
      if (config.imageName.isEmpty) {
        throw ArgumentError('Container image name cannot be empty');
      }
      
      // Create container instance
      final containerId = _nextContainerId++;
      final instance = ContainerInstance(
        containerId: containerId,
        imageName: config.imageName,
        containerSettings: config.containerSettings,
        networkConfig: config.networkConfig,
        startTime: DateTime.now(),
      );
      
      // Simulate container startup
      await _startContainer(instance);
      
      _containers[containerId] = instance;
      instance.isRunning = true;
      
      return containerId;
    } catch (e) {
      throw StateError('Failed to launch container plugin: $e');
    }
  }
  
  @override
  Future<void> terminatePlugin(int processId) async {
    final container = _containers[processId];
    if (container != null) {
      await _stopContainer(container);
      container.isRunning = false;
      _containers.remove(processId);
    }
  }
  
  @override
  Future<bool> isPluginRunning(int processId) async {
    final container = _containers[processId];
    return container?.isRunning ?? false;
  }
  
  @override
  Future<PluginProcessStatus> getProcessStatus(int processId) async {
    final container = _containers[processId];
    if (container == null) {
      throw StateError('Container instance $processId not found');
    }
    
    final uptime = DateTime.now().difference(container.startTime);
    
    return PluginProcessStatus(
      processId: processId,
      isRunning: container.isRunning,
      startTime: container.startTime,
      uptime: uptime,
      metrics: {
        'containerId': processId,
        'imageName': container.imageName,
        'startTime': container.startTime.toIso8601String(),
        'uptime': uptime.inSeconds,
        'containerSettings': container.containerSettings,
        'networkConfig': container.networkConfig,
      },
    );
  }
  
  /// Start a container instance (simulated)
  Future<void> _startContainer(ContainerInstance instance) async {
    // In a real implementation, this would use Docker API or similar
    // For now, we simulate container startup with validation
    
    // Validate container settings
    final settings = instance.containerSettings;
    if (settings.containsKey('ports')) {
      final ports = settings['ports'] as List<dynamic>?;
      if (ports != null) {
        for (final port in ports) {
          if (port is! int || port < 1 || port > 65535) {
            throw ArgumentError('Invalid port configuration: $port');
          }
        }
      }
    }
    
    // Validate network configuration
    final networkConfig = instance.networkConfig;
    if (networkConfig.containsKey('networkMode')) {
      final mode = networkConfig['networkMode'] as String?;
      if (mode != null && !['bridge', 'host', 'none', 'container'].contains(mode)) {
        throw ArgumentError('Invalid network mode: $mode');
      }
    }
    
    // Simulate startup delay
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// Stop a container instance (simulated)
  Future<void> _stopContainer(ContainerInstance instance) async {
    // In a real implementation, this would stop the Docker container
    // For now, we simulate container shutdown
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

/// Represents a container plugin instance
class ContainerInstance {
  final int containerId;
  final String imageName;
  final Map<String, dynamic> containerSettings;
  final Map<String, dynamic> networkConfig;
  final DateTime startTime;
  bool isRunning;
  
  ContainerInstance({
    required this.containerId,
    required this.imageName,
    required this.containerSettings,
    required this.networkConfig,
    required this.startTime,
    this.isRunning = false,
  });
}

