import 'package:flutter/material.dart';

import '../../models/report_snapshot.dart';
import '../../theme/app_colors.dart';

class ReportGroupSummarySection extends StatelessWidget {
  final List<ReportGroupSummary> groups;
  final double viewTotal;
  final Color valueColor;

  const ReportGroupSummarySection({
    super.key,
    required this.groups,
    required this.viewTotal,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '大类汇总',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '先看整体结构，再往下看具体分类排行',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        ...groups.map((summary) {
          final percentage =
              viewTotal > 0 ? summary.amount / viewTotal * 100 : 0.0;
          return _GroupSummaryCard(
            summary: summary,
            percentage: percentage,
            valueColor: valueColor,
          );
        }),
      ],
    );
  }
}

class _GroupSummaryCard extends StatelessWidget {
  final ReportGroupSummary summary;
  final double percentage;
  final Color valueColor;

  const _GroupSummaryCard({
    required this.summary,
    required this.percentage,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final deltaText = _buildDeltaText(summary);
    final deltaColor = _buildDeltaColor(summary, valueColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                summary.amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '占比 ${percentage.toStringAsFixed(1)}%  ·  ${summary.count} 笔',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: deltaColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deltaText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildDeltaText(ReportGroupSummary summary) {
    if (summary.previousAmount <= 0 && summary.amount > 0) {
      return '较上期新增';
    }
    if (summary.deltaAmount == 0) {
      return '较上期持平';
    }
    if (summary.deltaRate != null) {
      final change = summary.deltaAmount > 0 ? '增加' : '减少';
      return '较上期$change ${(summary.deltaRate!.abs() * 100).toStringAsFixed(1)}%';
    }
    final change = summary.deltaAmount > 0 ? '+' : '-';
    return '较上期$change${summary.deltaAmount.abs().toStringAsFixed(2)}';
  }

  Color _buildDeltaColor(ReportGroupSummary summary, Color valueColor) {
    if (summary.deltaAmount == 0) {
      return AppColors.textMuted;
    }
    if (summary.deltaAmount > 0) {
      return valueColor;
    }
    return AppColors.success;
  }
}
