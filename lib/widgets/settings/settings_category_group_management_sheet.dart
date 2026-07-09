import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/category_group.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_colors.dart';

class SettingsCategoryGroupManagementSheet extends StatelessWidget {
  final bool isExpense;
  final Future<void> Function() onAddGroup;
  final Future<void> Function(CategoryGroup group) onEditGroup;

  const SettingsCategoryGroupManagementSheet({
    super.key,
    required this.isExpense,
    required this.onAddGroup,
    required this.onEditGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        final groups = provider.categoryGroups
            .where((group) => group.isExpense == isExpense)
            .toList(growable: false);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    isExpense ? '管理支出大类' : '管理收入大类',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onAddGroup,
                    child: const Text('新增大类'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '长按拖拽排序，可修改名称',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: groups.length,
                onReorder: (oldIndex, newIndex) async {
                  final updated = List<CategoryGroup>.from(groups);
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = updated.removeAt(oldIndex);
                  updated.insert(newIndex, item);
                  await provider.reorderCategoryGroups(updated);
                },
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final usageCount = provider.categories
                      .where((category) => category.groupId == group.id)
                      .length;

                  return Container(
                    key: Key(group.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          MdiIcons.menu,
                          color: const Color(0xFFD1D5DB),
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '包含 $usageCount 个分类',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onEditGroup(group),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
