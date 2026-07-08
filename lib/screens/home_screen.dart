import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/record.dart';
import '../providers/data_provider.dart';
import '../screens/search_screen.dart';
import '../theme/app_colors.dart';
import '../utils/record_timeline.dart';
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
  DataProvider? _provider;
  DateTime _selectedMonth = _monthOnly(DateTime.now());

  static DateTime _monthOnly(DateTime date) {
    return DateTime(date.year, date.month);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime _resolveDisplayMonth(DataProvider provider) {
    final records = provider.records;
    if (records.isEmpty) {
      return _monthOnly(DateTime.now());
    }
    return _monthOnly(records.first.date);
  }

  void _syncSelectedMonthWithRecords({bool force = false}) {
    final provider = _provider;
    if (provider == null) {
      return;
    }

    final targetMonth = _resolveDisplayMonth(provider);
    if (force || !_isSameMonth(_selectedMonth, targetMonth)) {
      setState(() {
        _selectedMonth = targetMonth;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<DataProvider>();
    if (!identical(_provider, provider)) {
      _provider?.removeListener(_handleProviderChanged);
      _provider = provider;
      _provider?.addListener(_handleProviderChanged);
      _selectedMonth = _resolveDisplayMonth(provider);
    }
  }

  void _handleProviderChanged() {
    if (!mounted) {
      return;
    }
    _syncSelectedMonthWithRecords();
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderChanged);
    super.dispose();
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
                        IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setStateDialog(() => tempYear--)),
                        Text('$tempYear年',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setStateDialog(() => tempYear++)),
                      ],
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, childAspectRatio: 2),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          int month = index + 1;
                          bool isSelected = tempYear == _selectedMonth.year &&
                              month == _selectedMonth.month;
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
                                color: isSelected
                                    ? const Color(0xFF4A90E2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$month月',
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87)),
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
                      Icon(MdiIcons.chevronDown,
                          color: const Color(0xFF6B7280)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchScreen()),
                    );
                  },
                  child: Icon(MdiIcons.magnify,
                      size: 28, color: const Color(0xFF4B5563)),
                ),
              ],
            ),
          ),

          // 主内容滚动区
          Expanded(
            child: Consumer<DataProvider>(builder: (context, provider, child) {
              final records = provider.recordsInMonth(_selectedMonth);
              final validRecords =
                  records.where((record) => !record.isVoided).toList();
              final sections = buildRecordTimelineSections(records);

              final double monthlyExpense = validRecords
                  .where((r) => r.isExpense)
                  .fold(0.0, (s, r) => s + r.amount);
              final double monthlyIncome = validRecords
                  .where((r) => !r.isExpense)
                  .fold(0.0, (s, r) => s + r.amount);

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
                    ...sections.map(
                      (section) => _buildDailyRecordList(section, provider),
                    ),
                ],
              );
            }),
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
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '￥${monthlyExpense.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月收入',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(monthlyIncome.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月结余',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12)),
                      const SizedBox(height: 2),
                      Text((monthlyIncome - monthlyExpense).toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildDailyRecordList(
    RecordTimelineSection section,
    DataProvider provider,
  ) {
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
                section.label(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF6B7280)),
              ),
              Text(
                '支出 ${section.expense.toStringAsFixed(2)}  收入 ${section.income.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ),

        // 记录列表
        ...section.records.map((r) => _buildRecordItem(r, provider)),
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
        provider.toggleRecordVoided(record);
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
