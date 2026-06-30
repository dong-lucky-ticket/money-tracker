import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/report_snapshot.dart';
import '../../theme/app_colors.dart';
import '../common/app_card.dart';
import '../common/empty_state.dart';

class ReportOverviewSection extends StatelessWidget {
  final ReportSnapshot snapshot;

  const ReportOverviewSection({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '总支出',
                amount: snapshot.totalExpense,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: '总收入',
                amount: snapshot.totalIncome,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (snapshot.viewRecords.isEmpty)
          EmptyState(
            icon: Icon(
              MdiIcons.chartPie,
              size: 64,
              color: AppColors.border,
            ),
            title: '当前周期暂无${snapshot.typeName}记录',
          )
        else
          Row(
            children: [
              Expanded(
                child: _InsightCard(
                  title: '日均${snapshot.typeName}',
                  value: snapshot.averageAmount.toStringAsFixed(2),
                  icon: MdiIcons.calendarToday,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InsightCard(
                  title: '最大单笔',
                  value: snapshot.maxRecord?.amount.toStringAsFixed(2) ?? '0.00',
                  icon: MdiIcons.arrowUpBoldCircleOutline,
                  color: Colors.orange,
                  subtitle: snapshot.maxRecord?.category.name,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.surfaceMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
