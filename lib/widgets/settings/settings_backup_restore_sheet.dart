import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';

class SettingsBackupRestoreSheet extends StatelessWidget {
  final Future<void> Function() onSaveBackup;
  final Future<void> Function() onShareBackup;
  final Future<void> Function() onImportBackup;
  final Future<void> Function() onRestoreRecentExport;

  const SettingsBackupRestoreSheet({
    super.key,
    required this.onSaveBackup,
    required this.onShareBackup,
    required this.onImportBackup,
    required this.onRestoreRecentExport,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '备份与恢复',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '正式备份建议保存到设备、云盘或电脑。最近导出仅保存在应用临时目录，系统可能会自动清理。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionTile(
                  icon: MdiIcons.contentSaveOutline,
                  iconColor: Colors.blue,
                  title: '保存备份到设备',
                  subtitle: '主路径，系统会让你选择保存位置',
                  onTap: onSaveBackup,
                ),
                _ActionTile(
                  icon: MdiIcons.shareVariantOutline,
                  iconColor: Colors.teal,
                  title: '分享备份文件',
                  subtitle: '发送到微信、文件、云盘或电脑',
                  onTap: onShareBackup,
                ),
                _ActionTile(
                  icon: MdiIcons.backupRestore,
                  iconColor: Colors.green,
                  title: '从备份文件恢复',
                  subtitle: '从系统文件选择器选择一个 CSV 备份',
                  onTap: onImportBackup,
                ),
                _ActionTile(
                  icon: MdiIcons.history,
                  iconColor: Colors.orange,
                  title: '从最近导出恢复',
                  subtitle: '从应用最近生成的临时备份中恢复',
                  isLast: true,
                  onTap: onRestoreRecentExport,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;
  final Future<void> Function() onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}
