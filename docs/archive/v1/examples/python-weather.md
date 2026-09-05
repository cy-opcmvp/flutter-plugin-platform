# 天气插件 (Python)

一个演示使用 Python 的插件 SDK 用法的天气信息插件。

## 功能

- 当前天气状况
- 5天天气预报
- 基于位置的天气数据
- 天气警报和通知
- 可配置的更新间隔
- 多位置支持

## 快速开始

### 前提条件

- Python 3.7+
- Python 插件 SDK
- 获取天气数据的互联网连接

### 安装

1. 克隆或下载此示例
2. 安装依赖：
   ```bash
   pip install -r requirements.txt
   ```
3. 在 `config.json` 中配置 API 密钥
4. 构建插件：
   ```bash
   dart tools/plugin_cli.dart build
   ```
5. 打包以分发：
   ```bash
   dart tools/plugin_cli.dart package --output weather.pkg
   ```

### 配置

创建一个包含天气 API 配置的 `config.json` 文件：

```json
{
  "api_key": "your_weather_api_key",
  "default_location": "New York, NY",
  "update_interval": 300,
  "units": "metric"
}
```

### 测试

本地测试插件：

```bash
dart tools/plugin_cli.dart test --plugin weather.pkg
```

## 代码结构

```
python_weather/
├── main.py                   # 主入口点
├── weather_service.py        # Weather API 集成
├── weather_ui.py            # 用户界面（如果适用）
├── config.json              # 配置文件
├── requirements.txt         # Python 依赖
├── plugin_manifest.json     # 插件配置
└── README.md               # 本文件
```

## 演示的关键 SDK 功能

1. **异步插件架构**: 使用 asyncio 进行非阻塞操作
2. **API 集成**: 从外部天气 API 获取数据
3. **配置管理**: 加载和保存插件设置
4. **事件处理**: 响应位置更改和用户请求
5. **计划任务**: 定期天气更新
6. **错误处理**: 对网络问题的强大错误处理
7. **日志记录**: 用于调试的综合日志记录

## 使用方法

安装到 Flutter 插件平台后：

1. 配置您的首选位置
2. 设置更新间隔和单位
3. 查看当前天气和预报
4. 接收天气警报和通知

## API 集成

插件演示了与以下内容的集成：

- 天气 API 服务（OpenWeatherMap 等）
- 用于通知和首选项的主机应用程序 API
- 用于自动位置检测的位置服务

## 开发说明

此示例展示了基于 Python 的外部插件的最佳实践：

- 用于非阻塞操作的 async/await 模式
- 网络操作的适当异常处理
- 配置文件管理
- 日志记录和调试支持
- 清晰的关注点分离（API、UI、逻辑）
