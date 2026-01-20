# 计算器插件配置说明

## 配置概述

计算器插件配置文件定义了计算器的精度、角度模式、历史记录管理、内存管理、界面显示和交互反馈等行为。所有配置项都有合理的默认值，一般情况下无需修改。

## 配置项说明

### version
- **类型**: `string`
- **默认值**: `"1.0.0"`
- **说明**: 配置文件版本号，用于未来的配置迁移和兼容性管理
- **注意**: 不要手动修改此字段

### precision
- **类型**: `integer`
- **默认值**: `10`
- **取值范围**: `0-15`
- **说明**: 计算精度，指定小数点后保留的最大位数
- **影响**: 影响除法、三角函数、对数等运算的结果精度
- **建议**:
  - 一般计算: `10`
  - 高精度计算: `15`
  - 快速计算: `5`
- **示例**:
  ```json
  "precision": 10  // 保留10位小数
  ```

### angleMode
- **类型**: `string`
- **默认值**: `"deg"`
- **可选值**: `"deg"`, `"rad"`
- **说明**: 角度模式，控制三角函数计算的角度单位
- **选项**:
  - `"deg"` - 角度制 (0-360°)，日常使用
  - `"rad"` - 弧度制 (0-2π)，数学和工程使用
- **示例**:
  ```json
  "angleMode": "deg"  // 使用角度制
  ```

### historySize
- **类型**: `integer`
- **默认值**: `50`
- **取值范围**: `10-500`
- **说明**: 历史记录保存的最大数量
- **影响**: 控制可以回溯查看之前的计算结果的数量
- **建议**:
  - 轻度使用: `20-30`
  - 一般使用: `50`
  - 重度使用: `100-200`
- **注意**: 增加此值会占用更多内存
- **示例**:
  ```json
  "historySize": 50  // 保存50条历史记录
  ```

### memorySlots
- **类型**: `integer`
- **默认值**: `10`
- **取值范围**: `1-20`
- **说明**: 内存槽位的数量，用于存储临时计算结果
- **功能**: 支持标准的计算器内存操作
  - `M+` - 将当前值加到内存
  - `M-` - 从内存减去当前值
  - `MR` - 读取内存值
  - `MC` - 清除内存
- **建议**: 大多数用户使用默认值 `10` 即可
- **示例**:
  ```json
  "memorySlots": 10  // 提供10个内存槽位
  ```

### showGroupingSeparator
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 是否显示千分位分隔符，提高大数字的可读性
- **效果对比**:
  - `true`: `1,234,567.89`
  - `false`: `1234567.89`
- **建议**: 保持默认值 `true`，除非有特殊需求
- **示例**:
  ```json
  "showGroupingSeparator": true  // 显示千分位分隔符
  ```

### enableVibration
- **类型**: `boolean`
- **默认值**: `true`
- **说明**: 按键时是否启用振动反馈（仅支持振动的设备）
- **平台支持**:
  - Android: 支持
  - iOS: 支持
  - Windows: 不支持（配置无效）
  - macOS: 不支持（配置无效）
  - Linux: 不支持（配置无效）
  - Web: 不支持（配置无效）
- **建议**:
  - 移动设备: `true`（提升手感）
  - 桌面平台: 可设为 `false`（无效果）
- **示例**:
  ```json
  "enableVibration": true  // 启用振动反馈
  ```

### buttonSoundVolume
- **类型**: `integer`
- **默认值**: `50`
- **取值范围**: `0-100`
- **说明**: 按键音效的音量
- **效果**:
  - `0` - 静音
  - `1-49` - 较小音量
  - `50-100` - 较大音量
- **建议**:
  - 安静环境: `0-20`
  - 一般环境: `40-60`
  - 嘈杂环境: `80-100`
- **示例**:
  ```json
  "buttonSoundVolume": 50  // 50% 音量
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
  "precision": 10,
  "angleMode": "deg",
  "historySize": 50,
  "memorySlots": 10,
  "showGroupingSeparator": true,
  "enableVibration": true,
  "buttonSoundVolume": 50
}
```

### 高精度计算配置
```json
{
  "version": "1.0.0",
  "precision": 15,
  "angleMode": "rad",
  "historySize": 100,
  "memorySlots": 10,
  "showGroupingSeparator": true,
  "enableVibration": false,
  "buttonSoundVolume": 0
}
```

### 移动设备优化配置
```json
{
  "version": "1.0.0",
  "precision": 8,
  "angleMode": "deg",
  "historySize": 30,
  "memorySlots": 5,
  "showGroupingSeparator": true,
  "enableVibration": true,
  "buttonSoundVolume": 70
}
```

## 配置验证

所有配置项在保存前都会进行验证，不符合规范的配置将被拒绝：

- ✅ `precision`: 必须在 0-15 范围内
- ✅ `angleMode`: 必须是 "deg" 或 "rad"
- ✅ `historySize`: 必须在 10-500 范围内
- ✅ `memorySlots`: 必须在 1-20 范围内
- ✅ `buttonSoundVolume`: 必须在 0-100 范围内

## 常见问题

### Q: 如何提高计算精度？
**A**: 增加 `precision` 值，最大可设为 15。

### Q: 如何在计算器和数学软件之间切换？
**A**: 将 `angleMode` 在 "deg"（角度制）和 "rad"（弧度制）之间切换。

### Q: 如何关闭按键音效？
**A**: 将 `buttonSoundVolume` 设为 0。

### Q: 历史记录太多会影响性能吗？
**A**: 不会。历史记录限制在 500 条以内，内存占用很小。

### Q: 为什么振动在桌面平台没有效果？
**A**: 振动反馈仅在支持的移动平台（Android、iOS）上有效。

## 更新日志

- **v1.0.0** (2026-01-19) - 初始版本
