import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.padding = const EdgeInsets.symmetric(vertical: 60),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
