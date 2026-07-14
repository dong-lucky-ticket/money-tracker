import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../controllers/settings_screen_controller.dart';
import '../../theme/app_colors.dart';
import '../common/app_card.dart';
import '../common/app_toast.dart';
import 'settings_section.dart';

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  static const String _aboutCopy =
      '记账助储，帮你把每一笔收支记清楚，也把每一个小目标存下来。';

  void _showAboutSheet(BuildContext context, String version) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppCard(
              borderRadius: BorderRadius.circular(28),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '关于记账助储',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    _aboutCopy,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '希望它能陪你把消费看得更明白，把存钱这件事做得更轻松一点。',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '当前版本 $version',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(text: _aboutCopy),
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            if (context.mounted) {
                              AppToast.showSuccess(context, '介绍文案已复制');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('复制介绍'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('知道了'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: [
        FutureBuilder<String>(
          future: SettingsScreenController.appVersionFuture,
          builder: (context, snapshot) {
            final version = snapshot.data ?? '--';
            return SettingsItem(
              icon: MdiIcons.informationOutline,
              iconColor: Colors.grey,
              title: '关于记账助储',
              customTrailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    version,
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
              onTap: () => _showAboutSheet(context, version),
            );
          },
        ),
        SettingsItem(
          icon: MdiIcons.starOutline,
          iconColor: Colors.yellow.shade700,
          title: '喜欢它的话',
          showArrow: true,
          isLast: true,
          onTap: () {
            AppToast.showInfo(context, '点开“关于记账助储”，可以复制介绍文案分享给朋友。');
          },
        ),
      ],
    );
  }
}
