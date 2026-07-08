import '../models/category.dart';
import '../models/category_group.dart';
import '../models/record.dart';
import '../models/report_filter.dart';
import 'record_timeline.dart';

class RecordAmountSummary {
  final double income;
  final double expense;

  const RecordAmountSummary({
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

RecordAmountSummary summarizeRecords(
  Iterable<Record> records, {
  bool includeVoided = false,
}) {
  var income = 0.0;
  var expense = 0.0;

  for (final record in records) {
    if (!includeVoided && record.isVoided) {
      continue;
    }

    if (record.isExpense) {
      expense += record.amount;
    } else {
      income += record.amount;
    }
  }

  return RecordAmountSummary(
    income: income,
    expense: expense,
  );
}

List<Record> sortRecordsByTimeline(Iterable<Record> records) {
  return List<Record>.from(records)..sort(compareRecordsByTimeline);
}

List<Record> searchRecords(
  Iterable<Record> records,
  String keyword, {
  bool caseSensitive = false,
}) {
  final normalizedKeyword = caseSensitive ? keyword.trim() : keyword.trim().toLowerCase();
  if (normalizedKeyword.isEmpty) {
    return const [];
  }

  return records.where((record) {
    final remark = caseSensitive ? record.remark : record.remark.toLowerCase();
    final categoryName =
        caseSensitive ? record.category.name : record.category.name.toLowerCase();
    return remark.contains(normalizedKeyword) ||
        categoryName.contains(normalizedKeyword);
  }).toList(growable: false);
}

List<CategoryGroup> filterCategoryGroupsByRecordType(
  Iterable<CategoryGroup> groups,
  ReportRecordType recordType,
) {
  return groups.where((group) {
    switch (recordType) {
      case ReportRecordType.expense:
        return group.isExpense;
      case ReportRecordType.income:
        return !group.isExpense;
      case ReportRecordType.all:
        return true;
    }
  }).toList(growable: false);
}

List<Category> filterCategoriesByRecordType(
  Iterable<Category> categories,
  ReportRecordType recordType, {
  Set<String> groupIds = const <String>{},
}) {
  return categories.where((category) {
    final matchesType = switch (recordType) {
      ReportRecordType.expense => category.isExpense,
      ReportRecordType.income => !category.isExpense,
      ReportRecordType.all => true,
    };

    if (!matchesType) {
      return false;
    }

    if (groupIds.isNotEmpty && !groupIds.contains(category.groupId)) {
      return false;
    }

    return true;
  }).toList(growable: false);
}
