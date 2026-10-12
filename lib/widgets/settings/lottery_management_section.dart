import 'package:flutter/material.dart';

import '../../screens/double_color_ball_screen.dart';
import '../../screens/lottery_screen.dart';
import '../../screens/seven_star_screen.dart';
import '../../theme/app_colors.dart';
import 'settings_section.dart';

class LotteryManagementSection extends StatelessWidget {
  final Future<void> Function(Widget page)? onOpenPage;

  const LotteryManagementSection({super.key, this.onOpenPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '彩票管理'),
        SettingsSectionCard(
          children: [
            SettingsItem(
              icon: Icons.confirmation_number_outlined,
              iconColor: AppColors.primary,
              title: '体彩大乐透',
              showArrow: true,
              onTap: () => _openPage(context, const LotteryScreen()),
            ),
            SettingsItem(
              icon: Icons.confirmation_number_outlined,
              iconColor: Colors.deepOrange,
              title: '体彩七星彩',
              showArrow: true,
              onTap: () => _openPage(context, const SevenStarScreen()),
            ),
            SettingsItem(
              icon: Icons.confirmation_number_outlined,
              iconColor: Colors.redAccent,
              title: '福彩双色球',
              showArrow: true,
              isLast: true,
              onTap: () => _openPage(context, const DoubleColorBallScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    if (onOpenPage != null) {
      await onOpenPage!(page);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }
}
