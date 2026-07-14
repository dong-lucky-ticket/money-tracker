import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_screen_controller.dart';
import '../../providers/data_provider.dart';
import 'settings_section.dart';

class SettingsDataManagementSection extends StatelessWidget {
  final SettingsScreenController controller;

  const SettingsDataManagementSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '数据管理'),
        SettingsSectionCard(
          children: [
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.fileExportOutline,
                  iconColor: Colors.blue,
                  title: '导出数据为 CSV',
                  onTap: () => controller.exportToCsv(context, provider),
                );
              },
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.fileImportOutline,
                  iconColor: Colors.teal,
                  title: '导入 CSV 数据',
                  showArrow: true,
                  onTap: () => controller.importFromCsv(context, provider),
                );
              },
            ),
            SettingsItem(
              icon: MdiIcons.fileDocumentMultipleOutline,
              iconColor: Colors.orange,
              title: '查看已导出的 CSV',
              showArrow: true,
              onTap: () => controller.viewExportedFiles(context),
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: Icons.restore_from_trash_rounded,
                  iconColor: Colors.deepPurple,
                  title: '回收站',
                  customTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.recycleBinItemCount == 0
                            ? '空'
                            : '${provider.recycleBinItemCount} 项',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD1D5DB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFFD1D5DB),
                      ),
                    ],
                  ),
                  onTap: () => controller.showRecycleBin(context),
                );
              },
            ),
            SettingsItem(
              icon: MdiIcons.cloudSyncOutline,
              iconColor: Colors.green,
              title: '云端备份与恢复',
              trailingText: '已关闭',
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.trashCanOutline,
                  iconColor: Colors.red,
                  title: '清空所有本地账单',
                  titleColor: Colors.red,
                  showArrow: true,
                  isLast: true,
                  onTap: () => controller.clearData(context, provider),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
