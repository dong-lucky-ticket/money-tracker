import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/data_provider.dart';
import '../models/record.dart';
import '../utils/icon_mapper.dart';
import '../widgets/edit_record_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(MdiIcons.textSearch, size: 64, color: const Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  const Text(
                    '输入分类或备注进行搜索',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            );
          }

          final filteredRecords = provider.records.where((r) {
            return r.remark.contains(_searchQuery) ||
                r.category.name.contains(_searchQuery);
          }).toList();

          if (filteredRecords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(MdiIcons.textSearch, size: 64, color: const Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  const Text(
                    '没有找到相关账单',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ],
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: groupedRecords.entries.map((e) => _buildDailyRecordList(e.key, e.value, provider)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDailyRecordList(String dateStr, List<Record> records, DataProvider provider) {
    final date = DateTime.parse(dateStr);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isYesterday = date.year == today.year && date.month == today.month && date.day == today.day - 1;

    String dateDisplay = DateFormat('M月d日').format(date);
    if (isToday) {
      dateDisplay += ' 今天';
    } else if (isYesterday) {
      dateDisplay += ' 昨天';
    }

    double dayIncome = records.where((r) => !r.isExpense).fold(0.0, (s, r) => s + r.amount);
    double dayExpense = records.where((r) => r.isExpense).fold(0.0, (s, r) => s + r.amount);

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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
                Row(
                  children: [
                    if (dayIncome > 0)
                      Text('收入: ${dayIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    if (dayIncome > 0 && dayExpense > 0) const SizedBox(width: 12),
                    if (dayExpense > 0)
                      Text('支出: ${dayExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
    final catColor = record.isVoided ? Colors.grey : _hexToColor(record.category.colorHex);
    final amountColor = record.isVoided
        ? Colors.grey
        : (record.isExpense ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F));
        
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteRecord(record.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5A5A),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (record.isVoided) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditRecordSheet(record: record, provider: provider),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: record.isVoided ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!record.isVoided)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconMapper.getIcon(record.category.iconName), color: catColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: record.isVoided ? Colors.grey : const Color(0xFF1F2937),
                            decoration: record.isVoided ? TextDecoration.lineThrough : null,
                          )
                        ),
                        if (record.isVoided) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('已废弃', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ]
                      ],
                    ),
                    if (record.remark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.remark,
                        style: TextStyle(
                          fontSize: 12,
                          color: record.isVoided ? Colors.grey.shade400 : const Color(0xFF9CA3AF),
                          decoration: record.isVoided ? TextDecoration.lineThrough : null,
                        )
                      ),
                    ]
                  ],
                ),
              ),
              Text(
                '${record.isExpense ? '-' : '+'}${record.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  decoration: record.isVoided ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String code) {
    if (code.startsWith('#')) {
      code = code.substring(1);
    }
    if (code.length == 6) {
      code = 'FF$code';
    }
    return Color(int.parse(code, radix: 16));
  }
}
