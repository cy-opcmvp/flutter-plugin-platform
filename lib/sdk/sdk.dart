/// External Plugin SDK for Flutter Plugin Platform
///
/// This SDK provides tools and utilities for developing external plugins
/// that can run independently and communicate with the host application.
///
/// ## Getting Started
///
/// 1. Initialize the SDK in your plugin's main function:
/// ```dart
/// import 'package:flutter_app/sdk/sdk.dart';
///
/// void main() async {
///   await PluginSDK.initialize(
///     pluginId: 'com.example.my-plugin',
///     config: {
///       'name': 'My Plugin',
///       'version': '1.0.0',
///     },
///   );
///
///   // Your plugin logic here
/// }
/// ```
///
/// 2. Use helper classes for specific plugin types:
/// ```dart
/// // For executable plugins
/// await ExecutablePluginHelper.initialize(
///   pluginId: 'com.example.my-plugin',
///   executablePath: '/path/to/executable',
/// );
///
/// // For web plugins
/// await WebPluginHelper.initialize(
///   pluginId: 'com.example.my-plugin',
///   entryUrl: 'https://my-plugin.example.com',
/// );
///
/// // For container plugins
/// await ContainerPluginHelper.initialize(
///   pluginId: 'com.example.my-plugin',
///   imageName: 'my-plugin:latest',
/// );
/// ```
///
/// 3. Communicate with the host application:
/// ```dart
/// // Call host APIs
/// final result = await PluginSDK.callHostAPI<String>(
///   'getUserPreference',
///   {'key': 'theme'},
/// );
///
/// // Send events to host
/// await PluginSDK.sendEvent('user_action', {
///   'action': 'button_clicked',
///   'button_id': 'save',
/// });
///
/// // Listen for host events
/// PluginSDK.onHostEvent('theme_changed', (event) async {
///   final newTheme = event.data['theme'] as String;
///   // Update plugin UI theme
/// });
/// ```
///
/// ## Plugin Types
///
/// The SDK supports multiple plugin types:
///
/// - **Executable Plugins**: Native executables that communicate via IPC
/// - **Web Plugins**: Web applications running in a sandboxed WebView
/// - **Container Plugins**: Containerized applications (Docker, etc.)
/// - **Script Plugins**: Interpreted scripts (Python, Node.js, etc.)
///
/// ## Security and Permissions
///
/// External plugins run in a sandboxed environment with limited permissions.
/// Request permissions as needed:
///
/// ```dart
/// // Request file system access
/// final hasAccess = await PluginSDK.requestPermission(
///   Permission.fileSystemRead,
/// );
///
/// if (hasAccess) {
///   // Access files
/// }
/// ```
///
/// ## Configuration Management
///
/// Use the configuration helper to manage plugin settings:
///
/// ```dart
/// // Get configuration values
/// final apiKey = await PluginConfigHelper.getConfig<String>('api_key');
/// final timeout = await PluginConfigHelper.getConfig<int>('timeout', 30);
///
/// // Set configuration values
/// await PluginConfigHelper.setConfig('last_sync', DateTime.now().toIso8601String());
/// ```
///
/// ## Lifecycle Management
///
/// Handle plugin lifecycle events:
///
/// ```dart
/// PluginLifecycleHelper.registerLifecycleHandlers(
///   onStart: () {
///     debugPrint('Plugin started');
///   },
///   onPause: () {
///     debugPrint('Plugin paused');
///   },
///   onStop: () {
///     debugPrint('Plugin stopped');
///   },
/// );
///
/// // Report when plugin is ready
/// await PluginLifecycleHelper.reportReady();
/// ```
///
/// ## Error Handling
///
/// Handle errors gracefully and report them to the host:
///
/// ```dart
/// try {
///   // Plugin logic
/// } catch (e) {
///   await PluginLifecycleHelper.reportError(
///     e.toString(),
///     {'stackTrace': StackTrace.current.toString()},
///   );
/// }
/// ```
///
/// ## Logging
///
/// Use the SDK's logging system to send logs to the host:
///
/// ```dart
/// await PluginSDK.logInfo('Plugin operation completed');
/// await PluginSDK.logWarning('Deprecated API used');
/// await PluginSDK.logError('Failed to process request');
/// await PluginSDK.logDebug('Debug information');
/// ```

library plugin_sdk;

// Core SDK
export 'plugin_sdk.dart';

// Helper classes
export 'plugin_helpers.dart';

// Models and interfaces (re-exported for convenience)
export '../core/models/plugin_models.dart';
export '../core/models/external_plugin_models.dart';
export '../core/interfaces/i_external_plugin.dart';

// Common types and enums
export '../core/models/plugin_models.dart'
    show PluginState, PluginType, Permission;

export '../core/models/external_plugin_models.dart'
    show PluginRuntimeType, SecurityLevel, ResourceLimits;
