import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/categories/category_list_panel.dart';

class SettingsCategoryGroupsPanel extends StatelessWidget {
  final bool isExpense;
  final DataProvider provider;
  final ValueChanged<Category> onDeleteCategory;
  final VoidCallback onManageGroups;
  final VoidCallback onAddCategory;

  const SettingsCategoryGroupsPanel({
    super.key,
    required this.isExpense,
    required this.provider,
    required this.onDeleteCategory,
    required this.onManageGroups,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = provider.categories
        .where((category) => category.isExpense == isExpense)
        .toList(growable: false);
    final groups = provider.categoryGroups
        .where((group) => group.isExpense == isExpense)
        .toList(growable: false);
    final groupedCategories = <String, List<Category>>{
      for (final group in groups) group.id: [],
    };
    final ungroupedCategories = <Category>[];

    for (final category in categories) {
      final bucket = groupedCategories[category.groupId];
      if (bucket != null) {
        bucket.add(category);
      } else {
        ungroupedCategories.add(category);
      }
    }

    return Column(
      children: [
        for (final group in groups)
          if ((groupedCategories[group.id] ?? const []).isNotEmpty)
            _CategoryGroupSection(
              title: group.name,
              categories: groupedCategories[group.id] ?? const [],
              onReorder: (updated) {
                provider.reorderCategoriesInGroup(
                  groupId: group.id,
                  isExpense: isExpense,
                  newOrderList: updated,
                );
              },
              onDelete: onDeleteCategory,
            ),
        if (ungroupedCategories.isNotEmpty)
          _CategoryGroupSection(
            title: '未分组',
            categories: ungroupedCategories,
            onReorder: (updated) {
              provider.reorderCategoriesInGroup(
                groupId: '',
                isExpense: isExpense,
                newOrderList: updated,
              );
            },
            onDelete: onDeleteCategory,
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
                onTap: onManageGroups,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.view_list_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpense ? '管理支出大类' : '管理收入大类',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onAddCategory,
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
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
  }
}

class _CategoryGroupSection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final ValueChanged<List<Category>> onReorder;
  final ValueChanged<Category> onDelete;

  const _CategoryGroupSection({
    required this.title,
    required this.categories,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${categories.length} 项',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        CategoryListPanel(
          categories: categories,
          onReorder: onReorder,
          onDelete: onDelete,
          wrapInCard: false,
        ),
      ],
    );
  }
}
