# 世界时钟插件配置说明

## 配置概述

世界时钟插件配置文件定义了默认时区、时间格式、显示选项、通知设置和更新频率等行为。所有配置项都有合理的默认值，一般情况下无需修改。

## 配置项说明

### version
- **类型**: `string`
- **默认值**: `"1.0.0"`
- **说明**: 配置文件版本号，用于未来的配置迁移和兼容性管理
- **注意**: 不要手动修改此字段

### defaultTimeZone
- **类型**: `string`
- **默认值**: `"Asia/Shanghai"`
- **说明**: 默认显示的时区，使用 IANA 时区标识符
- **常用时区**:
  - `"Asia/Shanghai"` - 北京时间 (UTC+8)
  - `"America/New_York"` - 纽约时间 (UTC-5/UTC-4)
  - `"Europe/London"` - 伦敦时间 (UTC+0/UTC+1)
  - `"Asia/Tokyo"` - 东京时间 (UTC+9)
  - `"Europe/Paris"` - 巴黎时间 (UTC+1/UTC+2)
  - `"Australia/Sydney"` - 悉尼时间 (UTC+10/UTC+11)
- **完整列表**: [IANA 时区数据库](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
- **示例**:
  ```json
  "defaultTimeZone": "Asia/Shanghai"  // 北京时间
  ```

### timeFormat
- **类型**: `string`
- **默认值**: `"24h"`
- **可选值**: `"12h"`, `"24h"`
- **说明**: 时间显示格式
- **选项**:
  - `"12h"` - 12小时制，带上午/下午标识（如：下午 3:30）
  - `"24h"` - 24小时制（如：15:30）
- **建议**: 根据个人偏好和地区习惯选择
- **示例**:
  ```json
  "timeFormat": "24h"  // 使用24小时制
  ```

### showSeconds
- **类型**: `boolean`
- **默认值**: `false`
- **说明**: 是否显示秒数
- **效果对比**:
  - `true`: `15:30:45`
  - `false`: `15:30`
- **建议**:
  - 需要精确时间: `true`
  - 简洁显示: `false`
- **注意**: 显示秒数会略微增加界面宽度
- **示例**:
  ```json
  "showSeconds": false  // 不显示秒数
  ```

### enableNotifications
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 倒计时完成时是否显示系统通知
- **平台支持**:
  - Windows: 支持
  - macOS: 支持
  - Linux: 支持
  - Android: 支持
  - iOS: 支持
  - Web: 部分支持（取决于浏览器权限）
- **建议**: 保持默认值 `true`，确保不会错过倒计时
- **示例**:
  ```json
  "enableNotifications": true  // 启用通知
  ```

### updateInterval
- **类型**: `integer`
- **默认值**: `1000`
- **取值范围**: `100-60000`
- **单位**: 毫秒
- **说明**: 时钟更新间隔，控制时间显示的刷新频率
- **常用值**:
  - `100` (0.1秒) - 高精度显示，秒数平滑更新
  - `1000` (1秒) - 标准更新，推荐值
  - `5000` (5秒) - 低频更新，节省资源
  - `60000` (1分钟) - 仅显示分钟
- **性能影响**:
  - 较小的值 = 更流畅的动画，更高的 CPU 占用
  - 较大的值 = 更低的资源占用，但时间更新可能延迟
- **建议**:
  - 一般使用: `1000`（默认值）
  - 节省电量: `5000` 或更大
  - 秒级精度: `100` 或 `500`
- **示例**:
  ```json
  "updateInterval": 1000  // 每秒更新一次
  ```

## 配置示例

### 最小配置（使用所有默认值）
```json
{
}
```

### 默认配置（显式指定）
```json
{
  "version": "1.0.0",
  "defaultTimeZone": "Asia/Shanghai",
  "timeFormat": "24h",
  "showSeconds": false,
  "enableNotifications": true,
  "updateInterval": 1000
}
```

### 精确时间显示配置
```json
{
  "version": "1.0.0",
  "defaultTimeZone": "Asia/Shanghai",
  "timeFormat": "24h",
  "showSeconds": true,
  "enableNotifications": true,
  "updateInterval": 100
}
```

### 12小时制配置（适合美国用户）
```json
{
  "version": "1.0.0",
  "defaultTimeZone": "America/New_York",
  "timeFormat": "12h",
  "showSeconds": false,
  "enableNotifications": true,
  "updateInterval": 1000
}
```

### 低功耗配置（适合移动设备）
```json
{
  "version": "1.0.0",
  "defaultTimeZone": "Asia/Shanghai",
  "timeFormat": "24h",
  "showSeconds": false,
  "enableNotifications": true,
  "updateInterval": 5000
}
```

## 配置验证

所有配置项在保存前都会进行验证，不符合规范的配置将被拒绝：

- ✅ `timeFormat`: 必须是 "12h" 或 "24h"
- ✅ `updateInterval`: 必须在 100-60000 范围内

## 常见问题

### Q: 如何添加多个时区？
**A**: 配置文件中的 `defaultTimeZone` 只是默认值。你可以在应用界面中添加多个时区，无需修改配置文件。

### Q: 如何使用12小时制？
**A**: 将 `timeFormat` 设置为 "12h"。

### Q: 时间不准确怎么办？
**A**: 世界时钟使用系统时间，请检查设备的系统时间设置是否正确。

### Q: 如何让时间更新更流畅？
**A**: 将 `updateInterval` 设置为 100（0.1秒）并启用 `showSeconds`。

### Q: 倒计时通知没有显示？
**A**: 请检查：
  1. `enableNotifications` 是否为 `true`
  2. 系统通知权限是否已授予
  3. 是否开启了专注模式或勿扰模式

### Q: 如何找到我的时区标识符？
**A**: 访问 [IANA 时区数据库](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) 搜索你的城市。

## 技术说明

### 时区处理
- 使用 IANA 时区标识符（如 "Asia/Shanghai"）
- 自动处理夏令时（DST）调整
- 基于系统的时区数据库，确保准确性

### 更新机制
- 使用 `Timer.periodic` 定期更新时间显示
- 即使应用在后台，也会保持时间更新
- 自动处理时区变化（如跨时区旅行）

### 通知系统
- 使用平台原生通知 API
- 支持通知声音和震动（取决于平台）
- 通知点击可快速返回应用

## 更新日志

- **v1.0.0** (2026-01-19) - 初始版本
