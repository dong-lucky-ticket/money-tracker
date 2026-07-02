import 'package:flutter/material.dart';

import 'category.dart';
import 'record.dart';

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

class ReportSnapshot {
  final List<Record> expenseRecords;
  final List<Record> incomeRecords;
  final List<Record> viewRecords;
  final double totalExpense;
  final double totalIncome;
  final double viewTotal;
  final double previousViewTotal;
  final double viewDeltaAmount;
  final double? viewDeltaRate;
  final double averageAmount;
  final Record? maxRecord;
  final List<ReportCategorySummary> categories;
  final Map<int, double> trendData;
  final Map<int, String> trendAxisLabels;
  final Map<int, String> trendTooltipLabels;
  final int maxX;
  final bool isExpenseView;
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
    required this.viewTotal,
    required this.previousViewTotal,
    required this.viewDeltaAmount,
    required this.viewDeltaRate,
    required this.averageAmount,
    required this.maxRecord,
    required this.categories,
    required this.trendData,
    required this.trendAxisLabels,
    required this.trendTooltipLabels,
    required this.maxX,
    required this.isExpenseView,
    required this.viewRecordCount,
    required this.periodLabel,
    required this.compareLabel,
    required this.averageTitle,
    required this.insights,
  });

  String get typeName => isExpenseView ? '支出' : '收入';

  Color get valueColor =>
      isExpenseView ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F);

  double get balance => totalIncome - totalExpense;
}
