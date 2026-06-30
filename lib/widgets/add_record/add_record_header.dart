import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/segmented_selector.dart';

class AddRecordHeader extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const AddRecordHeader({
    super.key,
    required this.isExpense,
    required this.onTypeChanged,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text(
              '取消',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 164,
            child: SegmentedSelector<bool>(
              value: isExpense,
              onChanged: onTypeChanged,
              borderRadius: BorderRadius.circular(24),
              itemPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              options: const [
                SegmentedOption(value: true, label: '支出'),
                SegmentedOption(value: false, label: '收入'),
              ],
            ),
          ),
          TextButton(
            onPressed: onDone,
            child: const Text(
              '完成',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
