import 'dart:convert';

/// JSON-RPC 消息基类（严格子集，见框架计划的消息格式定义）。
sealed class RpcMessage {
  const RpcMessage();
}

/// 请求：期待响应。
final class RpcRequest extends RpcMessage {
  const RpcRequest({required this.id, required this.method, this.params});

  /// 请求标识：非负 int 或非空 String。
  final Object id;
  final String method;
  final Map<String, Object?>? params;
}

/// 通知：不期待响应。
final class RpcNotification extends RpcMessage {
  const RpcNotification({required this.method, this.params});

  final String method;
  final Map<String, Object?>? params;
}

/// 成功响应。
final class RpcSuccess extends RpcMessage {
  const RpcSuccess({required this.id, required this.result});

  final Object id;
  final Object? result;
}

/// 错误响应；[id] 可为 null，表示无法定位对应请求。
final class RpcError extends RpcMessage {
  const RpcError({
    required this.id,
    required this.code,
    required this.message,
    this.data,
  });

  final Object? id;
  final int code;
  final String message;
  final Object? data;
}

/// 解码严格 JSON-RPC 消息；任何违规抛 [FormatException]。
///
/// 异常消息只含字段路径，不含 payload 原文。
RpcMessage decodeRpcMessage(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    throw const FormatException('Invalid message: payload is not valid JSON');
  }

  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Invalid message: expected a JSON object');
  }

  const allowedFields = {
    'jsonrpc',
    'id',
    'method',
    'params',
    'result',
    'error',
  };
  for (final key in decoded.keys) {
    if (!allowedFields.contains(key)) {
      throw FormatException('Invalid message: unknown field "$key"');
    }
  }

  if (decoded['jsonrpc'] != '2.0') {
    throw const FormatException(
      'Invalid message: field "jsonrpc" must be "2.0"',
    );
  }

  if (decoded.containsKey('method')) {
    return _decodeCall(decoded);
  }
  return _decodeResponse(decoded);
}

/// 解码 request / notification。
RpcMessage _decodeCall(Map<String, Object?> fields) {
  final Object? methodValue = fields['method'];
  if (methodValue is! String || methodValue.isEmpty) {
    throw const FormatException(
      'Invalid message: field "method" must be a non-empty string',
    );
  }

  Map<String, Object?>? params;
  final Object? paramsValue = fields['params'];
  if (paramsValue != null) {
    if (paramsValue is! Map<String, Object?>) {
      throw const FormatException(
        'Invalid message: field "params" must be an object',
      );
    }
    params = paramsValue;
  }

  if (!fields.containsKey('id')) {
    return RpcNotification(method: methodValue, params: params);
  }

  final Object? idValue = fields['id'];
  _validateId(idValue, allowNull: false, fieldPath: 'id');
  return RpcRequest(id: idValue as Object, method: methodValue, params: params);
}

/// 解码 success / error 响应。
RpcMessage _decodeResponse(Map<String, Object?> fields) {
  if (!fields.containsKey('id')) {
    throw const FormatException('Invalid message: field "id" is required');
  }

  final hasResult = fields.containsKey('result');
  final hasError = fields.containsKey('error');
  if (hasResult == hasError) {
    throw const FormatException(
      'Invalid message: exactly one of "result" or "error" is required',
    );
  }

  final Object? idValue = fields['id'];
  if (hasResult) {
    _validateId(idValue, allowNull: false, fieldPath: 'id');
    return RpcSuccess(id: idValue as Object, result: fields['result']);
  }

  _validateId(idValue, allowNull: true, fieldPath: 'id');
  final Object? errorValue = fields['error'];
  if (errorValue is! Map<String, Object?>) {
    throw const FormatException(
      'Invalid message: field "error" must be an object',
    );
  }

  const allowedErrorFields = {'code', 'message', 'data'};
  for (final key in errorValue.keys) {
    if (!allowedErrorFields.contains(key)) {
      throw FormatException('Invalid message: unknown field "error.$key"');
    }
  }
  if (!errorValue.containsKey('code') || !errorValue.containsKey('message')) {
    throw const FormatException(
      'Invalid message: fields "error.code" and "error.message" are required',
    );
  }

  final Object? codeValue = errorValue['code'];
  if (codeValue is! int) {
    throw const FormatException(
      'Invalid message: field "error.code" must be an int',
    );
  }
  final Object? messageValue = errorValue['message'];
  if (messageValue is! String || messageValue.isEmpty) {
    throw const FormatException(
      'Invalid message: field "error.message" must be a non-empty string',
    );
  }

  return RpcError(
    id: idValue,
    code: codeValue,
    message: messageValue,
    data: errorValue['data'],
  );
}

/// 校验 id 字段取值：非负 int 或非空 String；error 响应的 id 允许为 null。
void _validateId(
  Object? value, {
  required bool allowNull,
  required String fieldPath,
}) {
  if (value == null) {
    if (allowNull) {
      return;
    }
    throw FormatException(
      'Invalid message: field "$fieldPath" must be a non-negative int '
      'or non-empty string',
    );
  }
  final isValid =
      (value is int && value >= 0) || (value is String && value.isNotEmpty);
  if (!isValid) {
    throw FormatException(
      'Invalid message: field "$fieldPath" must be a non-negative int '
      'or non-empty string',
    );
  }
}

/// 编码 JSON-RPC 消息；构造约束被破坏时抛 [ArgumentError]。
///
/// 字段顺序固定（jsonrpc、id、method、params），保证往返字节一致。
String encodeRpcMessage(RpcMessage message) {
  final map = <String, Object?>{'jsonrpc': '2.0'};
  if (message is RpcRequest) {
    _requireValidId(message.id, allowNull: false);
    _requireNonEmpty(message.method, 'method');
    map['id'] = message.id;
    map['method'] = message.method;
    final params = message.params;
    if (params != null) {
      map['params'] = params;
    }
  } else if (message is RpcNotification) {
    _requireNonEmpty(message.method, 'method');
    map['method'] = message.method;
    final params = message.params;
    if (params != null) {
      map['params'] = params;
    }
  } else if (message is RpcSuccess) {
    _requireValidId(message.id, allowNull: false);
    map['id'] = message.id;
    map['result'] = message.result;
  } else if (message is RpcError) {
    _requireValidId(message.id, allowNull: true);
    _requireNonEmpty(message.message, 'message');
    map['id'] = message.id;
    map['error'] = <String, Object?>{
      'code': message.code,
      'message': message.message,
      if (message.data != null) 'data': message.data,
    };
  }
  return jsonEncode(map);
}

void _requireValidId(Object? id, {required bool allowNull}) {
  if (id == null) {
    if (!allowNull) {
      throw ArgumentError.value(
        id,
        'id',
        'must be a non-negative int or non-empty string',
      );
    }
    return;
  }
  final isValid = (id is int && id >= 0) || (id is String && id.isNotEmpty);
  if (!isValid) {
    throw ArgumentError.value(
      id,
      'id',
      'must be a non-negative int or non-empty string',
    );
  }
}

void _requireNonEmpty(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
}
