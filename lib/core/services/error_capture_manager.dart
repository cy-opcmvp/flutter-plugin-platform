import 'dart:async';
import 'dart:io';

/// Exception thrown when error capture operations fail
class ErrorCaptureException implements Exception {
  final String message;
  final String? pluginId;
  final Exception? cause;

  const ErrorCaptureException(this.message, {this.pluginId, this.cause});

  @override
  String toString() => 'ErrorCaptureException: $message${pluginId != null ? ' (Plugin: $pluginId)' : ''}';
}

/// Severity levels for errors
enum ErrorSeverity {
  low,
  medium,
  high,
  critical
}

/// Types of errors that can be captured
enum ErrorType {
  pluginCrash,
  pluginException,
  ipcError,
  securityViolation,
  resourceExhaustion,
  networkError,
  fileSystemError,
  validationError,
  timeoutError,
  unknownError
}

/// Captured error information
class CapturedError {
  final String id;
  final String? pluginId;
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final List<String> breadcrumbs;
  final Map<String, dynamic> systemInfo;

  const CapturedError({
    required this.id,
    this.pluginId,
    required this.type,
    required this.severity,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    required this.context,
    required this.breadcrumbs,
    required this.systemInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pluginId': pluginId,
      'type': type.toString(),
      'severity': severity.toString(),
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'breadcrumbs': breadcrumbs,
      'systemInfo': systemInfo,
    };
  }

  factory CapturedError.fromJson(Map<String, dynamic> json) {
    return CapturedError(
      id: json['id'] as String,
      pluginId: json['pluginId'] as String?,
      type: ErrorType.values.firstWhere((e) => e.toString() == json['type']),
      severity: ErrorSeverity.values.firstWhere((e) => e.toString() == json['severity']),
      message: json['message'] as String,
      stackTrace: json['stackTrace'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as Map<String, dynamic>,
      breadcrumbs: List<String>.from(json['breadcrumbs'] as List),
      systemInfo: json['systemInfo'] as Map<String, dynamic>,
    );
  }
}

/// Crash report containing detailed information about a plugin crash
class CrashReport {
  final String id;
  final String pluginId;
  final DateTime crashTime;
  final String crashReason;
  final String? stackTrace;
  final Map<String, dynamic> pluginState;
  final Map<String, dynamic> systemState;
  final List<String> recentLogs;
  final Map<String, dynamic> performanceMetrics;
  final List<CapturedError> relatedErrors;

  const CrashReport({
    required this.id,
    required this.pluginId,
    required this.crashTime,
    required this.crashReason,
    this.stackTrace,
    required this.pluginState,
    required this.systemState,
    required this.recentLogs,
    required this.performanceMetrics,
    required this.relatedErrors,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pluginId': pluginId,
      'crashTime': crashTime.toIso8601String(),
      'crashReason': crashReason,
      'stackTrace': stackTrace,
      'pluginState': pluginState,
      'systemState': systemState,
      'recentLogs': recentLogs,
      'performanceMetrics': performanceMetrics,
      'relatedErrors': relatedErrors.map((e) => e.toJson()).toList(),
    };
  }
}

/// Debugging interface for external plugins
class DebugInterface {
  final String pluginId;
  final Map<String, dynamic> _debugData = {};
  final List<String> _debugLogs = [];
  final Map<String, dynamic> _breakpoints = {};
  final Map<String, dynamic> _watchedVariables = {};

  DebugInterface(this.pluginId);

  /// Add debug data
  void addDebugData(String key, dynamic value) {
    _debugData[key] = value;
  }

  /// Get debug data
  Map<String, dynamic> getDebugData() => Map.unmodifiable(_debugData);

  /// Add debug log
  void addDebugLog(String message) {
    _debugLogs.add('[${DateTime.now().toIso8601String()}] $message');
    
    // Keep only last 500 log entries
    if (_debugLogs.length > 500) {
      _debugLogs.removeRange(0, _debugLogs.length - 500);
    }
  }

  /// Get debug logs
  List<String> getDebugLogs() => List.unmodifiable(_debugLogs);

  /// Set breakpoint
  void setBreakpoint(String location, Map<String, dynamic> condition) {
    _breakpoints[location] = condition;
  }

  /// Remove breakpoint
  void removeBreakpoint(String location) {
    _breakpoints.remove(location);
  }

  /// Get breakpoints
  Map<String, dynamic> getBreakpoints() => Map.unmodifiable(_breakpoints);

