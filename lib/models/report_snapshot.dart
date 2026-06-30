import 'package:flutter/material.dart';

import 'category.dart';
import 'record.dart';

class ReportCategorySummary {
  final Category category;
  final double amount;
  final int count;

  const ReportCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
  });
}

class ReportSnapshot {
  final List<Record> expenseRecords;
  final List<Record> incomeRecords;
  final List<Record> viewRecords;
  final double totalExpense;
  final double totalIncome;
  final double viewTotal;
  final double averageAmount;
  final Record? maxRecord;
  final List<ReportCategorySummary> categories;
  final Map<int, double> trendData;
  final int maxX;
  final bool isExpenseView;

  const ReportSnapshot({
    required this.expenseRecords,
    required this.incomeRecords,
    required this.viewRecords,
    required this.totalExpense,
    required this.totalIncome,
    required this.viewTotal,
    required this.averageAmount,
    required this.maxRecord,
    required this.categories,
    required this.trendData,
    required this.maxX,
    required this.isExpenseView,
  });

  String get typeName => isExpenseView ? '支出' : '收入';

  Color get valueColor =>
      isExpenseView ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F);
}
