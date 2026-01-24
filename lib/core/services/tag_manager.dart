library;

import 'package:flutter/foundation.dart';
import '../models/tag_model.dart';
import 'config_service.dart';

/// 标签管理服务
///
/// 负责标签的创建、修改、删除，以及插件与标签的关联管理
class TagManager {
  static TagManager? _instance;

  /// 获取单例实例
  static TagManager get instance {
    _instance ??= TagManager._internal();
    return _instance!;
  }

  TagManager._internal();

  final ConfigService _configService = ConfigService.instance;

  /// 所有标签
  List<Tag> _tags = [];

  /// 标签变化通知器
  final ValueNotifier<List<Tag>> tagsNotifier = ValueNotifier<List<Tag>>([]);

  /// 插件与标签的映射关系 pluginId -> tagIds
  final Map<String, Set<String>> _pluginTagMap = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 所有标签
  List<Tag> get tags => List.unmodifiable(_tags);

  /// 插件与标签的映射
  Map<String, Set<String>> get pluginTagMap => Map.unmodifiable(_pluginTagMap);

  /// 初始化标签管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _configService.initialize();
      await _loadTags();
      await _loadPluginTagMap();

      // 如果没有标签，初始化系统标签
      if (_tags.isEmpty) {
        await _initializeSystemTags();
      }

