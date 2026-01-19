library;

import 'package:flutter/foundation.dart';

/// 标签颜色主题
enum TagColor { blue, green, orange, purple, red, teal, indigo, pink }

/// 标签模型
class Tag {
  /// 标签ID
  final String id;

  /// 标签名称
  final String name;

  /// 标签描述
  final String description;

  /// 标签颜色
  final TagColor color;

  /// 标签图标（可选）
  final String? icon;

  /// 创建时间
  final DateTime createdAt;

  /// 是否为系统标签（不可删除）
  final bool isSystem;

  /// 排序顺序
  final int sortOrder;

  Tag({
    required this.id,
    required this.name,
    this.description = '',
    required this.color,
    this.icon,
    DateTime? createdAt,
    this.isSystem = false,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 创建
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: TagColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => TagColor.blue,
      ),
      icon: json['icon'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isSystem: json['isSystem'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.name,
      if (icon != null) 'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'isSystem': isSystem,
      'sortOrder': sortOrder,
    };
  }

  /// 复制并修改
  Tag copyWith({
    String? id,
    String? name,
    String? description,
    TagColor? color,
    String? icon,
    DateTime? createdAt,
    bool? isSystem,
    int? sortOrder,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// 验证标签是否有效
  bool isValid() {
    return id.isNotEmpty && name.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 预定义的系统标签
class SystemTags {
  /// 生产力工具
  static final productivity = Tag(
    id: 'tag_productivity',
    name: '生产力工具',
    description: '提高工作效率的工具',
    color: TagColor.blue,
    icon: '⚡',
    isSystem: true,
    sortOrder: 1,
  );

  /// 系统工具
  static final system = Tag(
    id: 'tag_system',
    name: '系统工具',
    description: '系统相关工具',
    color: TagColor.orange,
    icon: '🔧',
    isSystem: true,
    sortOrder: 2,
  );

  /// 娱乐休闲
  static final entertainment = Tag(
    id: 'tag_entertainment',
    name: '娱乐休闲',
    description: '娱乐和休闲应用',
    color: TagColor.pink,
    icon: '🎮',
    isSystem: true,
    sortOrder: 3,
  );

  /// 游戏
  static final game = Tag(
    id: 'tag_game',
    name: '游戏',
    description: '游戏相关',
    color: TagColor.purple,
    icon: '🎯',
    isSystem: true,
    sortOrder: 4,
  );

  /// 开发工具
  static final development = Tag(
    id: 'tag_development',
    name: '开发工具',
    description: '开发者工具',
    color: TagColor.green,
    icon: '💻',
    isSystem: true,
    sortOrder: 5,
  );

  /// 常用
  static final favorite = Tag(
    id: 'tag_favorite',
    name: '常用',
    description: '常用插件',
    color: TagColor.red,
    icon: '⭐',
    isSystem: true,
    sortOrder: 0,
  );

  /// 所有系统标签列表
  static final List<Tag> all = [
    favorite,
    productivity,
    system,
    entertainment,
    game,
    development,
  ];
}

/// 标签过滤器
class TagFilter {
  final Set<String> selectedTagIds;
  final String? searchQuery;

  const TagFilter({this.selectedTagIds = const {}, this.searchQuery});

  /// 检查插件是否匹配过滤器
  bool matches(
    Set<String> pluginTagIds,
    String pluginName,
    String pluginDescription,
  ) {
    // 检查标签匹配
    if (selectedTagIds.isNotEmpty) {
      final hasMatchingTag = pluginTagIds.any(selectedTagIds.contains);
      if (!hasMatchingTag) return false;
    }

    // 检查搜索匹配
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      final matchesName = pluginName.toLowerCase().contains(query);
      final matchesDescription = pluginDescription.toLowerCase().contains(
        query,
      );
      if (!matchesName && !matchesDescription) return false;
    }

    return true;
  }

  /// 检查是否有活动过滤器
  bool get isActive =>
      selectedTagIds.isNotEmpty ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// 复制并修改
  TagFilter copyWith({Set<String>? selectedTagIds, String? searchQuery}) {
    return TagFilter(
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagFilter &&
        other.selectedTagIds.toString() == selectedTagIds.toString() &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(selectedTagIds, searchQuery);
}
