import 'package:flutter/material.dart';
import '../../core/interfaces/i_external_plugin.dart';
import '../../core/models/external_plugin_models.dart';

/// Manages theming and styling for external plugins
/// Implements requirement 5.4 for consistent theming across plugin types
class PluginThemeManager {
  static final PluginThemeManager _instance = PluginThemeManager._internal();
  factory PluginThemeManager() => _instance;
  PluginThemeManager._internal();

  /// Apply theme to external plugin
  Future<void> applyTheme(IExternalPlugin plugin, ThemeData theme) async {
    if (!plugin.manifest.uiIntegration.supportsTheming) {
      return;
    }

    switch (plugin.pluginRuntimeType) {
      case PluginRuntimeType.webApp:
        await _applyWebTheme(plugin, theme);
        break;
      case PluginRuntimeType.container:
        await _applyContainerTheme(plugin, theme);
        break;
      case PluginRuntimeType.executable:
      case PluginRuntimeType.native:
      case PluginRuntimeType.script:
        await _applyNativeTheme(plugin, theme);
        break;
    }
  }

  /// Apply theme to web-based plugins
  Future<void> _applyWebTheme(IExternalPlugin plugin, ThemeData theme) async {
    final themeData = _extractThemeData(theme);

    // Send theme data to web plugin via IPC
    await plugin.sendMessage(
      IPCMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: 'theme_update',
        sourceId: 'host',
        targetId: plugin.id,
        payload: {'theme': themeData, 'type': 'web'},
      ),
    );
  }

  /// Apply theme to container-based plugins
  Future<void> _applyContainerTheme(
    IExternalPlugin plugin,
    ThemeData theme,
  ) async {
    final themeData = _extractThemeData(theme);

    // Send theme data to container plugin
    await plugin.sendMessage(
      IPCMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: 'theme_update',
        sourceId: 'host',
        targetId: plugin.id,
        payload: {
          'theme': themeData,
          'type': 'container',
          'environment': _getContainerThemeEnvironment(themeData),
        },
      ),
    );
  }

  /// Apply theme to native/executable plugins
  Future<void> _applyNativeTheme(
    IExternalPlugin plugin,
    ThemeData theme,
  ) async {
    final themeData = _extractThemeData(theme);

    // Send theme data to native plugin
    await plugin.sendMessage(
      IPCMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        messageType: 'theme_update',
        sourceId: 'host',
        targetId: plugin.id,
        payload: {
          'theme': themeData,
          'type': 'native',
          'config': _getNativeThemeConfig(themeData),
        },
      ),
    );
  }

  /// Extract theme data from Flutter theme
  Map<String, dynamic> _extractThemeData(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return {
      'brightness': theme.brightness.name,
      'colors': {
        'primary': _colorToHex(colorScheme.primary),
        'primaryContainer': _colorToHex(colorScheme.primaryContainer),
        'onPrimary': _colorToHex(colorScheme.onPrimary),
        'onPrimaryContainer': _colorToHex(colorScheme.onPrimaryContainer),
        'secondary': _colorToHex(colorScheme.secondary),
        'secondaryContainer': _colorToHex(colorScheme.secondaryContainer),
        'onSecondary': _colorToHex(colorScheme.onSecondary),
        'onSecondaryContainer': _colorToHex(colorScheme.onSecondaryContainer),
        'tertiary': _colorToHex(colorScheme.tertiary),
        'tertiaryContainer': _colorToHex(colorScheme.tertiaryContainer),
        'onTertiary': _colorToHex(colorScheme.onTertiary),
        'onTertiaryContainer': _colorToHex(colorScheme.onTertiaryContainer),
        'error': _colorToHex(colorScheme.error),
        'errorContainer': _colorToHex(colorScheme.errorContainer),
        'onError': _colorToHex(colorScheme.onError),
        'onErrorContainer': _colorToHex(colorScheme.onErrorContainer),
        'surface': _colorToHex(colorScheme.surface),
        'surfaceDim': _colorToHex(colorScheme.surfaceDim),
        'surfaceBright': _colorToHex(colorScheme.surfaceBright),
        'surfaceContainerLowest': _colorToHex(
          colorScheme.surfaceContainerLowest,
        ),
        'surfaceContainerLow': _colorToHex(colorScheme.surfaceContainerLow),
        'surfaceContainer': _colorToHex(colorScheme.surfaceContainer),
        'surfaceContainerHigh': _colorToHex(colorScheme.surfaceContainerHigh),
        'surfaceContainerHighest': _colorToHex(
          colorScheme.surfaceContainerHighest,
        ),
        'onSurface': _colorToHex(colorScheme.onSurface),
        'onSurfaceVariant': _colorToHex(colorScheme.onSurfaceVariant),
        'outline': _colorToHex(colorScheme.outline),
        'outlineVariant': _colorToHex(colorScheme.outlineVariant),
        'shadow': _colorToHex(colorScheme.shadow),
        'scrim': _colorToHex(colorScheme.scrim),
        'inverseSurface': _colorToHex(colorScheme.inverseSurface),
        'onInverseSurface': _colorToHex(colorScheme.onInverseSurface),
        'inversePrimary': _colorToHex(colorScheme.inversePrimary),
      },
      'typography': {
        'fontFamily': theme.textTheme.bodyMedium?.fontFamily ?? 'system-ui',
        'displayLarge': _textStyleToMap(theme.textTheme.displayLarge),
        'displayMedium': _textStyleToMap(theme.textTheme.displayMedium),
        'displaySmall': _textStyleToMap(theme.textTheme.displaySmall),
        'headlineLarge': _textStyleToMap(theme.textTheme.headlineLarge),
        'headlineMedium': _textStyleToMap(theme.textTheme.headlineMedium),
        'headlineSmall': _textStyleToMap(theme.textTheme.headlineSmall),
        'titleLarge': _textStyleToMap(theme.textTheme.titleLarge),
        'titleMedium': _textStyleToMap(theme.textTheme.titleMedium),
        'titleSmall': _textStyleToMap(theme.textTheme.titleSmall),
        'bodyLarge': _textStyleToMap(theme.textTheme.bodyLarge),
        'bodyMedium': _textStyleToMap(theme.textTheme.bodyMedium),
        'bodySmall': _textStyleToMap(theme.textTheme.bodySmall),
        'labelLarge': _textStyleToMap(theme.textTheme.labelLarge),
        'labelMedium': _textStyleToMap(theme.textTheme.labelMedium),
        'labelSmall': _textStyleToMap(theme.textTheme.labelSmall),
      },
      'spacing': {
        'xs': 4.0,
        'sm': 8.0,
        'md': 16.0,
        'lg': 24.0,
        'xl': 32.0,
        'xxl': 48.0,
      },
      'borderRadius': {
        'xs': 2.0,
        'sm': 4.0,
        'md': 8.0,
        'lg': 12.0,
        'xl': 16.0,
        'xxl': 24.0,
      },
      'elevation': {
        'level0': 0.0,
        'level1': 1.0,
        'level2': 3.0,
        'level3': 6.0,
        'level4': 8.0,
        'level5': 12.0,
      },
    };
  }

  /// Convert Color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Convert TextStyle to map
  Map<String, dynamic>? _textStyleToMap(TextStyle? textStyle) {
    if (textStyle == null) return null;

    return {
      'fontSize': textStyle.fontSize,
      'fontWeight': textStyle.fontWeight?.value,
      'fontFamily': textStyle.fontFamily,
      'letterSpacing': textStyle.letterSpacing,
      'height': textStyle.height,
      'color': textStyle.color != null ? _colorToHex(textStyle.color!) : null,
    };
  }

  /// Get container theme environment variables
  Map<String, String> _getContainerThemeEnvironment(
    Map<String, dynamic> themeData,
  ) {
    final colors = themeData['colors'] as Map<String, dynamic>;

    return {
      'THEME_BRIGHTNESS': themeData['brightness'] as String,
      'THEME_PRIMARY': colors['primary'] as String,
      'THEME_SURFACE': colors['surface'] as String,
      'THEME_ON_SURFACE': colors['onSurface'] as String,
      'THEME_ERROR': colors['error'] as String,
      'THEME_OUTLINE': colors['outline'] as String,
    };
  }

  /// Get native theme configuration
  Map<String, dynamic> _getNativeThemeConfig(Map<String, dynamic> themeData) {
    return {
      'configFile': 'theme.json',
      'format': 'json',
      'data': themeData,
      'reloadCommand': 'reload_theme',
    };
  }

  /// Generate CSS variables for web plugins
  String generateCSSVariables(ThemeData theme) {
    final themeData = _extractThemeData(theme);
    final colors = themeData['colors'] as Map<String, dynamic>;
    final typography = themeData['typography'] as Map<String, dynamic>;
    final spacing = themeData['spacing'] as Map<String, dynamic>;
    final borderRadius = themeData['borderRadius'] as Map<String, dynamic>;
    final elevation = themeData['elevation'] as Map<String, dynamic>;

    final cssVariables = StringBuffer();
    cssVariables.writeln(':root {');

    // Color variables
    colors.forEach((key, value) {
      final cssKey = key.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '-${match.group(1)!.toLowerCase()}',
      );
      cssVariables.writeln('  --host-color-$cssKey: $value;');
    });

    // Typography variables
    final fontFamily = typography['fontFamily'] as String;
    cssVariables.writeln('  --host-font-family: $fontFamily;');

    typography.forEach((key, value) {
      if (key != 'fontFamily' && value != null) {
        final styleMap = value as Map<String, dynamic>;
        final cssKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '-${match.group(1)!.toLowerCase()}',
        );

        if (styleMap['fontSize'] != null) {
          cssVariables.writeln(
            '  --host-font-size-$cssKey: ${styleMap['fontSize']}px;',
          );
        }
        if (styleMap['fontWeight'] != null) {
          cssVariables.writeln(
            '  --host-font-weight-$cssKey: ${styleMap['fontWeight']};',
          );
        }
        if (styleMap['letterSpacing'] != null) {
          cssVariables.writeln(
            '  --host-letter-spacing-$cssKey: ${styleMap['letterSpacing']}px;',
          );
        }
        if (styleMap['height'] != null) {
          cssVariables.writeln(
            '  --host-line-height-$cssKey: ${styleMap['height']};',
          );
        }
      }
    });

    // Spacing variables
    spacing.forEach((key, value) {
      cssVariables.writeln('  --host-spacing-$key: ${value}px;');
    });

    // Border radius variables
    borderRadius.forEach((key, value) {
      cssVariables.writeln('  --host-border-radius-$key: ${value}px;');
    });

    // Elevation variables (as box-shadow)
    elevation.forEach((key, value) {
      final elevationValue = value as double;
      if (elevationValue == 0) {
        cssVariables.writeln('  --host-elevation-$key: none;');
      } else {
        final blur = elevationValue * 2;
        final offset = elevationValue / 2;
        cssVariables.writeln(
          '  --host-elevation-$key: 0 ${offset}px ${blur}px rgba(0, 0, 0, 0.2);',
        );
      }
    });

    cssVariables.writeln('}');

    return cssVariables.toString();
  }

  /// Generate theme adaptation script for web plugins
  String generateThemeAdaptationScript(ThemeData theme) {
    final cssVariables = generateCSSVariables(theme);

    return '''
(function() {
  // Inject CSS variables
  const style = document.createElement('style');
  style.textContent = `$cssVariables`;
  document.head.appendChild(style);
  
  // Add theme class to body
  document.body.classList.remove('host-theme-light', 'host-theme-dark');
  document.body.classList.add('host-theme-${theme.brightness.name}');
  
  // Dispatch theme change event
  window.dispatchEvent(new CustomEvent('hostThemeChanged', {
    detail: {
      brightness: '${theme.brightness.name}',
      timestamp: Date.now()
    }
  }));
  
  // Update meta theme-color for mobile browsers
  let metaThemeColor = document.querySelector('meta[name="theme-color"]');
  if (!metaThemeColor) {
    metaThemeColor = document.createElement('meta');
    metaThemeColor.name = 'theme-color';
    document.head.appendChild(metaThemeColor);
  }
  metaThemeColor.content = '${_colorToHex(theme.colorScheme.primary)}';
})();
''';
  }

  /// Create theme-aware widget wrapper
  Widget createThemedWrapper({
    required Widget child,
    required IExternalPlugin plugin,
    ThemeData? theme,
  }) {
    return Builder(
      builder: (context) {
        final effectiveTheme = theme ?? Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            color: effectiveTheme.colorScheme.surface,
            border: Border.all(
              color: effectiveTheme.colorScheme.outline.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Theme(data: effectiveTheme, child: child),
          ),
        );
      },
    );
  }

  /// Get theme-aware colors for plugin UI elements
  PluginThemeColors getThemeColors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PluginThemeColors(
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      primaryContainer: colorScheme.primaryContainer,
      onPrimaryContainer: colorScheme.onPrimaryContainer,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      surface: colorScheme.surface,
      onSurface: colorScheme.onSurface,
      surfaceContainer: colorScheme.surfaceContainer,
      error: colorScheme.error,
      onError: colorScheme.onError,
      outline: colorScheme.outline,
      shadow: colorScheme.shadow,
      brightness: theme.brightness,
    );
  }
}

