import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/error_log_service.dart';
import '../../theme/app_colors.dart';

class SettingsErrorLogsSheet extends StatelessWidget {
  final ValueChanged<ErrorLogEntry> onTapEntry;
  final VoidCallback onClear;

  const SettingsErrorLogsSheet({
    super.key,
    required this.onTapEntry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ErrorLogService>(
        builder: (context, errorLogService, child) {
          final logs = errorLogService.entries;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '错误日志',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (logs.isNotEmpty)
                        TextButton(
                          onPressed: onClear,
                          child: const Text('清空'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      logs.isEmpty
                          ? '当前没有缓存的错误信息'
                          : '已缓存 ${logs.length} 条错误，点击可查看完整详情',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无错误日志',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = logs[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => onTapEntry(entry),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.sourceLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MM-dd HH:mm:ss')
                                              .format(entry.timestamp),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                    if (entry.scene != null &&
                                        entry.scene!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.scene!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
