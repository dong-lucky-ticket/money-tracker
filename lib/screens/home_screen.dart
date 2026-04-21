import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/record.dart';
import '../utils/icon_mapper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 顶部导航
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('yyyy年M月').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(MdiIcons.chevronDown, color: const Color(0xFF6B7280)),
                  ],
                ),
                Icon(MdiIcons.magnify, size: 28, color: const Color(0xFF4B5563)),
              ],
            ),
          ),
          
          // 主内容滚动区
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, provider, child) {
                final records = provider.records;
                
                // Group records by date (yyyy-MM-dd)
                final Map<String, List<Record>> groupedRecords = {};
                for (var r in records) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(r.date);
                  if (!groupedRecords.containsKey(dateStr)) {
                    groupedRecords[dateStr] = [];
                  }
                  groupedRecords[dateStr]!.add(r);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 总览卡片
                    _buildOverviewCard(provider),
                    const SizedBox(height: 32),
                    // 流水列表
                    ...groupedRecords.entries.map((e) => _buildDailyRecordList(e.key, e.value, provider)),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DataProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本月总支出 (元)',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '￥${provider.monthlyExpense.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月收入', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(provider.monthlyIncome.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月结余', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text((provider.monthlyIncome - provider.monthlyExpense).toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
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
          // 日期和汇总
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
          
          // 记录列表
          ...records.map((r) => _buildRecordItem(r, provider)),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Record record, DataProvider provider) {
    final catColor = _hexToColor(record.category.colorHex);
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
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
                  Text(record.category.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  if (record.remark.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(record.remark, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ]
                ],
              ),
            ),
            Text(
              '${record.isExpense ? '-' : '+'}${record.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: record.isExpense ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F),
              ),
            ),
          ],
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