/// Theme colors for plugin UI elements
class PluginThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainer;
  final Color error;
  final Color onError;
  final Color outline;
  final Color shadow;
  final Brightness brightness;

  const PluginThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainer,
    required this.error,
    required this.onError,
    required this.outline,
    required this.shadow,
    required this.brightness,
  });

  /// Check if theme is dark
  bool get isDark => brightness == Brightness.dark;

  /// Check if theme is light
  bool get isLight => brightness == Brightness.light;
}

/// Plugin theme configuration
class PluginThemeConfig {
  final bool enableTheming;
  final bool adaptToSystemTheme;
  final bool injectCSSVariables;
  final bool sendThemeEvents;
  final Duration themeTransitionDuration;

  const PluginThemeConfig({
    this.enableTheming = true,
    this.adaptToSystemTheme = true,
    this.injectCSSVariables = true,
    this.sendThemeEvents = true,
    this.themeTransitionDuration = const Duration(milliseconds: 200),
  });

  factory PluginThemeConfig.fromManifest(PluginManifest manifest) {
    final uiIntegration = manifest.uiIntegration;

    return PluginThemeConfig(
      enableTheming: uiIntegration.supportsTheming,
      adaptToSystemTheme: true,
      injectCSSVariables: uiIntegration.containerType == 'webApp',
      sendThemeEvents: true,
    );
  }
}
