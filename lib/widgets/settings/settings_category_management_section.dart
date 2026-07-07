import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../../models/category_group.dart';
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

  Future<void> _showGroupNameDialog(
    BuildContext context,
    DataProvider provider, {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入大类名称')),
                  );
                  return;
                }

                final duplicated = provider.categoryGroups.any(
                  (item) =>
                      item.isExpense == _isExpense &&
                      item.name == name &&
                      item.id != group?.id,
                );
                if (duplicated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('该大类已存在，请修改名称')),
                  );
                  return;
                }

                if (group == null) {
                  final newGroup = CategoryGroup(
                    id: const Uuid().v4(),
                    name: name,
                    isExpense: _isExpense,
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

  void _showGroupManagementSheet(
    BuildContext context,
    DataProvider provider,
  ) {
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
            child: StatefulBuilder(
              builder: (sheetContext, setSheetState) {
                final groups = provider.categoryGroups
                    .where((group) => group.isExpense == _isExpense)
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            _isExpense ? '管理支出大类' : '管理收入大类',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showGroupNameDialog(
                              context,
                              provider,
                            ),
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
                          setSheetState(() {});
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  onPressed: () => _showGroupNameDialog(
                                    context,
                                    provider,
                                    group: group,
                                  ),
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
            ),
          ),
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
                final groups = provider.categoryGroups
                    .where((group) => group.isExpense == _isExpense)
                    .toList();
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
                              isExpense: _isExpense,
                              newOrderList: updated,
                            );
                          },
                          onDelete: (category) {
                            _confirmDelete(context, category, provider);
                          },
                        ),
                    if (ungroupedCategories.isNotEmpty)
                      _CategoryGroupSection(
                        title: '未分组',
                        categories: ungroupedCategories,
                        onReorder: (updated) {
                          provider.reorderCategoriesInGroup(
                            groupId: '',
                            isExpense: _isExpense,
                            newOrderList: updated,
                          );
                        },
                        onDelete: (category) {
                          _confirmDelete(context, category, provider);
                        },
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
                            onTap: () =>
                                _showGroupManagementSheet(context, provider),
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
                                  Icon(
                                    MdiIcons.viewListOutline,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isExpense ? '管理支出大类' : '管理收入大类',
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
