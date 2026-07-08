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

List<Record> recordsForMonth(Iterable<Record> records, DateTime month) {
  return records.where((record) {
    return record.date.year == month.year && record.date.month == month.month;
  }).toList(growable: false);
}

int countActiveCategories(
  Iterable<Record> records, {
  bool includeVoided = false,
}) {
  final ids = <String>{};
  for (final record in records) {
    if (!includeVoided && record.isVoided) {
      continue;
    }
    ids.add(record.category.id);
  }
  return ids.length;
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

List<Category> recentCategoriesFromRecords({
  required Iterable<Record> records,
  required Iterable<Category> categories,
  required bool isExpense,
  int limit = 4,
}) {
  final activeCategories = {
    for (final category in categories)
      if (category.isExpense == isExpense) category.id: category,
  };
  final sortedRecords = sortRecordsByTimeline(
    records.where((record) => !record.isVoided && record.isExpense == isExpense),
  );
  final result = <Category>[];
  final seenIds = <String>{};

  for (final record in sortedRecords) {
    final currentCategory = activeCategories[record.category.id];
    if (currentCategory == null || !seenIds.add(currentCategory.id)) {
      continue;
    }

    result.add(currentCategory);
    if (result.length >= limit) {
      break;
    }
  }

  return result;
}
