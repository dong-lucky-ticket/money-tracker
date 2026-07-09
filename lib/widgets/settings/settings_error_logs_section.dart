import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_screen_controller.dart';
import '../../services/error_log_service.dart';
import 'settings_section.dart';

class SettingsErrorLogsSection extends StatelessWidget {
  final SettingsScreenController controller;

  const SettingsErrorLogsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsSectionTitle(title: '问题排查'),
        SettingsSectionCard(
          children: [
            Consumer<ErrorLogService>(
              builder: (context, errorLogService, child) {
                final latestEntry = errorLogService.latestEntry;
                final latestLabel = latestEntry == null
                    ? '暂无'
                    : DateFormat('MM-dd HH:mm').format(latestEntry.timestamp);

                return SettingsItem(
                  icon: MdiIcons.alertCircleOutline,
                  iconColor: Colors.deepOrange,
                  title: '查看错误日志',
                  customTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (errorLogService.hasUnreadEntries) ...[
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
                        errorLogService.entryCount == 0
                            ? latestLabel
                            : '$latestLabel / ${errorLogService.entryCount} 条',
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
                  onTap: () => controller.showErrorLogs(context),
                );
              },
            ),
            SettingsItem(
              icon: MdiIcons.fileDocumentOutline,
              iconColor: Colors.indigo,
              title: '导出错误日志',
              showArrow: true,
              onTap: () => controller.shareErrorLogs(context),
            ),
            SettingsItem(
              icon: MdiIcons.broom,
              iconColor: Colors.redAccent,
              title: '清空错误日志',
              titleColor: Colors.redAccent,
              showArrow: true,
              isLast: true,
              onTap: () => controller.clearErrorLogs(context),
            ),
          ],
        ),
      ],
    );
  }
}
