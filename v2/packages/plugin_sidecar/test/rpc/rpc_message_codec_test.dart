// 覆盖场景清单：
// 1. 四类消息 encode/decode 往返字节一致，且解码得到正确类型与字段。
// 2. jsonrpc 字段缺失或非 "2.0" 拒绝。
// 3. 未知字段拒绝，异常消息含字段名。
// 4. method 空串、params 为数组拒绝。
// 5. 非法 id 拒绝：request/success 的负数、空串、null；error.id 非 null 时同样校验。
// 6. result 与 error 同现或同缺、响应缺 id 字段拒绝。
// 7. error 对象畸形拒绝：code 非 int、message 空串、未知字段、缺必备字段。
// 8. 顶层非 object 与非法 JSON 拒绝。
// 9. encode 前对构造约束防御：负 id、空 method、空 error message 抛 ArgumentError。
// 10. 脱敏：所有 FormatException 消息不含 payload 值原文，只含字段路径。
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 断言 payload 解码抛出 FormatException，且异常消息不泄露值原文。
///
/// [allowSecretInField] 为 true 时豁免 SECRET 检查（用于字段名本身含
/// SECRET 的用例：字段名属于字段路径，计划要求包含在异常消息中）。
void expectMessageInvalid(
  String payload, {
  String? containsField,
  bool allowSecretInField = false,
}) {
  late final FormatException exception;
  try {
    decodeRpcMessage(payload);
    fail('expected FormatException for payload: $payload');
  } on FormatException catch (e) {
    exception = e;
  }
  if (containsField != null) {
    expect(exception.message, contains(containsField));
  }
  if (!allowSecretInField) {
    expect(exception.message, isNot(contains('SECRET')));
  }
}