  /// Watch variable
  void watchVariable(String name, dynamic value) {
    _watchedVariables[name] = {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get watched variables
  Map<String, dynamic> getWatchedVariables() => Map.unmodifiable(_watchedVariables);

  /// Clear all debug data
  void clear() {
    _debugData.clear();
    _debugLogs.clear();
    _breakpoints.clear();
    _watchedVariables.clear();
  }
}

/// Error capture and debugging manager
class ErrorCaptureManager {
  final StreamController<CapturedError> _errorController = StreamController<CapturedError>.broadcast();
  final StreamController<CrashReport> _crashController = StreamController<CrashReport>.broadcast();
  
  bool _isInitialized = false;
  bool _isErrorCaptureEnabled = false;
  final Map<String, CapturedError> _capturedErrors = {};
  final Map<String, CrashReport> _crashReports = {};
  final Map<String, DebugInterface> _debugInterfaces = {};
  final List<String> _systemBreadcrumbs = [];
  
  int _maxStoredErrors = 1000;
  int _maxStoredCrashes = 100;
  int _maxBreadcrumbs = 100;

  /// Initialize the error capture manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Set up global error handlers
    await _setupGlobalErrorHandlers();
    
    _isInitialized = true;
    _isErrorCaptureEnabled = true;
  }

  /// Shutdown the error capture manager
  Future<void> shutdown() async {
    if (!_isInitialized) return;
    
    await _errorController.close();
    await _crashController.close();
    
    _isInitialized = false;
    _isErrorCaptureEnabled = false;
  }

  /// Stream of captured errors
  Stream<CapturedError> get errorStream => _errorController.stream;

  /// Stream of crash reports
  Stream<CrashReport> get crashStream => _crashController.stream;

  /// Check if error capture is enabled
  bool get isErrorCaptureEnabled => _isErrorCaptureEnabled;

  /// Enable error capture
  void enableErrorCapture() {
    _isErrorCaptureEnabled = true;
  }

  /// Disable error capture
  void disableErrorCapture() {
    _isErrorCaptureEnabled = false;
  }

  /// Capture an error
  Future<String> captureError({
    String? pluginId,
    required ErrorType type,
    required ErrorSeverity severity,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? context,
    List<String>? breadcrumbs,
  }) async {
    _ensureInitialized();
    
    if (!_isErrorCaptureEnabled) return '';
    
    final errorId = _generateErrorId();
    final systemInfo = await _collectSystemInfo();
    
    final error = CapturedError(
      id: errorId,
      pluginId: pluginId,
      type: type,
      severity: severity,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context ?? {},
      breadcrumbs: breadcrumbs ?? List.from(_systemBreadcrumbs),
      systemInfo: systemInfo,
    );
    
    // Store error
    _capturedErrors[errorId] = error;
    
    // Maintain storage limits
    _maintainErrorStorageLimits();
    
    // Emit error event
    _errorController.add(error);
    
    // Add to system breadcrumbs
    _addSystemBreadcrumb('Error captured: ${error.type} - ${error.message}');
    
    return errorId;
  }

  /// Capture a plugin crash
  Future<String> captureCrash({
    required String pluginId,
    required String crashReason,
    String? stackTrace,
    Map<String, dynamic>? pluginState,
    List<String>? recentLogs,
    Map<String, dynamic>? performanceMetrics,
  }) async {
    _ensureInitialized();
    
    if (!_isErrorCaptureEnabled) return '';
    
    final crashId = _generateCrashId();
    final systemState = await _collectSystemInfo();
    
    // Get related errors for this plugin
    final relatedErrors = _capturedErrors.values
        .where((error) => error.pluginId == pluginId)
        .toList();
    
    final crashReport = CrashReport(
      id: crashId,
      pluginId: pluginId,
      crashTime: DateTime.now(),
      crashReason: crashReason,
      stackTrace: stackTrace,
      pluginState: pluginState ?? {},
      systemState: systemState,
      recentLogs: recentLogs ?? [],
      performanceMetrics: performanceMetrics ?? {},
      relatedErrors: relatedErrors,
    );
    
    // Store crash report
    _crashReports[crashId] = crashReport;
    
    // Maintain storage limits
    _maintainCrashStorageLimits();
    
    // Emit crash event
    _crashController.add(crashReport);
    
    // Add to system breadcrumbs
    _addSystemBreadcrumb('Plugin crash: $pluginId - $crashReason');
    
    return crashId;
  }

  /// Get debug interface for a plugin
  DebugInterface getDebugInterface(String pluginId) {
    _ensureInitialized();
    
    if (!_debugInterfaces.containsKey(pluginId)) {
      _debugInterfaces[pluginId] = DebugInterface(pluginId);
    }
    
    return _debugInterfaces[pluginId]!;
  }

  /// Remove debug interface for a plugin
  void removeDebugInterface(String pluginId) {
    _debugInterfaces.remove(pluginId);
  }

  /// Get all captured errors
  List<CapturedError> getCapturedErrors({String? pluginId}) {
    _ensureInitialized();
    
    if (pluginId != null) {
      return _capturedErrors.values
          .where((error) => error.pluginId == pluginId)
          .toList();
    }
    
    return _capturedErrors.values.toList();
  }

  /// Get all crash reports
  List<CrashReport> getCrashReports({String? pluginId}) {
    _ensureInitialized();
    
    if (pluginId != null) {
      return _crashReports.values
          .where((report) => report.pluginId == pluginId)
          .toList();
    }
    
    return _crashReports.values.toList();
  }

  /// Get error by ID
  CapturedError? getError(String errorId) {
    _ensureInitialized();
    return _capturedErrors[errorId];
  }

  /// Get crash report by ID
  CrashReport? getCrashReport(String crashId) {
    _ensureInitialized();
    return _crashReports[crashId];
  }

  /// Add system breadcrumb
  void addSystemBreadcrumb(String breadcrumb) {
    _systemBreadcrumbs.add('[${DateTime.now().toIso8601String()}] $breadcrumb');
    
    // Maintain breadcrumb limits
    if (_systemBreadcrumbs.length > _maxBreadcrumbs) {
      _systemBreadcrumbs.removeRange(0, _systemBreadcrumbs.length - _maxBreadcrumbs);
    }
  }

  /// Get system breadcrumbs
  List<String> getSystemBreadcrumbs() => List.unmodifiable(_systemBreadcrumbs);

  /// Clear all captured data
  void clearAll() {
    _ensureInitialized();
    
    _capturedErrors.clear();
    _crashReports.clear();
    _debugInterfaces.clear();
    _systemBreadcrumbs.clear();
  }

  /// Clear data for a specific plugin
  void clearPluginData(String pluginId) {
    _ensureInitialized();
    
    // Remove errors for this plugin
    _capturedErrors.removeWhere((key, error) => error.pluginId == pluginId);
    
    // Remove crash reports for this plugin
    _crashReports.removeWhere((key, report) => report.pluginId == pluginId);
    
    // Remove debug interface for this plugin
    _debugInterfaces.remove(pluginId);
  }

  /// Export error data for analysis
  Future<Map<String, dynamic>> exportErrorData({String? pluginId}) async {
    _ensureInitialized();
    
    final errors = getCapturedErrors(pluginId: pluginId);
    final crashes = getCrashReports(pluginId: pluginId);
    
    return {
      'exportTime': DateTime.now().toIso8601String(),
      'pluginId': pluginId,
      'errors': errors.map((e) => e.toJson()).toList(),
      'crashes': crashes.map((c) => c.toJson()).toList(),
      'systemBreadcrumbs': _systemBreadcrumbs,
      'debugInterfaces': _debugInterfaces.map((key, value) => MapEntry(
        key,
        {
          'debugData': value.getDebugData(),
          'debugLogs': value.getDebugLogs(),
          'breakpoints': value.getBreakpoints(),
          'watchedVariables': value.getWatchedVariables(),
        },
      )),
    };
  }

  /// Configure storage limits
  void configureStorageLimits({
    int? maxStoredErrors,
    int? maxStoredCrashes,
    int? maxBreadcrumbs,
  }) {
    if (maxStoredErrors != null) _maxStoredErrors = maxStoredErrors;
    if (maxStoredCrashes != null) _maxStoredCrashes = maxStoredCrashes;
    if (maxBreadcrumbs != null) _maxBreadcrumbs = maxBreadcrumbs;
  }

  /// Dispose the error capture manager
  Future<void> dispose() async {
    await shutdown();
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ErrorCaptureManager not initialized. Call initialize() first.');
    }
  }

