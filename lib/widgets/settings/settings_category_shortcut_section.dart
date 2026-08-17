import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';
import '../../screens/categories_screen.dart';
import 'settings_section.dart';

class SettingsCategoryShortcutSection extends StatelessWidget {
  final Future<void> Function(Widget page)? onOpenPage;

  const SettingsCategoryShortcutSection({super.key, this.onOpenPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '分类管理'),
        SettingsSectionCard(
          children: [
            SettingsItem(
              icon: MdiIcons.formatListBulleted,
              iconColor: AppColors.primary,
              title: '管理收支分类',
              trailingText: '排序、删除、新增',
              showArrow: true,
              isLast: true,
              onTap: () async {
                const page = CategoriesScreen();
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
