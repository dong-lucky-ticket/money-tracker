import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/data_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      print(path);
      final file = File(path);
      await file.writeAsString(csv);
      
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                provider.clearAllData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空所有账单')));
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
      return (name.startsWith('expensetracker_') || name.startsWith('记账助储_')) && name.endsWith('.csv');
    }).toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('已导出的 CSV 文件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: files.isEmpty
                      ? const Center(child: Text('暂无导出的文件', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (listContext, index) {
                            final file = files[index];
                            final fileName = file.path.split(Platform.pathSeparator).last;
                            final fileSize = (file.lengthSync() / 1024).toStringAsFixed(2);
                            final modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(file.lastModifiedSync());

                            return Builder(
                              builder: (itemContext) {
                                return ListTile(
                                  leading: Icon(MdiIcons.fileDelimitedOutline, color: const Color(0xFF4A90E2)),
                                  title: Text(fileName, style: const TextStyle(fontSize: 14)),
                                  subtitle: Text('$modifiedTime  |  $fileSize KB', style: const TextStyle(fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, size: 20, color: Colors.grey),
                                        onPressed: () async {
                                          final box = itemContext.findRenderObject() as RenderBox?;
                                          await Share.shareXFiles(
                                            [XFile(file.path)],
                                            subject: '分享 CSV 数据',
                                            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        onPressed: () {
                                          showDialog(
                                            context: itemContext,
                                            builder: (dialogCtx) {
                                              return AlertDialog(
                                                title: const Text('删除文件'),
                                                content: const Text('确定要删除这个导出的文件吗？此操作不可恢复。'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('取消')),
                                                  TextButton(
                                                    onPressed: () {
                                                      file.deleteSync();
                                                      setSheetState(() {
                                                        files.removeAt(index);
                                                      });
                                                      Navigator.pop(dialogCtx);
                                                    },
                                                    child: const Text('删除', style: TextStyle(color: Colors.red)),
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
    return SafeArea(
      child: Column(
        children: [
          // 个人资料卡片
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4A90E2), width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFF3F4F6),
                    child: Icon(Icons.person, size: 32, color: Color(0xFF9CA3AF)),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('记账达人', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 2),
                      Text('已坚持记账 248 天', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                Icon(MdiIcons.chevronRight, size: 24, color: const Color(0xFFD1D5DB)),
              ],
            ),
          ),
          
          // 统计概览
          Consumer<DataProvider>(
            builder: (context, provider, child) {
              final now = DateTime.now();
              final thisMonthCount = provider.records.where((r) => r.date.year == now.year && r.date.month == now.month).length;
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF3F4F6)),
                    bottom: BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStatItem(provider.records.length.toString(), '总记账'),
                    _buildDivider(),
                    _buildStatItem(thisMonthCount.toString(), '本月笔数'),
                    _buildDivider(),
                    _buildStatItem(provider.activeCategoryCount.toString(), '活跃分类'),
                  ],
                ),
              );
            }
          ),
          
          // 功能列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                // 数据管理
                _buildSectionTitle('数据管理'),
                _buildSectionContainer(
                  children: [
                    Consumer<DataProvider>(
                      builder: (context, provider, child) {
                        return _buildSettingItem(
                          icon: MdiIcons.fileExportOutline,
                          iconColor: Colors.blue,
                          title: '导出数据为 CSV',
                          onTap: () => _exportToCSV(context, provider),
                        );
                      }
                    ),
                    _buildSettingItem(
                      icon: MdiIcons.fileDocumentMultipleOutline,
                      iconColor: Colors.orange,
                      title: '查看已导出的 CSV',
                      showArrow: true,
                      onTap: () => _viewExportedFiles(context),
                    ),
                    _buildSettingItem(
                      icon: MdiIcons.cloudSyncOutline,
                      iconColor: Colors.green,
                      title: '云端备份与恢复',
                      trailingText: '已关闭',
                    ),
                    Consumer<DataProvider>(
                      builder: (context, provider, child) {
                        return _buildSettingItem(
                          icon: MdiIcons.trashCanOutline,
                          iconColor: Colors.red,
                          title: '清空所有本地账单',
                          titleColor: Colors.red,
                          showArrow: true,
                          isLast: true,
                          onTap: () => _clearData(context, provider),
                        );
                      }
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 应用设置
                _buildSectionTitle('应用设置'),
                _buildSectionContainer(
                  children: [
                    Consumer<DataProvider>(
                      builder: (context, provider, child) {
                        return _buildSettingItem(
                          icon: MdiIcons.paletteOutline,
                          iconColor: Colors.purple,
                          title: '主题风格切换',
                          trailingText: provider.isDarkTheme ? '暗黑模式' : '简约蓝',
                          showArrow: true,
                          onTap: () => provider.toggleTheme(),
                        );
                      }
                    ),
                    _buildSettingItem(
                      icon: MdiIcons.bellOutline,
                      iconColor: Colors.orange,
                      title: '记账提醒',
                      customTrailing: Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: const Color(0xFF4A90E2),
                      ),
                    ),
                    _buildSettingItem(
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
                _buildSectionContainer(
                  children: [
                    _buildSettingItem(
                      icon: MdiIcons.informationOutline,
                      iconColor: Colors.grey,
                      title: '关于记账助储',
                      trailingText: 'v1.0.0',
                    ),
                    _buildSettingItem(
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
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 2),
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? trailingText,
    bool showArrow = false,
    Widget? customTrailing,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: titleColor ?? const Color(0xFF374151)),
              ),
            ),
            if (customTrailing != null)
              customTrailing
            else if (trailingText != null)
              Text(trailingText, style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)))
            else if (showArrow)
              Icon(MdiIcons.chevronRight, size: 20, color: const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}
