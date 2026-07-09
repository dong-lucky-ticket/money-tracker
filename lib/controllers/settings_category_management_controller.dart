import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/categories/category_editor_panel.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/settings/settings_category_group_management_sheet.dart';

class SettingsCategoryManagementController {
  const SettingsCategoryManagementController();

  void showAddCategoryDialog(
    BuildContext context, {
    required bool isExpense,
  }) {
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
              isExpense: isExpense,
              onClose: () => Navigator.pop(sheetContext),
            ),
          ),
        );
      },
    );
  }

  void confirmDelete(
    BuildContext context, {
    required Category category,
    required DataProvider provider,
  }) {
    final usageCount = provider.records
        .where((record) => record.category.id == category.id)
        .length;

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

  Future<void> showGroupNameDialog(
    BuildContext context,
    DataProvider provider, {
    required bool isExpense,
    CategoryGroup? group,
  }) async {
    final controller = TextEditingController(text: group?.name ?? '');
    final isEditing = group != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? '编辑大类' : '新增大类',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 6,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '输入大类名称',
              counterText: '',
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
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  AppToast.showError(context, '请输入大类名称');
                  return;
                }

                final duplicated = provider.categoryGroups.any(
                  (item) =>
                      item.isExpense == isExpense &&
                      item.name == name &&
                      item.id != group?.id,
                );
                if (duplicated) {
                  AppToast.showError(context, '该大类已存在，请修改名称');
                  return;
                }

                if (group == null) {
                  final newGroup = CategoryGroup(
                    id: const Uuid().v4(),
                    name: name,
                    isExpense: isExpense,
                    sortOrder: -1,
                  );
                  await provider.addCategoryGroup(newGroup);
                } else {
                  group.name = name;
                  await provider.updateCategoryGroup(group);
                }

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text(
                '保存',
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

  void showGroupManagementSheet(
    BuildContext context,
    DataProvider provider, {
    required bool isExpense,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: SafeArea(
            top: false,
            child: SettingsCategoryGroupManagementSheet(
              isExpense: isExpense,
              onAddGroup: () {
                return showGroupNameDialog(
                  context,
                  provider,
                  isExpense: isExpense,
                );
              },
              onEditGroup: (group) {
                return showGroupNameDialog(
                  context,
                  provider,
                  isExpense: isExpense,
                  group: group,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
