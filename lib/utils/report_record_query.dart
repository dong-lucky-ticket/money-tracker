import '../models/record.dart';
import '../models/report_filter.dart';
import '../models/report_time_range.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

List<Record> queryReportRecords({
  required List<Record> records,
  required ReportFilter filter,
  required DateTime anchorDate,
  ReportDateRange? rangeOverride,
}) {
  final targetRange =
      rangeOverride ?? filter.timeRange.resolveCurrent(anchorDate);
  final normalizedKeyword = filter.normalizedKeyword;

  return records.where((record) {
    if (!filter.includeVoided && record.isVoided) {
      return false;
    }

    final recordDay = _dateOnly(record.date);
    if (recordDay.isBefore(targetRange.start) ||
        recordDay.isAfter(targetRange.end)) {
      return false;
    }

    switch (filter.recordType) {
      case ReportRecordType.expense:
        if (!record.isExpense) {
          return false;
        }
        break;
      case ReportRecordType.income:
        if (record.isExpense) {
          return false;
        }
        break;
      case ReportRecordType.all:
        break;
    }

    if (filter.hasGroupFilter &&
        !filter.groupIds.contains(record.category.groupId)) {
      return false;
    }

    if (filter.hasCategoryFilter &&
        !filter.categoryIds.contains(record.category.id)) {
      return false;
    }

    if (normalizedKeyword.isNotEmpty) {
      final keywordScope =
          '${record.remark} ${record.category.name}'.toLowerCase();
      if (!keywordScope.contains(normalizedKeyword)) {
        return false;
      }
    }

    return true;
  }).toList();
}
