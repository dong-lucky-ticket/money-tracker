import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/data_provider.dart';
import '../../theme/app_colors.dart';
import 'settings_section.dart';

class SettingsAppPreferencesSection extends StatelessWidget {
  const SettingsAppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '应用设置'),
        SettingsSectionCard(
          children: [
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.paletteOutline,
                  iconColor: Colors.purple,
                  title: '主题风格切换',
                  trailingText: provider.isDarkTheme ? '暗黑模式' : '简约蓝',
                  showArrow: true,
                  onTap: () => provider.toggleTheme(),
                );
              },
            ),
            SettingsItem(
              icon: MdiIcons.bellOutline,
              iconColor: Colors.orange,
              title: '记账提醒',
              customTrailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ),
            SettingsItem(
              icon: MdiIcons.shieldLockOutline,
              iconColor: Colors.indigo,
              title: '安全锁屏 (FaceID/指纹)',
              showArrow: true,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}
