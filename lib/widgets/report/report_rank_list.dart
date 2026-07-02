import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/report_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class ReportRankList extends StatelessWidget {
  final List<ReportCategorySummary> categories;
  final double viewTotal;
  final Color valueColor;
  final String typeName;
  final bool isExpenseView;
  final ValueChanged<ReportCategorySummary> onTapCategory;

  const ReportRankList({
    super.key,
    required this.categories,
    required this.viewTotal,
    required this.valueColor,
    required this.typeName,
    required this.isExpenseView,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$typeName排行',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Text(
              '按金额排序',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '点击分类可查看该分类的汇总与明细记录',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.map((summary) {
          final percentage = viewTotal > 0 ? (summary.amount / viewTotal) * 100 : 0.0;
          return _RankItem(
            summary: summary,
            percentage: percentage,
            valueColor: valueColor,
            isExpenseView: isExpenseView,
            onTap: () => onTapCategory(summary),
          );
        }),
      ],
    );
  }
}

class _RankItem extends StatelessWidget {
  final ReportCategorySummary summary;
  final double percentage;
  final Color valueColor;
  final bool isExpenseView;
  final VoidCallback onTap;

  const _RankItem({
    required this.summary,
    required this.percentage,
    required this.valueColor,
    required this.isExpenseView,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(summary.category.colorHex);
    final deltaText = _buildDeltaText(summary);
    final deltaColor = _buildDeltaColor(summary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceMuted),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
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
                  child: Icon(
                    IconMapper.getIcon(summary.category.iconName),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                summary.category.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              MdiIcons.chevronRight,
                              size: 16,
                              color: const Color(0xFFD1D5DB),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        summary.amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: valueColor,
                        ),
                      ),
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
                backgroundColor: AppColors.surfaceSoft,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '占比 ${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${summary.count} 笔',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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

  Color _buildDeltaColor(ReportCategorySummary summary) {
    if (summary.deltaAmount == 0) {
      return AppColors.textMuted;
    }
    if (summary.deltaAmount > 0) {
      return valueColor;
    }
    return isExpenseView ? AppColors.success : AppColors.danger;
  }
}
