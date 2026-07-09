import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../controllers/settings_screen_controller.dart';
import '../common/app_toast.dart';
import 'settings_section.dart';

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: [
        FutureBuilder<String>(
          future: SettingsScreenController.appVersionFuture,
          builder: (context, snapshot) {
            return SettingsItem(
              icon: MdiIcons.informationOutline,
              iconColor: Colors.grey,
              title: '关于记账助储',
              trailingText: snapshot.data ?? '--',
            );
          },
        ),
        SettingsItem(
          icon: MdiIcons.starOutline,
          iconColor: Colors.yellow.shade700,
          title: '去商店好评',
          showArrow: true,
          isLast: true,
          onTap: () {
            AppToast.showInfo(context, '好评，好评，给好评行了吧。');
          },
        ),
      ],
    );
  }
}
