import 'package:flutter/material.dart';

import '../../screens/lottery_screen.dart';
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
              title: '体彩',
              showArrow: true,
              onTap: () => _openLottery(context, '体彩'),
            ),
            SettingsItem(
              icon: Icons.confirmation_number_outlined,
              iconColor: Colors.redAccent,
              title: '福彩',
              showArrow: true,
              isLast: true,
              onTap: () => _openLottery(context, '福彩'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openLottery(BuildContext context, String lotteryType) async {
    final page = LotteryScreen(lotteryType: lotteryType);
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
