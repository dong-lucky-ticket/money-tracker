import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../theme/app_colors.dart';

class CategoryBottomActions extends StatelessWidget {
  final VoidCallback onAdd;

  const CategoryBottomActions({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: AppColors.pageBackground,
        child: Column(
          children: [
            GestureDetector(
              onTap: onAdd,
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
            const Center(
              child: Text(
                '长按分类项目可以拖拽排序',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
