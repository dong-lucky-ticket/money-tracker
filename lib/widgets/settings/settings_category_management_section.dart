import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/data_provider.dart';
import '../../widgets/categories/category_editor_panel.dart';
import '../../theme/app_colors.dart';
import '../../widgets/categories/category_list_panel.dart';
import '../../widgets/common/segmented_selector.dart';
import 'settings_section.dart';

class SettingsCategoryManagementSection extends StatefulWidget {
  const SettingsCategoryManagementSection({super.key});

  @override
  State<SettingsCategoryManagementSection> createState() =>
      _SettingsCategoryManagementSectionState();
}

class _SettingsCategoryManagementSectionState
    extends State<SettingsCategoryManagementSection> {
  bool _isExpense = true;

  void _showAddCategoryDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SafeArea(
            top: false,
            child: CategoryEditorPanel(
              isExpense: _isExpense,
              onClose: () => Navigator.pop(sheetContext),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Category category,
    DataProvider provider,
  ) {
    final usageCount =
        provider.records.where((record) => record.category.id == category.id).length;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '删除分类',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            usageCount > 0
                ? '该分类已被使用 $usageCount 次。\n\n删除分类不会影响已记账的原始数据。\n\n确定要删除「${category.name}」吗？'
                : '该分类暂未使用。\n\n确定要删除「${category.name}」吗？',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                provider.deleteCategory(category.id);
                Navigator.pop(dialogContext);
              },
              child: const Text(
                '删除',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSectionCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SegmentedSelector<bool>(
                value: _isExpense,
                onChanged: (value) => setState(() => _isExpense = value),
                padding: const EdgeInsets.all(3),
                itemPadding: const EdgeInsets.symmetric(vertical: 8),
                options: const [
                  SegmentedOption(value: true, label: '支出分类'),
                  SegmentedOption(value: false, label: '收入分类'),
                ],
              ),
            ),
            Consumer<DataProvider>(
              builder: (context, provider, child) {
                final categories = provider.categories
                    .where((category) => category.isExpense == _isExpense)
                    .toList();

                return Column(
                  children: [
                    CategoryListPanel(
                      categories: categories,
                      onReorder: provider.reorderCategories,
                      onDelete: (category) {
                        _confirmDelete(context, category, provider);
                      },
                      wrapInCard: false,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.surfaceMuted),
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showAddCategoryDialog(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    MdiIcons.plus,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '新增分类',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '长按分类项目可以拖拽排序',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
