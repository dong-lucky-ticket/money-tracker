import 'package:flutter/material.dart';

import '../../models/report_snapshot.dart';
import '../../models/record.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class ReportCategoryDetailSheet extends StatelessWidget {
  final ReportCategorySummary summary;
  final List<Record> records;
  final Color amountColor;

  const ReportCategoryDetailSheet({
    super.key,
    required this.summary,
    required this.records,
    required this.amountColor,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportCategorySummary summary,
    required List<Record> records,
    required Color amountColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportCategoryDetailSheet(
        summary: summary,
        records: records,
        amountColor: amountColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(summary.category.colorHex);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
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
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateText,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          if (record.remark.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              record.remark,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        record.amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
