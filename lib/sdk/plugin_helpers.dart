import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/plugin_models.dart';
import 'plugin_sdk.dart';

/// Helper class for executable-based external plugins
class ExecutablePluginHelper {
  static const String _pluginType = 'executable';

  /// Initialize an executable plugin
  static Future<void> initialize({
    required String pluginId,
    required String executablePath,
    List<String>? arguments,
    Map<String, String>? environment,
    Map<String, dynamic>? config,
  }) async {
    await PluginSDK.initialize(
      pluginId: pluginId,
      config: {
        'type': _pluginType,
        'executablePath': executablePath,
        'arguments': arguments ?? [],
        'environment': environment ?? {},
        ...?config,
      },
    );

    // Register executable-specific event handlers
    PluginSDK.onHostEvent('process_signal', _handleProcessSignal);
    PluginSDK.onHostEvent('resource_limit_warning', _handleResourceWarning);
  }

  /// Handle process signals from host
  static Future<void> _handleProcessSignal(HostEvent event) async {
    final signal = event.data['signal'] as String;

    switch (signal) {
      case 'SIGTERM':
      case 'SIGINT':
        await PluginSDK.logInfo('Received termination signal: $signal');
        await PluginSDK.shutdown();
        exit(0);
      case 'SIGUSR1':
        await PluginSDK.logInfo('Received user signal 1');
        // Handle custom signal logic
        break;
      default:
        await PluginSDK.logWarning('Received unknown signal: $signal');
    }
  }

  /// Handle resource limit warnings
  static Future<void> _handleResourceWarning(HostEvent event) async {
    final resourceType = event.data['resourceType'] as String;
    final currentUsage = event.data['currentUsage'] as num;
    final limit = event.data['limit'] as num;

    await PluginSDK.logWarning(
      'Resource limit warning: $resourceType usage at ${(currentUsage / limit * 100).toStringAsFixed(1)}%',
      {
        'resourceType': resourceType,
        'currentUsage': currentUsage,
        'limit': limit,
      },
    );
  }

  /// Report process metrics to host
  static Future<void> reportMetrics({
    required double cpuUsage,
    required int memoryUsageMB,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    await PluginSDK.callHostAPI<void>('reportProcessMetrics', {
      'pluginId': PluginSDK.instance.pluginId,
      'cpuUsage': cpuUsage,
      'memoryUsageMB': memoryUsageMB,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalMetrics,
    });
  }
}

/// Helper class for web-based external plugins
class WebPluginHelper {
  static const String _pluginType = 'web';

  /// Initialize a web plugin
  static Future<void> initialize({
    required String pluginId,
    required String entryUrl,
    Map<String, dynamic>? webViewConfig,
    Map<String, dynamic>? securityPolicy,
    Map<String, dynamic>? config,
  }) async {
    await PluginSDK.initialize(
      pluginId: pluginId,
      config: {
        'type': _pluginType,
        'entryUrl': entryUrl,
        'webViewConfig': webViewConfig ?? {},
        'securityPolicy': securityPolicy ?? {},
        ...?config,
      },
    );

    // Register web-specific event handlers
    PluginSDK.onHostEvent('webview_ready', _handleWebViewReady);
    PluginSDK.onHostEvent('navigation_blocked', _handleNavigationBlocked);
    PluginSDK.onHostEvent('security_violation', _handleSecurityViolation);
  }

  /// Handle WebView ready event
  static Future<void> _handleWebViewReady(HostEvent event) async {
    await PluginSDK.logInfo('WebView container ready');

    // Inject plugin bridge script
    await injectBridgeScript();
  }

  /// Handle blocked navigation attempts
  static Future<void> _handleNavigationBlocked(HostEvent event) async {
    final blockedUrl = event.data['url'] as String;
    final reason = event.data['reason'] as String;

    await PluginSDK.logWarning('Navigation blocked: $blockedUrl', {
      'reason': reason,
    });
  }

  /// Handle security violations
  static Future<void> _handleSecurityViolation(HostEvent event) async {
    final violationType = event.data['type'] as String;
    final details = event.data['details'] as Map<String, dynamic>;

    await PluginSDK.logError('Security violation: $violationType', details);
  }

