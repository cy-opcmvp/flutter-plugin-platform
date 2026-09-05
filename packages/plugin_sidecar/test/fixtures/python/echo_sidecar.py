"""Echo sidecar fixture: length-prefixed JSON-RPC over stdio."""
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
    elif method == "echo":
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": msg.get("params")})
    elif method == "stderrNoise":
        sys.stderr.write("noise\n")
        sys.stderr.flush()
        write_frame({"jsonrpc": "2.0", "id": msg["id"], "result": "ok"})
    elif method == "hang":
        pass  # intentional no-reply for timeout testing
    elif method == "crash":
        sys.exit(1)
    else:
        write_frame({
            "jsonrpc": "2.0",
            "id": msg.get("id"),
            "error": {"code": -32601, "message": "Method not found"},
        })


def main():
    # Readiness signal: supervisor treats the first stdout byte as ready.
    write_frame("ready")
    while True:
        msg = read_frame()
        if msg is None:
            break
        handle(msg)


if __name__ == "__main__":
    main()
