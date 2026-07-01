import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final Map<String, GlobalKey> categoryKeys;
  final ValueChanged<Category> onCategorySelected;
  final VoidCallback onAddCategory;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.categoryKeys,
    required this.onCategorySelected,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
        final key = categoryKeys.putIfAbsent(category.id, () => GlobalKey());

        return _CategoryGridItem(
          key: key,
          category: category,
          isSelected: isSelected,
          onTap: () => onCategorySelected(category),
        );
      },
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

class _AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
            ),
            child: Icon(
              MdiIcons.plus,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
