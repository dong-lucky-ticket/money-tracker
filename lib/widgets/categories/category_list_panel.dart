import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../models/category.dart';
import '../../theme/app_colors.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_mapper.dart';
import '../common/app_card.dart';

class CategoryListPanel extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<List<Category>> onReorder;
  final ValueChanged<Category> onDelete;
  final bool wrapInCard;

  const CategoryListPanel({
    super.key,
    required this.categories,
    required this.onReorder,
    required this.onDelete,
    this.wrapInCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final listView = ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        final updated = List<Category>.from(categories);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        onReorder(updated);
      },
      children: categories.map((category) {
        return _CategoryListTile(
          key: Key(category.id),
          category: category,
          onDelete: () => onDelete(category),
        );
      }).toList(),
    );

    if (!wrapInCard) {
      return listView;
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: listView,
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;

  const _CategoryListTile({
    super.key,
    required this.category,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceMuted)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(MdiIcons.menu, color: const Color(0xFFD1D5DB), size: 20),
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconMapper.getIcon(category.iconName),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF4444),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
