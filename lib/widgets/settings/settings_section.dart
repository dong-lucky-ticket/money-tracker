import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../common/app_card.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Column(children: children),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? trailingText;
  final bool showArrow;
  final Widget? customTrailing;
  final bool isLast;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailingText,
    this.showArrow = false,
    this.customTrailing,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.surfaceMuted),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColors.textSecondary,
                ),
              ),
            ),
            if (customTrailing != null)
              customTrailing!
            else if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD1D5DB),
                ),
              )
            else if (showArrow)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFD1D5DB),
              ),
          ],
        ),
      ),
    );
  }
}
