import '../models/category.dart';
import '../models/category_group.dart';
import '../models/record.dart';
import '../models/report_snapshot.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _weekdayLabel(int weekday) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[weekday - 1];
}

String _periodLabel(DateTime targetDay, int filterIndex) {
  if (filterIndex == 0) {
    final start = targetDay.subtract(const Duration(days: 6));
    return '${start.month}月${start.day}日 - ${targetDay.month}月${targetDay.day}日';
  }
  if (filterIndex == 1) {
    return '${targetDay.year}年${targetDay.month}月';
  }
  return '${targetDay.year}年';
}

String _compareLabel(int filterIndex) {
  if (filterIndex == 0) {
    return '上7天';
  }
  if (filterIndex == 1) {
    return '上月';
  }
  return '上年';
}

List<Record> _recordsInRange(
  List<Record> records,
  DateTime start,
  DateTime end,
) {
  return records.where((record) {
    if (record.isVoided) {
      return false;
    }
    final recordDay = _dateOnly(record.date);
    return !recordDay.isBefore(start) && !recordDay.isAfter(end);
  }).toList();
}

({DateTime start, DateTime end}) _currentRange(
    DateTime targetDay, int filterIndex) {
  if (filterIndex == 0) {
    return (
      start: targetDay.subtract(const Duration(days: 6)),
      end: targetDay,
    );
  }
  if (filterIndex == 1) {
    return (
      start: DateTime(targetDay.year, targetDay.month, 1),
      end: DateTime(targetDay.year, targetDay.month + 1, 0),
    );
  }
  return (
    start: DateTime(targetDay.year, 1, 1),
    end: DateTime(targetDay.year, 12, 31),
  );
}

({DateTime start, DateTime end}) _previousRange(
    DateTime targetDay, int filterIndex) {
  if (filterIndex == 0) {
    final currentStart = targetDay.subtract(const Duration(days: 6));
    return (
      start: currentStart.subtract(const Duration(days: 7)),
      end: currentStart.subtract(const Duration(days: 1)),
    );
  }
  if (filterIndex == 1) {
    final previousMonth = DateTime(targetDay.year, targetDay.month - 1, 1);
    return (
      start: previousMonth,
      end: DateTime(previousMonth.year, previousMonth.month + 1, 0),
    );
  }
  final previousYear = targetDay.year - 1;
  return (
    start: DateTime(previousYear, 1, 1),
    end: DateTime(previousYear, 12, 31),
  );
}

List<String> _buildInsights({
  required bool isExpenseView,
  required String compareLabel,
  required double viewTotal,
  required double previousViewTotal,
  required double viewDeltaAmount,
  required double? viewDeltaRate,
  required List<ReportCategorySummary> categories,
  required Map<int, double> trendData,
  required Map<int, String> trendTooltipLabels,
  required int filterIndex,
  required int recordCount,
}) {
  final typeName = isExpenseView ? '支出' : '收入';
  final insights = <String>[];

  if (viewTotal > 0) {
    if (previousViewTotal > 0 && viewDeltaRate != null) {
      final changeText = viewDeltaAmount >= 0 ? '增加' : '减少';
      insights.add(
        '较$compareLabel$changeText${viewDeltaAmount.abs().toStringAsFixed(2)}，幅度${(viewDeltaRate.abs() * 100).toStringAsFixed(1)}%',
      );
    } else if (previousViewTotal == 0) {
      insights.add('本期共有 $recordCount 笔$typeName记录，是新的统计起点。');
    }

    if (categories.isNotEmpty) {
      final top = categories.first;
      final share = viewTotal == 0 ? 0.0 : top.amount / viewTotal * 100;
      insights.add(
        '${top.category.name}是本期$typeName最高分类，占比${share.toStringAsFixed(1)}%',
      );
    }

    if (trendData.isNotEmpty) {
      final peak =
          trendData.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final label = trendTooltipLabels[peak.key] ?? '';
      final unit = filterIndex == 2 ? '月份' : '日期';
      insights
          .add('$label是本期$typeName最高$unit，金额${peak.value.toStringAsFixed(2)}');
    }
  }

  return insights;
}

