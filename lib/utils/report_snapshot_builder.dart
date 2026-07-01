import '../models/category.dart';
import '../models/record.dart';
import '../models/report_snapshot.dart';

ReportSnapshot buildReportSnapshot({
  required List<Record> records,
  required DateTime targetDate,
  required int filterIndex,
  required bool isExpenseView,
}) {
  final filteredRecords = records.where((record) {
    if (record.isVoided) {
      return false;
    }
    if (filterIndex == 1) {
      return record.date.year == targetDate.year &&
          record.date.month == targetDate.month;
    }
    if (filterIndex == 2) {
      return record.date.year == targetDate.year;
    }
    final difference = targetDate.difference(record.date).inDays;
    return difference >= 0 && difference <= 7;
  }).toList();

  final expenseRecords =
      filteredRecords.where((record) => record.isExpense).toList();
  final incomeRecords =
      filteredRecords.where((record) => !record.isExpense).toList();
  final totalExpense = expenseRecords.fold(0.0, (sum, item) => sum + item.amount);
  final totalIncome = incomeRecords.fold(0.0, (sum, item) => sum + item.amount);

  final viewRecords = isExpenseView ? expenseRecords : incomeRecords;
  final viewTotal = isExpenseView ? totalExpense : totalIncome;

  final amountByCategory = <String, double>{};
  final countByCategory = <String, int>{};
  final categoryById = <String, Category>{};

  for (final record in viewRecords) {
    final categoryId = record.category.id;
    amountByCategory[categoryId] = (amountByCategory[categoryId] ?? 0) + record.amount;
    countByCategory[categoryId] = (countByCategory[categoryId] ?? 0) + 1;
    categoryById[categoryId] = record.category;
  }

  final categories = amountByCategory.entries
      .map((entry) => ReportCategorySummary(
            category: categoryById[entry.key]!,
            amount: entry.value,
            count: countByCategory[entry.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final trendData = <int, double>{};
  var maxX = 0;
  var averageAmount = 0.0;
  Record? maxRecord;

  if (viewRecords.isNotEmpty) {
    var points = 1;
    if (filterIndex == 0) {
      points = 7;
    } else if (filterIndex == 1) {
      points = DateTime(targetDate.year, targetDate.month + 1, 0).day;
    } else {
      points = 12;
    }

    averageAmount = filterIndex == 2 ? viewTotal / 12 : viewTotal / points;
    maxRecord = viewRecords.reduce((a, b) => a.amount > b.amount ? a : b);

    for (var index = 1; index <= points; index++) {
      trendData[index] = 0.0;
    }

    for (final record in viewRecords) {
      late final int key;
      if (filterIndex == 0) {
        key = record.date.weekday;
      } else if (filterIndex == 1) {
        key = record.date.day;
      } else {
        key = record.date.month;
      }
      trendData[key] = (trendData[key] ?? 0) + record.amount;
    }

    maxX = points;
  }

  return ReportSnapshot(
    expenseRecords: expenseRecords,
    incomeRecords: incomeRecords,
    viewRecords: viewRecords,
    totalExpense: totalExpense,
    totalIncome: totalIncome,
    viewTotal: viewTotal,
    averageAmount: averageAmount,
    maxRecord: maxRecord,
    categories: categories,
    trendData: trendData,
    maxX: maxX,
    isExpenseView: isExpenseView,
  );
}
