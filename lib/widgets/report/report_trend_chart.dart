import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/app_card.dart';

class ReportTrendChart extends StatelessWidget {
  final String typeName;
  final Map<int, double> trendData;
  final int maxX;
  final int filterIndex;
  final Color color;

  const ReportTrendChart({
    super.key,
    required this.typeName,
    required this.trendData,
    required this.maxX,
    required this.filterIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = trendData.values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });
    final interval = maxValue > 0 ? maxValue / 4 : 100.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$typeName趋势',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
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
                              text: filterIndex == 0
                                  ? '周${spot.x.toInt()}'
                                  : filterIndex == 1
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
                  horizontalInterval: interval,
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
                      interval: filterIndex == 1 ? 7 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == 0 || value.toInt() > maxX) {
                          return const SizedBox();
                        }
                        var text = '';
                        if (filterIndex == 0) {
                          const days = ['一', '二', '三', '四', '五', '六', '日'];
                          if (value.toInt() >= 1 && value.toInt() <= 7) {
                            text = days[value.toInt() - 1];
                          }
                        } else {
                          text = value.toInt().toString();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
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
                        if (value == 0) {
                          return const SizedBox();
                        }
                        return Text(
                          value >= 1000
                              ? '${(value / 1000).toStringAsFixed(1)}k'
                              : value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: maxX.toDouble(),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                        .toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: filterIndex == 0,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
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
    );
  }
}
