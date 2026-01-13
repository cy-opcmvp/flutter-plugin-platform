import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// {{PLUGIN_NAME}} - External Plugin
/// {{PLUGIN_DESCRIPTION}}

const String pluginId = '{{PLUGIN_ID}}';
const String pluginVersion = '1.0.0';

late Stream<String> _inputStream;
late IOSink _outputSink;

void main(List<String> args) async {
  print('[$pluginId] Starting...');
  
  // 设置 IPC 通信
  _inputStream = stdin.transform(utf8.decoder).transform(const LineSplitter());
  _outputSink = stdout;
  
  // 注册消息处理器
  await _setupMessageHandlers();
  
  // 报告就绪状态
  await _sendMessage({
    'type': 'ready',
    'pluginId': pluginId,
    'version': pluginVersion,
  });
  
  // 监听输入消息
  await for (final line in _inputStream) {
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      await _handleMessage(message);
    } catch (e) {
      await _sendError('Failed to parse message: $e');
    }
  }
}

Future<void> _setupMessageHandlers() async {
  // 初始化插件资源
}

Future<void> _handleMessage(Map<String, dynamic> message) async {
  final messageType = message['type'] as String?;
  final messageId = message['messageId'] as String?;
  
  switch (messageType) {
    case 'ping':
      await _sendMessage({
        'type': 'pong',
        'messageId': messageId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      break;
      
    case 'execute':
      final command = message['command'] as String?;
      final params = message['params'] as Map<String, dynamic>? ?? {};
      final result = await _executeCommand(command, params);
      await _sendMessage({
        'type': 'response',
        'messageId': messageId,
        'result': result,
      });
      break;
      
    case 'shutdown':
      await _sendMessage({
        'type': 'shutdown_ack',
        'messageId': messageId,
      });
      exit(0);
      
    default:
      await _sendError('Unknown message type: $messageType', messageId: messageId);
  }
}

Future<Map<String, dynamic>> _executeCommand(String? command, Map<String, dynamic> params) async {
  switch (command) {
    case 'getInfo':
      return {
        'pluginId': pluginId,
        'version': pluginVersion,
        'name': '{{PLUGIN_NAME}}',
        'description': '{{PLUGIN_DESCRIPTION}}',
      };
      
    case 'process':
      // TODO: 实现你的业务逻辑
      final data = params['data'];
      return {
        'success': true,
        'processed': data,
      };
      
    default:
      return {
        'error': 'Unknown command: $command',
      };
  }
}

Future<void> _sendMessage(Map<String, dynamic> message) async {
  final json = jsonEncode(message);
  _outputSink.writeln(json);
  await _outputSink.flush();
}

Future<void> _sendError(String error, {String? messageId}) async {
  await _sendMessage({
    'type': 'error',
    'messageId': messageId,
    'error': error,
  });
}
