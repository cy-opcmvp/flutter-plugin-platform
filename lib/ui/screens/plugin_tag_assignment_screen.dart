library;

import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/plugins/plugin_registry.dart';
import 'package:plugin_platform/core/models/plugin_models.dart';
import 'package:plugin_platform/core/services/tag_manager.dart';
import 'package:plugin_platform/core/models/tag_model.dart';
import 'package:plugin_platform/core/services/plugin_metadata.dart';
import 'package:plugin_platform/core/services/tag_color_helper.dart';

/// 插件标签关联界面
///
/// 展示所有插件，允许为每个插件设置标签
class PluginTagAssignmentScreen extends StatefulWidget {
  const PluginTagAssignmentScreen({super.key});

  @override
  State<PluginTagAssignmentScreen> createState() =>
      _PluginTagAssignmentScreenState();
}

class _PluginTagAssignmentScreenState extends State<PluginTagAssignmentScreen> {
  final TagManager _tagManager = TagManager.instance;

  /// 插件列表
  List<PluginDescriptor> _plugins = [];

  /// 标签列表
  List<Tag> _tags = [];

  /// 插件与标签的映射缓存
  final Map<String, Set<String>> _pluginTagCache = {};

  /// 加载状态
  bool _isLoading = true;

  /// 搜索关键词
  String _searchQuery = '';

  /// 标签过滤器
  final Set<String> _selectedTagFilter = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 初始化 TagManager
      await _tagManager.initialize();

      // 加载插件列表
      _plugins = ExamplePluginRegistry.getAllDescriptors();

      // 加载标签列表
      _tags = _tagManager.getAllTags();

      // 加载插件标签映射
      _pluginTagCache.clear();
      for (final plugin in _plugins) {
        _pluginTagCache[plugin.id] = _tagManager.getPluginTags(plugin.id);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Failed to load data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 过滤插件列表
  List<PluginDescriptor> get _filteredPlugins {
    var filtered = _plugins.toList();

    // 按搜索关键词过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((plugin) => plugin.name.toLowerCase().contains(query))
          .toList();
    }

    // 按标签过滤
    if (_selectedTagFilter.isNotEmpty) {
      filtered = filtered.where((plugin) {
        final tagIds = _pluginTagCache[plugin.id] ?? {};
        return tagIds.any(_selectedTagFilter.contains);
      }).toList();
    }

    return filtered;
  }

  /// 为插件设置标签
  Future<void> _assignTagsToPlugin(PluginDescriptor plugin) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PluginTagSelectionDialog(
        plugin: plugin,
        allTags: _tags,
        selectedTagIds: _pluginTagCache[plugin.id] ?? {},
      ),
    );

    if (result != null) {
      try {
        await _tagManager.setPluginTags(plugin.id, result);
        setState(() {
          _pluginTagCache[plugin.id] = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.tag_assign_success),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.error_loadFailed(e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tag_plugin_assignment_title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜索栏
                _buildSearchBar(l10n),

                // 标签过滤器
                _buildTagFilter(l10n),

                // 插件列表
                Expanded(
                  child: _filteredPlugins.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredPlugins.length,
                          itemBuilder: (context, index) {
                            final plugin = _filteredPlugins[index];
                            return _buildPluginTile(plugin);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.tag_search_plugins,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  /// 构建标签过滤器
  Widget _buildTagFilter(AppLocalizations l10n) {
    if (_tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = _selectedTagFilter.contains(tag.id);
          final color = TagColorHelper.getTagColor(tag.color);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTagFilter.add(tag.id);
                  } else {
                    _selectedTagFilter.remove(tag.id);
                  }
                });
              },
              selectedColor: color.withValues(alpha: 0.3),
              checkmarkColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(
                color: isSelected ? color : color.withValues(alpha: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建插件卡片
  Widget _buildPluginTile(PluginDescriptor plugin) {
    final tagIds = _pluginTagCache[plugin.id] ?? {};
    final pluginTags = tagIds
        .map((id) => _tagManager.getTagById(id))
        .whereType<Tag>()
        .toList();

    final l10n = AppLocalizations.of(context)!;
    final pluginName = PluginMetadata.instance.getPluginName(plugin.id, context);
    final pluginIcon = PluginMetadata.instance.getPluginIcon(plugin.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: CircleAvatar(
          child: Icon(
            pluginIcon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          pluginName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签显示
            if (pluginTags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: pluginTags.take(3).map((tag) {
                  final color = TagColorHelper.getTagColor(tag.color);
                  return Chip(
                    label: Text(
                      tag.name,
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                    backgroundColor: TagColorHelper.getTagColorLight(tag.color),
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        onTap: () => _assignTagsToPlugin(plugin),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.extension_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            l10n.tag_no_plugins_found,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// 插件标签选择对话框
class _PluginTagSelectionDialog extends StatefulWidget {
  final PluginDescriptor plugin;
  final List<Tag> allTags;
  final Set<String> selectedTagIds;

  const _PluginTagSelectionDialog({
    required this.plugin,
    required this.allTags,
    required this.selectedTagIds,
  });

  @override
  State<_PluginTagSelectionDialog> createState() =>
      _PluginTagSelectionDialogState();
}

class _PluginTagSelectionDialogState extends State<_PluginTagSelectionDialog> {
  late Set<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set.from(widget.selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.tag_select_tags_for_plugin),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 插件信息
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    widget.plugin.name.isNotEmpty
                        ? widget.plugin.name[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plugin.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.plugin.version,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 已选标签
            if (_selectedTagIds.isNotEmpty) ...[
              Text(
                l10n.tag_selected_tags,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTagIds.map((tagId) {
                  final tag = widget.allTags.firstWhere(
                    (t) => t.id == tagId,
                    orElse: () => throw StateError('Tag not found: $tagId'),
                  );
                  final color = TagColorHelper.getTagColor(tag.color);
                  return Chip(
                    label: Text(tag.name),
                    backgroundColor: color.withValues(alpha: 0.2),
                    side: BorderSide(color: color),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedTagIds.remove(tagId);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // 所有标签
            Text(
              l10n.tag_all_available_tags,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.allTags.length,
                itemBuilder: (context, index) {
                  final tag = widget.allTags[index];
                  final isSelected = _selectedTagIds.contains(tag.id);
                  final color = TagColorHelper.getTagColor(tag.color);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(tag.name),
                    subtitle: tag.description.isNotEmpty
                        ? Text(
                            tag.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    secondary: Icon(Icons.label, color: color),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedTagIds.add(tag.id);
                        } else {
                          _selectedTagIds.remove(tag.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTagIds);
          },
          child: Text(l10n.common_confirm),
        ),
      ],
    );
  }
}
