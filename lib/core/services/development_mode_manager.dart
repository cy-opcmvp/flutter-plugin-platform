import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;


import 'platform_environment.dart';

/// Exception thrown when development mode operations fail
class DevelopmentModeException implements Exception {
  final String message;
  final String? pluginId;
  final Exception? cause;

  const DevelopmentModeException(this.message, {this.pluginId, this.cause});

  @override
  String toString() => 'DevelopmentModeException: $message${pluginId != null ? ' (Plugin: $pluginId)' : ''}';
}

/// Development environment detection result
class DevelopmentEnvironment {
  final bool isDevelopment;
  final String environment;
  final Map<String, dynamic> environmentVariables;
  final List<String> developmentIndicators;

  const DevelopmentEnvironment({
    required this.isDevelopment,
    required this.environment,
    required this.environmentVariables,
    required this.developmentIndicators,
  });

  Map<String, dynamic> toJson() {
    return {
      'isDevelopment': isDevelopment,
      'environment': environment,
      'environmentVariables': environmentVariables,
      'developmentIndicators': developmentIndicators,
    };
  }
}

/// Development mode logging configuration
class DevelopmentLoggingConfig {
  final bool enableVerboseLogging;
  final bool enablePluginTracing;
  final bool enablePerformanceMetrics;
  final bool enableMemoryTracking;
  final List<String> logCategories;
  final String logLevel;

  const DevelopmentLoggingConfig({
    this.enableVerboseLogging = true,
    this.enablePluginTracing = true,
    this.enablePerformanceMetrics = true,
    this.enableMemoryTracking = true,
    this.logCategories = const ['plugin', 'ipc', 'security', 'performance'],
    this.logLevel = 'DEBUG',
  });

  Map<String, dynamic> toJson() {
    return {
      'enableVerboseLogging': enableVerboseLogging,
      'enablePluginTracing': enablePluginTracing,
      'enablePerformanceMetrics': enablePerformanceMetrics,
      'enableMemoryTracking': enableMemoryTracking,
      'logCategories': logCategories,
      'logLevel': logLevel,
    };
  }
}

/// Development mode debugging features
class DevelopmentDebuggingFeatures {
  final bool enableBreakpoints;
  final bool enableStepDebugging;
  final bool enableVariableInspection;
  final bool enableCallStackTracing;
  final bool enableLiveReload;
  final Map<String, dynamic> debuggerSettings;

  const DevelopmentDebuggingFeatures({
    this.enableBreakpoints = true,
    this.enableStepDebugging = true,
    this.enableVariableInspection = true,
    this.enableCallStackTracing = true,
    this.enableLiveReload = true,
    this.debuggerSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'enableBreakpoints': enableBreakpoints,
      'enableStepDebugging': enableStepDebugging,
      'enableVariableInspection': enableVariableInspection,
      'enableCallStackTracing': enableCallStackTracing,
      'enableLiveReload': enableLiveReload,
      'debuggerSettings': debuggerSettings,
    };
  }
}

/// Development mode event types
enum DevelopmentModeEventType {
  modeEnabled,
  modeDisabled,
  environmentDetected,
  loggingConfigured,
  debuggingEnabled,
  pluginDevelopmentStarted,
  pluginDevelopmentStopped,
}

