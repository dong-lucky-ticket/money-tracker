import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';
import '../common/segmented_selector.dart';

class ReportHeader extends StatelessWidget {
  final bool isExpenseView;
  final int filterIndex;
  final VoidCallback onPickDate;
  final ValueChanged<bool> onTypeChanged;
  final ValueChanged<int> onFilterChanged;

  const ReportHeader({
    super.key,
    required this.isExpenseView,
    required this.filterIndex,
    required this.onPickDate,
    required this.onTypeChanged,
    required this.onFilterChanged,
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
                  const Text(
                    '收支报表',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: onPickDate,
                    child: Icon(
                      MdiIcons.calendarMonthOutline,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
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
                    child: SegmentedSelector<bool>(
                      value: isExpenseView,
                      onChanged: onTypeChanged,
                      options: const [
                        SegmentedOption(value: true, label: '支出'),
                        SegmentedOption(value: false, label: '收入'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SegmentedSelector<int>(
                      value: filterIndex,
                      onChanged: onFilterChanged,
                      options: const [
                        SegmentedOption(value: 0, label: '周'),
                        SegmentedOption(value: 1, label: '月'),
                        SegmentedOption(value: 2, label: '年'),
                      ],
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
