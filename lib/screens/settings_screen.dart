import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import 'categories_screen.dart';
import '../widgets/settings/settings_profile_card.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_stats_bar.dart';

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

  static final Future<String> _appVersionFuture = _loadAppVersion();

  static Future<String> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.version.isEmpty) {
      return '--';
    }
    return 'v${packageInfo.version}';
  }

  Future<void> _importFromCSV(
      BuildContext context, DataProvider provider) async {
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

      if (!context.mounted) return;

      await showDialog(
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
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：${e.message}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  Future<void> _exportToCSV(BuildContext context, DataProvider provider) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["ID", "类型", "金额", "分类", "备注", "日期"]);

      for (var r in provider.records) {
        rows.add([
          r.id,
          r.isExpense ? "支出" : "收入",
          r.amount,
          r.category.name,
          r.remark,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(r.date),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/记账助储_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv, encoding: utf8);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          subject: '账单数据导出',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  void _clearData(BuildContext context, DataProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('清空数据'),
          content: const Text('确定要清空所有本地账单数据吗？此操作不可恢复。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                provider.clearAllData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('已清空所有账单')));
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewExportedFiles(BuildContext context) async {
    final directory = await getTemporaryDirectory();
    List<File> files = directory.listSync().whereType<File>().where((file) {
      final name = file.path.split(Platform.pathSeparator).last;
      return (name.startsWith('expensetracker_') || name.startsWith('记账助储_')) &&
          name.endsWith('.csv');
    }).toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('已导出的 CSV 文件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                Expanded(
                  child: files.isEmpty
                      ? const Center(
                          child: Text('暂无导出的文件',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (listContext, index) {
                            final file = files[index];
                            final fileName =
                                file.path.split(Platform.pathSeparator).last;
                            final fileSize =
                                (file.lengthSync() / 1024).toStringAsFixed(2);
                            final modifiedTime =
                                DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(file.lastModifiedSync());

                            return Builder(
                              builder: (itemContext) {
                                return ListTile(
                                  leading: Icon(MdiIcons.fileDelimitedOutline,
                                      color: const Color(0xFF4A90E2)),
                                  title: Text(fileName,
                                      style: const TextStyle(fontSize: 14)),
                                  subtitle: Text(
                                      '$modifiedTime  |  $fileSize KB',
                                      style: const TextStyle(fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share,
                                            size: 20, color: Colors.grey),
                                        onPressed: () async {
                                          final box = itemContext
                                              .findRenderObject() as RenderBox?;
                                          await Share.shareXFiles(
                                            [XFile(file.path)],
                                            subject: '分享 CSV 数据',
                                            sharePositionOrigin: box!
                                                    .localToGlobal(
                                                        Offset.zero) &
                                                box.size,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        onPressed: () {
                                          showDialog(
                                            context: itemContext,
                                            builder: (dialogCtx) {
                                              return AlertDialog(
                                                title: const Text('删除文件'),
                                                content: const Text(
                                                    '确定要删除这个导出的文件吗？此操作不可恢复。'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dialogCtx),
                                                      child: const Text('取消')),
                                                  TextButton(
                                                    onPressed: () {
                                                      file.deleteSync();
                                                      setSheetState(() {
                                                        files.removeAt(index);
                                                      });
                                                      Navigator.pop(dialogCtx);
                                                    },
                                                    child: const Text('删除',
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SettingsProfileCard(),
                Consumer<DataProvider>(builder: (context, provider, child) {
                  final now = DateTime.now();
                  final thisMonthCount = provider.records
                      .where((r) =>
                          r.date.year == now.year && r.date.month == now.month)
                      .length;

                  return SettingsStatsBar(
                    totalRecords: provider.records.length.toString(),
                    monthlyRecords: thisMonthCount.toString(),
                    activeCategories: provider.activeCategoryCount.toString(),
                  );
                }),
              ],
            ),
          ),
        ),

        // 功能列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              const SettingsSectionTitle(title: '分类管理'),
              SettingsSectionCard(
                children: [
                  SettingsItem(
                    icon: MdiIcons.formatListBulleted,
                    iconColor: AppColors.primary,
                    title: '管理收支分类',
                    trailingText: '排序、删除、新增',
                    showArrow: true,
                    isLast: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 数据管理
              const SettingsSectionTitle(title: '数据管理'),
              SettingsSectionCard(
                children: [
                  Consumer<DataProvider>(builder: (context, provider, child) {
                    return SettingsItem(
                      icon: MdiIcons.fileExportOutline,
                      iconColor: Colors.blue,
                      title: '导出数据为 CSV',
                      onTap: () => _exportToCSV(context, provider),
                    );
                  }),
                  Consumer<DataProvider>(builder: (context, provider, child) {
                    return SettingsItem(
                      icon: MdiIcons.fileImportOutline,
                      iconColor: Colors.teal,
                      title: '导入 CSV 数据',
                      showArrow: true,
                      onTap: () => _importFromCSV(context, provider),
                    );
                  }),
                  SettingsItem(
                    icon: MdiIcons.fileDocumentMultipleOutline,
                    iconColor: Colors.orange,
                    title: '查看已导出的 CSV',
                    showArrow: true,
                    onTap: () => _viewExportedFiles(context),
                  ),
                  SettingsItem(
                    icon: MdiIcons.cloudSyncOutline,
                    iconColor: Colors.green,
                    title: '云端备份与恢复',
                    trailingText: '已关闭',
                  ),
                  Consumer<DataProvider>(builder: (context, provider, child) {
                    return SettingsItem(
                      icon: MdiIcons.trashCanOutline,
                      iconColor: Colors.red,
                      title: '清空所有本地账单',
                      titleColor: Colors.red,
                      showArrow: true,
                      isLast: true,
                      onTap: () => _clearData(context, provider),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // 应用设置
              const SettingsSectionTitle(title: '应用设置'),
              SettingsSectionCard(
                children: [
                  Consumer<DataProvider>(builder: (context, provider, child) {
                    return SettingsItem(
                      icon: MdiIcons.paletteOutline,
                      iconColor: Colors.purple,
                      title: '主题风格切换',
                      trailingText: provider.isDarkTheme ? '暗黑模式' : '简约蓝',
                      showArrow: true,
                      onTap: () => provider.toggleTheme(),
                    );
                  }),
                  SettingsItem(
                    icon: MdiIcons.bellOutline,
                    iconColor: Colors.orange,
                    title: '记账提醒',
                    customTrailing: Switch(
                      value: true,
                      onChanged: (v) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  SettingsItem(
                    icon: MdiIcons.shieldLockOutline,
                    iconColor: Colors.indigo,
                    title: '安全锁屏 (FaceID/指纹)',
                    showArrow: true,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 关于
              SettingsSectionCard(
                children: [
                  FutureBuilder<String>(
                    future: _appVersionFuture,
                    builder: (context, snapshot) {
                      return SettingsItem(
                        icon: MdiIcons.informationOutline,
                        iconColor: Colors.grey,
                        title: '关于记账助储',
                        trailingText: snapshot.data ?? '--',
                      );
                    },
                  ),
                  SettingsItem(
                    icon: MdiIcons.starOutline,
                    iconColor: Colors.yellow.shade700,
                    title: '去商店好评',
                    showArrow: true,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
