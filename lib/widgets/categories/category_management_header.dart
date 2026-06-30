import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';

class CategoryManagementHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CategoryManagementHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              MdiIcons.arrowLeft,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
          const Expanded(
            child: Text(
              '分类管理',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
