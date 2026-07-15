import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_screen_controller.dart';
import '../../providers/data_provider.dart';
import '../../services/operation_log_service.dart';
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
            Consumer<OperationLogService>(
              builder: (context, operationLogService, child) {
                final latestEntry = operationLogService.latestEntry;
                final latestLabel = latestEntry == null
                    ? '暂无'
                    : DateFormat('MM-dd HH:mm').format(latestEntry.timestamp);

                return SettingsItem(
                  icon: MdiIcons.history,
                  iconColor: Colors.indigo,
                  title: '操作记录',
                  customTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (operationLogService.hasUnreadEntries) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        operationLogService.entryCount == 0
                            ? latestLabel
                            : '$latestLabel / ${operationLogService.entryCount} 条',
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
                  onTap: () => controller.showOperationLogs(context),
                );
              },
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.backupRestore,
                  iconColor: Colors.blue,
                  title: '备份与恢复',
                  showArrow: true,
                  onTap: () =>
                      controller.showBackupAndRestoreSheet(context, provider),
                );
              },
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                return SettingsItem(
                  icon: MdiIcons.fileDocumentMultipleOutline,
                  iconColor: Colors.orange,
                  title: '最近导出',
                  showArrow: true,
                  onTap: () => controller.viewExportedFiles(context, provider),
                );
              },
            ),
            SettingsItem(
              icon: MdiIcons.cloudSyncOutline,
              iconColor: Colors.orange,
              title: '云端备份与恢复',
              trailingText: '已关闭',
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
