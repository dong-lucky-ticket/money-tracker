import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/report_filter.dart';
import '../../models/report_time_range.dart';
import '../../theme/app_colors.dart';
import '../common/segmented_selector.dart';

class ReportHeader extends StatelessWidget {
  final ReportRecordType recordType;
  final ReportTimeRange selectedRange;
  final String periodLabel;
  final bool hasAdvancedFilters;
  final VoidCallback onPickDate;
  final VoidCallback onPickRange;
  final VoidCallback onOpenFilters;
  final ValueChanged<ReportRecordType> onTypeChanged;

  const ReportHeader({
    super.key,
    required this.recordType,
    required this.selectedRange,
    required this.periodLabel,
    required this.hasAdvancedFilters,
    required this.onPickDate,
    required this.onPickRange,
    required this.onOpenFilters,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      const Text(
                        '收支报表',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        periodLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onOpenFilters,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              MdiIcons.tuneVariant,
                              size: 22,
                              color: hasAdvancedFilters
                                  ? const Color(0xFF4A90E2)
                                  : AppColors.textSecondary,
                            ),
                            if (hasAdvancedFilters)
                              const Positioned(
                                right: -2,
                                top: -2,
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4A90E2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: onPickDate,
                        child: Icon(
                          selectedRange.isCustom
                              ? MdiIcons.calendarRangeOutline
                              : MdiIcons.calendarMonthOutline,
                          size: 24,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedSelector<ReportRecordType>(
                      value: recordType,
                      onChanged: onTypeChanged,
                      options: const [
                        SegmentedOption(
                          value: ReportRecordType.expense,
                          label: '支出',
                        ),
                        SegmentedOption(
                          value: ReportRecordType.income,
                          label: '收入',
                        ),
                        SegmentedOption(
                          value: ReportRecordType.all,
                          label: '全部',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPickRange,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedRange.selectionLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
