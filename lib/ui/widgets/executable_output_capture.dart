import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/interfaces/i_external_plugin.dart';
import '../../core/models/external_plugin_models.dart';

/// Captures and displays output from executable-based external plugins
/// Implements requirement 5.3 for native plugin output handling
class ExecutableOutputCapture extends StatefulWidget {
  final IExternalPlugin plugin;
  final bool captureStdout;
  final bool captureStderr;
  final Function(String)? onOutput;
  final Function(String)? onError;
  final int maxLines;
  final bool showTimestamps;
  final bool allowInput;

  const ExecutableOutputCapture({
    super.key,
    required this.plugin,
    this.captureStdout = true,
    this.captureStderr = true,
    this.onOutput,
    this.onError,
    this.maxLines = 1000,
    this.showTimestamps = true,
    this.allowInput = false,
  });

  @override
  State<ExecutableOutputCapture> createState() => _ExecutableOutputCaptureState();
}

class _ExecutableOutputCaptureState extends State<ExecutableOutputCapture> {
  final List<OutputLine> _outputLines = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  bool _isCapturing = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _startCapturing();
  }

  /// Start capturing output from the plugin process
  Future<void> _startCapturing() async {
    if (_isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      // Ensure plugin is running
      if (!widget.plugin.isRunning) {
        await widget.plugin.launch();
      }

      // Set up output capture based on plugin type
      await _setupOutputCapture();

      // Register IPC message handler for structured output
      widget.plugin.registerMessageHandler('output', _handleStructuredOutput);
      widget.plugin.registerMessageHandler('ui_update', _handleUIUpdate);

    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _addOutputLine('Error starting capture: $e', OutputType.error);
      widget.onError?.call('Failed to start output capture: $e');
    }
  }

  /// Set up output capture based on plugin runtime type
  Future<void> _setupOutputCapture() async {
    switch (widget.plugin.pluginRuntimeType) {
      case PluginRuntimeType.executable:
      case PluginRuntimeType.native:
        await _setupProcessOutputCapture();
        break;
      case PluginRuntimeType.script:
        await _setupScriptOutputCapture();
        break;
      case PluginRuntimeType.container:
        await _setupContainerOutputCapture();
        break;
      case PluginRuntimeType.webApp:
        // Web apps don't typically have stdout/stderr
        _addOutputLine('Web plugin loaded', OutputType.info);
        break;
    }
  }

  /// Set up output capture for executable processes
  Future<void> _setupProcessOutputCapture() async {
    // In a real implementation, this would connect to the actual process streams
    // For now, we'll simulate by listening to IPC messages
    _addOutputLine('Connected to plugin process (PID: ${widget.plugin.processId})', OutputType.info);
    
    // Request initial output from plugin
    await widget.plugin.sendMessage(IPCMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      messageType: 'request_output',
      sourceId: 'host',
      targetId: widget.plugin.id,
      payload: {
        'captureStdout': widget.captureStdout,
        'captureStderr': widget.captureStderr,
      },
    ));
  }

  /// Set up output capture for script-based plugins
  Future<void> _setupScriptOutputCapture() async {
    _addOutputLine('Script plugin initialized', OutputType.info);
    
    // Request script output
    await widget.plugin.sendMessage(IPCMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      messageType: 'start_script',
      sourceId: 'host',
      targetId: widget.plugin.id,
      payload: {},
    ));
  }

  /// Set up output capture for containerized plugins
  Future<void> _setupContainerOutputCapture() async {
    _addOutputLine('Container plugin started', OutputType.info);
    
    // Request container logs
    await widget.plugin.sendMessage(IPCMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      messageType: 'get_logs',
      sourceId: 'host',
      targetId: widget.plugin.id,
      payload: {
        'follow': true,
        'timestamps': widget.showTimestamps,
      },
    ));
  }

  /// Handle structured output messages from plugin
  Future<void> _handleStructuredOutput(IPCMessage message) async {
    final payload = message.payload;
    final outputType = OutputType.values.firstWhere(
      (type) => type.name == payload['type'],
      orElse: () => OutputType.stdout,
    );
    
    final content = payload['content'] as String? ?? '';
    final timestamp = payload['timestamp'] != null 
        ? DateTime.parse(payload['timestamp'] as String)
        : DateTime.now();
    
    _addOutputLine(content, outputType, timestamp);
    widget.onOutput?.call(content);
  }

  /// Handle UI update messages from plugin
  Future<void> _handleUIUpdate(IPCMessage message) async {
    final payload = message.payload;
    final updateType = payload['updateType'] as String?;
    
    switch (updateType) {
      case 'clear':
        _clearOutput();
        break;
      case 'scroll_to_bottom':
        _scrollToBottom();
        break;
      case 'set_title':
        // Handle title updates if needed
        break;
    }
  }

  /// Add a new output line
  void _addOutputLine(String content, OutputType type, [DateTime? timestamp]) {
    setState(() {
      final line = OutputLine(
        content: content,
        type: type,
        timestamp: timestamp ?? DateTime.now(),
      );
      
      _outputLines.add(line);
      
      // Limit number of lines to prevent memory issues
      if (_outputLines.length > widget.maxLines) {
        _outputLines.removeAt(0);
      }
    });
    
    // Auto-scroll to bottom if enabled
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  /// Clear all output
  void _clearOutput() {
    setState(() {
      _outputLines.clear();
    });
  }

  /// Scroll to bottom of output
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Send input to the plugin
  Future<void> _sendInput(String input) async {
    if (input.trim().isEmpty) return;
    
    // Add input to output display
    _addOutputLine('> $input', OutputType.input);
    
    // Send input to plugin via IPC
    await widget.plugin.sendMessage(IPCMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      messageType: 'input',
      sourceId: 'host',
      targetId: widget.plugin.id,
      payload: {'input': input},
    ));
    
    _inputController.clear();
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        _buildToolbar(),
        
        // Output area
        Expanded(
          child: _buildOutputArea(),
        ),
        
        // Input area (if enabled)
        if (widget.allowInput)
          _buildInputArea(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.plugin.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: _clearOutput,
            icon: Icon(Icons.clear_all, size: 18),
            tooltip: 'Clear Output',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
              if (_autoScroll) {
                _scrollToBottom();
              }
            },
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              size: 18,
            ),
            tooltip: _autoScroll ? 'Disable Auto-scroll' : 'Enable Auto-scroll',
          ),
          IconButton(
            onPressed: _scrollToBottom,
            icon: Icon(Icons.keyboard_arrow_down, size: 18),
            tooltip: 'Scroll to Bottom',
          ),
        ],
      ),
    );
  }

  Widget _buildOutputArea() {
    if (_outputLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for plugin output...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(8),
        itemCount: _outputLines.length,
        itemBuilder: (context, index) {
          return _buildOutputLine(_outputLines[index]);
        },
      ),
    );
  }

  Widget _buildOutputLine(OutputLine line) {
    final theme = Theme.of(context);
    Color textColor;
    IconData? icon;
    
    switch (line.type) {
      case OutputType.stdout:
        textColor = theme.colorScheme.onSurface;
        break;
      case OutputType.stderr:
        textColor = theme.colorScheme.error;
        icon = Icons.error_outline;
        break;
      case OutputType.info:
        textColor = theme.colorScheme.primary;
        icon = Icons.info_outline;
        break;
      case OutputType.warning:
        textColor = Colors.orange;
        icon = Icons.warning_outlined;
        break;
      case OutputType.error:
        textColor = theme.colorScheme.error;
        icon = Icons.error_outline;
        break;
      case OutputType.input:
        textColor = theme.colorScheme.secondary;
        icon = Icons.keyboard_arrow_right;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          if (widget.showTimestamps)
            Container(
              width: 80,
              child: Text(
                _formatTimestamp(line.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          
          // Icon
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(right: 4, top: 2),
              child: Icon(
                icon,
                size: 14,
                color: textColor.withOpacity(0.7),
              ),
            ),
          
          // Content
          Expanded(
            child: SelectableText(
              line.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Enter command...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: TextStyle(fontFamily: 'monospace'),
              onSubmitted: _sendInput,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendInput(_inputController.text),
            icon: Icon(Icons.send),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Represents a line of output from the plugin
class OutputLine {
  final String content;
  final OutputType type;
  final DateTime timestamp;

  const OutputLine({
    required this.content,
    required this.type,
    required this.timestamp,
  });
}

/// Types of output that can be captured
enum OutputType {
  stdout,
  stderr,
  info,
  warning,
  error,
  input,
}