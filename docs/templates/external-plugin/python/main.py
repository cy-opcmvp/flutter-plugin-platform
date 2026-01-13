#!/usr/bin/env python3
"""
{{PLUGIN_NAME}} - External Plugin
{{PLUGIN_DESCRIPTION}}
"""

import sys
import json
from datetime import datetime

PLUGIN_ID = "{{PLUGIN_ID}}"
PLUGIN_VERSION = "1.0.0"


def send_message(message: dict):
    """发送消息到宿主"""
    print(json.dumps(message), flush=True)


def send_error(error: str, message_id: str = None):
    """发送错误消息"""
    send_message({
        "type": "error",
        "messageId": message_id,
        "error": error
    })


def execute_command(command: str, params: dict) -> dict:
    """执行命令"""
    if command == "getInfo":
        return {
            "pluginId": PLUGIN_ID,
            "version": PLUGIN_VERSION,
            "name": "{{PLUGIN_NAME}}",
            "description": "{{PLUGIN_DESCRIPTION}}"
        }
    elif command == "process":
        # TODO: 实现你的业务逻辑
        data = params.get("data")
        return {
            "success": True,
            "processed": data
        }
    else:
        return {"error": f"Unknown command: {command}"}


def handle_message(message: dict):
    """处理接收到的消息"""
    msg_type = message.get("type")
    msg_id = message.get("messageId")
    
    if msg_type == "ping":
        send_message({
            "type": "pong",
            "messageId": msg_id,
            "timestamp": datetime.now().isoformat()
        })
    elif msg_type == "execute":
        command = message.get("command")
        params = message.get("params", {})
        result = execute_command(command, params)
        send_message({
            "type": "response",
            "messageId": msg_id,
            "result": result
        })
    elif msg_type == "shutdown":
        send_message({
            "type": "shutdown_ack",
            "messageId": msg_id
        })
        sys.exit(0)
    else:
        send_error(f"Unknown message type: {msg_type}", msg_id)


def main():
    """主函数"""
    # 报告就绪状态
    send_message({
        "type": "ready",
        "pluginId": PLUGIN_ID,
        "version": PLUGIN_VERSION
    })
    
    # 监听输入消息
    for line in sys.stdin:
        try:
            message = json.loads(line.strip())
            handle_message(message)
        except json.JSONDecodeError as e:
            send_error(f"Failed to parse message: {e}")
        except Exception as e:
            send_error(f"Error handling message: {e}")


if __name__ == "__main__":
    main()
