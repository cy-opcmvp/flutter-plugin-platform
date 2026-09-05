"""Hash 工具 sidecar 示例（Python 3 标准库实现，零 pip 依赖）。

协议（与 plugin_sidecar 帧层一致）：
- stdin/stdout 传输 4 字节大端无符号长度前缀 + UTF-8 JSON 载荷的帧；
- 启动后先发送纯字符串帧 ``ready`` 声明就绪；
- 请求为 JSON-RPC 2.0 对象（``id``/``method``/``params``），响应回写
  ``id`` 与 ``result``；未知方法回错误码 -32601。
"""

import hashlib
import json
import struct
import sys

READY = "ready"


def read_frame(stream):
    """读取一帧：4 字节大端长度前缀 + UTF-8 JSON 载荷。"""
    header = stream.read(4)
    if len(header) < 4:
        return None
    (length,) = struct.unpack(">I", header)
    payload = stream.read(length)
    if len(payload) < length:
        return None
    return json.loads(payload.decode("utf-8"))


def write_frame(value):
    """写出一帧：长度前缀 + UTF-8 JSON 载荷，并立即冲刷。"""
    payload = json.dumps(value, ensure_ascii=False).encode("utf-8")
    sys.stdout.buffer.write(struct.pack(">I", len(payload)))
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()


def handle_compute(params):
    """hash.compute：params {text} → result {md5, sha1, sha256}（hex 小写）。"""
    text = params.get("text")
    if not isinstance(text, str):
        raise ValueError("params.text must be a string")
    data = text.encode("utf-8")
    return {
        "md5": hashlib.md5(data).hexdigest(),
        "sha1": hashlib.sha1(data).hexdigest(),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def main():
    write_frame(READY)
    while True:
        request = read_frame(sys.stdin.buffer)
        if request is None:
            return
        request_id = request.get("id")
        try:
            if request.get("method") == "hash.compute":
                result = handle_compute(request.get("params") or {})
            else:
                raise LookupError("Method not found")
        except LookupError:
            write_frame(
                {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32601, "message": "Method not found"},
                }
            )
        except (ValueError, TypeError) as error:
            write_frame(
                {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32602, "message": str(error)},
                }
            )
        else:
            write_frame(
                {"jsonrpc": "2.0", "id": request_id, "result": result}
            )


if __name__ == "__main__":
    main()