  Future<void> _setupGlobalErrorHandlers() async {
    // Set up global error handlers for uncaught exceptions
    // This would integrate with Flutter's error handling system
  }

  String _generateErrorId() {
    return 'error_${DateTime.now().millisecondsSinceEpoch}_${_capturedErrors.length}';
  }

  String _generateCrashId() {
    return 'crash_${DateTime.now().millisecondsSinceEpoch}_${_crashReports.length}';
  }

  Future<Map<String, dynamic>> _collectSystemInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'memoryUsage': _getMemoryUsage(),
      'cpuUsage': _getCpuUsage(),
    };
  }

  Map<String, dynamic> _getMemoryUsage() {
    // In a real implementation, this would collect actual memory usage
    return {
      'used': 0,
      'available': 0,
      'total': 0,
    };
  }

  Map<String, dynamic> _getCpuUsage() {
    // In a real implementation, this would collect actual CPU usage
    return {
      'percentage': 0.0,
      'cores': Platform.numberOfProcessors,
    };
  }

  void _addSystemBreadcrumb(String breadcrumb) {
    addSystemBreadcrumb(breadcrumb);
  }

  void _maintainErrorStorageLimits() {
    if (_capturedErrors.length > _maxStoredErrors) {
      // Remove oldest errors
      final sortedErrors = _capturedErrors.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedErrors.take(_capturedErrors.length - _maxStoredErrors);
      for (final entry in toRemove) {
        _capturedErrors.remove(entry.key);
      }
    }
  }

  void _maintainCrashStorageLimits() {
    if (_crashReports.length > _maxStoredCrashes) {
      // Remove oldest crash reports
      final sortedCrashes = _crashReports.entries.toList()
        ..sort((a, b) => a.value.crashTime.compareTo(b.value.crashTime));
      
      final toRemove = sortedCrashes.take(_crashReports.length - _maxStoredCrashes);
      for (final entry in toRemove) {
        _crashReports.remove(entry.key);
      }
    }
  }
}