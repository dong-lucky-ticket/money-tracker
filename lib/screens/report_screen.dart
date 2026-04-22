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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 顶部导航
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text('收支报表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                Icon(MdiIcons.calendarMonthOutline, size: 24, color: const Color(0xFF4B5563)),
              ],
            ),
          ),
          
          // 筛选器
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
          
          // 主内容
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, provider, child) {
                // Filter records
                final now = DateTime.now();
                List<Record> filteredRecords = provider.records.where((r) {
                  if (_filterIndex == 1) { // Month
                    return r.date.year == now.year && r.date.month == now.month;
                  } else if (_filterIndex == 2) { // Year
                    return r.date.year == now.year;
                  } else { // Week (simplified to last 7 days)
                    return now.difference(r.date).inDays <= 7;
                  }
                }).toList();

                final expenseRecords = filteredRecords.where((r) => r.isExpense).toList();
                final incomeRecords = filteredRecords.where((r) => !r.isExpense).toList();
                
                final totalExp = expenseRecords.fold(0.0, (s, r) => s + r.amount);
                final totalInc = incomeRecords.fold(0.0, (s, r) => s + r.amount);

                // Group expenses by category
                final Map<String, double> catExpense = {};
                final Map<String, int> catCount = {};
                final Map<String, String> catColor = {};
                final Map<String, String> catIcon = {};

                for (var r in expenseRecords) {
                  final catId = r.category.id;
                  catExpense[catId] = (catExpense[catId] ?? 0) + r.amount;
                  catCount[catId] = (catCount[catId] ?? 0) + 1;
                  catColor[catId] = r.category.colorHex;
                  catIcon[catId] = r.category.iconName;
                }

                final sortedCats = catExpense.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 数据统计卡片
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('总支出', totalExp, const Color(0xFFFF5A5A))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('总收入', totalInc, const Color(0xFF28CA7F))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 图表区域
                    if (totalExp > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('支出占比', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  sections: sortedCats.map((e) {
                                    final percentage = (e.value / totalExp) * 100;
                                    return PieChartSectionData(
                                      color: _hexToColor(catColor[e.key]!),
                                      value: e.value,
                                      title: '${percentage.toStringAsFixed(1)}%',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    );
                                  }).toList(),
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
                                  final cat = expenseRecords.firstWhere((r) => r.category.id == e.key).category;
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
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
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
                    if (totalExp > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('支出分类统计', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value.toInt() >= 0 && value.toInt() < sortedCats.length) {
                                            final catId = sortedCats[value.toInt()].key;
                                            final cat = expenseRecords.firstWhere((r) => r.category.id == catId).category;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                cat.name,
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: sortedCats.asMap().entries.map((entry) {
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
                    if (totalExp > 0)
                      Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('支出排行', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                              Text('按金额排序', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...sortedCats.map((e) {
                            final cat = expenseRecords.firstWhere((r) => r.category.id == e.key).category;
                            final percentage = (e.value / totalExp) * 100;
                            return _buildRankItem(cat, e.value, percentage, catCount[e.key]!);
                          }),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
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
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF4A90E2) : const Color(0xFF9CA3AF),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(Category cat, double amount, double percentage, int count) {
    final color = _hexToColor(cat.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
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
                child: Icon(IconMapper.getIcon(cat.iconName), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    Text(amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('占比 ${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              Text('$count 笔', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String code) {
    if (code.startsWith('#')) code = code.substring(1);
    if (code.length == 6) code = 'FF$code';
    return Color(int.parse(code, radix: 16));
  }
}
