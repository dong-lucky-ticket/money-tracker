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
    final primaryTitle = snapshot.isExpenseView ? '本期总支出' : '本期总收入';
    final secondaryTitle = snapshot.isExpenseView ? '本期总收入' : '本期总支出';
    final secondaryValue =
        snapshot.isExpenseView ? snapshot.totalIncome : snapshot.totalExpense;
    final deltaRate = snapshot.viewDeltaRate;
    final deltaText = deltaRate == null
        ? '暂无${snapshot.compareLabel}可对比数据'
        : '较${snapshot.compareLabel}${snapshot.viewDeltaAmount >= 0 ? '增加' : '减少'} ${(deltaRate.abs() * 100).toStringAsFixed(1)}%';
    final topCategory = snapshot.categories.isEmpty ? null : snapshot.categories.first;

    return Column(
      children: [
        _PrimarySummaryCard(
          title: primaryTitle,
          amount: snapshot.viewTotal,
          color: snapshot.valueColor,
          deltaText: deltaText,
          compareLabel: snapshot.compareLabel,
          periodLabel: snapshot.periodLabel,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SecondaryStatCard(
                title: secondaryTitle,
                value: secondaryValue.toStringAsFixed(2),
                icon: snapshot.isExpenseView
                    ? MdiIcons.arrowDownBoldCircleOutline
                    : MdiIcons.arrowUpBoldCircleOutline,
                color: snapshot.isExpenseView
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryStatCard(
                title: '本期结余',
                value: snapshot.balance.toStringAsFixed(2),
                icon: MdiIcons.scaleBalance,
                color: snapshot.balance >= 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryStatCard(
                title: '本期笔数',
                value: snapshot.viewRecordCount.toString(),
                icon: MdiIcons.receiptTextOutline,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (snapshot.viewRecords.isEmpty)
          EmptyState(
            icon: Icon(
              MdiIcons.chartPie,
              size: 64,
              color: AppColors.border,
            ),
            title: '当前周期暂无${snapshot.typeName}记录',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _InsightMetricCard(
                  title: snapshot.averageTitle,
                  value: snapshot.averageAmount.toStringAsFixed(2),
                  subtitle: '${snapshot.viewRecordCount} 笔记录',
                  icon: MdiIcons.calendarToday,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightMetricCard(
                  title: '最大单笔',
                  value: snapshot.maxRecord?.amount.toStringAsFixed(2) ?? '0.00',
                  subtitle: snapshot.maxRecord?.category.name ?? '--',
                  icon: MdiIcons.arrowUpBoldCircleOutline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightMetricCard(
                  title: '最高分类',
                  value: topCategory?.category.name ?? '--',
                  subtitle: topCategory == null
                      ? '--'
                      : '￥${topCategory.amount.toStringAsFixed(2)}',
                  icon: MdiIcons.chartDonutVariant,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          if (snapshot.insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '本期洞察',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...snapshot.insights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 7),
                            decoration: BoxDecoration(
                              color: snapshot.valueColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              insight,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textSecondary,
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
          ],
        ],
      ],
    );
  }
}

class _PrimarySummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String deltaText;
  final String compareLabel;
  final String periodLabel;

  const _PrimarySummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.deltaText,
    required this.compareLabel,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withOpacity(0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periodLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '对比$compareLabel',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '￥${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deltaText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SecondaryStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _InsightMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
