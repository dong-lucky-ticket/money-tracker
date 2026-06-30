import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/report_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../common/app_card.dart';

class ReportPieChartCard extends StatelessWidget {
  final String typeName;
  final double viewTotal;
  final List<ReportCategorySummary> categories;
  final ValueChanged<ReportCategorySummary> onCategoryTap;

  const ReportPieChartCard({
    super.key,
    required this.typeName,
    required this.viewTotal,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$typeName占比',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: categories.map((summary) {
                  final percentage = (summary.amount / viewTotal) * 100;
                  return PieChartSectionData(
                    color: colorFromHex(summary.category.colorHex),
                    value: summary.amount,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      return;
                    }
                    final index = response.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < categories.length) {
                      onCategoryTap(categories[index]);
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
              children: categories.map((summary) {
                final color = colorFromHex(summary.category.colorHex);
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
                      summary.category.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportBarChartCard extends StatelessWidget {
  final String typeName;
  final List<ReportCategorySummary> categories;
  final ValueChanged<ReportCategorySummary> onCategoryTap;

  const ReportBarChartCard({
    super.key,
    required this.typeName,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$typeName分类统计',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
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
                      final summary = categories[groupIndex];
                      return BarTooltipItem(
                        '${summary.category.name}\n${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      return;
                    }
                    final index = response.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < categories.length) {
                      onCategoryTap(categories[index]);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < categories.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              categories[value.toInt()].category.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: categories.asMap().entries.map((entry) {
                  final color = colorFromHex(entry.value.category.colorHex);
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
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
    );
  }
}
