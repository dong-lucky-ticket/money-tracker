import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/record.dart';
import '../models/report_filter.dart';
import '../models/report_snapshot.dart';
import '../models/report_time_range.dart';
import 'report_record_query.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _weekdayLabel(int weekday) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[weekday - 1];
}

int _inclusiveMonthCount(DateTime start, DateTime end) {
  return (end.year - start.year) * 12 + end.month - start.month + 1;
}

int _monthOffset(DateTime start, DateTime target) {
  return (target.year - start.year) * 12 + target.month - start.month;
}

List<Record> _recordsForType(
  List<Record> records,
  ReportRecordType recordType,
) {
  switch (recordType) {
    case ReportRecordType.expense:
      return records.where((record) => record.isExpense).toList();
    case ReportRecordType.income:
      return records.where((record) => !record.isExpense).toList();
    case ReportRecordType.all:
      return List<Record>.from(records);
  }
}

List<String> _buildInsights({
  required ReportRecordType recordType,
  required String compareLabel,
  required double viewTotal,
  required double previousViewTotal,
  required double viewDeltaAmount,
  required double? viewDeltaRate,
  required List<ReportCategorySummary> categories,
  required Map<int, double> trendData,
  required Map<int, String> trendTooltipLabels,
  required ReportTrendMode trendMode,
  required int recordCount,
}) {
  final typeName = switch (recordType) {
    ReportRecordType.expense => '支出',
    ReportRecordType.income => '收入',
    ReportRecordType.all => '收支',
  };
  final insights = <String>[];

  if (viewTotal <= 0) {
    return insights;
  }

  if (previousViewTotal > 0 && viewDeltaRate != null) {
    final changeText = viewDeltaAmount >= 0 ? '增加' : '减少';
    insights.add(
      '较$compareLabel$changeText${viewDeltaAmount.abs().toStringAsFixed(2)}，幅度 ${(viewDeltaRate.abs() * 100).toStringAsFixed(1)}%',
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
    final peak = trendData.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final label = trendTooltipLabels[peak.key] ?? '';
    final unit = trendMode == ReportTrendMode.monthly ? '月份' : '日期';
    insights
        .add('$label是本期$typeName最高$unit，金额${peak.value.toStringAsFixed(2)}');
  }

  return insights;
}

ReportSnapshot buildReportSnapshot({
  required List<Record> records,
  required List<CategoryGroup> categoryGroups,
  required DateTime targetDate,
  required ReportFilter filter,
}) {
  final targetDay = _dateOnly(targetDate);
  final currentRange = filter.timeRange.resolveCurrent(targetDay);
  final previousRange = filter.timeRange.resolvePrevious(targetDay);
  final trendMode = filter.timeRange.resolveTrendMode(targetDay);
  final filteredRecords = queryReportRecords(
    records: records,
    filter: filter,
    anchorDate: targetDay,
    rangeOverride: currentRange,
  );
  final previousRecords = queryReportRecords(
    records: records,
    filter: filter,
    anchorDate: targetDay,
    rangeOverride: previousRange,
  );

  final expenseRecords =
      filteredRecords.where((record) => record.isExpense).toList();
  final incomeRecords =
      filteredRecords.where((record) => !record.isExpense).toList();

  final totalExpense =
      expenseRecords.fold(0.0, (sum, item) => sum + item.amount);
  final totalIncome = incomeRecords.fold(0.0, (sum, item) => sum + item.amount);

  final viewRecords = _recordsForType(filteredRecords, filter.recordType);
  final previousViewRecords =
      _recordsForType(previousRecords, filter.recordType);
  final viewTotal = viewRecords.fold(0.0, (sum, item) => sum + item.amount);
  final previousViewTotal =
      previousViewRecords.fold(0.0, (sum, item) => sum + item.amount);
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
  final averageTitle =
      '${trendMode == ReportTrendMode.monthly ? '月均' : '日均'}${switch (filter.recordType) {
    ReportRecordType.expense => '支出',
    ReportRecordType.income => '收入',
    ReportRecordType.all => '收支',
  }}';

  if (viewRecords.isNotEmpty) {
    final pointCount = trendMode == ReportTrendMode.monthly
        ? _inclusiveMonthCount(currentRange.start, currentRange.end)
        : currentRange.dayCount;

    averageAmount = pointCount > 0 ? viewTotal / pointCount : 0.0;
    maxRecord = viewRecords.reduce((a, b) => a.amount > b.amount ? a : b);

    for (var index = 0; index < pointCount; index++) {
      final key = index + 1;
      trendData[key] = 0.0;

      if (trendMode == ReportTrendMode.monthly) {
        final monthDate = DateTime(
            currentRange.start.year, currentRange.start.month + index, 1);
        trendAxisLabels[key] = monthDate.month.toString();
        trendTooltipLabels[key] = DateFormat('yyyy年M月').format(monthDate);
      } else {
        final day = currentRange.start.add(Duration(days: index));
        trendAxisLabels[key] =
            filter.timeRange.preset == ReportTimeRangePreset.last7Days
                ? _weekdayLabel(day.weekday)
                : day.day.toString();
        trendTooltipLabels[key] = DateFormat('M月d日').format(day);
      }
    }

    for (final record in viewRecords) {
      late final int key;
      if (trendMode == ReportTrendMode.monthly) {
        key = _monthOffset(currentRange.start, record.date) + 1;
      } else {
        key = _dateOnly(record.date).difference(currentRange.start).inDays + 1;
      }
      trendData[key] = (trendData[key] ?? 0) + record.amount;
    }

    maxX = pointCount;
  }

  final compareLabel = filter.timeRange.compareLabel;
  final insights = _buildInsights(
    recordType: filter.recordType,
    compareLabel: compareLabel,
    viewTotal: viewTotal,
    previousViewTotal: previousViewTotal,
    viewDeltaAmount: viewDeltaAmount,
    viewDeltaRate: viewDeltaRate,
    categories: categories,
    trendData: trendData,
    trendTooltipLabels: trendTooltipLabels,
    trendMode: trendMode,
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
    trendMode: trendMode,
    recordType: filter.recordType,
    viewRecordCount: viewRecords.length,
    periodLabel: filter.timeRange.buildPeriodLabel(targetDay),
    compareLabel: compareLabel,
    averageTitle: averageTitle,
    insights: insights,
  );
}
