import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/interfaces/i_external_plugin.dart';
import '../../core/models/external_plugin_models.dart';
import 'plugin_theme_manager.dart';

/// Secure web view container for web-based external plugins
/// Implements requirements 5.2 with security restrictions
class WebViewContainer extends StatefulWidget {
  final IExternalPlugin plugin;
  final String initialUrl;
  final Map<String, dynamic> securityRestrictions;
  final Function(String)? onPageFinished;
  final Function(WebResourceError)? onWebResourceError;
  final Function(String)? onNavigationRequest;

  const WebViewContainer({
    super.key,
    required this.plugin,
    required this.initialUrl,
    required this.securityRestrictions,
    this.onPageFinished,
    this.onWebResourceError,
    this.onNavigationRequest,
  });

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Initialize web view with security restrictions
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(_getJavaScriptMode())
      ..setBackgroundColor(Theme.of(context).colorScheme.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onPageFinished?.call(url);
            _injectSecurityPolicies();
            _injectThemeSupport();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            widget.onWebResourceError?.call(error);
          },
          onNavigationRequest: (NavigationRequest request) {
            final decision = _handleNavigationRequest(request);
            widget.onNavigationRequest?.call(request.url);
            return decision;
          },
        ),
      )
      ..addJavaScriptChannel(
        'PluginHost',
        onMessageReceived: _handlePluginMessage,
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /// Get JavaScript mode based on security restrictions
  JavaScriptMode _getJavaScriptMode() {
    final allowJS =
        widget.securityRestrictions['allowJavaScript'] as bool? ?? true;
    return allowJS ? JavaScriptMode.unrestricted : JavaScriptMode.disabled;
  }

  /// Handle navigation requests with security filtering
  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;
    final uri = Uri.tryParse(url);

    if (uri == null) {
      return NavigationDecision.prevent;
    }

    // Check allowed domains
    final allowedDomains =
        widget.securityRestrictions['allowedDomains'] as List<String>? ?? [];
    final blockedDomains =
        widget.securityRestrictions['blockedDomains'] as List<String>? ?? [];

    // Block explicitly blocked domains
    if (blockedDomains.any((domain) => uri.host.contains(domain))) {
      return NavigationDecision.prevent;
    }

    // If allowed domains are specified, only allow those
    if (allowedDomains.isNotEmpty) {
      if (!allowedDomains.any((domain) => uri.host.contains(domain))) {
        return NavigationDecision.prevent;
      }
    }

    // Block dangerous protocols
    if (!['http', 'https', 'about', 'data'].contains(uri.scheme)) {
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Handle messages from the plugin web page
  void _handlePluginMessage(JavaScriptMessage message) {
    try {
      // Parse message and forward to plugin via IPC
      final messageData = message.message;

      // Create IPC message for the plugin
      final ipcMessage = IPCMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: 'web_message',
        sourceId: 'webview',
        targetId: widget.plugin.id,
        payload: {'message': messageData},
      );

      // Send to plugin
      widget.plugin.sendMessage(ipcMessage);
    } catch (e) {
      debugPrint('Error handling plugin message: $e');
    }
  }

  /// Inject security policies into the web page
  Future<void> _injectSecurityPolicies() async {
    final securityScript =
        '''
      (function() {
        // Disable certain APIs based on security level
        ${_generateSecurityScript()}
        
        // Set up plugin host communication
        window.pluginHost = {
          sendMessage: function(message) {
            PluginHost.postMessage(JSON.stringify(message));
          },
          getTheme: function() {
            return ${_getThemeData()};
          }
        };
        
        // Notify plugin that host is ready
        window.dispatchEvent(new CustomEvent('pluginHostReady'));
      })();
    ''';

    await _controller.runJavaScript(securityScript);
  }

  /// Generate security script based on restrictions
  String _generateSecurityScript() {
    final restrictions = widget.securityRestrictions;
    final scripts = <String>[];

    // Disable geolocation if not allowed
    if (!(restrictions['allowGeolocation'] as bool? ?? false)) {
      scripts.add('''
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition = function() {
            throw new Error('Geolocation access denied by security policy');
          };
        }
      ''');
    }

    // Disable camera/microphone if not allowed
    if (!(restrictions['allowCamera'] as bool? ?? false) ||
        !(restrictions['allowMicrophone'] as bool? ?? false)) {
      scripts.add('''
        if (navigator.mediaDevices) {
          navigator.mediaDevices.getUserMedia = function() {
            return Promise.reject(new Error('Media access denied by security policy'));
          };
        }
      ''');
    }

    // Disable notifications if not allowed
    if (!(restrictions['allowNotifications'] as bool? ?? false)) {
      scripts.add('''
        if (window.Notification) {
          window.Notification.requestPermission = function() {
            return Promise.resolve('denied');
          };
        }
      ''');
    }

    // Disable local storage if not allowed
    if (!(restrictions['allowLocalStorage'] as bool? ?? true)) {
      scripts.add('''
        try {
          Object.defineProperty(window, 'localStorage', {
            value: null,
            writable: false
          });
          Object.defineProperty(window, 'sessionStorage', {
            value: null,
            writable: false
          });
        } catch (e) {}
      ''');
    }

    return scripts.join('\n');
  }

  /// Inject theme support for consistent styling
  Future<void> _injectThemeSupport() async {
    if (!widget.plugin.manifest.uiIntegration.supportsTheming) {
      return;
    }

    final theme = Theme.of(context);
    final themeManager = PluginThemeManager();
    final themeScript = themeManager.generateThemeAdaptationScript(theme);

    await _controller.runJavaScript(themeScript);
  }

  /// Get theme data as JSON string for JavaScript injection
  String _getThemeData() {
    final theme = Theme.of(context);
    final themeData = {
      'primaryColor': theme.primaryColor.toARGB32().toRadixString(16),
      'backgroundColor': theme.scaffoldBackgroundColor.toARGB32().toRadixString(16),
      'textColor':
          theme.textTheme.bodyLarge?.color?.toARGB32().toRadixString(16) ??
          'ff000000',
      'isDark': theme.brightness == Brightness.dark,
    };
    return "'${themeData.toString().replaceAll("'", "\\'")}'";
  }

  /// Reload the web view
  Future<void> reload() async {
    await _controller.reload();
  }

  /// Navigate back if possible
  Future<bool> goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return true;
    }
    return false;
  }

  /// Navigate forward if possible
  Future<bool> goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Loading progress bar
        if (_isLoading)
          LinearProgressIndicator(
            value: _loadingProgress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),

        // Web view
        Expanded(child: WebViewWidget(controller: _controller)),

        // Navigation bar (optional)
        if (_shouldShowNavigationBar()) _buildNavigationBar(),
      ],
    );
  }

  /// Check if navigation bar should be shown
  bool _shouldShowNavigationBar() {
    // Show navigation bar for development or if explicitly enabled
    return widget.securityRestrictions['showNavigationBar'] as bool? ?? false;
  }

  /// Build navigation bar with basic controls
  Widget _buildNavigationBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: goBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          IconButton(
            onPressed: goForward,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Forward',
          ),
          IconButton(
            onPressed: reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _currentUrl ?? widget.initialUrl,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Security configuration for web view container
class WebViewSecurityConfig {
  final List<String> allowedDomains;
  final List<String> blockedDomains;
  final bool allowJavaScript;
  final bool allowLocalStorage;
  final bool allowGeolocation;
  final bool allowCamera;
  final bool allowMicrophone;
  final bool allowNotifications;
  final bool showNavigationBar;

  const WebViewSecurityConfig({
    this.allowedDomains = const [],
    this.blockedDomains = const [],
    this.allowJavaScript = true,
    this.allowLocalStorage = true,
    this.allowGeolocation = false,
    this.allowCamera = false,
    this.allowMicrophone = false,
    this.allowNotifications = false,
    this.showNavigationBar = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'allowedDomains': allowedDomains,
      'blockedDomains': blockedDomains,
      'allowJavaScript': allowJavaScript,
      'allowLocalStorage': allowLocalStorage,
      'allowGeolocation': allowGeolocation,
      'allowCamera': allowCamera,
      'allowMicrophone': allowMicrophone,
      'allowNotifications': allowNotifications,
      'showNavigationBar': showNavigationBar,
    };
  }

  factory WebViewSecurityConfig.fromSecurityLevel(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.minimal:
        return const WebViewSecurityConfig(
          allowJavaScript: true,
          allowLocalStorage: true,
          allowGeolocation: true,
          allowCamera: true,
          allowMicrophone: true,
          allowNotifications: true,
        );
      case SecurityLevel.standard:
        return const WebViewSecurityConfig(
          allowJavaScript: true,
          allowLocalStorage: true,
          allowGeolocation: false,
          allowCamera: false,
          allowMicrophone: false,
          allowNotifications: true,
        );
      case SecurityLevel.strict:
        return const WebViewSecurityConfig(
          allowJavaScript: true,
          allowLocalStorage: false,
          allowGeolocation: false,
          allowCamera: false,
          allowMicrophone: false,
          allowNotifications: false,
        );
      case SecurityLevel.isolated:
        return const WebViewSecurityConfig(
          allowJavaScript: false,
          allowLocalStorage: false,
          allowGeolocation: false,
          allowCamera: false,
          allowMicrophone: false,
          allowNotifications: false,
        );
    }
  }
}
