/// 世界时钟数据模型
class WorldClockItem {
  final String id;
  final String cityName;
  final String timeZone;
  final bool isDefault;

  const WorldClockItem({
    required this.id,
    required this.cityName,
    required this.timeZone,
    required this.isDefault,
  });

  /// 获取时区显示名称（中文）
  String get displayName {
    final timeZoneInfo = TimeZoneInfo.findByTimeZoneId(timeZone);
    return timeZoneInfo?.displayName ?? cityName;
  }

  /// 获取当前时区的时间
  DateTime get currentTime {
    // 注意：这是一个简化的实现
    // 在实际应用中，应该使用更精确的时区处理库，如 timezone 包
    final now = DateTime.now().toUtc();

    // 简单的时区偏移映射
    final offsetHours = _getTimeZoneOffset(timeZone);
    return now.add(Duration(hours: offsetHours));
  }

  /// 获取格式化的时间字符串
  /// timeFormat: '12h' 或 '24h'
  String getFormattedTime(String timeFormat, {bool showSeconds = true}) {
    final time = currentTime;
    final hour = time.hour;
    final minute = time.minute;
    final second = time.second;

    String timeStr;
    if (timeFormat == '12h') {
      // 12小时制
      final period = hour >= 12 ? '下午' : '上午';
      int displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;
      timeStr =
          '${displayHour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
      if (showSeconds) {
        timeStr += ':${second.toString().padLeft(2, '0')}';
      }
      timeStr += ' $period';
    } else {
      // 24小时制
      timeStr =
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
      if (showSeconds) {
        timeStr += ':${second.toString().padLeft(2, '0')}';
      }
    }
    return timeStr;
  }

  /// 获取格式化的时间字符串（24小时制，兼容旧代码）
  @deprecated
  String get formattedTime {
    return getFormattedTime('24h', showSeconds: true);
  }

  /// 获取格式化的日期字符串
  String get formattedDate {
    final time = currentTime;
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return '${time.year}年${time.month}月${time.day}日 ${weekdays[time.weekday % 7]}';
  }

  /// 简化的时区偏移计算
  int _getTimeZoneOffset(String timeZone) {
    switch (timeZone) {
      case 'Asia/Shanghai':
      case 'Asia/Beijing':
        return 8; // UTC+8
      case 'Asia/Tokyo':
        return 9; // UTC+9
      case 'Asia/Seoul':
        return 9; // UTC+9
      case 'Asia/Singapore':
        return 8; // UTC+8
      case 'Australia/Sydney':
        return 11; // UTC+11 (考虑夏令时，这里简化处理)
      case 'Europe/London':
        return 0; // UTC+0 (考虑夏令时，这里简化处理)
      case 'Europe/Paris':
        return 1; // UTC+1 (考虑夏令时，这里简化处理)
      case 'America/New_York':
        return -5; // UTC-5 (考虑夏令时，这里简化处理)
      case 'America/Los_Angeles':
        return -8; // UTC-8 (考虑夏令时，这里简化处理)
      case 'America/Chicago':
        return -6; // UTC-6 (考虑夏令时，这里简化处理)
      default:
        return 8; // 默认北京时间
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cityName': cityName,
      'timeZone': timeZone,
      'isDefault': isDefault,
    };
  }

