library;

import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/tag_model.dart';
import '../../core/services/tag_manager.dart';
import '../../core/services/tag_color_helper.dart';

/// 标签管理界面
///
/// 提供标签的增删改查功能，采用卡片式网格布局
class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final TagManager _tagManager = TagManager.instance;
  List<Tag> _tags = [];
  List<Tag> _filteredTags = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _tagManager.initialize();
      _tags = _tagManager.getAllTags();
      _filteredTags = _tags;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.error_loadFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTags(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTags = _tags;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTags = _tags
            .where(
              (tag) =>
                  tag.name.toLowerCase().contains(lowerQuery) ||
                  tag.description.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
    });
  }

  Future<void> _createTag() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => const _TagEditDialog(),
    );

    if (result != null) {
      try {
        await _tagManager.createTag(
          name: result.name,
          description: result.description,
          color: result.color,
          icon: result.icon,
        );
        await _loadTags();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.tag_create_success),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.error_operationFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editTag(Tag tag) async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => _TagEditDialog(tag: tag),
    );

    if (result != null) {
      try {
        await _tagManager.updateTag(result);
        await _loadTags();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.tag_update_success),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.error_operationFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tag_delete),
        content: Text(context.l10n.tag_delete_confirm(tag.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 检查标签是否在使用中
        if (_tagManager.isTagInUse(tag.id)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.tag_in_use),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        await _tagManager.deleteTag(tag.id);
        await _loadTags();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.tag_delete_success),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.error_operationFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tag_title),
        actions: [
          IconButton(
            onPressed: _createTag,
            icon: const Icon(Icons.add),
            tooltip: l10n.tag_add,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜索框和新增按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.common_search,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: _filterTags,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _createTag,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.tag_add),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 标签网格
                Expanded(
                  child: _filteredTags.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 4 / 3,
                            ),
                            itemCount: _filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = _filteredTags[index];
                              return _buildTagCard(tag);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? l10n.hint_noResults
                : l10n.tag_no_tags,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.tag_create_hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createTag,
              icon: const Icon(Icons.add),
              label: Text(l10n.tag_add),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagCard(Tag tag) {
    final color = TagColorHelper.getTagColor(tag.color);
    final pluginCount = _tagManager.getPluginsByTag(tag.id).length;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _editTag(tag),
        onLongPress: () => _deleteTag(tag),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标签头部：图标 + 名称
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        tag.icon ?? '🏷️',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tag.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (tag.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tag.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: '编辑',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _editTag(tag),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    tooltip: '删除',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteTag(tag),
                  ),
                ],
              ),
              // 底部信息：插件数量
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$pluginCount 个插件',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签编辑对话框
class _TagEditDialog extends StatefulWidget {
  final Tag? tag;

  const _TagEditDialog({this.tag});

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _iconController;
  late TagColor _selectedColor;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _descriptionController = TextEditingController(text: widget.tag?.description ?? '');
    _iconController = TextEditingController(text: widget.tag?.icon ?? '');
    _selectedColor = widget.tag?.color ?? TagColor.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.tag != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.tag_edit : l10n.tag_add),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标签名称
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.tag_name,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.hint_inputRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 标签描述
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.tag_description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // 标签图标
              TextFormField(
                controller: _iconController,
                decoration: InputDecoration(
                  labelText: l10n.tag_icon,
                  border: const OutlineInputBorder(),
                  hintText: '🏷️',
                  suffixIcon: const Icon(Icons.emoji_emotions),
                ),
              ),
              const SizedBox(height: 8),

              // 预设图标选择
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '或选择预设图标',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getPresetIcons(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 颜色选择
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tag_color,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TagColor.values.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: TagColorHelper.getTagColor(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.white,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final tag = Tag(
                id: widget.tag?.id ?? '',
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                color: _selectedColor,
                icon: _iconController.text.trim().isEmpty ? null : _iconController.text.trim(),
                createdAt: widget.tag?.createdAt,
                isSystem: widget.tag?.isSystem ?? false,
                sortOrder: widget.tag?.sortOrder ?? 0,
              );
              Navigator.of(context).pop(tag);
            }
          },
          child: Text(l10n.common_save),
        ),
      ],
    );
  }

  /// 获取预设图标列表
  List<Widget> _getPresetIcons() {
    final presetIcons = [
      '🏷️', // 标签
      '⭐', // 星星
      '❤️', // 爱心
      '🔥', // 火焰
      '💡', // 灯泡
      '🎯', // 目标
      '📌', // 图钉
      '🚀', // 火箭
      '💎', // 钻石
      '🎨', // 调色板
      '🔧', // 扳手
      '📱', // 手机
      '💻', // 电脑
      '🎮', // 游戏
      '🎬', // 电影
      '📚', // 书本
      '🏠', // 房子
      '🌟', // 闪亮
      '✅', // 勾选
      '📊', // 图表
      '🔔', // 铃铛
      '🎁', // 礼物
      '📷', // 相机
      '🎵', // 音乐
    ];

    return presetIcons.map((icon) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _iconController.text = icon;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      );
    }).toList();
  }
}
