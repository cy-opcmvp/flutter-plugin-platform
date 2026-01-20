import 'dart:async';
import 'dart:collection';
import '../models/plugin_models.dart';
import '../models/external_plugin_models.dart';

/// Comprehensive security monitoring system for external plugins
class SecurityMonitor {
  final Map<String, List<SecurityEvent>> _pluginEvents = {};
  final Map<String, SecurityProfile> _pluginProfiles = {};
  final Queue<SecurityEvent> _recentEvents = Queue<SecurityEvent>();
  final StreamController<SecurityAlert> _alertController =
      StreamController<SecurityAlert>.broadcast();

  // Configuration
  final int _maxRecentEvents = 1000;
  final Duration _alertCooldown = const Duration(minutes: 5);
  final Map<String, DateTime> _lastAlerts = {};

  // Threat detection patterns
  final List<ThreatPattern> _threatPatterns = [];

  SecurityMonitor() {
    _initializeThreatPatterns();
  }

  /// Stream of security alerts
  Stream<SecurityAlert> get alerts => _alertController.stream;

  /// Start monitoring a plugin
  void startMonitoring(String pluginId, SecurityLevel securityLevel) {
    _pluginEvents[pluginId] = [];
    _pluginProfiles[pluginId] = SecurityProfile(
      pluginId: pluginId,
      securityLevel: securityLevel,
      startTime: DateTime.now(),
    );
  }

  /// Stop monitoring a plugin
  void stopMonitoring(String pluginId) {
    _pluginEvents.remove(pluginId);
    _pluginProfiles.remove(pluginId);
    _lastAlerts.remove(pluginId);
  }

  /// Log a security event
  void logSecurityEvent(SecurityEvent event) {
    // Add to plugin-specific events
    _pluginEvents.putIfAbsent(event.pluginId, () => []).add(event);

    // Add to recent events queue
    _recentEvents.add(event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }

    // Update plugin profile
    _updatePluginProfile(event);

    // Analyze for threats
    _analyzeThreatPatterns(event);

    // Check for immediate alerts
    _checkImmediateAlerts(event);
  }

  /// Log access violation
  void logAccessViolation(
    String pluginId,
    Permission permission,
    String resource,
    String reason,
  ) {
    final event = SecurityEvent(
      pluginId: pluginId,
      type: SecurityEventType.accessViolation,
      severity: SecuritySeverity.medium,
      description: 'Access violation: $reason',
      metadata: {
        'permission': permission.name,
        'resource': resource,
        'reason': reason,
      },
    );

    logSecurityEvent(event);
  }

  /// Log resource limit violation
  void logResourceViolation(
    String pluginId,
    String resourceType,
    double usage,
    double limit,
  ) {
    final event = SecurityEvent(
      pluginId: pluginId,
      type: SecurityEventType.resourceViolation,
      severity: SecuritySeverity.high,
      description: 'Resource limit exceeded: $resourceType',
      metadata: {
        'resourceType': resourceType,
        'usage': usage.toString(),
        'limit': limit.toString(),
        'percentage': ((usage / limit) * 100).toStringAsFixed(1),
      },
    );

    logSecurityEvent(event);
  }

  /// Log suspicious behavior
  void logSuspiciousBehavior(
    String pluginId,
    String behavior,
    Map<String, dynamic> details,
  ) {
    final event = SecurityEvent(
      pluginId: pluginId,
      type: SecurityEventType.suspiciousBehavior,
      severity: SecuritySeverity.high,
      description: 'Suspicious behavior detected: $behavior',
      metadata: details,
    );

    logSecurityEvent(event);
  }

  /// Log security policy violation
  void logPolicyViolation(String pluginId, String policy, String details) {
    final event = SecurityEvent(
      pluginId: pluginId,
      type: SecurityEventType.policyViolation,
      severity: SecuritySeverity.medium,
      description: 'Security policy violation: $policy',
      metadata: {'policy': policy, 'details': details},
    );

    logSecurityEvent(event);
  }

