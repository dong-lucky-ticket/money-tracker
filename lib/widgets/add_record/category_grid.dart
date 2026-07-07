import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/category_group.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final List<CategoryGroup> categoryGroups;
  final List<Category> recentCategories;
  final Category? selectedCategory;
  final Map<String, GlobalKey> categoryKeys;
  final void Function(Category category, String keyId) onCategorySelected;
  final VoidCallback onAddCategory;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.categoryGroups,
    required this.recentCategories,
    required this.selectedCategory,
    required this.categoryKeys,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final groupedCategories = <String, List<Category>>{
      for (final group in categoryGroups) group.id: [],
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

    final visibleGroups = categoryGroups
        .where((group) => (groupedCategories[group.id] ?? const []).isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (recentCategories.isNotEmpty) ...[
          _CategoryGroupSection(
            title: '最近使用',
            categories: recentCategories,
            keyNamespace: 'recent',
            selectedCategory: selectedCategory,
            categoryKeys: categoryKeys,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 20),
        ],
        for (final group in visibleGroups) ...[
          _CategoryGroupSection(
            title: group.name,
            categories: groupedCategories[group.id] ?? const [],
            keyNamespace: 'group:${group.id}',
            selectedCategory: selectedCategory,
            categoryKeys: categoryKeys,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 20),
        ],
        if (ungroupedCategories.isNotEmpty) ...[
          _CategoryGroupSection(
            title: '未分组',
            categories: ungroupedCategories,
            keyNamespace: 'ungrouped',
            selectedCategory: selectedCategory,
            categoryKeys: categoryKeys,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: 20),
        ],
        _CategoryManagementButton(onTap: onAddCategory),
      ],
    );
  }
}

class _CategoryGroupSection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final String keyNamespace;
  final Category? selectedCategory;
  final Map<String, GlobalKey> categoryKeys;
  final void Function(Category category, String keyId) onCategorySelected;

  const _CategoryGroupSection({
    required this.title,
    required this.categories,
    required this.keyNamespace,
    required this.selectedCategory,
    required this.categoryKeys,
    required this.onCategorySelected,
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
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategory?.id == category.id;
            final keyId = '$keyNamespace:${category.id}';
            final key = categoryKeys.putIfAbsent(keyId, () => GlobalKey());

            return _CategoryGridItem(
              key: key,
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category, keyId),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryManagementButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CategoryManagementButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              '分类管理',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridItem({
    super.key,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.surfaceSoft,
              shape: BoxShape.circle,
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
            style: TextStyle(
              fontSize: 11,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
