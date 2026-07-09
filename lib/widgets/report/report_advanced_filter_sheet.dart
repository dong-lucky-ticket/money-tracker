import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/category_group.dart';
import '../../models/report_filter.dart';
import '../common/segmented_selector.dart';

class ReportAdvancedFilterSheet extends StatefulWidget {
  final ReportFilter initialFilter;
  final List<CategoryGroup> groups;
  final List<Category> categories;

  const ReportAdvancedFilterSheet({
    super.key,
    required this.initialFilter,
    required this.groups,
    required this.categories,
  });

  static Future<ReportFilter?> show(
    BuildContext context, {
    required ReportFilter initialFilter,
    required List<CategoryGroup> groups,
    required List<Category> categories,
  }) {
    return showModalBottomSheet<ReportFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ReportAdvancedFilterSheet(
          initialFilter: initialFilter,
          groups: groups,
          categories: categories,
        );
      },
    );
  }

  @override
  State<ReportAdvancedFilterSheet> createState() =>
      _ReportAdvancedFilterSheetState();
}

class _ReportAdvancedFilterSheetState extends State<ReportAdvancedFilterSheet> {
  late ReportRecordType _recordType;
  late Set<String> _selectedGroupIds;
  late Set<String> _selectedCategoryIds;
  late TextEditingController _keywordController;

  @override
  void initState() {
    super.initState();
    _recordType = widget.initialFilter.recordType;
    _selectedGroupIds = Set<String>.from(widget.initialFilter.groupIds);
    _selectedCategoryIds = Set<String>.from(widget.initialFilter.categoryIds);
    _keywordController =
        TextEditingController(text: widget.initialFilter.keyword);
    _sanitizeSelectedCategories();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Category> get _visibleCategories {
    final candidates = widget.categories.where((category) {
      switch (_recordType) {
        case ReportRecordType.expense:
          return category.isExpense;
        case ReportRecordType.income:
          return !category.isExpense;
        case ReportRecordType.all:
          return true;
      }
    });

    if (_selectedGroupIds.isEmpty) {
      return candidates.toList();
    }

    return candidates
        .where((category) => _selectedGroupIds.contains(category.groupId))
        .toList();
  }

  List<CategoryGroup> get _visibleGroups {
    return widget.groups.where((group) {
      switch (_recordType) {
        case ReportRecordType.expense:
          return group.isExpense;
        case ReportRecordType.income:
          return !group.isExpense;
        case ReportRecordType.all:
          return true;
      }
    }).toList();
  }

  void _sanitizeSelectedCategories() {
    final validGroupIds = _visibleGroups.map((item) => item.id).toSet();
    _selectedGroupIds = _selectedGroupIds.intersection(validGroupIds);
    if (_selectedGroupIds.length > 1) {
      final firstMatchedGroup = _visibleGroups
          .map((group) => group.id)
          .firstWhere(_selectedGroupIds.contains);
      _selectedGroupIds = {firstMatchedGroup};
    }
    final validCategoryIds = _visibleCategories.map((item) => item.id).toSet();
    _selectedCategoryIds = _selectedCategoryIds.intersection(validCategoryIds);
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
      } else {
        _selectedGroupIds
          ..clear()
          ..add(id);
      }
      _sanitizeSelectedCategories();
    });
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedGroupIds.clear();
      _selectedCategoryIds.clear();
      _keywordController.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initialFilter.copyWith(
        recordType: _recordType,
        groupIds: _selectedGroupIds,
        categoryIds: _selectedCategoryIds,
        keyword: _keywordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _visibleCategories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '高级筛选',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  children: [
                    const _FilterSectionTitle(
                      title: '收支类型',
                      subtitle: '切换为支出、收入或全部流水',
                    ),
                    const SizedBox(height: 8),
                    SegmentedSelector<ReportRecordType>(
                      value: _recordType,
                      onChanged: (value) {
                        setState(() {
                          _recordType = value;
                          _sanitizeSelectedCategories();
                        });
                      },
                      options: const [
                        SegmentedOption(
                          value: ReportRecordType.expense,
                          label: '支出',
                        ),
                        SegmentedOption(
                          value: ReportRecordType.income,
                          label: '收入',
                        ),
                        SegmentedOption(
                          value: ReportRecordType.all,
                          label: '全部',
                        ),
                      ],
                      itemPadding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    const SizedBox(height: 16),
                    const _FilterSectionTitle(
                      title: '备注关键词',
                      subtitle: '支持按备注或分类名称做模糊筛选',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keywordController,
                      decoration: InputDecoration(
                        hintText: '例如：彩票、房租、加油',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _FilterSectionTitle(
                      title: '大类',
                      subtitle: '单选，先缩小大类范围',
                    ),
                    const SizedBox(height: 8),
                    _FixedWidthFilterChipWrap(
                      columnCount: 4,
                      children: _visibleGroups
                          .map(
                            (group) => _FixedWidthFilterTile(
                              label: group.name,
                              selected: _selectedGroupIds.contains(group.id),
                              onTap: () => _toggleGroup(group.id),
                              selectedBackgroundColor: const Color(0xFFF3F8FF),
                              selectedBorderColor: const Color(0xFFBFDBFE),
                              selectedTextColor: const Color(0xFF1D4ED8),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    _FilterSectionTitle(
                      title: '分类',
                      subtitle: visibleCategories.isEmpty
                          ? '当前没有可选分类'
                          : '可多选，继续收窄到具体分类',
                    ),
                    const SizedBox(height: 8),
                    if (visibleCategories.isEmpty)
                      const Text(
                        '请先调整大类筛选，或者当前类型下暂无分类。',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                    else
                      _FixedWidthFilterChipWrap(
                        children: visibleCategories
                            .map(
                              (category) => _FixedWidthFilterTile(
                                label: category.name,
                                selected:
                                    _selectedCategoryIds.contains(category.id),
                                onTap: () => _toggleCategory(category.id),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('应用筛选'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FilterSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FixedWidthFilterChipWrap extends StatelessWidget {
  final List<Widget> children;
  final int? columnCount;

  const _FixedWidthFilterChipWrap({
    required this.children,
    this.columnCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        const targetItemWidth = 74.0;
        final resolvedColumnCount = columnCount ??
            (constraints.maxWidth / targetItemWidth).floor().clamp(1, 5);
        final itemWidth =
            (constraints.maxWidth - spacing * (resolvedColumnCount - 1)) /
                resolvedColumnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FixedWidthFilterTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBackgroundColor;
  final Color selectedBorderColor;
  final Color selectedTextColor;

  const _FixedWidthFilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackgroundColor = const Color(0xFFF8FAFC),
    this.selectedBorderColor = const Color(0xFFCBD5E1),
    this.selectedTextColor = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? selectedBackgroundColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedBorderColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? selectedTextColor : const Color(0xFF334155),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