  /// Inject JavaScript bridge for host communication
  static Future<void> injectBridgeScript() async {
    const bridgeScript = '''
      window.PluginBridge = {
        sendMessage: function(type, data) {
          window.parent.postMessage({
            source: 'plugin',
            type: type,
            data: data,
            timestamp: new Date().toISOString()
          }, '*');
        },
        
        callHostAPI: function(method, params) {
          return new Promise((resolve, reject) => {
            const messageId = 'api_' + Date.now() + '_' + Math.random();
            
            const handler = function(event) {
              if (event.data.messageId === messageId) {
                window.removeEventListener('message', handler);
                if (event.data.error) {
                  reject(new Error(event.data.error.message));
                } else {
                  resolve(event.data.result);
                }
              }
            };
            
            window.addEventListener('message', handler);
            
            window.parent.postMessage({
              source: 'plugin',
              type: 'api_call',
              messageId: messageId,
              method: method,
              params: params
            }, '*');
          });
        }
      };
    ''';

    await PluginSDK.callHostAPI<void>('injectScript', {'script': bridgeScript});
  }

  /// Navigate to a new URL within the plugin
  static Future<void> navigate(String url) async {
    await PluginSDK.callHostAPI<void>('navigateWebView', {
      'pluginId': PluginSDK.instance.pluginId,
      'url': url,
    });
  }

  /// Update WebView security policy
  static Future<void> updateSecurityPolicy(Map<String, dynamic> policy) async {
    await PluginSDK.callHostAPI<void>('updateWebViewSecurityPolicy', {
      'pluginId': PluginSDK.instance.pluginId,
      'policy': policy,
    });
  }
}

/// Helper class for container-based external plugins
class ContainerPluginHelper {
  static const String _pluginType = 'container';

  /// Initialize a container plugin
  static Future<void> initialize({
    required String pluginId,
    required String imageName,
    Map<String, dynamic>? containerConfig,
    Map<String, dynamic>? networkConfig,
    Map<String, dynamic>? config,
  }) async {
    await PluginSDK.initialize(
      pluginId: pluginId,
      config: {
        'type': _pluginType,
        'imageName': imageName,
        'containerConfig': containerConfig ?? {},
        'networkConfig': networkConfig ?? {},
        ...?config,
      },
    );

    // Register container-specific event handlers
    PluginSDK.onHostEvent('container_started', _handleContainerStarted);
    PluginSDK.onHostEvent('container_stopped', _handleContainerStopped);
    PluginSDK.onHostEvent('health_check', _handleHealthCheck);
  }

  /// Handle container started event
  static Future<void> _handleContainerStarted(HostEvent event) async {
    final containerId = event.data['containerId'] as String;
    await PluginSDK.logInfo('Container started: $containerId');
  }

  /// Handle container stopped event
  static Future<void> _handleContainerStopped(HostEvent event) async {
    final containerId = event.data['containerId'] as String;
    final exitCode = event.data['exitCode'] as int;

    await PluginSDK.logInfo(
      'Container stopped: $containerId (exit code: $exitCode)',
    );
  }

