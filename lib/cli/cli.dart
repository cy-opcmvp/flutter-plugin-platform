/// Plugin CLI - Command-line interface for plugin development
///
/// This module provides comprehensive CLI tools for developing, testing,
/// packaging, and publishing external plugins for the Flutter Plugin Platform.
///
/// ## Available Commands
///
/// - **create**: Create a new plugin project from templates
/// - **init**: Initialize plugin in existing directory
/// - **build**: Build the plugin for distribution
/// - **package**: Package plugin into distributable format
/// - **test**: Test plugin locally with host application
/// - **validate**: Validate plugin manifest and structure
/// - **publish**: Publish plugin to registry
/// - **clean**: Clean build artifacts and temporary files
///
/// ## Usage Examples
///
/// ```bash
/// # Create new plugin
/// plugin-cli create --name my-plugin --type executable --language dart
///
/// # Build and package
/// plugin-cli build
/// plugin-cli package --platform all --output my-plugin.pkg
///
/// # Test locally
/// plugin-cli test --plugin my-plugin.pkg --host-version 1.0.0
///
/// # Publish to registry
/// plugin-cli publish --plugin my-plugin.pkg --registry official
/// ```

library plugin_cli;

// Core CLI functionality
export 'plugin_cli.dart';

// CLI utilities and helpers
export 'cli_utils.dart';

// Template system
export 'templates.dart';
