import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/services/platform_environment.dart';

/// Utility functions for CLI operations
class CLIUtils {
  /// Print colored output to console
  static void printColored(String message, {String color = 'white'}) {
    const colors = {
      'black': '\x1B[30m',
      'red': '\x1B[31m',
      'green': '\x1B[32m',
      'yellow': '\x1B[33m',
      'blue': '\x1B[34m',
      'magenta': '\x1B[35m',
      'cyan': '\x1B[36m',
      'white': '\x1B[37m',
      'reset': '\x1B[0m',
    };

    final colorCode = colors[color] ?? colors['white']!;
    final resetCode = colors['reset']!;
    print('$colorCode$message$resetCode');
  }

  /// Print success message
  static void printSuccess(String message) {
    printColored('✓ $message', color: 'green');
  }

  /// Print error message
  static void printError(String message) {
    printColored('✗ $message', color: 'red');
  }

  /// Print warning message
  static void printWarning(String message) {
    printColored('⚠ $message', color: 'yellow');
  }

  /// Print info message
  static void printInfo(String message) {
    printColored('ℹ $message', color: 'blue');
  }

  /// Prompt user for input
  static String? prompt(String message, {String? defaultValue}) {
    final displayMessage = defaultValue != null
        ? '$message [$defaultValue]: '
        : '$message: ';

    stdout.write(displayMessage);
    final input = stdin.readLineSync();

    if (input == null || input.trim().isEmpty) {
      return defaultValue;
    }

    return input.trim();
  }

  /// Prompt user for confirmation
  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultText = defaultValue ? 'Y/n' : 'y/N';
    final input = prompt(
      '$message ($defaultText)',
      defaultValue: defaultValue ? 'y' : 'n',
    );

    if (input == null) return defaultValue;

