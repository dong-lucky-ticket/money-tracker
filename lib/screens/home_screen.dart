import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/record.dart';
import '../screens/search_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/edit_record_sheet.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/record/record_list_item.dart';

// Note: floatingActionButton replacement skipped as it is likely located in the parent Scaffold/MainScreen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();

  int _compareRecordTimeline(Record a, Record b) {
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  void _pickMonth() {
    showDialog(
      context: context,
      builder: (context) {
        int tempYear = _selectedMonth.year;
        return AlertDialog(
          title: const Text('选择月份'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setStateDialog(() => tempYear--)),
                        Text('$tempYear年', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setStateDialog(() => tempYear++)),
                      ],
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          int month = index + 1;
                          bool isSelected = tempYear == _selectedMonth.year && month == _selectedMonth.month;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMonth = DateTime(tempYear, month);
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$month月', style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
                GestureDetector(
                  onTap: _pickMonth,
                  child: Row(
                    children: [
                      Text(
                        DateFormat('yyyy年M月').format(_selectedMonth),
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
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Icon(MdiIcons.magnify, size: 28, color: const Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          
          // 主内容滚动区
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, provider, child) {
                final records = provider.records
                    .where((r) =>
                        r.date.year == _selectedMonth.year &&
                        r.date.month == _selectedMonth.month)
                    .toList();
                final validRecords =
                    records.where((record) => !record.isVoided).toList();

                final double monthlyExpense = validRecords
                    .where((r) => r.isExpense)
                    .fold(0.0, (s, r) => s + r.amount);
                final double monthlyIncome = validRecords
                    .where((r) => !r.isExpense)
                    .fold(0.0, (s, r) => s + r.amount);

                // Group records by date (yyyy-MM-dd)
                final Map<String, List<Record>> groupedRecords = {};
                for (var r in records) {
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 总览卡片
                    _buildOverviewCard(monthlyExpense, monthlyIncome),
                    // 流水列表
                    if (records.isEmpty)
                      _buildEmptyState()
                    else
                      ...groupedEntries
                          .map((e) => _buildDailyRecordList(e.key, e.value, provider)),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(double monthlyExpense, double monthlyIncome) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
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
                style:
                    TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '￥${monthlyExpense.toStringAsFixed(2)}',
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
                      Text(monthlyIncome.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月结余', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text((monthlyIncome - monthlyExpense).toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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

    double dayIncome = records.where((r) => !r.isExpense && !r.isVoided).fold(0.0, (s, r) => s + r.amount);
    double dayExpense = records.where((r) => r.isExpense && !r.isVoided).fold(0.0, (s, r) => s + r.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // 日期和汇总
        Padding(
          padding: const EdgeInsets.only(top: 6.0, left: 4.0, right: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                '支出 ${dayExpense.toStringAsFixed(2)}  收入 ${dayIncome.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ),
        
        // 记录列表
        ...records.map((r) => _buildRecordItem(r, provider)),
      ],
    );
  }

  Widget _buildRecordItem(Record record, DataProvider provider) {
    return RecordListItem(
      record: record,
      margin: const EdgeInsets.only(top: 12),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditRecordSheet(record: record, provider: provider),
        );
      },
      onConfirmDelete: () async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: const Text('你确定要删除这条账单吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDelete: () => provider.deleteRecord(record.id),
      onToggleVoided: () {
        record.isVoided = !record.isVoided;
        record.updatedAt = DateTime.now();
        record.save();
        provider.refreshUI();
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icon(
        MdiIcons.textBoxRemoveOutline,
        size: 64,
        color: AppColors.border,
      ),
      title: '本月还没有记账哦\n快去记录第一笔账单吧！',
    );
  }
}
