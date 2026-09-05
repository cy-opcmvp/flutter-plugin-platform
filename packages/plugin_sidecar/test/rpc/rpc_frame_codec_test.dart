// 覆盖场景清单：
// 1. 编码/解码往返一致；编码 payload 超上限抛 RpcFrameException。
// 2. 半包逐字节投递：帧未完整前 drainFrames 不产出。
// 3. 粘包：单个 chunk 携带多帧时按序产出。
// 4. 声明长度超上限：在 payload 到达前立即失败。
// 5. 零长度帧拒绝。
// 6. 非 UTF-8 payload 拒绝。
// 7. reset 丢弃半包状态，之后可继续解码新帧。
// 8. 异常携带结构化 PluginFailure（code=rpc.frame_invalid，reason=tooLarge）。
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

void main() {
  group('RpcFrameCodec', () {
    test('encode/decode round trip', () {
      final bytes = encodeFrame('{"jsonrpc":"2.0"}');
      final decoder = RpcFrameDecoder();
      decoder.addBytes(bytes);
      expect(decoder.drainFrames(), ['{"jsonrpc":"2.0"}']);
      expect(
        () => encodeFrame('0123456789', maxFrameBytes: 8),
        throwsA(isA<RpcFrameException>()),
      );
    });

    test('half frames delivered one byte at a time', () {
      final bytes = encodeFrame('ok');
      final decoder = RpcFrameDecoder();
      // 帧未完整前（前 n-1 字节）不产出。
      for (final b in bytes.take(bytes.length - 1)) {
        decoder.addBytes([b]);
        expect(decoder.drainFrames(), isEmpty);
      }
      decoder.addBytes([bytes.last]);
      expect(decoder.drainFrames(), ['ok']);
    });

    test('multiple frames coalesced in one chunk', () {
      final decoder = RpcFrameDecoder();
      decoder.addBytes([...encodeFrame('a'), ...encodeFrame('bb')]);
      expect(decoder.drainFrames(), ['a', 'bb']);
    });

    test('declared length above limit fails before payload arrives', () {
      final decoder = RpcFrameDecoder(maxFrameBytes: 16);
      final header = ByteData(4)..setUint32(0, 17);
      expect(
        () => decoder.addBytes(header.buffer.asUint8List()),
        throwsA(isA<RpcFrameException>()),
      );
    });

    test('zero length frame is rejected', () {
      final decoder = RpcFrameDecoder();
      final header = ByteData(4)..setUint32(0, 0);
      expect(
        () => decoder.addBytes(header.buffer.asUint8List()),
        throwsA(isA<RpcFrameException>()),
      );
    });

    test('non utf-8 payload is rejected', () {
      final header = ByteData(4)..setUint32(0, 1);
      final decoder = RpcFrameDecoder();
      decoder.addBytes(header.buffer.asUint8List());
      expect(() => decoder.addBytes([0xFF]), throwsA(isA<RpcFrameException>()));
    });

    test('reset discards partial state', () {
      final decoder = RpcFrameDecoder();
      decoder.addBytes(encodeFrame('abc').take(3).toList());
      decoder.reset();
      decoder.addBytes(encodeFrame('z'));
      expect(decoder.drainFrames(), ['z']);
    });

    test('exception carries structured failure', () {
      PluginFailure? captured;
      try {
        final decoder = RpcFrameDecoder(maxFrameBytes: 4);
        final header = ByteData(4)..setUint32(0, 5);
        decoder.addBytes(header.buffer.asUint8List());
      } on RpcFrameException catch (e) {
        captured = e.failure;
      }
      expect(captured?.code, 'rpc.frame_invalid');
      expect(captured?.details['reason'], 'tooLarge');
    });
  });
}