    final normalized = input.toLowerCase();
    return normalized == 'y' || normalized == 'yes';
  }

  /// Select from multiple options
  static String? select(
    String message,
    List<String> options, {
    String? defaultValue,
  }) {
    print(message);
    for (int i = 0; i < options.length; i++) {
      final marker = options[i] == defaultValue ? '* ' : '  ';
      print('$marker${i + 1}. ${options[i]}');
    }

    final input = prompt(
      'Select option (1-${options.length})',
      defaultValue: defaultValue != null
          ? (options.indexOf(defaultValue) + 1).toString()
          : null,
    );

    if (input == null) return defaultValue;

    final index = int.tryParse(input);
    if (index != null && index >= 1 && index <= options.length) {
      return options[index - 1];
    }

    return defaultValue;
  }

  /// Execute shell command with output
  static Future<ProcessResult> executeCommand(
    String command,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool verbose = false,
  }) async {
    if (verbose) {
      printInfo('Executing: $command ${arguments.join(' ')}');
    }

    final result = await Process.run(
      command,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );

    if (verbose) {
      if (result.stdout.toString().isNotEmpty) {
        print('STDOUT:\n${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        print('STDERR:\n${result.stderr}');
      }
    }

    return result;
  }

  /// Check if command exists in PATH
  static Future<bool> commandExists(String command) async {
    try {
      final result = Platform.isWindows
          ? await Process.run('where', [command])
          : await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get current platform string
  static String getCurrentPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Validate plugin ID format
  static bool isValidPluginId(String id) {
    // Reverse domain notation: com.example.plugin-name
    final regex = RegExp(r'^[a-z0-9]+(\.[a-z0-9-]+)*$');
    return regex.hasMatch(id);
  }

  /// Validate semantic version format
  static bool isValidVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9-]+)?(\+[a-zA-Z0-9-]+)?$');
    return regex.hasMatch(version);
  }

  /// Create directory if it doesn't exist
  static Future<Directory> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Copy file with progress indication
  static Future<void> copyFileWithProgress(
    File source,
    File destination,
  ) async {
    final sourceSize = await source.length();
    final sink = destination.openWrite();
    final stream = source.openRead();

    int bytesWritten = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      bytesWritten += chunk.length;

      final progress = (bytesWritten / sourceSize * 100).round();
      stdout.write('\rCopying ${path.basename(source.path)}: $progress%');
    }

    await sink.close();
    print(''); // New line after progress
  }

  /// Archive directory to zip file (simplified implementation)
  static Future<void> archiveDirectory(
    Directory source,
    File destination,
  ) async {
    printInfo('Creating archive: ${destination.path}');

    // This is a simplified implementation
    // In a real CLI tool, you would use a proper archiving library
    final files = <String>[];

    await for (final entity in source.list(recursive: true)) {
      if (entity is File) {
        files.add(path.relative(entity.path, from: source.path));
      }
    }

    // Create a simple manifest file instead of actual zip
    final manifest = {
      'type': 'plugin_package',
      'created': DateTime.now().toIso8601String(),
      'files': files,
    };

    await destination.writeAsString(jsonEncode(manifest));
    printSuccess('Archive created: ${destination.path}');
  }

  /// Extract archive (simplified implementation)
  static Future<void> extractArchive(
    File archive,
    Directory destination,
  ) async {
    printInfo('Extracting archive: ${archive.path}');

    // This is a simplified implementation
    final content = await archive.readAsString();
    final manifest = jsonDecode(content) as Map<String, dynamic>;

    if (manifest['type'] != 'plugin_package') {
      throw ArgumentError('Invalid package format');
    }

    await ensureDirectory(destination.path);

    // In a real implementation, this would extract actual files
    printSuccess('Archive extracted to: ${destination.path}');
  }

  /// Format file size in human readable format
  static String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Get file checksum (simplified MD5-like)
  static Future<String> getFileChecksum(File file) async {
    final bytes = await file.readAsBytes();
    // This is a simplified checksum - in real implementation use crypto library
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Validate JSON file
  static Future<bool> isValidJsonFile(File file) async {
    try {
      final content = await file.readAsString();
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pretty print JSON
  static String prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  /// Load configuration from file
  static Future<Map<String, dynamic>> loadConfig(String configPath) async {
    final file = File(configPath);
    if (!file.existsSync()) {
      return {};
    }

    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      printWarning('Failed to load config from $configPath: $e');
      return {};
    }
  }

  /// Save configuration to file
  static Future<void> saveConfig(
    String configPath,
    Map<String, dynamic> config,
  ) async {
    final file = File(configPath);
    final dir = Directory(path.dirname(configPath));

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    await file.writeAsString(prettyPrintJson(config));
  }

  /// Show progress bar
  static void showProgress(String message, int current, int total) {
    const barLength = 30;
    final progress = current / total;
    final filledLength = (barLength * progress).round();
    final bar = '█' * filledLength + '░' * (barLength - filledLength);
    final percentage = (progress * 100).round();

    stdout.write('\r$message [$bar] $percentage% ($current/$total)');

    if (current >= total) {
      print(''); // New line when complete
    }
  }

  /// Spinner for long-running operations
  static void showSpinner(String message) {
    // This would need to be implemented with proper async handling
    // For now, just show a static message
    stdout.write('$message... ');
  }

  /// Stop spinner and show result
  static void stopSpinner({bool success = true, String? message}) {
    if (success) {
      printSuccess(message ?? 'Done');
    } else {
      printError(message ?? 'Failed');
    }
  }

  /// Validate plugin manifest structure
  static List<String> validateManifestStructure(Map<String, dynamic> manifest) {
    final errors = <String>[];

    // Required fields
    final requiredFields = ['id', 'name', 'version', 'type'];
    for (final field in requiredFields) {
      if (!manifest.containsKey(field) || manifest[field] == null) {
        errors.add('Missing required field: $field');
      }
    }

    // Validate ID format
    if (manifest.containsKey('id')) {
      final id = manifest['id'] as String?;
      if (id != null && !isValidPluginId(id)) {
        errors.add('Invalid plugin ID format: $id');
      }
    }

    // Validate version format
    if (manifest.containsKey('version')) {
      final version = manifest['version'] as String?;
      if (version != null && !isValidVersion(version)) {
        errors.add('Invalid version format: $version');
      }
    }

    return errors;
  }

  /// Get system information
  static Map<String, dynamic> getSystemInfo() {
    return {
      'platform': getCurrentPlatform(),
      'operatingSystem': Platform.operatingSystem,
      'operatingSystemVersion': Platform.operatingSystemVersion,
      'dartVersion': Platform.version,
      'executable': Platform.executable,
      'environment': PlatformEnvironment.instance.getAllVariables(),
    };
  }

  /// Check system requirements
  static Future<Map<String, bool>> checkSystemRequirements() async {
    final requirements = <String, bool>{};

    // Check for common tools
    requirements['dart'] = await commandExists('dart');
    requirements['flutter'] = await commandExists('flutter');
    requirements['git'] = await commandExists('git');
    requirements['node'] = await commandExists('node');
    requirements['python'] =
        await commandExists('python') || await commandExists('python3');
    requirements['cargo'] = await commandExists('cargo');

    return requirements;
  }
}