      _isInitialized = true;
      debugPrint('TagManager initialized with ${_tags.length} tags');
    } catch (e) {
      debugPrint('Failed to initialize TagManager: $e');
      rethrow;
    }
  }

  /// 加载所有标签
  Future<void> _loadTags() async {
    try {
      final tagsData = await _configService.loadCustomConfig('tags');
      if (tagsData != null && tagsData['tags'] != null) {
        final tagsList = tagsData['tags'] as List;
        _tags = tagsList
            .map((json) => Tag.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _tags = [];
      }
    } catch (e) {
      debugPrint('Failed to load tags: $e');
      _tags = [];
    }
  }

  /// 加载插件与标签的映射
  Future<void> _loadPluginTagMap() async {
    try {
      final mapData = await _configService.loadCustomConfig('plugin_tags');
      if (mapData != null) {
        _pluginTagMap.clear();
        mapData.forEach((pluginId, tagIds) {
          if (tagIds is List) {
            _pluginTagMap[pluginId] = (tagIds as List).cast<String>().toSet();
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load plugin tag map: $e');
      _pluginTagMap.clear();
    }
  }

  /// 初始化系统标签
  Future<void> _initializeSystemTags() async {
    _tags = List.from(SystemTags.all);
    await _saveTags();

    // 为现有插件设置默认标签
    await _initializeDefaultPluginTags();

    debugPrint('Initialized ${_tags.length} system tags');
  }

  /// 为现有插件初始化默认标签
  Future<void> _initializeDefaultPluginTags() async {
    // 截图插件 -> 生产力工具 + 常用
    await setPluginTags('com.example.screenshot', {
      'tag_productivity',
      'tag_system',
      'tag_favorite',
    });

    // 世界时钟 -> 生产力工具 + 常用
    await setPluginTags('com.example.worldclock', {
      'tag_productivity',
      'tag_favorite',
    });

    // 计算器 -> 生产力工具
    await setPluginTags('com.example.calculator', {'tag_productivity'});

    // 桌面宠物 -> 娱乐休闲 + 常用
    await setPluginTags('com.example.desktop_pet', {
      'tag_entertainment',
      'tag_favorite',
    });

    await _savePluginTagMap();
    debugPrint('Initialized default plugin tags');
  }

  /// 保存所有标签
  Future<void> _saveTags() async {
    await _configService.saveCustomConfig('tags', {
      'tags': _tags.map((tag) => tag.toJson()).toList(),
    });
    // 通知标签变化
    tagsNotifier.value = List.unmodifiable(_tags);
  }

  /// 保存插件标签映射
  Future<void> _savePluginTagMap() async {
    final mapData = <String, dynamic>{};
    _pluginTagMap.forEach((pluginId, tagIds) {
      mapData[pluginId] = tagIds.toList();
    });
    await _configService.saveCustomConfig('plugin_tags', mapData);
  }

  /// 获取所有标签
  List<Tag> getAllTags() {
    return List.unmodifiable(_tags);
  }

  /// 根据ID获取标签
  Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建新标签
  Future<Tag> createTag({
    required String name,
    String description = '',
    required TagColor color,
    String? icon,
  }) async {
    final id = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    final tag = Tag(
      id: id,
      name: name,
      description: description,
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      isSystem: false,
      sortOrder: _tags.length,
    );

    if (!tag.isValid()) {
      throw ArgumentError('Invalid tag data');
    }

    _tags.add(tag);
    await _saveTags();

    debugPrint('Created tag: $name ($id)');
    return tag;
  }

  /// 更新标签
  Future<void> updateTag(Tag updatedTag) async {
    final index = _tags.indexWhere((tag) => tag.id == updatedTag.id);
    if (index == -1) {
      throw StateError('Tag not found: ${updatedTag.id}');
    }

    if (!updatedTag.isValid()) {
      throw ArgumentError('Invalid tag data');
    }

    _tags[index] = updatedTag;
    await _saveTags();

    debugPrint('Updated tag: ${updatedTag.name}');
  }

  /// 删除标签
  Future<void> deleteTag(String tagId) async {
    final tag = getTagById(tagId);
    if (tag == null) {
      throw StateError('Tag not found: $tagId');
    }

    _tags.removeWhere((t) => t.id == tagId);

    // 从所有插件中移除该标签
    _pluginTagMap.forEach((pluginId, tagIds) {
      tagIds.remove(tagId);
    });

    await _saveTags();
    await _savePluginTagMap();

    debugPrint('Deleted tag: $tagId');
  }

  /// 获取插件的所有标签
  Set<String> getPluginTags(String pluginId) {
    return Set.unmodifiable(_pluginTagMap[pluginId] ?? {});
  }

  /// 设置插件的标签
  Future<void> setPluginTags(String pluginId, Set<String> tagIds) async {
    // 验证所有标签ID是否存在
    for (final tagId in tagIds) {
      if (!tags.any((tag) => tag.id == tagId)) {
        throw ArgumentError('Tag not found: $tagId');
      }
    }

    _pluginTagMap[pluginId] = Set.from(tagIds);
    await _savePluginTagMap();

    debugPrint('Set tags for plugin $pluginId: $tagIds');
  }

  /// 为插件添加标签
  Future<void> addPluginTag(String pluginId, String tagId) async {
    if (!tags.any((tag) => tag.id == tagId)) {
      throw ArgumentError('Tag not found: $tagId');
    }

    _pluginTagMap.putIfAbsent(pluginId, () => {});
    _pluginTagMap[pluginId]!.add(tagId);

    await _savePluginTagMap();

    debugPrint('Added tag $tagId to plugin $pluginId');
  }

  /// 从插件移除标签
  Future<void> removePluginTag(String pluginId, String tagId) async {
    if (_pluginTagMap.containsKey(pluginId)) {
      _pluginTagMap[pluginId]!.remove(tagId);
      await _savePluginTagMap();

      debugPrint('Removed tag $tagId from plugin $pluginId');
    }
  }

  /// 根据标签获取插件列表
  List<String> getPluginsByTag(String tagId) {
    return _pluginTagMap.entries
        .where((entry) => entry.value.contains(tagId))
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取常用的标签（使用频率最高的）
  List<Tag> getPopularTags({int limit = 5}) {
    final tagUsage = <String, int>{};

    // 统计每个标签的使用次数
    _pluginTagMap.forEach((pluginId, tagIds) {
      for (final tagId in tagIds) {
        tagUsage[tagId] = (tagUsage[tagId] ?? 0) + 1;
      }
    });

    // 按使用次数排序
    final sortedTags = _tags.toList()
      ..sort((a, b) {
        final aUsage = tagUsage[a.id] ?? 0;
        final bUsage = tagUsage[b.id] ?? 0;
        if (aUsage != bUsage) {
          return bUsage.compareTo(aUsage);
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return sortedTags.take(limit).toList();
  }

  /// 搜索标签
  List<Tag> searchTags(String query) {
    if (query.isEmpty) return getAllTags();

    final lowerQuery = query.toLowerCase();
    return _tags
        .where(
          (tag) =>
              tag.name.toLowerCase().contains(lowerQuery) ||
              tag.description.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// 检查标签是否在使用中
  bool isTagInUse(String tagId) {
    return _pluginTagMap.values.any((tagIds) => tagIds.contains(tagId));
  }
}
