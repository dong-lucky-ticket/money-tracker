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
    final primarySummary = _buildPrimarySummary(snapshot);
    final secondaryStats = _buildSecondaryStats(snapshot);
    final topCategory =
        snapshot.categories.isEmpty ? null : snapshot.categories.first;

    return Column(
      children: [
        _PrimarySummaryCard(
          title: primarySummary.title,
          amount: primarySummary.amount,
          color: primarySummary.color,
          deltaText: primarySummary.deltaText,
          compareLabel: snapshot.compareLabel,
          periodLabel: snapshot.periodLabel,
          recordCount: snapshot.viewRecordCount,
        ),
        const SizedBox(height: 16),
        if (secondaryStats.isNotEmpty) ...[
          Row(
            children: [
              for (var index = 0; index < secondaryStats.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryStatCard(
                    title: secondaryStats[index].title,
                    value: secondaryStats[index].value,
                    icon: secondaryStats[index].icon,
                    color: secondaryStats[index].color,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
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
                  value: _formatCurrency(snapshot.averageAmount),
                  subtitle: '共 ${snapshot.viewRecordCount} 笔记录',
                  icon: MdiIcons.calendarToday,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InsightMetricCard(
                  title: '最大单笔',
                  value: _formatCurrency(snapshot.maxRecord?.amount ?? 0),
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
                      : _formatCurrency(topCategory.amount),
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
                                fontSize: 14,
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

class _PrimarySummary {
  final String title;
  final double amount;
  final Color color;
  final String deltaText;

  const _PrimarySummary({
    required this.title,
    required this.amount,
    required this.color,
    required this.deltaText,
  });
}

class _SecondaryStat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SecondaryStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

_PrimarySummary _buildPrimarySummary(ReportSnapshot snapshot) {
  if (snapshot.isExpenseView) {
    return _PrimarySummary(
      title: '本期总支出',
      amount: snapshot.viewTotal,
      color: snapshot.valueColor,
      deltaText: _buildDeltaText(
        compareLabel: snapshot.compareLabel,
        currentAmount: snapshot.viewTotal,
        previousAmount: snapshot.previousViewTotal,
        deltaAmount: snapshot.viewDeltaAmount,
        deltaRate: snapshot.viewDeltaRate,
        increaseVerb: '增加',
        decreaseVerb: '减少',
        emptyText: '暂无${snapshot.compareLabel}支出数据可对比',
      ),
    );
  }

  if (snapshot.isIncomeView) {
    return _PrimarySummary(
      title: '本期总收入',
      amount: snapshot.viewTotal,
      color: snapshot.valueColor,
      deltaText: _buildDeltaText(
        compareLabel: snapshot.compareLabel,
        currentAmount: snapshot.viewTotal,
        previousAmount: snapshot.previousViewTotal,
        deltaAmount: snapshot.viewDeltaAmount,
        deltaRate: snapshot.viewDeltaRate,
        increaseVerb: '增加',
        decreaseVerb: '减少',
        emptyText: '暂无${snapshot.compareLabel}收入数据可对比',
      ),
    );
  }

  final balance = snapshot.balance;
  final previousBalance = snapshot.previousBalance;
  final balanceDelta = balance - previousBalance;
  final balanceRate =
      previousBalance != 0 ? balanceDelta / previousBalance.abs() : null;

  return _PrimarySummary(
    title: '本期净结余',
    amount: balance,
    color: balance >= 0 ? AppColors.success : AppColors.danger,
    deltaText: _buildDeltaText(
      compareLabel: snapshot.compareLabel,
      currentAmount: balance,
      previousAmount: previousBalance,
      deltaAmount: balanceDelta,
      deltaRate: balanceRate,
      increaseVerb: '改善',
      decreaseVerb: '回落',
      emptyText: '暂无${snapshot.compareLabel}结余数据可对比',
    ),
  );
}

List<_SecondaryStat> _buildSecondaryStats(ReportSnapshot snapshot) {
  if (snapshot.isExpenseView) {
    return const [];
  }

  if (snapshot.isIncomeView) {
    return const [];
  }

  return [
    _SecondaryStat(
      title: '本期总收入',
      value: _formatCurrency(snapshot.totalIncome),
      icon: MdiIcons.arrowUpBoldCircleOutline,
      color: AppColors.success,
    ),
    _SecondaryStat(
      title: '本期总支出',
      value: _formatCurrency(snapshot.totalExpense),
      icon: MdiIcons.arrowDownBoldCircleOutline,
      color: AppColors.danger,
    ),
  ];
}

String _buildDeltaText({
  required String compareLabel,
  required double currentAmount,
  required double previousAmount,
  required double deltaAmount,
  required double? deltaRate,
  required String increaseVerb,
  required String decreaseVerb,
  required String emptyText,
}) {
  if (currentAmount == 0 && previousAmount == 0) {
    return emptyText;
  }

  if (deltaAmount == 0) {
    return '与$compareLabel持平';
  }

  final verb = deltaAmount > 0 ? increaseVerb : decreaseVerb;
  final amountText = _formatCurrency(deltaAmount.abs());

  if (deltaRate == null) {
    return '较$compareLabel$verb $amountText';
  }

  return '较$compareLabel$verb $amountText (${(deltaRate.abs() * 100).toStringAsFixed(1)}%)';
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(2);
}

class _PrimarySummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String deltaText;
  final String compareLabel;
  final String periodLabel;
  final int recordCount;

  const _PrimarySummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.deltaText,
    required this.compareLabel,
    required this.periodLabel,
    required this.recordCount,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periodLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '对比$compareLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deltaText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                MdiIcons.receiptTextOutline,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '本期 $recordCount 笔',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
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
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
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
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
