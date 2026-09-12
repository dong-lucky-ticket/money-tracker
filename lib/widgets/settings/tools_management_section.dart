import 'package:flutter/material.dart';

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
