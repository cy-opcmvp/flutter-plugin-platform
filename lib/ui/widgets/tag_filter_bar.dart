library;

import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/models/tag_model.dart';

/// 标签筛选器组件
///
/// 用于在首页和配置页面显示标签筛选功能
class TagFilterBar extends StatefulWidget {
  /// 所有可用标签
  final List<Tag> tags;

  /// 当前选中的标签ID集合
  final Set<String> selectedTagIds;

  /// 标签选择变化回调
  final ValueChanged<Set<String>>? onTagSelectionChanged;

  /// 是否显示搜索框
  final bool showSearch;

  /// 是否显示"全部"选项
  final bool showAllOption;

  /// 标签显示模式（chip 或 list）
  final TagDisplayMode displayMode;

  /// 是否显示标题
  final bool showTitle;

  const TagFilterBar({
    super.key,
    required this.tags,
    this.selectedTagIds = const {},
    this.onTagSelectionChanged,
    this.showSearch = false,
    this.showAllOption = true,
    this.displayMode = TagDisplayMode.chip,
    this.showTitle = true,
  });

  @override
  State<TagFilterBar> createState() => _TagFilterBarState();
}

class _TagFilterBarState extends State<TagFilterBar> {
  late Set<String> _selectedTagIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set.from(widget.selectedTagIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTagTapped(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });

    widget.onTagSelectionChanged?.call(_selectedTagIds);
  }

  void _clearAll() {
    setState(() {
      _selectedTagIds.clear();
    });
    widget.onTagSelectionChanged?.call(_selectedTagIds);
  }

  List<Tag> get _filteredTags {
    var filtered = List<Tag>.from(widget.tags);

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (tag) =>
                tag.name.toLowerCase().contains(query) ||
                tag.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // 排序：按 sortOrder 排序
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredTags = _filteredTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题和操作按钮
        if (widget.showTitle)
          Row(
            children: [
              Text(
                l10n.tag_title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_selectedTagIds.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text(l10n.common_all),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
        if (widget.showTitle) const SizedBox(height: 8),

        // 搜索框
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.tag_select_hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

        // 标签列表
        if (filteredTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.tag,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? l10n.hint_noResults
                        : l10n.tag_no_tags,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          widget.displayMode == TagDisplayMode.chip
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.showAllOption) _buildAllChip(l10n),
                    ...filteredTags.map((tag) => _buildTagChip(tag)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showAllOption) _buildAllTile(l10n),
                    ...filteredTags.map((tag) => _buildTagTile(tag)),
                  ],
                ),

        // 选中状态提示
        if (_selectedTagIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.tag_filter_active(_selectedTagIds.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAllChip(l10n) {
    final isSelected = _selectedTagIds.isEmpty;
    return FilterChip(
      label: Text(l10n.tag_filter_all),
      selected: isSelected,
      onSelected: (_) {
        _clearAll();
      },
      selectedColor: _getTagColor(null).withValues(alpha: 0.2),
      checkmarkColor: _getTagColor(null),
      backgroundColor: _getTagColor(null).withValues(alpha: 0.1),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selectedTagIds.contains(tag.id);
    final color = _getTagColor(tag.color);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[Text(tag.icon!), const SizedBox(width: 4)],
          Text(tag.name),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _onTagTapped(tag.id),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      avatar: isSelected
          ? null
          : CircleAvatar(backgroundColor: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildAllTile(l10n) {
    final isSelected = _selectedTagIds.isEmpty;
    return CheckboxListTile(
      dense: true,
      value: isSelected,
      onChanged: (_) => _clearAll(),
      title: Text(l10n.tag_filter_all),
      selected: isSelected,
    );
  }

  Widget _buildTagTile(Tag tag) {
    final isSelected = _selectedTagIds.contains(tag.id);
    final color = _getTagColor(tag.color);

    return CheckboxListTile(
      dense: true,
      value: isSelected,
      onChanged: (_) => _onTagTapped(tag.id),
      secondary: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(tag.icon ?? '🏷️', style: const TextStyle(fontSize: 16)),
      ),
      title: Row(
        children: [
          if (tag.icon != null) ...[Text(tag.icon!), const SizedBox(width: 8)],
          Text(tag.name),
        ],
      ),
      selected: isSelected,
    );
  }

  Color _getTagColor(TagColor? color) {
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
      case null:
        return Colors.grey;
    }
  }
}

/// 标签显示模式
enum TagDisplayMode {
  /// Chip模式（横向排列）
  chip,

  /// List模式（纵向列表）
  list,
}