  /// Get security events for a plugin
  List<SecurityEvent> getPluginEvents(String pluginId, {int? limit}) {
    final events = _pluginEvents[pluginId] ?? [];
    if (limit != null && events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return List.from(events);
  }

  /// Get security profile for a plugin
  SecurityProfile? getPluginProfile(String pluginId) {
    return _pluginProfiles[pluginId];
  }

  /// Get recent security events across all plugins
  List<SecurityEvent> getRecentEvents({int? limit}) {
    final events = _recentEvents.toList();
    if (limit != null && events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Generate security report for a plugin
  SecurityReport generatePluginReport(String pluginId) {
    final profile = _pluginProfiles[pluginId];
    final events = _pluginEvents[pluginId] ?? [];

    if (profile == null) {
      throw ArgumentError('Plugin $pluginId is not being monitored');
    }

    return SecurityReport(
      pluginId: pluginId,
      profile: profile,
      events: events,
      generatedAt: DateTime.now(),
      summary: _generateEventSummary(events),
      riskScore: _calculateRiskScore(events, profile),
      recommendations: _generateRecommendations(events, profile),
    );
  }

  /// Generate system-wide security report
  SecuritySystemReport generateSystemReport() {
    final allEvents = _recentEvents.toList();
    final pluginReports = <String, SecurityReport>{};

    for (final pluginId in _pluginProfiles.keys) {
      pluginReports[pluginId] = generatePluginReport(pluginId);
    }

    return SecuritySystemReport(
      generatedAt: DateTime.now(),
      totalEvents: allEvents.length,
      pluginReports: pluginReports,
      systemRiskScore: _calculateSystemRiskScore(pluginReports.values.toList()),
      topThreats: _identifyTopThreats(allEvents),
      recommendations: _generateSystemRecommendations(
        pluginReports.values.toList(),
      ),
    );
  }

  /// Check if plugin behavior is suspicious
  bool isPluginSuspicious(String pluginId) {
    final profile = _pluginProfiles[pluginId];
    if (profile == null) return false;

    return profile.riskScore > 70.0 || profile.violationCount > 10;
  }

  /// Quarantine a plugin (mark as high risk)
  void quarantinePlugin(String pluginId, String reason) {
    final profile = _pluginProfiles[pluginId];
    if (profile != null) {
      profile.isQuarantined = true;
      profile.quarantineReason = reason;

      final alert = SecurityAlert(
        pluginId: pluginId,
        type: SecurityAlertType.pluginQuarantined,
        severity: SecuritySeverity.critical,
        message: 'Plugin quarantined: $reason',
        timestamp: DateTime.now(),
      );

      _alertController.add(alert);
    }
  }

  /// Release plugin from quarantine
  void releaseFromQuarantine(String pluginId) {
    final profile = _pluginProfiles[pluginId];
    if (profile != null) {
      profile.isQuarantined = false;
      profile.quarantineReason = null;
    }
  }

  /// Dispose of the security monitor
  void dispose() {
    _alertController.close();
  }

  // Private helper methods

  /// Initialize threat detection patterns
  void _initializeThreatPatterns() {
    // Rapid access violation pattern
    _threatPatterns.add(
      ThreatPattern(
        name: 'Rapid Access Violations',
        description: 'Multiple access violations in short time',
        detector: (events) {
          final recentViolations = events
              .where((e) => e.type == SecurityEventType.accessViolation)
              .where(
                (e) =>
                    DateTime.now().difference(e.timestamp) <
                    const Duration(minutes: 1),
              )
              .length;
          return recentViolations >= 5;
        },
        severity: SecuritySeverity.high,
      ),
    );

    // Resource exhaustion pattern
    _threatPatterns.add(
      ThreatPattern(
        name: 'Resource Exhaustion',
        description: 'Repeated resource limit violations',
        detector: (events) {
          final resourceViolations = events
              .where((e) => e.type == SecurityEventType.resourceViolation)
              .where(
                (e) =>
                    DateTime.now().difference(e.timestamp) <
                    const Duration(minutes: 5),
              )
              .length;
          return resourceViolations >= 3;
        },
        severity: SecuritySeverity.critical,
      ),
    );

    // Privilege escalation pattern
    _threatPatterns.add(
      ThreatPattern(
        name: 'Privilege Escalation',
        description: 'Attempts to access higher privilege resources',
        detector: (events) {
          final systemAccess = events
              .where((e) => e.type == SecurityEventType.accessViolation)
              .where(
                (e) =>
                    e.metadata['resource']?.toString().contains('/system/') ??
                    false,
              )
              .length;
          return systemAccess >= 3;
        },
        severity: SecuritySeverity.critical,
      ),
    );
  }

  /// Update plugin security profile
  void _updatePluginProfile(SecurityEvent event) {
    final profile = _pluginProfiles[event.pluginId];
    if (profile == null) return;

    profile.totalEvents++;
    profile.lastActivity = event.timestamp;

    switch (event.type) {
      case SecurityEventType.accessViolation:
        profile.violationCount++;
        break;
      case SecurityEventType.resourceViolation:
        profile.resourceViolations++;
        break;
      case SecurityEventType.suspiciousBehavior:
        profile.suspiciousActivities++;
        break;
      case SecurityEventType.policyViolation:
        profile.policyViolations++;
        break;
    }

    // Update risk score
    profile.riskScore = _calculatePluginRiskScore(profile);
  }

  /// Analyze events for threat patterns
  void _analyzeThreatPatterns(SecurityEvent event) {
    final pluginEvents = _pluginEvents[event.pluginId] ?? [];

    for (final pattern in _threatPatterns) {
      if (pattern.detector(pluginEvents)) {
        _triggerThreatAlert(event.pluginId, pattern);
      }
    }
  }

  /// Check for immediate security alerts
  void _checkImmediateAlerts(SecurityEvent event) {
    // Critical severity events trigger immediate alerts
    if (event.severity == SecuritySeverity.critical) {
      final alert = SecurityAlert(
        pluginId: event.pluginId,
        type: SecurityAlertType.criticalEvent,
        severity: event.severity,
        message: 'Critical security event: ${event.description}',
        timestamp: event.timestamp,
        relatedEvent: event,
      );

      _alertController.add(alert);
    }

    // Multiple violations in short time
    final recentViolations = (_pluginEvents[event.pluginId] ?? [])
        .where(
          (e) =>
              DateTime.now().difference(e.timestamp) <
              const Duration(minutes: 1),
        )
        .length;

    if (recentViolations >= 5) {
      _triggerAlert(
        event.pluginId,
        SecurityAlertType.rapidViolations,
        'Multiple security violations detected',
      );
    }
  }

  /// Trigger a threat pattern alert
  void _triggerThreatAlert(String pluginId, ThreatPattern pattern) {
    final lastAlert = _lastAlerts[pluginId];
    if (lastAlert != null &&
        DateTime.now().difference(lastAlert) < _alertCooldown) {
      return; // Cooldown period
    }

    final alert = SecurityAlert(
      pluginId: pluginId,
      type: SecurityAlertType.threatDetected,
      severity: pattern.severity,
      message: 'Threat detected: ${pattern.name} - ${pattern.description}',
      timestamp: DateTime.now(),
    );

    _alertController.add(alert);
    _lastAlerts[pluginId] = DateTime.now();
  }

  /// Trigger a general security alert
  void _triggerAlert(String pluginId, SecurityAlertType type, String message) {
    final alert = SecurityAlert(
      pluginId: pluginId,
      type: type,
      severity: SecuritySeverity.high,
      message: message,
      timestamp: DateTime.now(),
    );

    _alertController.add(alert);
  }

  /// Calculate risk score for a plugin
  double _calculatePluginRiskScore(SecurityProfile profile) {
    double score = 0.0;

    // Base score from violations
    score += profile.violationCount * 5.0;
    score += profile.resourceViolations * 10.0;
    score += profile.suspiciousActivities * 15.0;
    score += profile.policyViolations * 8.0;

    // Time-based decay (older violations matter less)
    final daysSinceStart = DateTime.now().difference(profile.startTime).inDays;
    if (daysSinceStart > 0) {
      score = score / (1 + daysSinceStart * 0.1);
    }

    // Security level adjustment
    switch (profile.securityLevel) {
      case SecurityLevel.isolated:
        score *= 0.5; // Lower risk due to isolation
        break;
      case SecurityLevel.strict:
        score *= 0.7;
        break;
      case SecurityLevel.standard:
        score *= 1.0;
        break;
      case SecurityLevel.minimal:
        score *= 1.5; // Higher risk due to minimal restrictions
        break;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Calculate system-wide risk score
  double _calculateSystemRiskScore(List<SecurityReport> reports) {
    if (reports.isEmpty) return 0.0;

    final totalScore = reports.fold(
      0.0,
      (sum, report) => sum + report.riskScore,
    );
    return totalScore / reports.length;
  }

  /// Calculate risk score from events
  double _calculateRiskScore(
    List<SecurityEvent> events,
    SecurityProfile profile,
  ) {
    return _calculatePluginRiskScore(profile);
  }

  /// Generate event summary
  Map<String, int> _generateEventSummary(List<SecurityEvent> events) {
    final summary = <String, int>{};

    for (final event in events) {
      final key = event.type.name;
      summary[key] = (summary[key] ?? 0) + 1;
    }

    return summary;
  }

  /// Generate recommendations for a plugin
  List<String> _generateRecommendations(
    List<SecurityEvent> events,
    SecurityProfile profile,
  ) {
    final recommendations = <String>[];

    if (profile.violationCount > 5) {
      recommendations.add(
        'Consider reviewing plugin permissions - high violation count detected',
      );
    }

    if (profile.resourceViolations > 2) {
      recommendations.add(
        'Adjust resource limits or monitor plugin resource usage',
      );
    }

    if (profile.suspiciousActivities > 0) {
      recommendations.add(
        'Investigate suspicious activities and consider stricter security level',
      );
    }

    if (profile.riskScore > 50.0) {
      recommendations.add(
        'High risk score detected - consider quarantining plugin',
      );
    }

    return recommendations;
  }

  /// Generate system-wide recommendations
  List<String> _generateSystemRecommendations(List<SecurityReport> reports) {
    final recommendations = <String>[];

    final highRiskPlugins = reports.where((r) => r.riskScore > 70.0).length;
    if (highRiskPlugins > 0) {
      recommendations.add(
        '$highRiskPlugins high-risk plugins detected - review security policies',
      );
    }

    final totalViolations = reports.fold(
      0,
      (sum, r) => sum + r.profile.violationCount,
    );
    if (totalViolations > 50) {
      recommendations.add(
        'High system-wide violation count - consider tightening security',
      );
    }

    return recommendations;
  }

  /// Identify top threats from events
  List<String> _identifyTopThreats(List<SecurityEvent> events) {
    final threatCounts = <String, int>{};

    for (final event in events) {
      if (event.severity == SecuritySeverity.high ||
          event.severity == SecuritySeverity.critical) {
        final threat = event.type.name;
        threatCounts[threat] = (threatCounts[threat] ?? 0) + 1;
      }
    }

    final sortedThreats = threatCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedThreats
        .take(5)
        .map((e) => '${e.key} (${e.value} occurrences)')
        .toList();
  }
}

/// Security event logged by the monitor
class SecurityEvent {
  final String pluginId;
  final SecurityEventType type;
  final SecuritySeverity severity;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  SecurityEvent({
    required this.pluginId,
    required this.type,
    required this.severity,
    required this.description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) : timestamp = timestamp ?? DateTime.now(),
       metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      pluginId: json['pluginId'] as String,
      type: SecurityEventType.values.firstWhere((e) => e.name == json['type']),
      severity: SecuritySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Security profile for a plugin
class SecurityProfile {
  final String pluginId;
  final SecurityLevel securityLevel;
  final DateTime startTime;

  DateTime lastActivity;
  int totalEvents = 0;
  int violationCount = 0;
  int resourceViolations = 0;
  int suspiciousActivities = 0;
  int policyViolations = 0;
  double riskScore = 0.0;
  bool isQuarantined = false;
  String? quarantineReason;

  SecurityProfile({
    required this.pluginId,
    required this.securityLevel,
    required this.startTime,
  }) : lastActivity = startTime;

  Duration get uptime => DateTime.now().difference(startTime);
  Duration get timeSinceLastActivity => DateTime.now().difference(lastActivity);
}

/// Security alert generated by the monitor
class SecurityAlert {
  final String pluginId;
  final SecurityAlertType type;
  final SecuritySeverity severity;
  final String message;
  final DateTime timestamp;
  final SecurityEvent? relatedEvent;

  SecurityAlert({
    required this.pluginId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.relatedEvent,
  });
}

/// Security report for a plugin
class SecurityReport {
  final String pluginId;
  final SecurityProfile profile;
  final List<SecurityEvent> events;
  final DateTime generatedAt;
  final Map<String, int> summary;
  final double riskScore;
  final List<String> recommendations;

  SecurityReport({
    required this.pluginId,
    required this.profile,
    required this.events,
    required this.generatedAt,
    required this.summary,
    required this.riskScore,
    required this.recommendations,
  });
}

/// System-wide security report
class SecuritySystemReport {
  final DateTime generatedAt;
  final int totalEvents;
  final Map<String, SecurityReport> pluginReports;
  final double systemRiskScore;
  final List<String> topThreats;
  final List<String> recommendations;

  SecuritySystemReport({
    required this.generatedAt,
    required this.totalEvents,
    required this.pluginReports,
    required this.systemRiskScore,
    required this.topThreats,
    required this.recommendations,
  });
}

/// Threat detection pattern
class ThreatPattern {
  final String name;
  final String description;
  final bool Function(List<SecurityEvent>) detector;
  final SecuritySeverity severity;

  ThreatPattern({
    required this.name,
    required this.description,
    required this.detector,
    required this.severity,
  });
}

/// Types of security events
enum SecurityEventType {
  accessViolation,
  resourceViolation,
  suspiciousBehavior,
  policyViolation,
}

/// Security event severity levels
enum SecuritySeverity { low, medium, high, critical }

/// Types of security alerts
enum SecurityAlertType {
  criticalEvent,
  rapidViolations,
  threatDetected,
  pluginQuarantined,
  systemCompromise,
}
