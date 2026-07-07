import 'package:flutter/material.dart';

import '../../models/report_snapshot.dart';
import '../../models/record.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class ReportCategoryDetailSheet extends StatelessWidget {
  final ReportCategorySummary summary;
  final List<Record> records;
  final double viewTotal;
  final String periodLabel;
  final Color amountColor;

  const ReportCategoryDetailSheet({
    super.key,
    required this.summary,
    required this.records,
    required this.viewTotal,
    required this.periodLabel,
    required this.amountColor,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportCategorySummary summary,
    required List<Record> records,
    required double viewTotal,
    required String periodLabel,
    required Color amountColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportCategoryDetailSheet(
        summary: summary,
        records: records,
        viewTotal: viewTotal,
        periodLabel: periodLabel,
        amountColor: amountColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(summary.category.colorHex);
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconMapper.getIcon(summary.category.iconName),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${summary.category.name}明细',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.12)),
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
                        title: '单笔均额',
                        value: '￥${averageAmount.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: '上期金额',
                        value: '￥${summary.previousAmount.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '相关记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                ...records.map((record) {
                  final date = record.date;
                  final dateText =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateText,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record.remark.isEmpty ? '无备注' : record.remark,
                                style: TextStyle(
                                  color: record.remark.isEmpty
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1F2937),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          record.amount.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildCompareText(ReportCategorySummary summary) {
    if (summary.previousAmount <= 0 && summary.amount > 0) {
      return '较上期新增，是本期新出现的重点分类';
    }
    if (summary.deltaAmount == 0) {
      return '较上期持平，分类金额没有变化';
    }
    if (summary.deltaRate != null) {
      final direction = summary.deltaAmount > 0 ? '增加' : '减少';
      return '较上期$direction ${summary.deltaAmount.abs().toStringAsFixed(2)}，幅度 ${(summary.deltaRate!.abs() * 100).toStringAsFixed(1)}%';
    }
    return '较上期变化 ${summary.deltaAmount.toStringAsFixed(2)}';
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
