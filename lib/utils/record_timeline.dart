import 'package:intl/intl.dart';

import '../models/record.dart';

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int compareRecordsByTimeline(Record a, Record b) {
  final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
  if (updatedCompare != 0) {
    return updatedCompare;
  }
  return b.createdAt.compareTo(a.createdAt);
}

String buildTimelineDateLabel(
  DateTime date, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  final buffer = StringBuffer(DateFormat('M月d日').format(date));

  if (_isSameDay(date, today)) {
    buffer.write(' 今天');
  } else if (_isSameDay(date, yesterday)) {
    buffer.write(' 昨天');
  }

  return buffer.toString();
}

class RecordTimelineSection {
  final DateTime date;
  final List<Record> records;

  const RecordTimelineSection({
    required this.date,
    required this.records,
  });

  double get income => records
      .where((record) => !record.isExpense && !record.isVoided)
      .fold(0.0, (sum, record) => sum + record.amount);

  double get expense => records
      .where((record) => record.isExpense && !record.isVoided)
      .fold(0.0, (sum, record) => sum + record.amount);

  String label({
    DateTime? now,
  }) {
    return buildTimelineDateLabel(date, now: now);
  }
}

List<RecordTimelineSection> buildRecordTimelineSections(
  Iterable<Record> records,
) {
  final groupedRecords = <DateTime, List<Record>>{};

  for (final record in records) {
    final date = _dateOnly(record.date);
    groupedRecords.putIfAbsent(date, () => <Record>[]).add(record);
  }

  final entries = groupedRecords.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  return entries.map((entry) {
    final sortedRecords = List<Record>.from(entry.value)
      ..sort(compareRecordsByTimeline);
    return RecordTimelineSection(
      date: entry.key,
      records: sortedRecords,
    );
  }).toList();
}