/// Development mode events
class DevelopmentModeEvent {
  final DevelopmentModeEventType type;
  final String? pluginId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const DevelopmentModeEvent({
    required this.type,
    this.pluginId,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'pluginId': pluginId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// Manager for development mode features and capabilities
class DevelopmentModeManager {
  final StreamController<DevelopmentModeEvent> _eventController = StreamController<DevelopmentModeEvent>.broadcast();
  
  bool _isInitialized = false;
  bool _isDevelopmentModeEnabled = false;
  DevelopmentEnvironment? _currentEnvironment;
  DevelopmentLoggingConfig _loggingConfig = const DevelopmentLoggingConfig();
  DevelopmentDebuggingFeatures _debuggingFeatures = const DevelopmentDebuggingFeatures();
  
  final Map<String, List<String>> _pluginLogs = {};
  final Map<String, Map<String, dynamic>> _pluginMetrics = {};
  final Map<String, DateTime> _pluginStartTimes = {};

  DevelopmentModeManager();

  /// Initialize the development mode manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Detect development environment
    _currentEnvironment = await _detectDevelopmentEnvironment();
    
    _isInitialized = true;
    
    // Enable development mode if in development environment
    if (_currentEnvironment!.isDevelopment) {
      await enableDevelopmentMode();
    }
  }

  /// Shutdown the development mode manager
  Future<void> shutdown() async {
    if (!_isInitialized) return;
    
    if (_isDevelopmentModeEnabled) {
      await disableDevelopmentMode();
    }
    
    await _eventController.close();
    _isInitialized = false;
  }

  /// Stream of development mode events
  Stream<DevelopmentModeEvent> get eventStream => _eventController.stream;

  /// Check if development mode is enabled
  bool get isDevelopmentModeEnabled => _isDevelopmentModeEnabled;

  /// Get current development environment information
  DevelopmentEnvironment? get currentEnvironment => _currentEnvironment;

  /// Get current logging configuration
  DevelopmentLoggingConfig get loggingConfig => _loggingConfig;

  /// Get current debugging features
  DevelopmentDebuggingFeatures get debuggingFeatures => _debuggingFeatures;

  /// Enable development mode with enhanced features
  Future<void> enableDevelopmentMode({
    DevelopmentLoggingConfig? loggingConfig,
    DevelopmentDebuggingFeatures? debuggingFeatures,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isDevelopmentModeEnabled) return;
    
    // Update configurations
    if (loggingConfig != null) {
      _loggingConfig = loggingConfig;
    }
    if (debuggingFeatures != null) {
      _debuggingFeatures = debuggingFeatures;
    }
    
    // Configure enhanced logging
    await _configureEnhancedLogging();
    
    // Enable debugging features
    await _enableDebuggingFeatures();
    
    _isDevelopmentModeEnabled = true;
    
    // Emit development mode enabled event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.modeEnabled,
      timestamp: DateTime.now(),
      data: {
        'loggingConfig': _loggingConfig.toJson(),
        'debuggingFeatures': _debuggingFeatures.toJson(),
        'environment': _currentEnvironment?.toJson(),
      },
    ));
  }

