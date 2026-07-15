import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/operation_log_service.dart';
import '../../theme/app_colors.dart';
import '../common/empty_state.dart';

class SettingsOperationLogsSheet extends StatelessWidget {
  final Future<void> Function(OperationLogEntry entry) onTapEntry;
  final Future<void> Function() onClear;

  const SettingsOperationLogsSheet({
    super.key,
    required this.onTapEntry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Consumer<OperationLogService>(
        builder: (context, service, child) {
          final entries = service.entries;

          return Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '操作记录',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (entries.isNotEmpty)
                      TextButton(
                        onPressed: onClear,
                        child: const Text(
                          '清空记录',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icon(
                            MdiIcons.history,
                            size: 60,
                            color: AppColors.border,
                          ),
                          title: '暂无操作记录',
                          subtitle: '后续新增、删除、导入导出等操作都会展示在这里',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        physics: const BouncingScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final accentColor =
                              _colorForCategory(entry.category);

                          return InkWell(
                            onTap: () => onTapEntry(entry),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.surfaceSoft),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _iconForCategory(entry.category),
                                      color: accentColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          entry.detail.isEmpty
                                              ? '无附加说明'
                                              : entry.detail,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          DateFormat('yyyy-MM-dd HH:mm:ss')
                                              .format(entry.timestamp),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _colorForCategory(String category) {
    switch (category) {
      case 'record':
        return AppColors.primary;
      case 'category':
        return Colors.orange;
      case 'data':
        return Colors.teal;
      case 'settings':
        return Colors.indigo;
      default:
        return AppColors.textTertiary;
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'record':
        return MdiIcons.receiptTextOutline;
      case 'category':
        return MdiIcons.shapeOutline;
      case 'data':
        return MdiIcons.databaseOutline;
      case 'settings':
        return MdiIcons.cogOutline;
      default:
        return MdiIcons.history;
    }
  }
}
