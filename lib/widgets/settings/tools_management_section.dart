
import 'package:flutter/material.dart';

import '../../screens/betting_simulator_screen.dart';
import '../../screens/gambling_stats_screen.dart';
import '../../screens/unit_converter_screen.dart';
import '../../theme/app_colors.dart';
import 'settings_section.dart';

class ToolsManagementSection extends StatelessWidget {
  final Future<void> Function(Widget page)? onOpenPage;

  const ToolsManagementSection({super.key, this.onOpenPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '实用工具'),
        SettingsSectionCard(
          children: [
            SettingsItem(
              icon: Icons.casino_outlined,
              iconColor: AppColors.warning,
              title: '模拟下注',
              trailingText: '虚拟投注',
              showArrow: true,
              onTap: () async {
                const page = BettingSimulatorScreen();
                if (onOpenPage != null) {
                  await onOpenPage!(page);
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            ),
            SettingsItem(
              icon: Icons.stacked_bar_chart,
              iconColor: AppColors.danger,
              title: '赌狗统计',
              trailingText: '体彩/福彩 · 刮刮乐/纸质彩票',
              showArrow: true,
              onTap: () async {
                const page = GamblingStatsScreen();
                if (onOpenPage != null) {
                  await onOpenPage!(page);
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            ),
            SettingsItem(
              icon: Icons.swap_horiz,
              iconColor: AppColors.primary,
              title: '单位换算',
              trailingText: '长度、面积、重量等',
              showArrow: true,
              isLast: true,
              onTap: () async {
                const page = UnitConverterScreen();
                if (onOpenPage != null) {
                  await onOpenPage!(page);
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => page),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}


