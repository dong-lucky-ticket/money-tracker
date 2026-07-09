import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/report_screen_controller.dart';
import '../models/record.dart';
import '../models/report_snapshot.dart';
import '../models/report_time_range.dart';
import '../providers/data_provider.dart';
import '../utils/record_queries.dart';
import '../widgets/report/report_active_filters.dart';
import '../widgets/report/report_advanced_filter_sheet.dart';
import '../widgets/report/report_category_detail_sheet.dart';
import '../widgets/report/report_group_detail_sheet.dart';
import '../widgets/report/report_group_summary_section.dart';
import '../widgets/report/report_header.dart';
import '../widgets/report/report_overview_section.dart';
import '../widgets/report/report_rank_list.dart';
import '../widgets/report/report_range_picker_sheet.dart';
import '../widgets/report/report_trend_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAdvancedFilters(DataProvider provider) async {
    final nextFilter = await ReportAdvancedFilterSheet.show(
      context,
      initialFilter: _controller.filter,
      groups: _controller.availableGroups(provider),
      categories: _controller.availableCategories(provider),
    );

    if (!mounted || nextFilter == null) {
      return;
    }

    _controller.updateFilter(nextFilter, provider);
  }

  Future<void> _pickDate() async {
    if (_controller.selectedRange.isCustom) {
      await _pickCustomRange();
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      _controller.setSelectedDate(picked);
    }
  }

  Future<void> _pickRange() async {
    final preset = await ReportRangePickerSheet.show(
      context,
      selectedPreset: _controller.selectedRange.preset,
    );

    if (!mounted || preset == null) {
      return;
    }

    if (preset == ReportTimeRangePreset.custom) {
      await _pickCustomRange();
      return;
    }

    _controller.setPresetRange(preset);
  }

  Future<void> _pickCustomRange() async {
    final currentRange = _controller.selectedRange.isCustom
        ? DateTimeRange(
            start:
                _controller.selectedRange.customStart ?? _controller.selectedDate,
            end: _controller.selectedRange.customEnd ?? _controller.selectedDate,
          )
        : DateTimeRange(
            start: _controller.selectedDate.subtract(const Duration(days: 29)),
            end: _controller.selectedDate,
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

    _controller.setCustomRange(picked);
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
    return sortRecordsByTimeline(
      snapshot.viewRecords.where((record) => record.category.id == categoryId),
    );
  }

  List<Record> _sortedRecordsByGroup(
    ReportSnapshot snapshot,
    String groupId,
  ) {
    return sortRecordsByTimeline(
      snapshot.viewRecords.where((record) => record.category.groupId == groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final filter = _controller.filter;
            final snapshot = _controller.buildSnapshot(provider);

            return Column(
              children: [
                ReportHeader(
                  recordType: filter.recordType,
                  selectedRange: _controller.selectedRange,
                  periodLabel: snapshot.periodLabel,
                  hasAdvancedFilters: filter.hasAdvancedFilters,
                  onPickDate: _pickDate,
                  onPickRange: _pickRange,
                  onOpenFilters: () => _openAdvancedFilters(provider),
                  onTypeChanged: (recordType) {
                    _controller.updateRecordType(recordType, provider);
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (filter.hasAdvancedFilters) ...[
                        ReportActiveFilters(
                          labels: _controller.activeFilterLabels(provider),
                          onClear: _controller.clearAdvancedFilters,
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
                        if (snapshot.groups.isNotEmpty)
                          const SizedBox(height: 32),
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
      },
    );
  }
}