ReportSnapshot buildReportSnapshot({
  required List<Record> records,
  required List<CategoryGroup> categoryGroups,
  required DateTime targetDate,
  required int filterIndex,
  required bool isExpenseView,
}) {
  final targetDay = _dateOnly(targetDate);
  final currentRange = _currentRange(targetDay, filterIndex);
  final previousRange = _previousRange(targetDay, filterIndex);
  final filteredRecords =
      _recordsInRange(records, currentRange.start, currentRange.end);
  final previousRecords =
      _recordsInRange(records, previousRange.start, previousRange.end);

  final expenseRecords =
      filteredRecords.where((record) => record.isExpense).toList();
  final incomeRecords =
      filteredRecords.where((record) => !record.isExpense).toList();
  final previousExpenseRecords =
      previousRecords.where((record) => record.isExpense).toList();
  final previousIncomeRecords =
      previousRecords.where((record) => !record.isExpense).toList();

  final totalExpense =
      expenseRecords.fold(0.0, (sum, item) => sum + item.amount);
  final totalIncome = incomeRecords.fold(0.0, (sum, item) => sum + item.amount);
  final previousTotalExpense =
      previousExpenseRecords.fold(0.0, (sum, item) => sum + item.amount);
  final previousTotalIncome =
      previousIncomeRecords.fold(0.0, (sum, item) => sum + item.amount);

  final viewRecords = isExpenseView ? expenseRecords : incomeRecords;
  final previousViewRecords =
      isExpenseView ? previousExpenseRecords : previousIncomeRecords;
  final viewTotal = isExpenseView ? totalExpense : totalIncome;
  final previousViewTotal =
      isExpenseView ? previousTotalExpense : previousTotalIncome;
  final viewDeltaAmount = viewTotal - previousViewTotal;
  final viewDeltaRate =
      previousViewTotal > 0 ? viewDeltaAmount / previousViewTotal : null;

  final amountByCategory = <String, double>{};
  final countByCategory = <String, int>{};
  final previousAmountByCategory = <String, double>{};
  final categoryById = <String, Category>{};
  final amountByGroup = <String, double>{};
  final countByGroup = <String, int>{};
  final previousAmountByGroup = <String, double>{};
  final groupById = <String, CategoryGroup>{
    for (final group in categoryGroups) group.id: group,
  };

  for (final record in viewRecords) {
    final categoryId = record.category.id;
    final groupId = record.category.groupId;
    amountByCategory[categoryId] =
        (amountByCategory[categoryId] ?? 0) + record.amount;
    countByCategory[categoryId] = (countByCategory[categoryId] ?? 0) + 1;
    categoryById[categoryId] = record.category;
    amountByGroup[groupId] = (amountByGroup[groupId] ?? 0) + record.amount;
    countByGroup[groupId] = (countByGroup[groupId] ?? 0) + 1;
  }

  for (final record in previousViewRecords) {
    final categoryId = record.category.id;
    final groupId = record.category.groupId;
    previousAmountByCategory[categoryId] =
        (previousAmountByCategory[categoryId] ?? 0) + record.amount;
    categoryById[categoryId] = record.category;
    previousAmountByGroup[groupId] =
        (previousAmountByGroup[groupId] ?? 0) + record.amount;
  }

  final categoryIds = {
    ...amountByCategory.keys,
    ...previousAmountByCategory.keys,
  };

  final categories = categoryIds
      .map((categoryId) {
        final amount = amountByCategory[categoryId] ?? 0.0;
        final previousAmount = previousAmountByCategory[categoryId] ?? 0.0;
        final deltaAmount = amount - previousAmount;
        final deltaRate =
            previousAmount > 0 ? deltaAmount / previousAmount : null;
        return ReportCategorySummary(
          category: categoryById[categoryId]!,
          amount: amount,
          count: countByCategory[categoryId] ?? 0,
          previousAmount: previousAmount,
          deltaAmount: deltaAmount,
          deltaRate: deltaRate,
        );
      })
      .where((summary) => summary.amount > 0)
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final groupIds = {
    ...amountByGroup.keys,
    ...previousAmountByGroup.keys,
  };

  final groups = groupIds
      .map((groupId) {
        final amount = amountByGroup[groupId] ?? 0.0;
        final previousAmount = previousAmountByGroup[groupId] ?? 0.0;
        final deltaAmount = amount - previousAmount;
        final deltaRate =
            previousAmount > 0 ? deltaAmount / previousAmount : null;
        return ReportGroupSummary(
          group: groupById[groupId],
          fallbackName: groupId.isEmpty ? '未分组' : '未命名大类',
          amount: amount,
          count: countByGroup[groupId] ?? 0,
          previousAmount: previousAmount,
          deltaAmount: deltaAmount,
          deltaRate: deltaRate,
        );
      })
      .where((summary) => summary.amount > 0)
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final trendData = <int, double>{};
  final trendAxisLabels = <int, String>{};
  final trendTooltipLabels = <int, String>{};
  var maxX = 0;
  var averageAmount = 0.0;
  Record? maxRecord;
  var averageTitle = '日均${isExpenseView ? '支出' : '收入'}';

  if (viewRecords.isNotEmpty) {
    var points = 1;
    if (filterIndex == 0) {
      points = 7;
    } else if (filterIndex == 1) {
      points = DateTime(targetDay.year, targetDay.month + 1, 0).day;
    } else {
      points = 12;
      averageTitle = '月均${isExpenseView ? '支出' : '收入'}';
    }

    averageAmount = viewTotal / points;
    maxRecord = viewRecords.reduce((a, b) => a.amount > b.amount ? a : b);

    for (var index = 1; index <= points; index++) {
      trendData[index] = 0.0;
      if (filterIndex == 0) {
        final day = currentRange.start.add(Duration(days: index - 1));
        trendAxisLabels[index] = _weekdayLabel(day.weekday);
        trendTooltipLabels[index] = '${day.month}月${day.day}日';
      } else if (filterIndex == 1) {
        trendAxisLabels[index] = index.toString();
        trendTooltipLabels[index] = '${targetDay.month}月$index日';
      } else {
        trendAxisLabels[index] = index.toString();
        trendTooltipLabels[index] = '$index月';
      }
    }

    for (final record in viewRecords) {
      late final int key;
      if (filterIndex == 0) {
        key = _dateOnly(record.date).difference(currentRange.start).inDays + 1;
      } else if (filterIndex == 1) {
        key = record.date.day;
      } else {
        key = record.date.month;
      }
      trendData[key] = (trendData[key] ?? 0) + record.amount;
    }

    maxX = points;
  }

  final compareLabel = _compareLabel(filterIndex);
  final insights = _buildInsights(
    isExpenseView: isExpenseView,
    compareLabel: compareLabel,
    viewTotal: viewTotal,
    previousViewTotal: previousViewTotal,
    viewDeltaAmount: viewDeltaAmount,
    viewDeltaRate: viewDeltaRate,
    categories: categories,
    trendData: trendData,
    trendTooltipLabels: trendTooltipLabels,
    filterIndex: filterIndex,
    recordCount: viewRecords.length,
  );

  return ReportSnapshot(
    expenseRecords: expenseRecords,
    incomeRecords: incomeRecords,
    viewRecords: viewRecords,
    totalExpense: totalExpense,
    totalIncome: totalIncome,
    viewTotal: viewTotal,
    previousViewTotal: previousViewTotal,
    viewDeltaAmount: viewDeltaAmount,
    viewDeltaRate: viewDeltaRate,
    averageAmount: averageAmount,
    maxRecord: maxRecord,
    categories: categories,
    groups: groups,
    trendData: trendData,
    trendAxisLabels: trendAxisLabels,
    trendTooltipLabels: trendTooltipLabels,
    maxX: maxX,
    isExpenseView: isExpenseView,
    viewRecordCount: viewRecords.length,
    periodLabel: _periodLabel(targetDay, filterIndex),
    compareLabel: compareLabel,
    averageTitle: averageTitle,
    insights: insights,
  );
}
