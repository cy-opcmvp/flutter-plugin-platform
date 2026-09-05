/// sidecar 插件骨架模板：Python 入口脚本内容内嵌为常量渲染函数。
///
/// 协议对齐 `plugin_sidecar` 的 M2 夹具约定（SidecarSession 契约）：
/// 4 字节大端无符号长度前缀 + UTF-8 JSON payload 的 stdio 帧；
/// JSON-RPC 2.0 消息；启动后先发送纯字符串 `"ready"` 就绪帧
/// （宿主会话以 stdout 首字节判定就绪并吞掉首帧）。
library;

/// sidecar 清单默认入口文件名。
const String sidecarFileName = 'main.py';

/// sidecar 清单声明的 surface 字面量。
const String sidecarSurface = 'command';

/// 渲染 sidecar 骨架源码（Python 3，无第三方依赖）。
String renderSidecarTemplate({
  required String pluginId,
  required String pluginName,
}) {
  return '''
"""$pluginName sidecar plugin: length-prefixed JSON-RPC over stdio.

Frame protocol (aligned with the plugin_sidecar M2 fixtures):
  * each frame is a 4-byte big-endian unsigned length prefix followed by
    a UTF-8 JSON payload;
  * messages follow JSON-RPC 2.0 request/response mapping;
  * the first frame must be the plain string "ready": the host session
    treats the first stdout byte as the readiness signal and swallows
    the first frame.
"""
import json
import struct
import sys


def read_frame():
    header = sys.stdin.buffer.read(4)
    if len(header) < 4:
        return None
    (length,) = struct.unpack(">I", header)
    body = sys.stdin.buffer.read(length)
    return json.loads(body.decode("utf-8"))


def write_frame(obj):
    data = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    sys.stdout.buffer.write(struct.pack(">I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def handle(msg):
    method = msg.get("method")
    if method == "ping":
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": "pong"})
    # TODO: add plugin methods here - @author
    else:
        write_frame({
            "jsonrpc": "2.0",
            "id": msg.get("id"),
            "error": {"code": -32601, "message": "Method not found"},
        })


def main():
    # Readiness signal: supervisor treats the first stdout byte as ready;
    # the first frame (the plain string "ready") is swallowed by the host
    # session and never reaches the RPC channel.
    write_frame("ready")
    while True:
        msg = read_frame()
        if msg is None:
            break
        handle(msg)


if __name__ == "__main__":
    main()
''';
}
