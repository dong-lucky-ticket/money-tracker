import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report_snapshot.dart';
import '../providers/data_provider.dart';
import '../utils/report_snapshot_builder.dart';
import '../widgets/report/report_category_detail_sheet.dart';
import '../widgets/report/report_group_summary_section.dart';
import '../widgets/report/report_header.dart';
import '../widgets/report/report_overview_section.dart';
import '../widgets/report/report_rank_list.dart';
import '../widgets/report/report_trend_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _filterIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool _isExpenseView = true;

  Future<void> _pickDate() async {
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

  void _showCategoryDetails(
    ReportCategorySummary summary,
    ReportSnapshot snapshot,
  ) {
    final records = snapshot.viewRecords
        .where((record) => record.category.id == summary.category.id)
        .toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        final snapshot = buildReportSnapshot(
          records: provider.records,
          categoryGroups: provider.categoryGroups,
          targetDate: _selectedDate,
          filterIndex: _filterIndex,
          isExpenseView: _isExpenseView,
        );

        return Column(
          children: [
            ReportHeader(
              isExpenseView: _isExpenseView,
              filterIndex: _filterIndex,
              periodLabel: snapshot.periodLabel,
              onPickDate: _pickDate,
              onTypeChanged: (value) => setState(() => _isExpenseView = value),
              onFilterChanged: (value) => setState(() => _filterIndex = value),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  ReportOverviewSection(snapshot: snapshot),
                  if (snapshot.viewRecords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ReportTrendChart(
                      typeName: snapshot.typeName,
                      trendData: snapshot.trendData,
                      trendAxisLabels: snapshot.trendAxisLabels,
                      trendTooltipLabels: snapshot.trendTooltipLabels,
                      maxX: snapshot.maxX,
                      filterIndex: _filterIndex,
                      color: snapshot.valueColor,
                    ),
                    const SizedBox(height: 32),
                    ReportGroupSummarySection(
                      groups: snapshot.groups,
                      viewTotal: snapshot.viewTotal,
                      valueColor: snapshot.valueColor,
                    ),
                    if (snapshot.groups.isNotEmpty) const SizedBox(height: 32),
                    ReportRankList(
                      categories: snapshot.categories,
                      viewTotal: snapshot.viewTotal,
                      valueColor: snapshot.valueColor,
                      typeName: snapshot.typeName,
                      isExpenseView: snapshot.isExpenseView,
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
