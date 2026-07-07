import 'package:flutter/material.dart';

import '../../models/record.dart';
import '../../models/report_snapshot.dart';
import '../../theme/app_colors.dart';
import 'report_category_detail_sheet.dart';

class ReportGroupDetailSheet extends StatelessWidget {
  final ReportGroupSummary summary;
  final List<ReportCategorySummary> categories;
  final List<Record> records;
  final double viewTotal;
  final String periodLabel;
  final Color amountColor;

  const ReportGroupDetailSheet({
    super.key,
    required this.summary,
    required this.categories,
    required this.records,
    required this.viewTotal,
    required this.periodLabel,
    required this.amountColor,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportGroupSummary summary,
    required List<ReportCategorySummary> categories,
    required List<Record> records,
    required double viewTotal,
    required String periodLabel,
    required Color amountColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportGroupDetailSheet(
        summary: summary,
        categories: categories,
        records: records,
        viewTotal: viewTotal,
        periodLabel: periodLabel,
        amountColor: amountColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final share = viewTotal > 0 ? summary.amount / viewTotal * 100 : 0.0;
    final averageAmount =
        summary.count > 0 ? summary.amount / summary.count : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
                Expanded(
                  child: Text(
                    '${summary.displayName}统计',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: amountColor.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '￥${summary.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildCompareText(summary),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: '本期占比',
                        value: '${share.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: '记录笔数',
                        value: '${summary.count} 笔',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: '分类数量',
                        value: '${categories.length} 项',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: '单笔均额',
                        value: '￥${averageAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '分类统计',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '点击分类可继续查看该分类下的详细记录',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  const Text(
                    '当前大类下暂无可展示分类。',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  ...categories.map(
                    (categorySummary) => _CategorySummaryTile(
                      summary: categorySummary,
                      groupTotal: summary.amount,
                      amountColor: amountColor,
                      onTap: () =>
                          _openCategoryDetail(context, categorySummary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCategoryDetail(
    BuildContext context,
    ReportCategorySummary categorySummary,
  ) {
    final categoryRecords = records
        .where((record) => record.category.id == categorySummary.category.id)
        .toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    if (categoryRecords.isEmpty) {
      return;
    }

    ReportCategoryDetailSheet.show(
      context,
      summary: categorySummary,
      records: categoryRecords,
      viewTotal: viewTotal,
      periodLabel: periodLabel,
      amountColor: amountColor,
    );
  }

  String _buildCompareText(ReportGroupSummary summary) {
    if (summary.previousAmount <= 0 && summary.amount > 0) {
      return '较上期新增，是本期重点大类之一';
    }
    if (summary.deltaAmount == 0) {
      return '较上期持平，大类金额没有变化';
    }
    if (summary.deltaRate != null) {
      final direction = summary.deltaAmount > 0 ? '增加' : '减少';
      return '较上期$direction ${summary.deltaAmount.abs().toStringAsFixed(2)}，幅度 ${(summary.deltaRate!.abs() * 100).toStringAsFixed(1)}%';
    }
    return '较上期变化 ${summary.deltaAmount.toStringAsFixed(2)}';
  }
}

class _CategorySummaryTile extends StatelessWidget {
  final ReportCategorySummary summary;
  final double groupTotal;
  final Color amountColor;
  final VoidCallback onTap;

  const _CategorySummaryTile({
    required this.summary,
    required this.groupTotal,
    required this.amountColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final share = groupTotal > 0 ? summary.amount / groupTotal * 100 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          summary.category.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFFD1D5DB),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '￥${summary.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '占组内 ${share.toStringAsFixed(1)}%  ·  ${summary.count} 笔',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  _buildDeltaText(summary),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _buildDeltaColor(summary, amountColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildDeltaText(ReportCategorySummary summary) {
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
    return '较上期 $change${summary.deltaAmount.abs().toStringAsFixed(2)}';
  }

  Color _buildDeltaColor(ReportCategorySummary summary, Color amountColor) {
    if (summary.deltaAmount == 0) {
      return AppColors.textMuted;
    }
    if (summary.deltaAmount > 0) {
      return amountColor;
    }
    return AppColors.success;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
