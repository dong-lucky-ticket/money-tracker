import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/record.dart';
import '../models/report_filter.dart';
import '../models/report_snapshot.dart';
import '../models/report_time_range.dart';
import '../providers/data_provider.dart';
import '../utils/report_snapshot_builder.dart';
import '../widgets/report/report_category_detail_sheet.dart';
import '../widgets/report/report_group_detail_sheet.dart';
import '../widgets/report/report_group_summary_section.dart';
import '../widgets/report/report_header.dart';
import '../widgets/report/report_overview_section.dart';
import '../widgets/report/report_rank_list.dart';
import '../widgets/report/report_trend_chart.dart';
import '../widgets/common/segmented_selector.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportFilter _filter = const ReportFilter();
  DateTime _selectedDate = DateTime.now();

  ReportTimeRange get _selectedRange => _filter.timeRange;

  List<CategoryGroup> _availableGroups(DataProvider provider) {
    return provider.categoryGroups.where((group) {
      switch (_filter.recordType) {
        case ReportRecordType.expense:
          return group.isExpense;
        case ReportRecordType.income:
          return !group.isExpense;
        case ReportRecordType.all:
          return true;
      }
    }).toList();
  }

  List<Category> _availableCategories(
    DataProvider provider, {
    Set<String>? selectedGroupIds,
  }) {
    final effectiveGroupIds = selectedGroupIds ?? _filter.groupIds;
    return provider.categories.where((category) {
      final matchesType = switch (_filter.recordType) {
        ReportRecordType.expense => category.isExpense,
        ReportRecordType.income => !category.isExpense,
        ReportRecordType.all => true,
      };

      if (!matchesType) {
        return false;
      }

      if (effectiveGroupIds.isNotEmpty &&
          !effectiveGroupIds.contains(category.groupId)) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  ReportFilter _normalizeFilter(
    ReportFilter candidate,
    DataProvider provider,
  ) {
    final validGroupIds =
        _availableGroups(provider).map((group) => group.id).toSet();
    final normalizedGroupIds = candidate.groupIds.intersection(validGroupIds);
    final validCategoryIds = _availableCategories(
      provider,
      selectedGroupIds: normalizedGroupIds,
    ).map((category) => category.id).toSet();
    final normalizedCategoryIds =
        candidate.categoryIds.intersection(validCategoryIds);

    return candidate.copyWith(
      groupIds: normalizedGroupIds,
      categoryIds: normalizedCategoryIds,
    );
  }

  Future<void> _openAdvancedFilters(DataProvider provider) async {
    final nextFilter = await showModalBottomSheet<ReportFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _ReportAdvancedFilterSheet(
          initialFilter: _filter,
          groups: _availableGroups(provider),
          categories: _availableCategories(provider),
        );
      },
    );

    if (!mounted || nextFilter == null) {
      return;
    }

    setState(() {
      _filter = _normalizeFilter(nextFilter, provider);
    });
  }

  List<String> _activeFilterLabels(DataProvider provider) {
    final groupNames = {
      for (final group in provider.categoryGroups) group.id: group.name,
    };
    final categoryNames = {
      for (final category in provider.categories) category.id: category.name,
    };
    final labels = <String>[];

    if (_filter.hasGroupFilter) {
      final names = _filter.groupIds
          .map((id) => groupNames[id])
          .whereType<String>()
          .toList();
      if (names.isNotEmpty) {
        labels.add(
          names.length <= 2
              ? '大类: ${names.join('、')}'
              : '大类: ${names.length} 项',
        );
      }
    }

    if (_filter.hasCategoryFilter) {
      final names = _filter.categoryIds
          .map((id) => categoryNames[id])
          .whereType<String>()
          .toList();
      if (names.isNotEmpty) {
        labels.add(
          names.length <= 2
              ? '分类: ${names.join('、')}'
              : '分类: ${names.length} 项',
        );
      }
    }

    if (_filter.hasKeywordFilter) {
      labels.add('关键词: ${_filter.keyword.trim()}');
    }

    return labels;
  }

  Future<void> _pickDate() async {
    if (_selectedRange.isCustom) {
      await _pickCustomRange();
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickRange() async {
    final preset = await showModalBottomSheet<ReportTimeRangePreset>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _ReportRangePickerSheet(
          selectedPreset: _selectedRange.preset,
        );
      },
    );

    if (!mounted || preset == null) {
      return;
    }

    if (preset == ReportTimeRangePreset.custom) {
      await _pickCustomRange();
      return;
    }

    setState(() {
      _filter = _filter.copyWith(
        timeRange: _presetRange(preset),
      );
    });
  }

  Future<void> _pickCustomRange() async {
    final currentRange = _selectedRange.isCustom
        ? DateTimeRange(
            start: _selectedRange.customStart ?? _selectedDate,
            end: _selectedRange.customEnd ?? _selectedDate,
          )
        : DateTimeRange(
            start: _selectedDate.subtract(const Duration(days: 29)),
            end: _selectedDate,
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: currentRange,
      saveText: '应用',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _filter = _filter.copyWith(
        timeRange: ReportTimeRange.custom(
          start: picked.start,
          end: picked.end,
        ),
      );
      _selectedDate = picked.end;
    });
  }

  ReportTimeRange _presetRange(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return const ReportTimeRange.last7Days();
      case ReportTimeRangePreset.last30Days:
        return const ReportTimeRange.last30Days();
      case ReportTimeRangePreset.thisMonth:
        return const ReportTimeRange.thisMonth();
      case ReportTimeRangePreset.last6Months:
        return const ReportTimeRange.last6Months();
      case ReportTimeRangePreset.thisYear:
        return const ReportTimeRange.thisYear();
      case ReportTimeRangePreset.custom:
        return _selectedRange;
    }
  }

  void _showCategoryDetails(
    ReportCategorySummary summary,
    ReportSnapshot snapshot,
  ) {
    final records = _sortedRecordsByCategory(snapshot, summary.category.id);
    if (records.isEmpty) {
      return;
    }

    ReportCategoryDetailSheet.show(
      context,
      summary: summary,
      records: records,
      viewTotal: snapshot.viewTotal,
      periodLabel: snapshot.periodLabel,
      amountColor: snapshot.valueColor,
    );
  }

  void _showGroupDetails(
    ReportGroupSummary summary,
    ReportSnapshot snapshot,
  ) {
    final groupId = summary.group?.id ?? '';
    final categories = snapshot.categories.where((categorySummary) {
      return categorySummary.category.groupId == groupId;
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final records = _sortedRecordsByGroup(snapshot, groupId);

    if (categories.isEmpty || records.isEmpty) {
      return;
    }

    ReportGroupDetailSheet.show(
      context,
      summary: summary,
      categories: categories,
      records: records,
      viewTotal: snapshot.viewTotal,
      periodLabel: snapshot.periodLabel,
      amountColor: snapshot.valueColor,
    );
  }

  List<Record> _sortedRecordsByCategory(
    ReportSnapshot snapshot,
    String categoryId,
  ) {
    return snapshot.viewRecords
        .where((record) => record.category.id == categoryId)
        .toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  List<Record> _sortedRecordsByGroup(
    ReportSnapshot snapshot,
    String groupId,
  ) {
    return snapshot.viewRecords
        .where((record) => record.category.groupId == groupId)
        .toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        final snapshot = buildReportSnapshot(
          records: provider.records,
          categoryGroups: provider.categoryGroups,
          targetDate: _selectedDate,
          filter: _filter,
        );

        return Column(
          children: [
            ReportHeader(
              recordType: _filter.recordType,
              selectedRange: _selectedRange,
              periodLabel: snapshot.periodLabel,
              hasAdvancedFilters: _filter.hasAdvancedFilters,
              onPickDate: _pickDate,
              onPickRange: _pickRange,
              onOpenFilters: () => _openAdvancedFilters(provider),
              onTypeChanged: (recordType) {
                setState(() {
                  _filter = _normalizeFilter(
                    _filter.copyWith(
                      recordType: recordType,
                    ),
                    provider,
                  );
                });
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_filter.hasAdvancedFilters) ...[
                    _ActiveReportFilters(
                      labels: _activeFilterLabels(provider),
                      onClear: () {
                        setState(() {
                          _filter = _filter.copyWith(
                            groupIds: <String>{},
                            categoryIds: <String>{},
                            keyword: '',
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ReportOverviewSection(snapshot: snapshot),
                  if (snapshot.viewRecords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ReportTrendChart(
                      typeName: snapshot.typeName,
                      trendData: snapshot.trendData,
                      trendAxisLabels: snapshot.trendAxisLabels,
                      trendTooltipLabels: snapshot.trendTooltipLabels,
                      maxX: snapshot.maxX,
                      trendMode: snapshot.trendMode,
                      color: snapshot.valueColor,
                    ),
                    const SizedBox(height: 32),
                    ReportGroupSummarySection(
                      groups: snapshot.groups,
                      viewTotal: snapshot.viewTotal,
                      valueColor: snapshot.valueColor,
                      onTapGroup: (summary) {
                        _showGroupDetails(summary, snapshot);
                      },
                    ),
                    if (snapshot.groups.isNotEmpty) const SizedBox(height: 32),
                    ReportRankList(
                      categories: snapshot.categories,
                      viewTotal: snapshot.viewTotal,
                      valueColor: snapshot.valueColor,
                      typeName: snapshot.typeName,
                      recordType: snapshot.recordType,
                      onTapCategory: (summary) {
                        _showCategoryDetails(summary, snapshot);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveReportFilters extends StatelessWidget {
  final List<String> labels;
  final VoidCallback onClear;

  const _ActiveReportFilters({
    required this.labels,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '已应用筛选',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90E2),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map(
                  (label) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ReportAdvancedFilterSheet extends StatefulWidget {
  final ReportFilter initialFilter;
  final List<CategoryGroup> groups;
  final List<Category> categories;

  const _ReportAdvancedFilterSheet({
    required this.initialFilter,
    required this.groups,
    required this.categories,
  });

  @override
  State<_ReportAdvancedFilterSheet> createState() =>
      _ReportAdvancedFilterSheetState();
}

class _ReportAdvancedFilterSheetState
    extends State<_ReportAdvancedFilterSheet> {
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

class _ReportRangePickerSheet extends StatelessWidget {
  final ReportTimeRangePreset selectedPreset;

  const _ReportRangePickerSheet({
    required this.selectedPreset,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                '选择统计范围',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '先切范围，再结合日期锚点查看不同周期',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ReportTimeRange.quickPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final preset = ReportTimeRange.quickPresets[index];
                    return _ReportRangeOptionTile(
                      preset: preset,
                      isSelected: preset == selectedPreset,
                      onTap: () => Navigator.pop(context, preset),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRangeOptionTile extends StatelessWidget {
  final ReportTimeRangePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportRangeOptionTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(preset);
    final description = _descriptionFor(preset);
    final accentColor =
        isSelected ? const Color(0xFF4A90E2) : const Color(0xFFD1D5DB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 34,
              margin: const EdgeInsets.only(top: 1, right: 12),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
              color: isSelected
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '近7天';
      case ReportTimeRangePreset.last30Days:
        return '近30天';
      case ReportTimeRangePreset.thisMonth:
        return '本月';
      case ReportTimeRangePreset.last6Months:
        return '近半年';
      case ReportTimeRangePreset.thisYear:
        return '本年';
      case ReportTimeRangePreset.custom:
        return '自定义区间';
    }
  }

  String _descriptionFor(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '适合看最近一周的波动和短期变化';
      case ReportTimeRangePreset.last30Days:
        return '适合看最近一个月的连续趋势';
      case ReportTimeRangePreset.thisMonth:
        return '按当前锚点所在月份统计';
      case ReportTimeRangePreset.last6Months:
        return '适合观察半年内的大类走势和阶段性消费';
      case ReportTimeRangePreset.thisYear:
        return '按当前锚点所在年份统计';
      case ReportTimeRangePreset.custom:
        return '手动指定开始和结束日期';
    }
  }
}
