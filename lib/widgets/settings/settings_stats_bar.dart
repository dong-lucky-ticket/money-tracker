import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SettingsStatsBar extends StatelessWidget {
  final String totalRecords;
  final String monthlyRecords;
  final String activeCategories;

  const SettingsStatsBar({
    super.key,
    required this.totalRecords,
    required this.monthlyRecords,
    required this.activeCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          _SettingsStatItem(value: totalRecords, label: '总记账'),
          const _SettingsStatDivider(),
          _SettingsStatItem(value: monthlyRecords, label: '本月笔数'),
          const _SettingsStatDivider(),
          _SettingsStatItem(value: activeCategories, label: '活跃分类'),
        ],
      ),
    );
  }
}

class _SettingsStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _SettingsStatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsStatDivider extends StatelessWidget {
  const _SettingsStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.border,
    );
  }
}
