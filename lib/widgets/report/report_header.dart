import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/report_filter.dart';
import '../../models/report_time_range.dart';
import '../../theme/app_colors.dart';
import '../common/segmented_selector.dart';

class ReportHeader extends StatelessWidget {
  final ReportRecordType recordType;
  final ReportTimeRange selectedRange;
  final bool hasAdvancedFilters;
  final VoidCallback onPickRange;
  final VoidCallback onOpenFilters;
  final ValueChanged<ReportRecordType> onTypeChanged;

  const ReportHeader({
    super.key,
    required this.recordType,
    required this.selectedRange,
    required this.hasAdvancedFilters,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: SegmentedSelector<ReportRecordType>(
                    value: recordType,
                    onChanged: onTypeChanged,
                    padding: const EdgeInsets.all(3),
                    itemPadding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFFF1F5F9),
                    activeBackgroundColor: Colors.white,
                    activeTextColor: const Color(0xFF0F172A),
                    inactiveTextColor: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(20),
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
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPickRange,
                      icon: Icon(
                        selectedRange.isCustom
                            ? MdiIcons.calendarRangeOutline
                            : MdiIcons.calendarMonthOutline,
                        size: 18,
                      ),
                      label: Text(selectedRange.selectionLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenFilters,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            MdiIcons.tuneVariant,
                            size: 18,
                            color: hasAdvancedFilters
                                ? const Color(0xFF2563EB)
                                : AppColors.textSecondary,
                          ),
                          if (hasAdvancedFilters)
                            const Positioned(
                              right: -3,
                              top: -3,
                              child: SizedBox(
                                width: 7,
                                height: 7,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('高级筛选'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
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
