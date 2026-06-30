import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';

class RecordDetailPanel extends StatelessWidget {
  final String amountText;
  final DateTime selectedDate;
  final TextEditingController remarkController;
  final FocusNode remarkFocusNode;
  final bool isKeyboardVisible;
  final ValueChanged<DateTime> onDateChanged;

  const RecordDetailPanel({
    super.key,
    required this.amountText,
    required this.selectedDate,
    required this.remarkController,
    required this.remarkFocusNode,
    required this.isKeyboardVisible,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '金额 (CNY)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          amountText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Visibility(
                          visible: !isKeyboardVisible,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Container(
                            width: 4,
                            height: 32,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (date != null) {
                        onDateChanged(date);
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          MdiIcons.calendarBlank,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        MdiIcons.pencilOutline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: remarkController,
                          focusNode: remarkFocusNode,
                          decoration: const InputDecoration(
                            hintText: '点击添加备注...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => remarkFocusNode.unfocus(),
                        ),
                      ),
                    ],
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
