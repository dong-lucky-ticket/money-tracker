import 'package:flutter/material.dart';

import '../controllers/settings_screen_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/settings/settings_about_section.dart';
import '../widgets/settings/settings_app_preferences_section.dart';
import '../widgets/settings/settings_category_shortcut_section.dart';
import '../widgets/settings/settings_data_management_section.dart';
import '../widgets/settings/settings_error_logs_section.dart';
import '../widgets/settings/settings_header_section.dart';

class SettingsPageScreen extends StatelessWidget {
  const SettingsPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScreenController();

    return Column(
      children: [
        const SettingsHeaderSection(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              const SettingsCategoryShortcutSection(),
              const SizedBox(height: 24),
              SettingsDataManagementSection(controller: controller),
              const SizedBox(height: 24),
              SettingsErrorLogsSection(controller: controller),
              const SizedBox(height: 24),
              const SettingsAppPreferencesSection(),
              const SizedBox(height: 24),
              const SettingsAboutSection(),
            ],
          ),
        ),
      ],
    );
  }
}
