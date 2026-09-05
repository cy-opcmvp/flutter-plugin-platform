# 世界时钟插件 (World Clock Plugin)

一个功能丰富的世界时钟插件，支持多时区显示和倒计时提醒功能。

## 功能特性

### 🌍 世界时钟
- **多时区支持**: 同时显示多个城市的时间
- **默认北京时间**: 预设北京时间作为默认时钟
- **实时更新**: 每秒自动更新时间显示
- **预定义时区**: 内置10个常用时区（北京、东京、首尔、新加坡、悉尼、伦敦、巴黎、纽约、洛杉矶、芝加哥）
- **自定义添加**: 支持添加自定义城市和时区
- **优雅界面**: 清晰的时间显示和城市信息

### ⏰ 倒计时提醒
- **灵活设置**: 支持小时、分钟、秒的任意组合
- **自定义标题**: 为每个倒计时设置个性化提醒内容
- **视觉反馈**: 
  - 进度圆环显示剩余时间比例
  - 即将完成时的脉冲动画效果
  - 不同状态的颜色区分
- **完成通知**: 倒计时结束时自动发送系统通知
- **状态管理**: 自动标记已完成的倒计时

### 🎨 用户界面
- **Material Design**: 遵循Material Design设计规范
- **响应式布局**: 适配不同屏幕尺寸
- **动画效果**: 流畅的过渡动画和状态变化
- **直观操作**: 简单易用的添加和删除功能

## 技术实现

### 架构设计
- **插件架构**: 基于IPlugin接口的标准插件实现
- **状态管理**: 完整的插件生命周期管理
- **数据持久化**: 自动保存和恢复用户设置
- **定时器管理**: 高效的时间更新机制

### 核心组件
```
world_clock/
├── world_clock_plugin.dart          # 主插件类
├── world_clock_plugin_factory.dart  # 插件工厂
├── models/
│   └── world_clock_models.dart      # 数据模型
└── widgets/
    ├── world_clock_widget.dart      # 时钟显示组件
    └── countdown_timer_widget.dart  # 倒计时组件
```

### 数据模型
- **WorldClockItem**: 世界时钟数据模型
- **CountdownTimer**: 倒计时定时器模型
- **TimeZoneInfo**: 时区信息模型

## 使用方法

### 添加世界时钟
1. 点击右上角的"+"按钮
2. 选择"添加时钟"
3. 输入城市名称
4. 选择对应时区
5. 点击"添加"完成

### 添加倒计时
1. 点击右上角的闹钟图标
2. 输入倒计时标题
3. 设置小时、分钟、秒
4. 点击"添加"开始倒计时

### 删除功能
- **删除时钟**: 点击时钟右侧的删除按钮（默认北京时间不可删除）
- **删除倒计时**: 点击倒计时右侧的删除按钮

## 权限要求

- **platformStorage**: 用于保存时钟和倒计时设置
- **systemNotifications**: 用于倒计时完成提醒
- **platformServices**: 用于访问平台服务

## 配置选项

```json
{
  "defaultTimeZone": "Asia/Shanghai",
  "updateInterval": 1000,
  "maxClocks": 10,
  "maxCountdowns": 20,
  "enableNotifications": true,
  "enableAnimations": true
}
```

## 支持的时区

| 城市 | 时区ID | UTC偏移 |
|------|--------|---------|
| 北京 | Asia/Shanghai | UTC+8 |
| 东京 | Asia/Tokyo | UTC+9 |
| 首尔 | Asia/Seoul | UTC+9 |
| 新加坡 | Asia/Singapore | UTC+8 |
| 悉尼 | Australia/Sydney | UTC+11 |
| 伦敦 | Europe/London | UTC+0 |
| 巴黎 | Europe/Paris | UTC+1 |
| 纽约 | America/New_York | UTC-5 |
| 洛杉矶 | America/Los_Angeles | UTC-8 |
| 芝加哥 | America/Chicago | UTC-6 |

*注意：时区偏移为简化实现，未考虑夏令时变化*

## 国际化支持

- **中文 (zh_CN)**: 默认语言
- **英文 (en_US)**: 完整翻译支持

## 版本历史

### v1.0.0 (当前版本)
- ✅ 多时区世界时钟显示
- ✅ 默认北京时间
- ✅ 倒计时提醒功能
- ✅ 自定义时钟添加
- ✅ 实时时间更新
- ✅ 完成通知提醒
- ✅ 国际化支持
- ✅ 数据持久化

### 未来计划
- 🔄 更精确的时区处理（集成timezone包）
- 🔄 时钟主题自定义
- 🔄 更多预设倒计时模板
- 🔄 倒计时声音提醒
- 🔄 世界时钟桌面小部件
- 🔄 时区搜索功能

## 开发说明

### 测试
```bash
flutter test test/plugins/world_clock_test.dart
```

### 构建
插件会自动包含在主应用构建中，无需单独构建。

### 调试
启用调试模式查看详细日志：
```dart
PluginDebugger.enableDebugMode();
```

## 技术限制

1. **时区处理**: 当前使用简化的UTC偏移计算，未处理夏令时变化
2. **最大数量**: 建议不超过10个时钟和20个倒计时以保证性能
3. **通知权限**: 需要用户授权系统通知权限

## 贡献指南

欢迎提交Issue和Pull Request来改进这个插件！

### 开发环境
- Flutter SDK 3.0.0+
- Dart SDK 2.17.0+

### 代码规范
- 遵循Dart官方代码规范
- 使用有意义的变量和函数命名
- 添加适当的注释和文档

## 许可证

MIT License - 详见项目根目录的LICENSE文件

## 联系方式

- 项目主页: https://pluginplatform.com
- 文档: https://docs.pluginplatform.com/plugins/world-clock
- 问题反馈: https://github.com/pluginplatform/world-clock-plugin/issues