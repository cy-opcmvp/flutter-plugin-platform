library;

import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/tag_model.dart';
import '../../core/services/tag_manager.dart';

/// 标签管理界面
///
/// 提供标签的增删改查功能
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
    if (tag.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tag_system_protected),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
    if (tag.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tag_system_protected),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                // 搜索框
                Padding(
                  padding: const EdgeInsets.all(16),
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

                // 标签列表
                Expanded(
                  child: _filteredTags.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tag,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? l10n.hint_noResults
                                    : l10n.tag_no_tags,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tag_create_hint,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTags.length,
                          itemBuilder: (context, index) {
                            final tag = _filteredTags[index];
                            return _buildTagTile(tag);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTagTile(Tag tag) {
    final color = _getTagColor(tag.color);
    final pluginCount = _tagManager.getPluginsByTag(tag.id).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(tag.icon ?? '🏷️', style: const TextStyle(fontSize: 20)),
        ),
        title: Row(
          children: [
            Text(tag.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (tag.isSystem) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '系统',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(tag.description),
            ],
            const SizedBox(height: 4),
            Text(
              '$pluginCount 个插件使用',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: tag.isSystem
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editTag(tag);
                      break;
                    case 'delete':
                      _deleteTag(tag);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(context.l10n.tag_edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.tag_delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () => _editTag(tag),
      ),
    );
  }

  Color _getTagColor(TagColor color) {
    switch (color) {
      case TagColor.blue:
        return Colors.blue;
      case TagColor.green:
        return Colors.green;
      case TagColor.orange:
        return Colors.orange;
      case TagColor.purple:
        return Colors.purple;
      case TagColor.red:
        return Colors.red;
      case TagColor.teal:
        return Colors.teal;
      case TagColor.indigo:
        return Colors.indigo;
      case TagColor.pink:
        return Colors.pink;
    }
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
    _descriptionController = TextEditingController(
      text: widget.tag?.description ?? '',
    );
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
      content: Form(
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
              ),
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
                  children: TagColor.values.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getTagColor(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
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
                icon: _iconController.text.trim().isEmpty
                    ? null
                    : _iconController.text.trim(),
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

  Color _getTagColor(TagColor color) {
    switch (color) {
      case TagColor.blue:
        return Colors.blue;
      case TagColor.green:
        return Colors.green;
      case TagColor.orange:
        return Colors.orange;
      case TagColor.purple:
        return Colors.purple;
      case TagColor.red:
        return Colors.red;
      case TagColor.teal:
        return Colors.teal;
      case TagColor.indigo:
        return Colors.indigo;
      case TagColor.pink:
        return Colors.pink;
    }
  }
}
