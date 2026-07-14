import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/record.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';
import '../common/app_toast.dart';
import '../common/empty_state.dart';
import '../common/segmented_selector.dart';

class SettingsRecycleBinSheet extends StatefulWidget {
  const SettingsRecycleBinSheet({super.key});

  @override
  State<SettingsRecycleBinSheet> createState() =>
      _SettingsRecycleBinSheetState();
}

class _SettingsRecycleBinSheetState extends State<SettingsRecycleBinSheet> {
  bool _showRecords = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Consumer<DataProvider>(
        builder: (context, provider, child) {
          final deletedRecords = provider.deletedRecords;
          final deletedCategories = provider.deletedCategories;
          final currentCount =
              _showRecords ? deletedRecords.length : deletedCategories.length;

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
                        '回收站',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (currentCount > 0)
                      TextButton(
                        onPressed: () => _confirmClearCurrentTab(context),
                        child: Text(
                          _showRecords ? '清空账单' : '清空分类',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SegmentedSelector<bool>(
                  value: _showRecords,
                  onChanged: (value) => setState(() => _showRecords = value),
                  padding: const EdgeInsets.all(3),
                  itemPadding: const EdgeInsets.symmetric(vertical: 8),
                  options: [
                    SegmentedOption(
                      value: true,
                      label: '账单 ${deletedRecords.length}',
                    ),
                    SegmentedOption(
                      value: false,
                      label: '分类 ${deletedCategories.length}',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _showRecords
                    ? _buildDeletedRecords(context, deletedRecords)
                    : _buildDeletedCategories(context, deletedCategories),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeletedRecords(BuildContext context, List<Record> records) {
    if (records.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 64,
            color: AppColors.border,
          ),
          title: '暂无已删除账单',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final categoryColor = colorFromHex(record.category.colorHex);
        final amountColor =
            record.isExpense ? AppColors.danger : AppColors.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconMapper.getIcon(record.category.iconName),
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.category.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.remark.isEmpty ? '无备注' : record.remark,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${record.isExpense ? '-' : '+'}${record.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '账单日期 ${DateFormat('yyyy-MM-dd HH:mm').format(record.date)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '删除时间 ${DateFormat('yyyy-MM-dd HH:mm').format(record.updatedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreRecord(context, record),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('恢复'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _confirmDeleteRecordPermanently(
                        context,
                        record,
                      ),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        backgroundColor: const Color(0xFFFFF1F2),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('彻底删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeletedCategories(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icon(
            MdiIcons.shapeOutline,
            size: 64,
            color: AppColors.border,
          ),
          title: '暂无已删除分类',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryColor = colorFromHex(category.colorHex);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceSoft),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconMapper.getIcon(category.iconName),
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.isExpense ? '支出分类' : '收入分类',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreCategory(context, category),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('恢复'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _confirmDeleteCategoryPermanently(
                        context,
                        category,
                      ),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        backgroundColor: const Color(0xFFFFF1F2),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('彻底删除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _restoreRecord(BuildContext context, Record record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('恢复账单'),
              content: const Text('确定要将这条账单恢复到原列表吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '确认恢复',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await context.read<DataProvider>().restoreRecord(record.id);
    if (!context.mounted) {
      return;
    }
    AppToast.showSuccess(context, '账单已恢复');
  }

  Future<void> _restoreCategory(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('恢复分类'),
              content: const Text('确定要将这个分类恢复到原列表吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '确认恢复',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await context.read<DataProvider>().restoreCategory(category.id);
    if (!context.mounted) {
      return;
    }
    AppToast.showSuccess(context, '分类已恢复');
  }

  Future<void> _confirmDeleteRecordPermanently(
    BuildContext context,
    Record record,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('彻底删除账单'),
              content: const Text('彻底删除后将无法恢复，确定继续吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '彻底删除',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await context.read<DataProvider>().permanentlyDeleteRecord(record.id);
    if (!context.mounted) {
      return;
    }
    AppToast.showSuccess(context, '账单已彻底删除');
  }

  Future<void> _confirmDeleteCategoryPermanently(
    BuildContext context,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('彻底删除分类'),
              content: const Text('彻底删除后将无法恢复，确定继续吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '彻底删除',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await context.read<DataProvider>().permanentlyDeleteCategory(category.id);
    if (!context.mounted) {
      return;
    }
    AppToast.showSuccess(context, '分类已彻底删除');
  }

  Future<void> _confirmClearCurrentTab(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(_showRecords ? '清空已删除账单' : '清空已删除分类'),
              content: Text(
                _showRecords
                    ? '清空后，回收站中的账单将无法恢复。'
                    : '清空后，回收站中的分类将无法恢复。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    '确认清空',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final provider = context.read<DataProvider>();
    if (_showRecords) {
      await provider.clearDeletedRecords();
    } else {
      await provider.clearDeletedCategories();
    }

    if (!context.mounted) {
      return;
    }
    AppToast.showSuccess(context, _showRecords ? '已清空已删除账单' : '已清空已删除分类');
  }
}