void main() {
  group('RpcMessageCodec', () {
    test('round trip preserves bytes for all message kinds', () {
      const messages = <RpcMessage>[
        RpcRequest(id: 0, method: 'ping'),
        RpcRequest(
          id: 'abc-1',
          method: 'echo',
          params: {
            'x': 1,
            'y': [true, null],
          },
        ),
        RpcNotification(method: 'ready'),
        RpcNotification(method: 'progress', params: {'pct': 50}),
        RpcSuccess(id: 7, result: 'pong'),
        RpcSuccess(id: 7, result: null),
        RpcSuccess(id: 's-1', result: {'a': 1}),
        RpcError(id: 3, code: -32601, message: 'Method not found'),
        RpcError(id: null, code: 1, message: 'boom', data: {'k': 'v'}),
      ];
      for (final message in messages) {
        final encoded = encodeRpcMessage(message);
        final decoded = decodeRpcMessage(encoded);
        expect(encodeRpcMessage(decoded), encoded);
      }

      final request = decodeRpcMessage('{"jsonrpc":"2.0","id":1,"method":"m"}');
      expect(request, isA<RpcRequest>());
      expect((request as RpcRequest).id, 1);
      expect(request.method, 'm');
      expect(request.params, isNull);

      final notification = decodeRpcMessage(
        '{"jsonrpc":"2.0","method":"n","params":{"a":1}}',
      );
      expect(notification, isA<RpcNotification>());
      expect((notification as RpcNotification).params, {'a': 1});

      final success = decodeRpcMessage(
        '{"jsonrpc":"2.0","id":2,"result":null}',
      );
      expect(success, isA<RpcSuccess>());
      expect((success as RpcSuccess).result, isNull);

      final error = decodeRpcMessage(
        '{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}',
      );
      expect(error, isA<RpcError>());
      final rpcError = error as RpcError;
      expect(rpcError.id, isNull);
      expect(rpcError.code, -32700);
      expect(rpcError.message, 'Parse error');
    });

    test('jsonrpc field missing or wrong version is rejected', () {
      expectMessageInvalid('{"id":1,"method":"m"}');
      expectMessageInvalid('{"jsonrpc":"1.0","id":1,"method":"m"}');
    });

    test('unknown field is rejected and named in the error', () {
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"method":"m","SECRET_FIELD":1}',
        containsField: 'SECRET_FIELD',
        allowSecretInField: true,
      );
    });

    test('empty method and array params are rejected', () {
      expectMessageInvalid('{"jsonrpc":"2.0","method":""}');
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"method":"m","params":[1]}',
      );
    });

    test('invalid ids are rejected', () {
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":-1,"method":"SECRET_METHOD"}',
      );
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":"","method":"SECRET_METHOD"}',
      );
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":null,"method":"SECRET_METHOD"}',
      );
      expectMessageInvalid('{"jsonrpc":"2.0","id":null,"result":1}');
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":-2,"error":{"code":1,"message":"x"}}',
      );
    });

    test('id-less or ambiguous responses are rejected', () {
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"result":{},"error":{"code":1,"message":"SECRET_MSG"}}',
      );
      expectMessageInvalid('{"jsonrpc":"2.0","id":1}');
      expectMessageInvalid('{"jsonrpc":"2.0","result":1}');
    });

    test('malformed error object is rejected', () {
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"error":{"code":"SECRET_CODE","message":"x"}}',
      );
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"error":{"code":1,"message":""}}',
      );
      expectMessageInvalid(
        '{"jsonrpc":"2.0","id":1,"error":{"code":1,"message":"m","foo":1}}',
        containsField: 'foo',
      );
      expectMessageInvalid('{"jsonrpc":"2.0","id":1,"error":{}}');
    });

    test('non-object payloads and invalid JSON are rejected', () {
      expectMessageInvalid('[1,2]');
      expectMessageInvalid('"SECRET_TEXT"');
      expectMessageInvalid('42');
      expectMessageInvalid('{invalid');
    });

    test('encode validates constructor constraints', () {
      expect(
        () => encodeRpcMessage(const RpcRequest(id: -1, method: 'm')),
        throwsArgumentError,
      );
      expect(
        () => encodeRpcMessage(const RpcRequest(id: '', method: 'm')),
        throwsArgumentError,
      );
      expect(
        () => encodeRpcMessage(const RpcRequest(id: 0, method: '')),
        throwsArgumentError,
      );
      expect(
        () => encodeRpcMessage(const RpcNotification(method: '')),
        throwsArgumentError,
      );
      expect(
        () => encodeRpcMessage(const RpcError(id: 0, code: 1, message: '')),
        throwsArgumentError,
      );
    });

    test('diagnostics never leak payload values', () {
      const poisoned = <String>[
        '{"jsonrpc":"1.9","method":"SECRET_METHOD"}',
        '{"jsonrpc":"2.0","id":-5,"method":"SECRET_METHOD"}',
        '{"jsonrpc":"2.0","id":"","method":"SECRET_METHOD"}',
        '{"jsonrpc":"2.0","id":null,"method":"SECRET_METHOD"}',
        '{"jsonrpc":"2.0","method":"SECRET_METHOD","params":[1]}',
        '{"jsonrpc":"2.0","method":"","extra":"SECRET_VALUE"}',
        '{"jsonrpc":"2.0","id":1,"result":{},"error":{"code":1,"message":"SECRET_MSG"}}',
        '{"jsonrpc":"2.0","id":1}',
        '{"jsonrpc":"2.0","id":1,"error":{"code":"x","message":"SECRET_MSG"}}',
        '"SECRET_TOP_LEVEL"',
        '{SECRET_INVALID',
      ];
      for (final payload in poisoned) {
        try {
          decodeRpcMessage(payload);
          fail('expected FormatException for payload: $payload');
        } on FormatException catch (e) {
          expect(
            e.message,
            isNot(contains('SECRET')),
            reason: 'payload leaked into diagnostics: $payload',
          );
        }
      }
    });
  });
}
