import 'package:flutter/material.dart';

import 'category.dart';
import 'category_group.dart';
import 'record.dart';
import 'report_filter.dart';
import 'report_time_range.dart';

class ReportCategorySummary {
  final Category category;
  final double amount;
  final int count;
  final double previousAmount;
  final double deltaAmount;
  final double? deltaRate;

  const ReportCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
    required this.previousAmount,
    required this.deltaAmount,
    required this.deltaRate,
  });
}

class ReportGroupSummary {
  final CategoryGroup? group;
  final String fallbackName;
  final double amount;
  final int count;
  final double previousAmount;
  final double deltaAmount;
  final double? deltaRate;

  const ReportGroupSummary({
    required this.group,
    required this.fallbackName,
    required this.amount,
    required this.count,
    required this.previousAmount,
    required this.deltaAmount,
    required this.deltaRate,
  });

  String get displayName => group?.name ?? fallbackName;
}

class ReportSnapshot {
  final List<Record> expenseRecords;
  final List<Record> incomeRecords;
  final List<Record> viewRecords;
  final double totalExpense;
  final double totalIncome;
  final double previousTotalExpense;
  final double previousTotalIncome;
  final double viewTotal;
  final double previousViewTotal;
  final double viewDeltaAmount;
  final double? viewDeltaRate;
  final double averageAmount;
  final Record? maxRecord;
  final List<ReportCategorySummary> categories;
  final List<ReportGroupSummary> groups;
  final Map<int, double> trendData;
  final Map<int, String> trendAxisLabels;
  final Map<int, String> trendTooltipLabels;
  final int maxX;
  final ReportTrendMode trendMode;
  final ReportRecordType recordType;
  final int viewRecordCount;
  final String periodLabel;
  final String compareLabel;
  final String averageTitle;
  final List<String> insights;

  const ReportSnapshot({
    required this.expenseRecords,
    required this.incomeRecords,
    required this.viewRecords,
    required this.totalExpense,
    required this.totalIncome,
    required this.previousTotalExpense,
    required this.previousTotalIncome,
    required this.viewTotal,
    required this.previousViewTotal,
    required this.viewDeltaAmount,
    required this.viewDeltaRate,
    required this.averageAmount,
    required this.maxRecord,
    required this.categories,
    required this.groups,
    required this.trendData,
    required this.trendAxisLabels,
    required this.trendTooltipLabels,
    required this.maxX,
    required this.trendMode,
    required this.recordType,
    required this.viewRecordCount,
    required this.periodLabel,
    required this.compareLabel,
    required this.averageTitle,
    required this.insights,
  });

  bool get isExpenseView => recordType == ReportRecordType.expense;

  bool get isIncomeView => recordType == ReportRecordType.income;

  bool get isMixedView => recordType == ReportRecordType.all;

  String get typeName {
    switch (recordType) {
      case ReportRecordType.expense:
        return '支出';
      case ReportRecordType.income:
        return '收入';
      case ReportRecordType.all:
        return '收支';
    }
  }

  Color get valueColor {
    switch (recordType) {
      case ReportRecordType.expense:
        return const Color(0xFFFF5A5A);
      case ReportRecordType.income:
        return const Color(0xFF28CA7F);
      case ReportRecordType.all:
        return const Color(0xFF4A90E2);
    }
  }

  double get balance => totalIncome - totalExpense;

  double get previousBalance => previousTotalIncome - previousTotalExpense;
}
