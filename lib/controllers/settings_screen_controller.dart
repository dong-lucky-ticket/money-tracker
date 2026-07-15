import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/data_provider.dart';
import '../services/app_share_service.dart';
import '../services/csv_export_service.dart';
import '../services/error_log_service.dart';
import '../services/operation_log_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/settings/settings_error_logs_sheet.dart';
import '../widgets/settings/settings_exported_files_sheet.dart';
import '../widgets/settings/settings_operation_logs_sheet.dart';
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
      final csv = CsvExportService.buildCsv(
        activeRecords: provider.records,
        deletedRecords: provider.deletedRecords,
        activeCategories: provider.categories,
        deletedCategories: provider.deletedCategories,
        categoryGroups: provider.categoryGroups,
      );
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/记账助手_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv, encoding: utf8);

      await OperationLogService.instance.record(
        title: '导出 CSV 数据',
        detail: '已生成文件 ${file.uri.pathSegments.last}',
        category: 'data',
      );

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
      return (name.startsWith('expensetracker_') ||
              name.startsWith('记账助手_')) &&
          name.endsWith('.csv');
    }).toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

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
          onSaveToDownloads: (itemContext, file) {
            return saveExportedFileToDownloads(itemContext, file);
          },
          onDeleteFile: (itemContext, file) {
            return deleteExportedFile(itemContext, file);
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

    await provider.clearAllData();
    if (context.mounted) {
      AppToast.showSuccess(context, '已清空所有账单');
    }
  }

  Future<void> showOperationLogs(BuildContext context) async {
    try {
      await OperationLogService.instance.markViewed();
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
          return SettingsOperationLogsSheet(
            onTapEntry: (entry) => showOperationLogDetail(sheetContext, entry),
            onClear: () => clearOperationLogs(sheetContext),
          );
        },
      );
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_view_operation_logs',
        scene: '查看操作记录',
      );
      if (context.mounted) {
        AppToast.showError(context, '打开操作记录失败：$e');
      }
    }
  }

  Future<void> showOperationLogDetail(
    BuildContext context,
    OperationLogEntry entry,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(entry.title),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearOperationLogs(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('清空操作记录'),
              content: const Text('确定要清空本地保存的操作记录吗？此操作不可恢复。'),
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
      await OperationLogService.instance.clear();
      if (context.mounted) {
        AppToast.showSuccess(context, '操作记录已清空');
      }
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_clear_operation_logs',
        scene: '清空操作记录',
      );
      if (context.mounted) {
        AppToast.showError(context, '清空操作记录失败：$e');
      }
    }
  }

  Future<void> shareErrorLogs(BuildContext context) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/记账助手_错误日志_$timestamp.txt';
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
        subject: '记账助手错误日志',
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

  Future<void> saveExportedFileToDownloads(
    BuildContext context,
    File file,
  ) async {
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw const FileSystemException('无法获取 Download 目录');
      }

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final targetPath = await _buildUniqueFilePath(
        downloadsDirectory.path,
        fileName,
      );
      final content = await file.readAsString(encoding: utf8);
      await File(targetPath).writeAsString(
        content,
        encoding: utf8,
        flush: true,
      );

      if (context.mounted) {
        AppToast.showSuccess(context, '已保存到 Download');
      }
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_save_exported_csv_to_downloads',
        scene: '保存已导出 CSV 到 Download',
      );
      if (context.mounted) {
        AppToast.showError(context, '保存失败：$e');
      }
    }
  }

  Future<bool> deleteExportedFile(
    BuildContext context,
    File file,
  ) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('删除文件'),
              content: const Text(
                '确定要删除这个已导出的文件吗？此操作不可恢复。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return false;
    }

    try {
      if (await file.exists()) {
        await file.delete();
      }
      if (context.mounted) {
        AppToast.showSuccess(context, '文件已删除');
      }
      return true;
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'settings_delete_exported_csv',
        scene: '删除已导出 CSV',
      );
      if (context.mounted) {
        AppToast.showError(context, '删除失败：$e');
      }
      return false;
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
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<String> _buildUniqueFilePath(
    String directoryPath,
    String fileName,
  ) async {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex >= 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex) : '';

    var candidatePath = '$directoryPath${Platform.pathSeparator}$fileName';
    var counter = 1;
    while (await File(candidatePath).exists()) {
      candidatePath =
          '$directoryPath${Platform.pathSeparator}${baseName}_$counter$extension';
      counter++;
    }
    return candidatePath;
  }
}
