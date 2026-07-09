import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/report_filter.dart';
import '../models/report_snapshot.dart';
import '../models/report_time_range.dart';
import '../providers/data_provider.dart';
import '../utils/record_queries.dart';
import '../utils/report_snapshot_builder.dart';

class ReportScreenController extends ChangeNotifier {
  ReportFilter _filter = const ReportFilter();
  DateTime _selectedDate = DateTime.now();

  ReportFilter get filter => _filter;
  DateTime get selectedDate => _selectedDate;
  ReportTimeRange get selectedRange => _filter.timeRange;

  ReportSnapshot buildSnapshot(DataProvider provider) {
    return buildReportSnapshot(
      records: provider.records,
      categoryGroups: provider.categoryGroups,
      targetDate: _selectedDate,
      filter: _filter,
    );
  }

  List<CategoryGroup> availableGroups(DataProvider provider) {
    return filterCategoryGroupsByRecordType(
      provider.categoryGroups,
      _filter.recordType,
    );
  }

  List<Category> availableCategories(
    DataProvider provider, {
    Set<String>? selectedGroupIds,
  }) {
    return filterCategoriesByRecordType(
      provider.categories,
      _filter.recordType,
      groupIds: selectedGroupIds ?? _filter.groupIds,
    );
  }

  ReportFilter normalizeFilter(
    ReportFilter candidate,
    DataProvider provider,
  ) {
    final validGroupIds =
        availableGroups(provider).map((group) => group.id).toSet();
    final normalizedGroupIds = candidate.groupIds.intersection(validGroupIds);
    final validCategoryIds = availableCategories(
      provider,
      selectedGroupIds: normalizedGroupIds,
    ).map((category) => category.id).toSet();
    final normalizedCategoryIds =
        candidate.categoryIds.intersection(validCategoryIds);

    return candidate.copyWith(
      groupIds: normalizedGroupIds,
      categoryIds: normalizedCategoryIds,
    );
  }

  List<String> activeFilterLabels(DataProvider provider) {
    final groupNames = {
      for (final group in provider.categoryGroups) group.id: group.name,
    };
    final categoryNames = {
      for (final category in provider.categories) category.id: category.name,
    };
    final labels = <String>[];

    if (_filter.hasGroupFilter) {
      final names = _filter.groupIds
          .map((id) => groupNames[id])
          .whereType<String>()
          .toList();
      if (names.isNotEmpty) {
        labels.add(
          names.length <= 2
              ? '大类: ${names.join('、')}'
              : '大类: ${names.length} 项',
        );
      }
    }

    if (_filter.hasCategoryFilter) {
      final names = _filter.categoryIds
          .map((id) => categoryNames[id])
          .whereType<String>()
          .toList();
      if (names.isNotEmpty) {
        labels.add(
          names.length <= 2
              ? '分类: ${names.join('、')}'
              : '分类: ${names.length} 项',
        );
      }
    }

    if (_filter.hasKeywordFilter) {
      labels.add('关键词: ${_filter.keyword.trim()}');
    }

    return labels;
  }

  void updateFilter(ReportFilter nextFilter, DataProvider provider) {
    _filter = normalizeFilter(nextFilter, provider);
    notifyListeners();
  }

  void updateRecordType(
    ReportRecordType recordType,
    DataProvider provider,
  ) {
    updateFilter(
      _filter.copyWith(recordType: recordType),
      provider,
    );
  }

  void clearAdvancedFilters() {
    _filter = _filter.copyWith(
      groupIds: <String>{},
      categoryIds: <String>{},
      keyword: '',
    );
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setPresetRange(ReportTimeRangePreset preset) {
    _filter = _filter.copyWith(timeRange: _presetRange(preset));
    notifyListeners();
  }

  void setCustomRange(DateTimeRange range) {
    _filter = _filter.copyWith(
      timeRange: ReportTimeRange.custom(
        start: range.start,
        end: range.end,
      ),
    );
    _selectedDate = range.end;
    notifyListeners();
  }

  ReportTimeRange _presetRange(ReportTimeRangePreset preset) {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return const ReportTimeRange.last7Days();
      case ReportTimeRangePreset.last30Days:
        return const ReportTimeRange.last30Days();
      case ReportTimeRangePreset.thisMonth:
        return const ReportTimeRange.thisMonth();
      case ReportTimeRangePreset.last6Months:
        return const ReportTimeRange.last6Months();
      case ReportTimeRangePreset.thisYear:
        return const ReportTimeRange.thisYear();
      case ReportTimeRangePreset.custom:
        return selectedRange;
    }
  }
}