  factory WorldClockItem.fromJson(Map<String, dynamic> json) {
    return WorldClockItem(
      id: json['id'] as String,
      cityName: json['cityName'] as String,
      timeZone: json['timeZone'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorldClockItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 倒计时定时器模型
class CountdownTimer {
  final String id;
  final String title;
  final DateTime endTime;
  bool isCompleted;

  CountdownTimer({
    required this.id,
    required this.title,
    required this.endTime,
    required this.isCompleted,
  });

  /// 获取剩余时间
  Duration get remainingTime {
    if (isCompleted) return Duration.zero;

    final now = DateTime.now();
    if (endTime.isBefore(now)) {
      return Duration.zero;
    }

    return endTime.difference(now);
  }

  /// 获取格式化的剩余时间字符串
  String get formattedRemainingTime {
    final remaining = remainingTime;

    if (remaining == Duration.zero) {
      return '00:00:00';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取进度百分比 (0.0 - 1.0)
  double getProgress(Duration originalDuration) {
    if (isCompleted) return 1.0;

    final elapsed = originalDuration - remainingTime;
    return elapsed.inMilliseconds / originalDuration.inMilliseconds;
  }

  /// 检查是否即将完成 (剩余时间少于1分钟)
  bool get isAlmostComplete {
    return !isCompleted && remainingTime.inMinutes < 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'endTime': endTime.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory CountdownTimer.fromJson(Map<String, dynamic> json) {
    return CountdownTimer(
      id: json['id'] as String,
      title: json['title'] as String,
      endTime: DateTime.parse(json['endTime'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountdownTimer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 时区信息模型
class TimeZoneInfo {
  final String name;
  final String displayName;
  final String timeZoneId;
  final int offsetHours;
  final bool supportsDST; // 是否支持夏令时

  const TimeZoneInfo({
    required this.name,
    required this.displayName,
    required this.timeZoneId,
    required this.offsetHours,
    this.supportsDST = false,
  });

  /// 预定义的时区列表
  static const List<TimeZoneInfo> predefinedTimeZones = [
    TimeZoneInfo(
      name: 'Beijing',
      displayName: '北京',
      timeZoneId: 'Asia/Shanghai',
      offsetHours: 8,
    ),
    TimeZoneInfo(
      name: 'Tokyo',
      displayName: '东京',
      timeZoneId: 'Asia/Tokyo',
      offsetHours: 9,
    ),
    TimeZoneInfo(
      name: 'Seoul',
      displayName: '首尔',
      timeZoneId: 'Asia/Seoul',
      offsetHours: 9,
    ),
    TimeZoneInfo(
      name: 'Singapore',
      displayName: '新加坡',
      timeZoneId: 'Asia/Singapore',
      offsetHours: 8,
    ),
    TimeZoneInfo(
      name: 'Sydney',
      displayName: '悉尼',
      timeZoneId: 'Australia/Sydney',
      offsetHours: 11,
      supportsDST: true,
    ),
    TimeZoneInfo(
      name: 'London',
      displayName: '伦敦',
      timeZoneId: 'Europe/London',
      offsetHours: 0,
      supportsDST: true,
    ),
    TimeZoneInfo(
      name: 'Paris',
      displayName: '巴黎',
      timeZoneId: 'Europe/Paris',
      offsetHours: 1,
      supportsDST: true,
    ),
    TimeZoneInfo(
      name: 'New York',
      displayName: '纽约',
      timeZoneId: 'America/New_York',
      offsetHours: -5,
      supportsDST: true,
    ),
    TimeZoneInfo(
      name: 'Los Angeles',
      displayName: '洛杉矶',
      timeZoneId: 'America/Los_Angeles',
      offsetHours: -8,
      supportsDST: true,
    ),
    TimeZoneInfo(
      name: 'Chicago',
      displayName: '芝加哥',
      timeZoneId: 'America/Chicago',
      offsetHours: -6,
      supportsDST: true,
    ),
  ];

  /// 根据时区ID查找时区信息
  static TimeZoneInfo? findByTimeZoneId(String timeZoneId) {
    try {
      return predefinedTimeZones.firstWhere(
        (tz) => tz.timeZoneId == timeZoneId,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'timeZoneId': timeZoneId,
      'offsetHours': offsetHours,
      'supportsDST': supportsDST,
    };
  }

  factory TimeZoneInfo.fromJson(Map<String, dynamic> json) {
    return TimeZoneInfo(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      timeZoneId: json['timeZoneId'] as String,
      offsetHours: json['offsetHours'] as int,
      supportsDST: json['supportsDST'] as bool? ?? false,
    );
  }
}
