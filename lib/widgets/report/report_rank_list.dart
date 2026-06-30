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
  final ValueChanged<ReportCategorySummary> onTapCategory;

  const ReportRankList({
    super.key,
    required this.categories,
    required this.viewTotal,
    required this.valueColor,
    required this.typeName,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$typeName排行',
              style: const TextStyle(
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
        const SizedBox(height: 16),
        ...categories.map((summary) {
          final percentage = (summary.amount / viewTotal) * 100;
          return _RankItem(
            summary: summary,
            percentage: percentage,
            valueColor: valueColor,
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
  final VoidCallback onTap;

  const _RankItem({
    required this.summary,
    required this.percentage,
    required this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(summary.category.colorHex);

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
                      Row(
                        children: [
                          Text(
                            summary.category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
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
                Text(
                  '占比 ${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '${summary.count} 笔',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
