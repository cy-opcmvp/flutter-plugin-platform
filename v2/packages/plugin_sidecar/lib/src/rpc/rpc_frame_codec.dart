import 'dart:convert';
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';

/// 帧默认字节上限：8 MiB。
const int defaultMaxFrameBytes = 8 * 1024 * 1024;

const int _headerBytes = 4;

/// 帧协议违规异常。
///
/// [failure] 的 code 固定为 `rpc.frame_invalid`，details 携带 `reason`
/// （`tooLarge` | `empty` | `invalidUtf8`）与当前帧已接收字节数。
final class RpcFrameException implements Exception {
  RpcFrameException(this.failure);

  final PluginFailure failure;

  @override
  String toString() => 'RpcFrameException(${failure.code}: ${failure.message})';
}

/// 编码单帧：4 字节大端长度前缀 + UTF-8 payload。
///
/// payload 字节数超过 [maxFrameBytes] 时抛出 [RpcFrameException]。
Uint8List encodeFrame(
  String payload, {
  int maxFrameBytes = defaultMaxFrameBytes,
}) {
  final data = utf8.encode(payload);
  if (data.length > maxFrameBytes) {
    throw _invalidFrame(
      reason: 'tooLarge',
      receivedBytes: data.length,
      message: 'frame payload exceeds the configured limit',
    );
  }

  final header = ByteData(_headerBytes)..setUint32(0, data.length, Endian.big);
  final bytes = BytesBuilder()
    ..add(header.buffer.asUint8List())
    ..add(data);
  return bytes.takeBytes();
}

/// 增量式帧解码器。
///
/// 可跨多次 [addBytes] 拼接半包与粘包；每次投递后通过 [drainFrames]
/// 取出所有已完整帧的 payload。
final class RpcFrameDecoder {
  RpcFrameDecoder({this.maxFrameBytes = defaultMaxFrameBytes});

  /// 单帧 payload 字节上限。
  final int maxFrameBytes;

  Uint8List _buffer = Uint8List(0);
  final List<String> _frames = <String>[];

  /// 追加原始字节并解码所有已完整的帧。
  ///
  /// 违反帧协议时抛出 [RpcFrameException]；此后解码器视为损坏，
  /// 调用方应停止使用（或显式调用 [reset] 后重建会话）。
  void addBytes(List<int> chunk) {
    final merged = Uint8List(_buffer.length + chunk.length);
    merged.setRange(0, _buffer.length, _buffer);
    merged.setRange(_buffer.length, merged.length, chunk);
    _buffer = merged;

    var offset = 0;
    while (_buffer.length - offset >= _headerBytes) {
      final header = ByteData.sublistView(
        _buffer,
        offset,
        offset + _headerBytes,
      );
      final length = header.getUint32(0, Endian.big);
      if (length == 0) {
        throw _invalidFrame(
          reason: 'empty',
          receivedBytes: _headerBytes,
          message: 'frame length must be positive',
        );
      }
      if (length > maxFrameBytes) {
        // 声明长度超限立即失败，不等 payload 到达。
        throw _invalidFrame(
          reason: 'tooLarge',
          receivedBytes: _headerBytes,
          message: 'declared frame length exceeds the configured limit',
        );
      }

      final totalBytes = _headerBytes + length;
      if (_buffer.length - offset < totalBytes) {
        break;
      }

      final payload = Uint8List.sublistView(
        _buffer,
        offset + _headerBytes,
        offset + totalBytes,
      );
      final String text;
      try {
        text = utf8.decode(payload, allowMalformed: false);
      } on FormatException {
        throw _invalidFrame(
          reason: 'invalidUtf8',
          receivedBytes: totalBytes,
          message: 'frame payload is not valid UTF-8',
        );
      }
      _frames.add(text);
      offset += totalBytes;
    }

    if (offset > 0) {
      _buffer = Uint8List.fromList(Uint8List.sublistView(_buffer, offset));
    }
  }

  /// 取出所有已完整帧的 payload；无完整帧时返回空列表。
  List<String> drainFrames() {
    if (_frames.isEmpty) {
      return const <String>[];
    }

    final drained = List<String>.of(_frames);
    _frames.clear();
    return drained;
  }

  /// 丢弃缓冲中的半包与尚未取走的帧。
  void reset() {
    _buffer = Uint8List(0);
    _frames.clear();
  }
}

RpcFrameException _invalidFrame({
  required String reason,
  required int receivedBytes,
  required String message,
}) {
  return RpcFrameException(
    PluginFailure('rpc.frame_invalid', message, <String, Object?>{
      'reason': reason,
      'receivedBytes': receivedBytes,
    }),
  );
}
