import 'package:flutter/material.dart';
import '../../core/interfaces/i_external_plugin.dart';
import '../../core/models/external_plugin_models.dart';
import '../../core/models/plugin_models.dart';
import 'web_view_container.dart';
import 'executable_output_capture.dart';
import 'plugin_theme_manager.dart';
import 'plugin_input_router.dart';

/// Container widget for embedding different types of external plugin UIs
/// Implements requirements 5.1, 5.2, 5.3
class PluginUIContainer extends StatefulWidget {
  final IExternalPlugin plugin;
  final VoidCallback? onClose;
  final Function(String)? onError;

  const PluginUIContainer({
    super.key,
    required this.plugin,
    this.onClose,
    this.onError,
  });

  @override
  State<PluginUIContainer> createState() => _PluginUIContainerState();
}

class _PluginUIContainerState extends State<PluginUIContainer> {
  bool _isLoading = true;
  String? _error;
  Widget? _pluginWidget;

  @override
  void initState() {
    super.initState();
    _initializePluginUI();
  }

  /// Initialize the appropriate UI container based on plugin type
  Future<void> _initializePluginUI() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Ensure plugin is running
      if (!widget.plugin.isRunning) {
        await widget.plugin.launch();
      }

      // Create appropriate UI container based on plugin runtime type
      switch (widget.plugin.pluginRuntimeType) {
        case PluginRuntimeType.webApp:
          _pluginWidget = await _createWebViewContainer();
          break;
        case PluginRuntimeType.executable:
        case PluginRuntimeType.native:
        case PluginRuntimeType.script:
          _pluginWidget = await _createExecutableOutputCapture();
          break;
        case PluginRuntimeType.container:
          _pluginWidget = await _createContainerUI();
          break;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize plugin UI: $e';
        _isLoading = false;
      });
      widget.onError?.call(_error!);
    }
  }

  /// Create web view container for web-based plugins
  Future<Widget> _createWebViewContainer() async {
    final uiConfig = widget.plugin.manifest.uiIntegration;
    final webConfig = uiConfig.containerConfig;
    
    return WebViewContainer(
      plugin: widget.plugin,
      initialUrl: webConfig['entryUrl'] as String? ?? 'about:blank',
      securityRestrictions: _getSecurityRestrictions(),
      onPageFinished: (url) {
        // Plugin UI loaded successfully
      },
      onWebResourceError: (error) {
        setState(() {
          _error = 'Web plugin error: ${error.description}';
        });
        widget.onError?.call(_error!);
      },
    );
  }

  /// Create executable output capture for native plugins
  Future<Widget> _createExecutableOutputCapture() async {
    return ExecutableOutputCapture(
      plugin: widget.plugin,
      captureStdout: true,
      captureStderr: true,
      onOutput: (output) {
        // Handle plugin output
      },
      onError: (error) {
        setState(() {
          _error = 'Plugin execution error: $error';
        });
        widget.onError?.call(_error!);
      },
    );
  }

  /// Create container UI for containerized plugins
  Future<Widget> _createContainerUI() async {
    // For container plugins, we typically expose a web interface
    // or use a specialized container UI
    final uiConfig = widget.plugin.manifest.uiIntegration;
    final containerConfig = uiConfig.containerConfig;
    
    if (containerConfig['uiType'] == 'web') {
      return WebViewContainer(
        plugin: widget.plugin,
        initialUrl: containerConfig['webUrl'] as String,
        securityRestrictions: _getSecurityRestrictions(),
        onPageFinished: (url) {
          // Container UI loaded successfully
        },
        onWebResourceError: (error) {
          setState(() {
            _error = 'Container UI error: ${error.description}';
          });
          widget.onError?.call(_error!);
        },
      );
    } else {
      // Use executable output capture for non-web container UIs
      return ExecutableOutputCapture(
        plugin: widget.plugin,
        captureStdout: true,
        captureStderr: true,
        onOutput: (output) {
          // Handle container output
        },
        onError: (error) {
          setState(() {
            _error = 'Container error: $error';
          });
          widget.onError?.call(_error!);
        },
      );
    }
  }

  /// Get security restrictions based on plugin security level
  Map<String, dynamic> _getSecurityRestrictions() {
    final securityLevel = widget.plugin.securityLevel;
    final securityReqs = widget.plugin.manifest.security;
    
    return {
      'allowedDomains': securityReqs.allowedDomains,
      'blockedDomains': securityReqs.blockedDomains,
      'allowJavaScript': securityLevel != SecurityLevel.isolated,
      'allowLocalStorage': securityLevel == SecurityLevel.minimal || 
                          securityLevel == SecurityLevel.standard,
      'allowGeolocation': false,
      'allowCamera': widget.plugin.requiredPermissions.contains(Permission.systemCamera),
      'allowMicrophone': widget.plugin.requiredPermissions.contains(Permission.systemMicrophone),
      'allowNotifications': widget.plugin.requiredPermissions.contains(Permission.systemNotifications),
    };
  }

  @override
  void dispose() {
    // Clean up plugin UI resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = PluginThemeManager();
    
    return themeManager.createThemedWrapper(
      plugin: widget.plugin,
      child: PluginInputRouter(
        plugin: widget.plugin,
        onInputEvent: (event) {
          // Handle input events if needed
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_pluginWidget != null) {
      return _pluginWidget!;
    }

    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading ${widget.plugin.name}...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Plugin Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _initializePluginUI,
                  child: Text('Retry'),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: widget.onClose,
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Plugin UI Not Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plugin UI container configuration
class PluginUIConfig {
  final PluginRuntimeType pluginRuntimeType;
  final Map<String, dynamic> containerSettings;
  final Map<String, dynamic> securitySettings;
  final bool enableTheming;

  const PluginUIConfig({
    required this.pluginRuntimeType,
    required this.containerSettings,
    required this.securitySettings,
    this.enableTheming = true,
  });

  factory PluginUIConfig.fromManifest(PluginManifest manifest) {
    final uiIntegration = manifest.uiIntegration;
    final security = manifest.security;
    
    return PluginUIConfig(
      pluginRuntimeType: PluginRuntimeType.values.firstWhere(
        (type) => type.name == uiIntegration.containerType,
        orElse: () => PluginRuntimeType.executable,
      ),
      containerSettings: uiIntegration.containerConfig,
      securitySettings: {
        'level': security.level.name,
        'allowedDomains': security.allowedDomains,
        'blockedDomains': security.blockedDomains,
        'resourceLimits': security.resourceLimits.toJson(),
      },
      enableTheming: uiIntegration.supportsTheming,
    );
  }
}