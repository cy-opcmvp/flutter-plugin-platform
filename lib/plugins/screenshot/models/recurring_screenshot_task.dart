library;

/// 循环截图任务状态
enum TaskStatus {
  /// 运行中
  running,

  /// 暂停
  paused,

  /// 已完成
  completed,

  /// 已停止
  stopped,
}

/// 循环截图任务模型
class RecurringScreenshotTask {
  /// 任务唯一ID
  final String id;

  /// 任务名称
  final String name;

  /// 目标窗口ID（如果为空，则全屏截图）
  final String? windowId;

  /// 目标窗口标题（用于显示）
  final String? windowTitle;

  /// 截图间隔（秒）
  final int intervalSeconds;

  /// 总截图次数（如果为null，则无限执行）
  final int? totalShots;

  /// 存放目录（如果为null，则使用默认目录）
  final String? saveDirectory;

  /// 任务状态
  final TaskStatus status;

  /// 已截图次数
  final int completedShots;

  /// 创建时间
  final DateTime createdAt;

  /// 最后截图时间
  final DateTime? lastShotTime;

  const RecurringScreenshotTask({
    required this.id,
    required this.name,
    this.windowId,
    this.windowTitle,
    required this.intervalSeconds,
    this.totalShots,
    this.saveDirectory,
    required this.status,
    this.completedShots = 0,
    required this.createdAt,
    this.lastShotTime,
  });

  /// 从 JSON 创建实例
  factory RecurringScreenshotTask.fromJson(Map<String, dynamic> json) {
    return RecurringScreenshotTask(
      id: json['id'] as String,
      name: json['name'] as String,
      windowId: json['windowId'] as String?,
      windowTitle: json['windowTitle'] as String?,
      intervalSeconds: json['intervalSeconds'] as int,
      totalShots: json['totalShots'] as int?,
      saveDirectory: json['saveDirectory'] as String?,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => TaskStatus.stopped,
      ),
      completedShots: json['completedShots'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastShotTime: json['lastShotTime'] != null
          ? DateTime.parse(json['lastShotTime'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'windowId': windowId,
      'windowTitle': windowTitle,
      'intervalSeconds': intervalSeconds,
      'totalShots': totalShots,
      'saveDirectory': saveDirectory,
      'status': status.name,
      'completedShots': completedShots,
      'createdAt': createdAt.toIso8601String(),
      'lastShotTime': lastShotTime?.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  RecurringScreenshotTask copyWith({
    String? id,
    String? name,
    String? windowId,
    String? windowTitle,
    int? intervalSeconds,
    int? totalShots,
    String? saveDirectory,
    TaskStatus? status,
    int? completedShots,
    DateTime? createdAt,
    DateTime? lastShotTime,
  }) {
    return RecurringScreenshotTask(
      id: id ?? this.id,
      name: name ?? this.name,
      windowId: windowId ?? this.windowId,
      windowTitle: windowTitle ?? this.windowTitle,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      totalShots: totalShots ?? this.totalShots,
      saveDirectory: saveDirectory ?? this.saveDirectory,
      status: status ?? this.status,
      completedShots: completedShots ?? this.completedShots,
      createdAt: createdAt ?? this.createdAt,
      lastShotTime: lastShotTime ?? this.lastShotTime,
    );
  }

  /// 是否为无限执行
  bool get isInfinite => totalShots == null;

  /// 是否已完成
  bool get isCompleted => !isInfinite && completedShots >= totalShots!;

  /// 获取进度百分比
  double get progress {
    if (isInfinite) return 0.0;
    if (totalShots == 0) return 1.0;
    return completedShots / totalShots!;
  }

  /// 格式化间隔时间显示
  String get formattedInterval {
    if (intervalSeconds < 60) {
      return '$intervalSeconds秒';
    } else if (intervalSeconds < 3600) {
      final minutes = intervalSeconds ~/ 60;
      return '$minutes分钟';
    } else {
      final hours = intervalSeconds ~/ 3600;
      return '$hours小时';
    }
  }

  /// 格式化窗口信息
  String get formattedWindowInfo {
    if (windowId == null || windowId!.isEmpty) {
      return '全屏截图';
    }
    if (windowTitle != null) {
      return windowTitle!;
    }
    return windowId!;
  }
}