  /// Disable development mode
  Future<void> disableDevelopmentMode() async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) return;
    
    // Disable debugging features
    await _disableDebuggingFeatures();
    
    // Reset logging to production level
    await _resetLoggingToProduction();
    
    _isDevelopmentModeEnabled = false;
    
    // Emit development mode disabled event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.modeDisabled,
      timestamp: DateTime.now(),
    ));
  }

  /// Detect development environment
  Future<DevelopmentEnvironment> detectEnvironment() async {
    _ensureInitialized();
    
    _currentEnvironment = await _detectDevelopmentEnvironment();
    
    // Emit environment detected event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.environmentDetected,
      timestamp: DateTime.now(),
      data: _currentEnvironment?.toJson(),
    ));
    
    return _currentEnvironment!;
  }

  /// Configure logging for development mode
  Future<void> configureLogging(DevelopmentLoggingConfig config) async {
    _ensureInitialized();
    
    _loggingConfig = config;
    
    if (_isDevelopmentModeEnabled) {
      await _configureEnhancedLogging();
    }
    
    // Emit logging configured event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.loggingConfigured,
      timestamp: DateTime.now(),
      data: config.toJson(),
    ));
  }

  /// Configure debugging features
  Future<void> configureDebugging(DevelopmentDebuggingFeatures features) async {
    _ensureInitialized();
    
    _debuggingFeatures = features;
    
    if (_isDevelopmentModeEnabled) {
      await _enableDebuggingFeatures();
    }
    
    // Emit debugging enabled event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.debuggingEnabled,
      timestamp: DateTime.now(),
      data: features.toJson(),
    ));
  }

  /// Start development session for a plugin
  Future<void> startPluginDevelopment(String pluginId) async {
    _ensureInitialized();
    
    if (!_isDevelopmentModeEnabled) {
      throw DevelopmentModeException('Development mode is not enabled', pluginId: pluginId);
    }
    
    // Initialize plugin development tracking
    _pluginLogs[pluginId] = [];
    _pluginMetrics[pluginId] = {};
    _pluginStartTimes[pluginId] = DateTime.now();
    
    // Start enhanced monitoring for the plugin
    await _startPluginMonitoring(pluginId);
    
    // Emit plugin development started event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.pluginDevelopmentStarted,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'startTime': _pluginStartTimes[pluginId]!.toIso8601String(),
      },
    ));
  }

  /// Stop development session for a plugin
  Future<void> stopPluginDevelopment(String pluginId) async {
    _ensureInitialized();
    
    // Stop plugin monitoring
    await _stopPluginMonitoring(pluginId);
    
    // Generate development session report
    final report = await _generateDevelopmentReport(pluginId);
    
    // Clean up tracking data
    _pluginLogs.remove(pluginId);
    _pluginMetrics.remove(pluginId);
    _pluginStartTimes.remove(pluginId);
    
    // Emit plugin development stopped event
    _eventController.add(DevelopmentModeEvent(
      type: DevelopmentModeEventType.pluginDevelopmentStopped,
      pluginId: pluginId,
      timestamp: DateTime.now(),
      data: {
        'report': report,
      },
    ));
  }

  /// Get development logs for a plugin
  List<String> getPluginLogs(String pluginId) {
    _ensureInitialized();
    return _pluginLogs[pluginId] ?? [];
  }

  /// Get development metrics for a plugin
  Map<String, dynamic> getPluginMetrics(String pluginId) {
    _ensureInitialized();
    return _pluginMetrics[pluginId] ?? {};
  }

  /// Add log entry for a plugin
  void addPluginLog(String pluginId, String logEntry) {
    if (!_isDevelopmentModeEnabled) return;
    
    final logs = _pluginLogs[pluginId] ?? [];
    logs.add('[${DateTime.now().toIso8601String()}] $logEntry');
    _pluginLogs[pluginId] = logs;
    
    // Keep only last 1000 log entries to prevent memory issues
    if (logs.length > 1000) {
      logs.removeRange(0, logs.length - 1000);
    }
  }

  /// Update plugin metrics
  void updatePluginMetrics(String pluginId, String metricName, dynamic value) {
    if (!_isDevelopmentModeEnabled) return;
    
    final metrics = _pluginMetrics[pluginId] ?? {};
    metrics[metricName] = value;
    metrics['lastUpdated'] = DateTime.now().toIso8601String();
    _pluginMetrics[pluginId] = metrics;
  }

  /// Dispose the development mode manager
  Future<void> dispose() async {
    await shutdown();
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('DevelopmentModeManager not initialized. Call initialize() first.');
    }
  }

  Future<DevelopmentEnvironment> _detectDevelopmentEnvironment() async {
    final platformEnv = PlatformEnvironment.instance;
    final environmentVariables = platformEnv.getAllVariables();
    final developmentIndicators = <String>[];
    
    // Check for common development environment indicators
    bool isDevelopment = false;
    
    // Log platform detection
    if (kDebugMode) {
      print('[DevelopmentModeManager] Detecting environment on ${platformEnv.isWeb ? "web" : "native"} platform');
    }
    
    // Check environment variables (native platforms only)
    if (!platformEnv.isWeb) {
      if (platformEnv.getVariable('FLUTTER_ENV') == 'development' ||
          platformEnv.getVariable('NODE_ENV') == 'development' ||
          platformEnv.getVariable('ENV') == 'development' ||
          platformEnv.getVariable('ENVIRONMENT') == 'development') {
        isDevelopment = true;
        developmentIndicators.add('Environment variable indicates development');
        if (kDebugMode) {
          print('[DevelopmentModeManager] Development mode detected via environment variable');
        }
      }
      
      // Check for debug mode
      if (platformEnv.getVariable('FLUTTER_DEBUG') == 'true') {
        isDevelopment = true;
        developmentIndicators.add('Flutter debug mode enabled');
        if (kDebugMode) {
          print('[DevelopmentModeManager] Flutter debug mode enabled via environment');
        }
      }
      
      // Check for development tools
      if (platformEnv.containsKey('FLUTTER_ROOT') ||
          platformEnv.containsKey('DART_SDK')) {
        developmentIndicators.add('Flutter/Dart SDK detected');
        if (kDebugMode) {
          print('[DevelopmentModeManager] Flutter/Dart SDK detected in environment');
        }
      }
      
      // Check for IDE indicators
      if (platformEnv.containsKey('VSCODE_PID') ||
          platformEnv.containsKey('INTELLIJ_ENVIRONMENT_READER')) {
        developmentIndicators.add('IDE environment detected');
        if (kDebugMode) {
          print('[DevelopmentModeManager] IDE environment detected');
        }
      }
      
      // Check for debugger
      final dartVmOptions = platformEnv.getVariable('DART_VM_OPTIONS');
      if (dartVmOptions != null && dartVmOptions.contains('--enable-vm-service')) {
        isDevelopment = true;
        developmentIndicators.add('Dart VM service enabled');
        if (kDebugMode) {
          print('[DevelopmentModeManager] Dart VM service enabled');
        }
      }
      
      // If no explicit indicators, check for common development patterns
      if (!isDevelopment) {
        // Check if running from source (common in development)
        try {
          final executable = Platform.resolvedExecutable;
          if (executable.contains('flutter') || executable.contains('dart')) {
            isDevelopment = true;
            developmentIndicators.add('Running from Flutter/Dart executable');
            if (kDebugMode) {
              print('[DevelopmentModeManager] Running from Flutter/Dart executable');
            }
          }
        } catch (e) {
          // Platform.resolvedExecutable may not be available on all platforms
          if (kDebugMode) {
            print('[DevelopmentModeManager] Could not check executable path: $e');
          }
        }
      }
    }
    
    // Alternative development indicators for web platform
    if (platformEnv.isWeb) {
      developmentIndicators.add('Running on web platform');
      
      // Check Flutter's debug mode constant (works on all platforms)
      if (kDebugMode) {
        isDevelopment = true;
        developmentIndicators.add('Flutter kDebugMode is true');
        print('[DevelopmentModeManager] Development mode detected via kDebugMode on web');
      }
      
      // Check for localhost/development URLs (web-specific indicator)
      try {
        // In a real web environment, we could check window.location
        // For now, we rely on kDebugMode as the primary indicator
        developmentIndicators.add('Using kDebugMode for web development detection');
      } catch (e) {
        if (kDebugMode) {
          print('[DevelopmentModeManager] Could not check web-specific indicators: $e');
        }
      }
    }
    
    final environment = isDevelopment ? 'development' : 'production';
    
    // Log final detection result
    if (kDebugMode) {
      print('[DevelopmentModeManager] Environment detected: $environment');
      print('[DevelopmentModeManager] Development indicators: ${developmentIndicators.join(", ")}');
    }
    
    return DevelopmentEnvironment(
      isDevelopment: isDevelopment,
      environment: environment,
      environmentVariables: environmentVariables,
      developmentIndicators: developmentIndicators,
    );
  }

  Future<void> _configureEnhancedLogging() async {
    // Configure enhanced logging based on development logging config
    if (_loggingConfig.enableVerboseLogging) {
      // Enable verbose logging for all categories
      for (final category in _loggingConfig.logCategories) {
        await _enableCategoryLogging(category, _loggingConfig.logLevel);
      }
    }
    
    if (_loggingConfig.enablePluginTracing) {
      // Enable plugin execution tracing
      await _enablePluginTracing();
    }
    
    if (_loggingConfig.enablePerformanceMetrics) {
      // Enable performance metrics collection
      await _enablePerformanceMetrics();
    }
    
    if (_loggingConfig.enableMemoryTracking) {
      // Enable memory usage tracking
      await _enableMemoryTracking();
    }
  }

  Future<void> _enableDebuggingFeatures() async {
    // Enable debugging features based on configuration
    if (_debuggingFeatures.enableBreakpoints) {
      await _enableBreakpoints();
    }
    
    if (_debuggingFeatures.enableStepDebugging) {
      await _enableStepDebugging();
    }
    
    if (_debuggingFeatures.enableVariableInspection) {
      await _enableVariableInspection();
    }
    
    if (_debuggingFeatures.enableCallStackTracing) {
      await _enableCallStackTracing();
    }
    
    if (_debuggingFeatures.enableLiveReload) {
      await _enableLiveReload();
    }
  }

  Future<void> _disableDebuggingFeatures() async {
    // Disable all debugging features
    await _disableBreakpoints();
    await _disableStepDebugging();
    await _disableVariableInspection();
    await _disableCallStackTracing();
    await _disableLiveReload();
  }

  Future<void> _resetLoggingToProduction() async {
    // Reset logging to production levels
    await _disableVerboseLogging();
    await _disablePluginTracing();
    await _disablePerformanceMetrics();
    await _disableMemoryTracking();
  }

  Future<void> _startPluginMonitoring(String pluginId) async {
    // Start enhanced monitoring for plugin development
    addPluginLog(pluginId, 'Started development monitoring');
    updatePluginMetrics(pluginId, 'monitoringStarted', DateTime.now().toIso8601String());
  }

  Future<void> _stopPluginMonitoring(String pluginId) async {
    // Stop plugin monitoring
    addPluginLog(pluginId, 'Stopped development monitoring');
  }

  Future<Map<String, dynamic>> _generateDevelopmentReport(String pluginId) async {
    final startTime = _pluginStartTimes[pluginId];
    final endTime = DateTime.now();
    final duration = startTime != null ? endTime.difference(startTime) : Duration.zero;
    
    return {
      'pluginId': pluginId,
      'sessionDuration': duration.inMilliseconds,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'logEntries': _pluginLogs[pluginId]?.length ?? 0,
      'metrics': _pluginMetrics[pluginId] ?? {},
    };
  }

  // Placeholder methods for logging and debugging features
  // These would be implemented with actual logging and debugging infrastructure

  Future<void> _enableCategoryLogging(String category, String level) async {
    // Implementation would configure actual logging system
  }

  Future<void> _enablePluginTracing() async {
    // Implementation would enable plugin execution tracing
  }

  Future<void> _enablePerformanceMetrics() async {
    // Implementation would enable performance metrics collection
  }

  Future<void> _enableMemoryTracking() async {
    // Implementation would enable memory usage tracking
  }

  Future<void> _enableBreakpoints() async {
    // Implementation would enable breakpoint support
  }

  Future<void> _enableStepDebugging() async {
    // Implementation would enable step debugging
  }

  Future<void> _enableVariableInspection() async {
    // Implementation would enable variable inspection
  }

  Future<void> _enableCallStackTracing() async {
    // Implementation would enable call stack tracing
  }

  Future<void> _enableLiveReload() async {
    // Implementation would enable live reload functionality
  }

  Future<void> _disableBreakpoints() async {
    // Implementation would disable breakpoint support
  }

  Future<void> _disableStepDebugging() async {
    // Implementation would disable step debugging
  }

  Future<void> _disableVariableInspection() async {
    // Implementation would disable variable inspection
  }

  Future<void> _disableCallStackTracing() async {
    // Implementation would disable call stack tracing
  }

  Future<void> _disableLiveReload() async {
    // Implementation would disable live reload functionality
  }

  Future<void> _disableVerboseLogging() async {
    // Implementation would disable verbose logging
  }

  Future<void> _disablePluginTracing() async {
    // Implementation would disable plugin tracing
  }

  Future<void> _disablePerformanceMetrics() async {
    // Implementation would disable performance metrics
  }

  Future<void> _disableMemoryTracking() async {
    // Implementation would disable memory tracking
  }
}