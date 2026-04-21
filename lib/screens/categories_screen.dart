import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../models/category.dart';
import '../utils/icon_mapper.dart';
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
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(MdiIcons.arrowLeft, size: 24, color: const Color(0xFF4B5563)),
                  ),
                  const Expanded(
                    child: Text(
                      '分类管理',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 24), // Balance the row
                ],
              ),
            ),
            
            // Tab 切换
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  _buildTab('支出分类', true),
                  const SizedBox(width: 32),
                  _buildTab('收入分类', false),
                ],
              ),
            ),
            
            // 内容列表
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, provider, child) {
                  final categories = provider.categories.where((c) => c.isExpense == _isExpense).toList();
                  
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final Category item = categories.removeAt(oldIndex);
                            categories.insert(newIndex, item);
                            provider.reorderCategories(categories);
                          },
                          children: categories.map((cat) {
                            return Container(
                              key: Key(cat.id),
                              child: _buildCategoryItem(cat, provider),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 新增分类按钮
                      GestureDetector(
                        onTap: () => _showAddCategoryDialog(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 2), // Instead of dashed
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(MdiIcons.plus, color: const Color(0xFF9CA3AF), size: 20),
                              const SizedBox(width: 8),
                              const Text('新增分类', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 底部说明
                      const Center(
                        child: Text('长按分类项目可以拖拽排序', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isExpense) {
    final isActive = _isExpense == isExpense;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpense),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF4A90E2) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF4A90E2) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category cat, DataProvider provider) {
    final color = _hexToColor(cat.colorHex);
    return Dismissible(
      key: Key('dismiss_${cat.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteCategory(cat.id);
      },
      background: Container(
        color: const Color(0xFFFF5A5A),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(IconMapper.getIcon(cat.iconName), color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
            ),
            Icon(MdiIcons.menu, color: const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String code) {
    if (code.startsWith('#')) code = code.substring(1);
    if (code.length == 6) code = 'FF$code';
    return Color(int.parse(code, radix: 16));
  }
}