  /// Handle health check requests
  static Future<void> _handleHealthCheck(HostEvent event) async {
    // Perform health check and report status
    final healthStatus = await performHealthCheck();

    await PluginSDK.sendEvent('health_check_response', {
      'pluginId': PluginSDK.instance.pluginId,
      'status': healthStatus['status'],
      'details': healthStatus['details'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Perform plugin health check
  static Future<Map<String, dynamic>> performHealthCheck() async {
    try {
      // Basic health check - can be overridden by specific plugins
      return {
        'status': 'healthy',
        'details': {
          'uptime': DateTime.now().millisecondsSinceEpoch,
          'memoryUsage': 'unknown',
          'cpuUsage': 'unknown',
        },
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'details': {'error': e.toString()},
      };
    }
  }

  /// Get container logs
  static Future<List<String>> getLogs({int? lines, DateTime? since}) async {
    final result =
        await PluginSDK.callHostAPI<List<dynamic>>('getContainerLogs', {
          'pluginId': PluginSDK.instance.pluginId,
          'lines': lines,
          'since': since?.toIso8601String(),
        });

    return result.cast<String>();
  }

  /// Execute command in container
  static Future<Map<String, dynamic>> executeCommand(
    List<String> command, {
    Map<String, String>? environment,
    String? workingDirectory,
  }) async {
    return await PluginSDK.callHostAPI<Map<String, dynamic>>(
      'executeContainerCommand',
      {
        'pluginId': PluginSDK.instance.pluginId,
        'command': command,
        'environment': environment ?? {},
        'workingDirectory': workingDirectory,
      },
    );
  }
}

/// Helper class for plugin configuration management
class PluginConfigHelper {
  /// Get configuration value with type safety
  static Future<T?> getConfig<T>(String key, [T? defaultValue]) async {
    try {
      final config = await PluginSDK.getPluginConfig();
      final value = config[key];

      if (value is T) {
        return value;
      } else if (value != null) {
        // Try to convert common types
        if (T == String) {
          return value.toString() as T;
        } else if (T == int && value is num) {
          return value.toInt() as T;
        } else if (T == double && value is num) {
          return value.toDouble() as T;
        } else if (T == bool) {
          if (value is String) {
            return (value.toLowerCase() == 'true') as T;
          }
        }
      }

      return defaultValue;
    } catch (e) {
      await PluginSDK.logWarning('Failed to get config for key $key: $e');
      return defaultValue;
    }
  }

  /// Set configuration value
  static Future<void> setConfig(String key, dynamic value) async {
    await PluginSDK.callHostAPI<void>('setPluginConfig', {
      'pluginId': PluginSDK.instance.pluginId,
      'key': key,
      'value': value,
    });
  }

  /// Get all configuration as typed map
  static Future<Map<String, T>> getTypedConfig<T>() async {
    final config = await PluginSDK.getPluginConfig();
    final typedConfig = <String, T>{};

    for (final entry in config.entries) {
      if (entry.value is T) {
        typedConfig[entry.key] = entry.value as T;
      }
    }

    return typedConfig;
  }
}

/// Helper class for plugin lifecycle management
class PluginLifecycleHelper {
  /// Register lifecycle event handlers
  static void registerLifecycleHandlers({
    VoidCallback? onInitialize,
    VoidCallback? onStart,
    VoidCallback? onPause,
    VoidCallback? onResume,
    VoidCallback? onStop,
    VoidCallback? onDestroy,
  }) {
    if (onInitialize != null) {
      PluginSDK.onHostEvent('plugin_initialize', (_) async => onInitialize());
    }

    if (onStart != null) {
      PluginSDK.onHostEvent('plugin_start', (_) async => onStart());
    }

    if (onPause != null) {
      PluginSDK.onHostEvent('plugin_pause', (_) async => onPause());
    }

    if (onResume != null) {
      PluginSDK.onHostEvent('plugin_resume', (_) async => onResume());
    }

    if (onStop != null) {
      PluginSDK.onHostEvent('plugin_stop', (_) async => onStop());
    }

    if (onDestroy != null) {
      PluginSDK.onHostEvent('plugin_destroy', (_) async => onDestroy());
    }
  }

  /// Report plugin ready status
  static Future<void> reportReady() async {
    await PluginSDK.updateStatus(PluginState.active, {
      'readyTime': DateTime.now().toIso8601String(),
    });

    await PluginSDK.sendEvent('plugin_ready', {
      'pluginId': PluginSDK.instance.pluginId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Report plugin error
  static Future<void> reportError(
    String error,
    Map<String, dynamic>? context,
  ) async {
    await PluginSDK.updateStatus(PluginState.error, {
      'error': error,
      'context': context ?? {},
      'errorTime': DateTime.now().toIso8601String(),
    });

    await PluginSDK.logError('Plugin error: $error', context);
  }

  /// Graceful shutdown
  static Future<void> gracefulShutdown() async {
    await PluginSDK.logInfo('Initiating graceful shutdown');

    await PluginSDK.updateStatus(PluginState.inactive, {
      'shutdownTime': DateTime.now().toIso8601String(),
    });

    await PluginSDK.shutdown();
  }
}
