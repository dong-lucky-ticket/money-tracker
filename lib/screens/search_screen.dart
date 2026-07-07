import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/data_provider.dart';
import '../models/record.dart';
import '../theme/app_colors.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/edit_record_sheet.dart';
import '../widgets/record/record_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  int _compareRecordTimeline(Record a, Record b) {
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索分类或备注',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          if (_searchQuery.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icon(
                  MdiIcons.textSearch,
                  size: 64,
                  color: AppColors.border,
                ),
                title: '输入分类或备注进行搜索',
              ),
            );
          }

          final filteredRecords = provider.records.where((r) {
            return r.remark.contains(_searchQuery) ||
                r.category.name.contains(_searchQuery);
          }).toList();

          if (filteredRecords.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icon(
                  MdiIcons.textSearch,
                  size: 64,
                  color: AppColors.border,
                ),
                title: '没有找到相关账单',
              ),
            );
          }

          // Group by date
          final Map<String, List<Record>> groupedRecords = {};
          for (var r in filteredRecords) {
            final dateStr = DateFormat('yyyy-MM-dd').format(r.date);
            if (!groupedRecords.containsKey(dateStr)) {
              groupedRecords[dateStr] = [];
            }
            groupedRecords[dateStr]!.add(r);
          }
          for (final grouped in groupedRecords.values) {
            grouped.sort(_compareRecordTimeline);
          }
          final groupedEntries = groupedRecords.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: groupedEntries
                .map((e) => _buildDailyRecordList(e.key, e.value, provider))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDailyRecordList(
      String dateStr, List<Record> records, DataProvider provider) {
    final date = DateTime.parse(dateStr);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isYesterday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day - 1;

    String dateDisplay = DateFormat('M月d日').format(date);
    if (isToday) {
      dateDisplay += ' 今天';
    } else if (isYesterday) {
      dateDisplay += ' 昨天';
    }

    double dayIncome = records
        .where((r) => !r.isExpense && !r.isVoided)
        .fold(0.0, (s, r) => s + r.amount);
    double dayExpense = records
        .where((r) => r.isExpense && !r.isVoided)
        .fold(0.0, (s, r) => s + r.amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateDisplay,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280)),
                ),
                Row(
                  children: [
                    if (dayIncome > 0)
                      Text('收入: ${dayIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    if (dayIncome > 0 && dayExpense > 0)
                      const SizedBox(width: 12),
                    if (dayExpense > 0)
                      Text('支出: ${dayExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          ...records.map((r) => _buildRecordItem(r, provider)),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Record record, DataProvider provider) {
    return RecordListItem(
      record: record,
      onDelete: () => provider.deleteRecord(record.id),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditRecordSheet(record: record, provider: provider),
        );
      },
    );
  }
}
