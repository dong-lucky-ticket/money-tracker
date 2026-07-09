import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/category_group.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class EditRecordCategoryPickerSheet extends StatelessWidget {
  final bool isExpense;
  final Category selectedCategory;
  final List<Category> recentCategories;
  final List<Category> ungroupedCategories;
  final List<CategoryGroup> visibleGroups;
  final Map<String, List<Category>> groupedCategories;

  const EditRecordCategoryPickerSheet({
    super.key,
    required this.isExpense,
    required this.selectedCategory,
    required this.recentCategories,
    required this.ungroupedCategories,
    required this.visibleGroups,
    required this.groupedCategories,
  });

  static Future<Category?> show(
    BuildContext context, {
    required bool isExpense,
    required Category selectedCategory,
    required List<Category> categories,
    required List<CategoryGroup> groups,
    required List<Category> recentCategories,
  }) {
    if (categories.isEmpty) {
      return Future.value(null);
    }

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

    final visibleGroups = groups
        .where((group) => (groupedCategories[group.id] ?? const []).isNotEmpty)
        .toList(growable: false);

    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return EditRecordCategoryPickerSheet(
          isExpense: isExpense,
          selectedCategory: selectedCategory,
          recentCategories: recentCategories,
          ungroupedCategories: ungroupedCategories,
          visibleGroups: visibleGroups,
          groupedCategories: groupedCategories,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择分类',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExpense ? '支出分类' : '收入分类',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: [
                if (recentCategories.isNotEmpty) ...[
                  _CategoryPickerSection(
                    title: '最近使用',
                    categories: recentCategories,
                    selectedCategory: selectedCategory,
                    onTapCategory: (category) => Navigator.pop(context, category),
                  ),
                  const SizedBox(height: 20),
                ],
                for (final group in visibleGroups) ...[
                  _CategoryPickerSection(
                    title: group.name,
                    categories: groupedCategories[group.id] ?? const [],
                    selectedCategory: selectedCategory,
                    onTapCategory: (category) => Navigator.pop(context, category),
                  ),
                  const SizedBox(height: 20),
                ],
                if (ungroupedCategories.isNotEmpty)
                  _CategoryPickerSection(
                    title: '未分组',
                    categories: ungroupedCategories,
                    selectedCategory: selectedCategory,
                    onTapCategory: (category) => Navigator.pop(context, category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerSection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final Category selectedCategory;
  final ValueChanged<Category> onTapCategory;

  const _CategoryPickerSection({
    required this.title,
    required this.categories,
    required this.selectedCategory,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 18,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedCategory.id;
            return _EditableCategoryItem(
              category: category,
              isSelected: isSelected,
              onTap: () => onTapCategory(category),
            );
          },
        ),
      ],
    );
  }
}

class _EditableCategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditableCategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.surfaceSoft,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              IconMapper.getIcon(category.iconName),
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
