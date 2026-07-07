import 'report_time_range.dart';

enum ReportRecordType {
  expense,
  income,
  all,
}

class ReportFilter {
  final ReportTimeRange timeRange;
  final ReportRecordType recordType;
  final Set<String> groupIds;
  final Set<String> categoryIds;
  final String keyword;
  final bool includeVoided;

  const ReportFilter({
    this.timeRange = const ReportTimeRange.last7Days(),
    this.recordType = ReportRecordType.expense,
    this.groupIds = const {},
    this.categoryIds = const {},
    this.keyword = '',
    this.includeVoided = false,
  });

  bool get hasGroupFilter => groupIds.isNotEmpty;

  bool get hasCategoryFilter => categoryIds.isNotEmpty;

  bool get hasKeywordFilter => keyword.trim().isNotEmpty;

  bool get hasAdvancedFilters =>
      hasGroupFilter || hasCategoryFilter || hasKeywordFilter || includeVoided;

  String get normalizedKeyword => keyword.trim().toLowerCase();

  ReportFilter copyWith({
    ReportTimeRange? timeRange,
    ReportRecordType? recordType,
    Set<String>? groupIds,
    Set<String>? categoryIds,
    String? keyword,
    bool? includeVoided,
  }) {
    return ReportFilter(
      timeRange: timeRange ?? this.timeRange,
      recordType: recordType ?? this.recordType,
      groupIds: groupIds ?? this.groupIds,
      categoryIds: categoryIds ?? this.categoryIds,
      keyword: keyword ?? this.keyword,
      includeVoided: includeVoided ?? this.includeVoided,
    );
  }
}
