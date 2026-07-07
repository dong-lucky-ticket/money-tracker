import 'package:intl/intl.dart';

enum ReportTimeRangePreset {
  last7Days,
  last30Days,
  thisMonth,
  last6Months,
  thisYear,
  custom,
}

enum ReportTrendMode {
  daily,
  monthly,
}

class ReportDateRange {
  final DateTime start;
  final DateTime end;

  const ReportDateRange({
    required this.start,
    required this.end,
  });

  int get dayCount => end.difference(start).inDays + 1;
}

class ReportTimeRange {
  final ReportTimeRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  const ReportTimeRange._({
    required this.preset,
    this.customStart,
    this.customEnd,
  });

  const ReportTimeRange.last7Days()
      : this._(preset: ReportTimeRangePreset.last7Days);

  const ReportTimeRange.last30Days()
      : this._(preset: ReportTimeRangePreset.last30Days);

  const ReportTimeRange.thisMonth()
      : this._(preset: ReportTimeRangePreset.thisMonth);

  const ReportTimeRange.last6Months()
      : this._(preset: ReportTimeRangePreset.last6Months);

  const ReportTimeRange.thisYear()
      : this._(preset: ReportTimeRangePreset.thisYear);

  ReportTimeRange.custom({
    required DateTime start,
    required DateTime end,
  }) : this._(
          preset: ReportTimeRangePreset.custom,
          customStart: _dateOnly(start),
          customEnd: _dateOnly(end),
        );

  static const quickPresets = [
    ReportTimeRangePreset.last7Days,
    ReportTimeRangePreset.last30Days,
    ReportTimeRangePreset.thisMonth,
    ReportTimeRangePreset.last6Months,
    ReportTimeRangePreset.thisYear,
    ReportTimeRangePreset.custom,
  ];

  bool get isCustom => preset == ReportTimeRangePreset.custom;

  String get selectionLabel {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '近7天';
      case ReportTimeRangePreset.last30Days:
        return '近30天';
      case ReportTimeRangePreset.thisMonth:
        return '本月';
      case ReportTimeRangePreset.last6Months:
        return '近半年';
      case ReportTimeRangePreset.thisYear:
        return '本年';
      case ReportTimeRangePreset.custom:
        return '自定义';
    }
  }

  String get compareLabel {
    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return '前7天';
      case ReportTimeRangePreset.last30Days:
        return '前30天';
      case ReportTimeRangePreset.thisMonth:
        return '上月';
      case ReportTimeRangePreset.last6Months:
        return '前半年';
      case ReportTimeRangePreset.thisYear:
        return '上年';
      case ReportTimeRangePreset.custom:
        return '上一周期';
    }
  }

  ReportDateRange resolveCurrent(DateTime anchorDate) {
    final normalizedAnchor = _dateOnly(anchorDate);

    switch (preset) {
      case ReportTimeRangePreset.last7Days:
        return ReportDateRange(
          start: normalizedAnchor.subtract(const Duration(days: 6)),
          end: normalizedAnchor,
        );
      case ReportTimeRangePreset.last30Days:
        return ReportDateRange(
          start: normalizedAnchor.subtract(const Duration(days: 29)),
          end: normalizedAnchor,
        );
      case ReportTimeRangePreset.thisMonth:
        return ReportDateRange(
          start: DateTime(normalizedAnchor.year, normalizedAnchor.month, 1),
          end: DateTime(normalizedAnchor.year, normalizedAnchor.month + 1, 0),
        );
      case ReportTimeRangePreset.last6Months:
        return ReportDateRange(
          start: DateTime(normalizedAnchor.year, normalizedAnchor.month - 5, 1),
          end: DateTime(normalizedAnchor.year, normalizedAnchor.month + 1, 0),
        );
      case ReportTimeRangePreset.thisYear:
        return ReportDateRange(
          start: DateTime(normalizedAnchor.year, 1, 1),
          end: DateTime(normalizedAnchor.year, 12, 31),
        );
      case ReportTimeRangePreset.custom:
        return ReportDateRange(
          start: customStart ?? normalizedAnchor,
          end: customEnd ?? normalizedAnchor,
        );
    }
  }

  ReportDateRange resolvePrevious(DateTime anchorDate) {
    final current = resolveCurrent(anchorDate);

    switch (preset) {
      case ReportTimeRangePreset.last7Days:
      case ReportTimeRangePreset.last30Days:
      case ReportTimeRangePreset.custom:
        return ReportDateRange(
          start: current.start.subtract(Duration(days: current.dayCount)),
          end: current.start.subtract(const Duration(days: 1)),
        );
      case ReportTimeRangePreset.thisMonth:
        final previousMonth =
            DateTime(current.start.year, current.start.month - 1, 1);
        return ReportDateRange(
          start: previousMonth,
          end: DateTime(previousMonth.year, previousMonth.month + 1, 0),
        );
      case ReportTimeRangePreset.last6Months:
        return ReportDateRange(
          start: DateTime(current.start.year, current.start.month - 6, 1),
          end: DateTime(current.start.year, current.start.month, 0),
        );
      case ReportTimeRangePreset.thisYear:
        final previousYear = current.start.year - 1;
        return ReportDateRange(
          start: DateTime(previousYear, 1, 1),
          end: DateTime(previousYear, 12, 31),
        );
    }
  }

  ReportTrendMode resolveTrendMode(DateTime anchorDate) {
    if (preset == ReportTimeRangePreset.thisYear ||
        preset == ReportTimeRangePreset.last6Months) {
      return ReportTrendMode.monthly;
    }

    if (preset == ReportTimeRangePreset.custom) {
      return resolveCurrent(anchorDate).dayCount > 62
          ? ReportTrendMode.monthly
          : ReportTrendMode.daily;
    }

    return ReportTrendMode.daily;
  }

  String buildPeriodLabel(DateTime anchorDate) {
    final range = resolveCurrent(anchorDate);
    final start = range.start;
    final end = range.end;

    switch (preset) {
      case ReportTimeRangePreset.thisMonth:
        return DateFormat('yyyy年M月').format(start);
      case ReportTimeRangePreset.thisYear:
        return DateFormat('yyyy年').format(start);
      case ReportTimeRangePreset.last6Months:
        return '${DateFormat('yyyy年M月').format(start)} - ${DateFormat('yyyy年M月').format(end)}';
      case ReportTimeRangePreset.last7Days:
      case ReportTimeRangePreset.last30Days:
      case ReportTimeRangePreset.custom:
        return _formatDateSpan(start, end);
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDateSpan(DateTime start, DateTime end) {
    final sameYear = start.year == end.year;
    final startFormat = DateFormat(sameYear ? 'M月d日' : 'yyyy年M月d日');
    final endFormat = DateFormat('yyyy年M月d日');
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }
}
