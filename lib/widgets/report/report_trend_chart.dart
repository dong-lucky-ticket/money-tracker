import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/report_time_range.dart';
import '../../theme/app_colors.dart';
import '../common/app_card.dart';

class ReportTrendChart extends StatelessWidget {
  final String typeName;
  final Map<int, double> trendData;
  final Map<int, String> trendAxisLabels;
  final Map<int, String> trendTooltipLabels;
  final int maxX;
  final ReportTrendMode trendMode;
  final Color color;

  const ReportTrendChart({
    super.key,
    required this.typeName,
    required this.trendData,
    required this.trendAxisLabels,
    required this.trendTooltipLabels,
    required this.maxX,
    required this.trendMode,
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
            trendMode == ReportTrendMode.monthly
                ? '$typeName月度走势'
                : '$typeName趋势',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: trendMode == ReportTrendMode.monthly
                ? _buildBarChart(interval)
                : _buildLineChart(interval),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(double interval) {
    return LineChart(
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
                      text: trendTooltipLabels[spot.x.toInt()] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
        titlesData: _buildTitles(),
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
              show: maxX <= 14,
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
                  color.withOpacity(0.25),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(double interval) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _maxValueWithPadding(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)}\n${trendTooltipLabels[group.x] ?? ''}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
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
        titlesData: _buildTitles(),
        borderData: FlBorderData(show: false),
        barGroups: trendData.entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: color,
                    width: 14,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  FlTitlesData _buildTitles() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: _bottomTitleInterval(),
          getTitlesWidget: (value, meta) {
            if (value.toInt() == 0 || value.toInt() > maxX) {
              return const SizedBox();
            }
            final text = trendAxisLabels[value.toInt()] ?? '';
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
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
                fontSize: 12,
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
    );
  }

  double _bottomTitleInterval() {
    if (trendMode == ReportTrendMode.monthly) {
      return 1;
    }

    if (maxX > 60) {
      return 10;
    }
    if (maxX > 31) {
      return 7;
    }
    if (maxX > 14) {
      return 5;
    }
    return 1;
  }

  double _maxValueWithPadding() {
    final maxValue = trendData.values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });
    if (maxValue <= 0) {
      return 100;
    }
    return maxValue * 1.15;
  }
}
