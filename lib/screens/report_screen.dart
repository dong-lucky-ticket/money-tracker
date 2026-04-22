import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/record.dart';
import '../models/category.dart';
import '../utils/icon_mapper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _filterIndex = 0; // 0:周, 1:月, 2:年
  DateTime _selectedDate = DateTime.now();
  bool _isExpenseView = true; // true: 支出, false: 收入

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 顶部导航
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text('收支报表',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827))),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Icon(MdiIcons.calendarMonthOutline,
                            size: 24, color: const Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),

                // 筛选器
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildTypeBtn('支出', true),
                              _buildTypeBtn('收入', false),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildFilterBtn('周', 0),
                              _buildFilterBtn('月', 1),
                              _buildFilterBtn('年', 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 主内容
        Expanded(
          child: Consumer<DataProvider>(
            builder: (context, provider, child) {
              // Filter records
              final targetDate = _selectedDate;
              List<Record> filteredRecords = provider.records.where((r) {
                if (_filterIndex == 1) {
                  // Month
                  return r.date.year == targetDate.year &&
                      r.date.month == targetDate.month;
                } else if (_filterIndex == 2) {
                  // Year
                  return r.date.year == targetDate.year;
                } else {
                  // Week (simplified to 7 days before targetDate)
                  final diff = targetDate.difference(r.date).inDays;
                  return diff >= 0 && diff <= 7;
                }
              }).toList();

              final expenseRecords =
                  filteredRecords.where((r) => r.isExpense).toList();
              final incomeRecords =
                  filteredRecords.where((r) => !r.isExpense).toList();

              final totalExp = expenseRecords.fold(0.0, (s, r) => s + r.amount);
              final totalInc = incomeRecords.fold(0.0, (s, r) => s + r.amount);

              // 确定当前视图要展示的数据
              final viewRecords = _isExpenseView ? expenseRecords : incomeRecords;
              final viewTotal = _isExpenseView ? totalExp : totalInc;
              final viewColor = _isExpenseView ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F);
              final typeName = _isExpenseView ? '支出' : '收入';

              // Group view records by category
                final Map<String, double> catAmount = {};
                final Map<String, int> catCount = {};
                final Map<String, String> catColor = {};
                final Map<String, String> catIcon = {};

                for (var r in viewRecords) {
                  final catId = r.category.id;
                  catAmount[catId] = (catAmount[catId] ?? 0) + r.amount;
                  catCount[catId] = (catCount[catId] ?? 0) + 1;
                  catColor[catId] = r.category.colorHex;
                  catIcon[catId] = r.category.iconName;
                }

                final sortedCats = catAmount.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // 数据洞察指标计算
                double avgAmount = 0.0;
                Record? maxRecord;
                
                // 折线图数据
                final Map<int, double> trendData = {};
                int maxX = 0;
                
                if (viewRecords.isNotEmpty) {
                  int days = 1;
                  if (_filterIndex == 0) days = 7;
                  if (_filterIndex == 1) days = DateTime(targetDate.year, targetDate.month + 1, 0).day;
                  if (_filterIndex == 2) days = 12; // 年视图按月统计
                  
                  if (_filterIndex == 2) {
                     avgAmount = viewTotal / 12; // 年均按月算
                  } else {
                     avgAmount = viewTotal / days;
                  }

                  maxRecord = viewRecords.reduce((a, b) => a.amount > b.amount ? a : b);
                  
                  // 初始化趋势数据
                  for (int i = 1; i <= days; i++) {
                    trendData[i] = 0.0;
                  }
                  
                  // 填充趋势数据
                  for (var r in viewRecords) {
                    int key;
                    if (_filterIndex == 0) { // 周视图: 周一到周日 (1-7)
                      key = r.date.weekday;
                    } else if (_filterIndex == 1) { // 月视图: 1号到月底
                      key = r.date.day;
                    } else { // 年视图: 1月到12月
                      key = r.date.month;
                    }
                    trendData[key] = (trendData[key] ?? 0) + r.amount;
                  }
                  maxX = days;
                }

                return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 数据统计卡片
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              '总支出', totalExp, const Color(0xFFFF5A5A))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildStatCard(
                              '总收入', totalInc, const Color(0xFF28CA7F))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (viewRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(MdiIcons.chartPie, size: 64, color: const Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),
                          Text('当前周期暂无$typeName记录', style: const TextStyle(color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    )
                  else ...[
                    // 数据洞察小卡片
                    Row(
                      children: [
                        Expanded(
                          child: _buildInsightCard(
                            '日均$typeName',
                            avgAmount.toStringAsFixed(2),
                            MdiIcons.calendarToday,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInsightCard(
                            '最大单笔',
                            maxRecord != null ? maxRecord.amount.toStringAsFixed(2) : '0.00',
                            MdiIcons.arrowUpBoldCircleOutline,
                            Colors.orange,
                            subtitle: maxRecord?.category.name,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 趋势折线图
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$typeName趋势',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (touchedSpot) => Colors.black87,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '${spot.y.toStringAsFixed(2)}\n',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: _filterIndex == 0
                                                  ? '周${spot.x.toInt()}'
                                                  : _filterIndex == 1
                                                      ? '${spot.x.toInt()}日'
                                                      : '${spot.x.toInt()}月',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: maxRecord != null && maxRecord.amount > 0 ? maxRecord.amount / 4 : 100,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.black.withOpacity(0.05),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: _filterIndex == 1 ? 7 : 1,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() == 0 || value.toInt() > maxX) return const SizedBox();
                                        String text = '';
                                        if (_filterIndex == 0) {
                                          const days = ['一', '二', '三', '四', '五', '六', '日'];
                                          if (value.toInt() >= 1 && value.toInt() <= 7) {
                                            text = days[value.toInt() - 1];
                                          }
                                        } else {
                                          text = value.toInt().toString();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF6B7280)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        if (value == 0) return const SizedBox();
                                        return Text(
                                          value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 1,
                                maxX: maxX.toDouble(),
                                minY: 0,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: trendData.entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                                        .toList(),
                                    isCurved: true,
                                    color: viewColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: _filterIndex == 0,
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: viewColor,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: viewColor.withOpacity(0.1),
                                      gradient: LinearGradient(
                                        colors: [
                                          viewColor.withOpacity(0.3),
                                          viewColor.withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 图表区域
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$typeName占比',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: sortedCats.map((e) {
                                  final percentage = (e.value / viewTotal) * 100;
                                  return PieChartSectionData(
                                    color: _hexToColor(catColor[e.key]!),
                                    value: e.value,
                                    title: '${percentage.toStringAsFixed(1)}%',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  );
                                }).toList(),
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                      return;
                                    }
                                    final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    if (index >= 0 && index < sortedCats.length) {
                                      final catId = sortedCats[index].key;
                                      final cat = viewRecords.firstWhere((r) => r.category.id == catId).category;
                                      _showCategoryDetails(cat, viewRecords);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: sortedCats.map((e) {
                                final cat = viewRecords
                                    .firstWhere((r) => r.category.id == e.key)
                                    .category;
                                final color = _hexToColor(catColor[e.key]!);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B5563)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 柱状图区域
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$typeName分类统计',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => Colors.black87,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final catId = sortedCats[groupIndex].key;
                                      final cat = viewRecords.firstWhere((r) => r.category.id == catId).category;
                                      return BarTooltipItem(
                                        '${cat.name}\n${rod.toY.toStringAsFixed(2)}',
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                                    if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                      return;
                                    }
                                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                                    if (index >= 0 && index < sortedCats.length) {
                                      final catId = sortedCats[index].key;
                                      final cat = viewRecords.firstWhere((r) => r.category.id == catId).category;
                                      _showCategoryDetails(cat, viewRecords);
                                    }
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < sortedCats.length) {
                                          final catId =
                                              sortedCats[value.toInt()].key;
                                          final cat = viewRecords
                                              .firstWhere(
                                                  (r) => r.category.id == catId)
                                              .category;
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              cat.name,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF6B7280)),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups:
                                    sortedCats.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final e = entry.value;
                                  final color = _hexToColor(catColor[e.key]!);
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value,
                                        color: color,
                                        width: 16,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 排行列表
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$typeName排行',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937))),
                            const Text('按金额排序',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...sortedCats.map((e) {
                          final cat = viewRecords
                              .firstWhere((r) => r.category.id == e.key)
                              .category;
                          final percentage = (e.value / viewTotal) * 100;
                          return _buildRankItem(
                              cat, e.value, percentage, catCount[e.key]!, viewColor, viewRecords);
                        }),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryDetails(Category cat, List<Record> viewRecords) {
    final records = viewRecords.where((r) => r.category.id == cat.id).toList();
    if (records.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(cat.colorHex).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(IconMapper.getIcon(cat.iconName),
                        color: _hexToColor(cat.colorHex), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${cat.name}明细',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')} ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 12),
                            ),
                            if (r.remark.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(r.remark,
                                  style: const TextStyle(
                                      color: Color(0xFF1F2937), fontSize: 14)),
                            ],
                          ],
                        ),
                        Text(
                          r.amount.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isExpenseView ? const Color(0xFFFF5A5A) : const Color(0xFF28CA7F),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBtn(String title, bool isExpense) {
    final isActive = _isExpenseView == isExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpenseView = isExpense),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 2)
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color:
                  isActive ? const Color(0xFF4A90E2) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBtn(String title, int index) {
    final isActive = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 2)
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color:
                  isActive ? const Color(0xFF4A90E2) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF9FAFB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(
      Category cat, double amount, double percentage, int count, Color valueColor, List<Record> viewRecords) {
    final color = _hexToColor(cat.colorHex);
    return GestureDetector(
      onTap: () => _showCategoryDetails(cat, viewRecords),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF9FAFB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(IconMapper.getIcon(cat.iconName),
                      color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(cat.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937))),
                          const SizedBox(width: 4),
                          Icon(MdiIcons.chevronRight, size: 16, color: const Color(0xFFD1D5DB)),
                        ],
                      ),
                      Text(amount.toStringAsFixed(2),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: valueColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('占比 ${percentage.toStringAsFixed(1)}%',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                Text('$count 笔',
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String code) {
    if (code.startsWith('#')) code = code.substring(1);
    if (code.length == 6) code = 'FF$code';
    return Color(int.parse(code, radix: 16));
  }
}
