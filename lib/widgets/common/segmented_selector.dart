import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SegmentedOption<T> {
  final T value;
  final String label;

  const SegmentedOption({
    required this.value,
    required this.label,
  });
}

class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemPadding;
  final Color backgroundColor;
  final Color activeBackgroundColor;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final BorderRadiusGeometry borderRadius;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.all(4),
    this.itemPadding = const EdgeInsets.symmetric(vertical: 8),
    this.backgroundColor = AppColors.surfaceSoft,
    this.activeBackgroundColor = AppColors.surface,
    this.activeTextColor = AppColors.textPrimary,
    this.inactiveTextColor = AppColors.textTertiary,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: Row(
        children: options.map((option) {
          final isActive = option.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.value),
              child: Container(
                padding: itemPadding,
                decoration: BoxDecoration(
                  color: isActive ? activeBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
