import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/categories/category_bottom_actions.dart';
import '../widgets/categories/category_list_panel.dart';
import '../widgets/categories/category_management_header.dart';
import '../widgets/common/segmented_selector.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isExpense = true;

  void _showAddCategoryDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(isExpense: _isExpense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.pageBackground,
              child: Column(
                children: [
                  CategoryManagementHeader(
                    onBack: () => Navigator.pop(context),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: SizedBox(
                      width: 220,
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
                  ),

                  Expanded(
                    child: Consumer<DataProvider>(
                      builder: (context, provider, child) {
                        final categories = provider.categories
                            .where((c) => c.isExpense == _isExpense)
                            .toList();

                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  CategoryListPanel(
                                    categories: categories,
                                    onReorder: provider.reorderCategories,
                                    onDelete: (category) {
                                      _confirmDelete(context, category, provider);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            CategoryBottomActions(
                              onAdd: () => _showAddCategoryDialog(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            )));
  }

  void _confirmDelete(
      BuildContext context, Category cat, DataProvider provider) {
    final usageCount =
        provider.records.where((r) => r.category.id == cat.id).length;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('删除分类',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          content: Text(
            usageCount > 0
                ? '该分类已被使用 $usageCount 次。\n\n删除分类不会影响已记账的原始数据。\n\n确定要删除「${cat.name}」吗？'
                : '该分类暂未使用。\n\n确定要删除「${cat.name}」吗？',
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('取消', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                provider.deleteCategory(cat.id);
                Navigator.pop(ctx);
              },
              child: const Text('删除',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
