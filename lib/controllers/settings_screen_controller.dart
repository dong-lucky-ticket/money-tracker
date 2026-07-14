import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/data_provider.dart';
import '../services/app_share_service.dart';
import '../services/error_log_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/settings/settings_error_logs_sheet.dart';
import '../widgets/settings/settings_exported_files_sheet.dart';
import '../widgets/settings/settings_recycle_bin_sheet.dart';

class SettingsScreenController {
  static final Future<String> appVersionFuture = _loadAppVersion();

  static Future<String> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.version.isEmpty) {
      return '--';
    }
    return 'v${packageInfo.version}';
  }

  Future<void> importFromCsv(
    BuildContext context,
    DataProvider provider,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes ??
          (pickedFile.path != null
              ? await File(pickedFile.path!).readAsBytes()
              : null);

      if (bytes == null) {
        throw const FormatException('无法读取所选文件');
      }

      final importResult = await provider
          .importRecordsFromCsv(utf8.decode(bytes, allowMalformed: true));

      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('导入完成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('文件：${pickedFile.name}'),
                const SizedBox(height: 12),
                Text('新增记录 ${importResult.importedCount} 条'),
                Text('更新记录 ${importResult.updatedCount} 条'),
                Text('跳过无效行 ${importResult.skippedCount} 条'),
                Text('新增分类 ${importResult.createdCategoryCount} 个'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );
    } on FormatException catch (e) {
      await ErrorLogService.instance.record(
        e,
        source: 'settings_import_csv',
        scene: '导入 CSV 数据',
      );
      if (context.mounted) {
        AppToast.showError(context, '导入失败：${e.message}');
      }
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_import_csv',
        scene: '导入 CSV 数据',
      );
      if (context.mounted) {
        AppToast.showError(context, '导入失败：$e');
      }
    }
  }

  Future<void> exportToCsv(
    BuildContext context,
    DataProvider provider,
  ) async {
    try {
      final rows = <List<dynamic>>[
        ['ID', '类型', '金额', '分类', '备注', '日期'],
        for (final record in provider.records)
          [
            record.id,
            record.isExpense ? '支出' : '收入',
            record.amount,
            record.category.name,
            record.remark,
            DateFormat('yyyy-MM-dd HH:mm:ss').format(record.date),
          ],
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/记账助储_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv, encoding: utf8);

      if (context.mounted) {
        await _shareFile(
          context,
          filePath: path,
          subject: '账单数据导出',
        );
      }
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_export_csv',
        scene: '导出 CSV 数据',
      );
      if (context.mounted) {
        AppToast.showError(context, '导出失败：$e');
      }
    }
  }

  Future<void> viewExportedFiles(BuildContext context) async {
    final directory = await getTemporaryDirectory();
    final files = directory.listSync().whereType<File>().where((file) {
      final name = file.path.split(Platform.pathSeparator).last;
      return (name.startsWith('expensetracker_') || name.startsWith('记账助储_')) &&
          name.endsWith('.csv');
    }).toList()
      ..sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SettingsExportedFilesSheet(
          initialFiles: files,
          onShareFile: (itemContext, file) {
            return _shareFile(
              itemContext,
              filePath: file.path,
              subject: '分享 CSV 数据',
            );
          },
        );
      },
    );
  }

  Future<void> showRecycleBin(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return const FractionallySizedBox(
          heightFactor: 0.9,
          child: SettingsRecycleBinSheet(),
        );
      },
    );
  }

  Future<void> clearData(
    BuildContext context,
    DataProvider provider,
  ) async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('清空数据'),
              content: const Text('确定要清空所有本地账单数据吗？此操作不可恢复。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('确定', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldClear) {
      return;
    }

    provider.clearAllData();
    if (context.mounted) {
      AppToast.showSuccess(context, '已清空所有账单');
    }
  }

  Future<void> shareErrorLogs(BuildContext context) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/记账助储_错误日志_$timestamp.txt';
      final file = File(path);
      await file.writeAsString(
        ErrorLogService.instance.buildExportText(),
        encoding: utf8,
      );

      if (!context.mounted) {
        return;
      }

      await _shareFile(
        context,
        filePath: file.path,
        subject: '记账助储错误日志',
      );
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_share_error_logs',
        scene: '导出错误日志',
      );
      if (context.mounted) {
        AppToast.showError(context, '导出错误日志失败：$e');
      }
    }
  }

  Future<void> showErrorLogs(BuildContext context) async {
    try {
      await ErrorLogService.instance.markViewed();
      if (!context.mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SettingsErrorLogsSheet(
            onTapEntry: (entry) => showErrorLogDetail(sheetContext, entry),
            onClear: () => clearErrorLogs(sheetContext),
          );
        },
      );
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_view_error_logs',
        scene: '查看错误日志',
      );
      if (context.mounted) {
        AppToast.showError(context, '打开错误日志失败：$e');
      }
    }
  }

  Future<void> showErrorLogDetail(
    BuildContext context,
    ErrorLogEntry entry,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(entry.sourceLabel),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                entry.toReadableText(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: entry.toReadableText()),
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  AppToast.showSuccess(context, '错误详情已复制');
                }
              },
              child: const Text('复制'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearErrorLogs(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('清空错误日志'),
              content: const Text('确定要清空本地缓存的错误日志吗？此操作不可恢复。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '清空',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldClear) {
      return;
    }

    try {
      await ErrorLogService.instance.clear();
      if (context.mounted) {
        AppToast.showSuccess(context, '错误日志已清空');
      }
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_clear_error_logs',
        scene: '清空错误日志',
      );
      if (context.mounted) {
        AppToast.showError(context, '清空错误日志失败：$e');
      }
    }
  }

  Future<void> _shareFile(
    BuildContext context, {
    required String filePath,
    required String subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    await AppShareService.shareXFiles(
      context,
      [XFile(filePath)],
      subject: subject,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }
}
