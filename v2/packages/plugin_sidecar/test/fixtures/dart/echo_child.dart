import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  // 就绪信号：立即写一个最小帧
  void writeFrame(String payload) {
    final data = utf8.encode(payload);
    final header = ByteData(4)..setUint32(0, data.length, Endian.big);
    stdout.add(header.buffer.asUint8List());
    stdout.add(data);
  }

  writeFrame('ready');
  await stdout.flush();
  // 常驻直到被 kill；被 kill 后以非零码退出属预期
  await Completer<void>().future;
}
