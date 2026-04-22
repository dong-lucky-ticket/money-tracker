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
        backgroundColor: Colors.white, // 确保系统状态栏背景色为白色
        body: SafeArea(
            bottom: false,
            child: Container(
              color: const Color(0xFFF7F9FC),
              child: Column(
                children: [
                  // 顶部导航
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(MdiIcons.arrowLeft,
                              size: 24, color: const Color(0xFF4B5563)),
                        ),
                        const Expanded(
                          child: Text(
                            '分类管理',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827)),
                          ),
                        ),
                        const SizedBox(width: 24), // Balance the row
                      ],
                    ),
                  ),

                  // Tab 切换
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
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
                        final categories = provider.categories
                            .where((c) => c.isExpense == _isExpense)
                            .toList();

                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: const Color(0xFFF3F4F6)),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.02),
                                            blurRadius: 4)
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ReorderableListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      onReorder: (oldIndex, newIndex) {
                                        if (oldIndex < newIndex) {
                                          newIndex -= 1;
                                        }
                                        final Category item =
                                            categories.removeAt(oldIndex);
                                        categories.insert(newIndex, item);
                                        provider.reorderCategories(categories);
                                      },
                                      children: categories.map((cat) {
                                        return Container(
                                          key: Key(cat.id),
                                          child:
                                              _buildCategoryItem(cat, provider),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 底部固定区域
                            SafeArea(
                              top: false,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 12, 20, 20), // 紧凑底部边距
                                color: const Color(0xFFF7F9FC),
                                child: Column(
                                  children: [
                                    // 新增分类按钮
                                    GestureDetector(
                                      onTap: () =>
                                          _showAddCategoryDialog(context),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12), // 紧凑按钮内边距
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                              width: 1.5), // 稍微调细边框
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(MdiIcons.plus,
                                                color: const Color(0xFF9CA3AF),
                                                size: 18),
                                            const SizedBox(width: 6),
                                            const Text('新增分类',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF9CA3AF))),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12), // 减小间距

                                    // 底部说明
                                    const Center(
                                      child: Text('长按分类项目可以拖拽排序',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9CA3AF))),
                                    ),
                                  ],
                                ),
                              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // 稍微减小垂直内边距，让列表更紧凑
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
        color: Colors.white, // 给拖拽对象添加背景色以优化动画显示
      ),
      child: Row(
        children: [
          // ReorderableListView 会在行末自动加上默认的拖拽手柄（如果没自定义拖拽区域），但这里我们自己实现或者保持原样。
          // 为了不和默认的拖拽冲突，我们可以使用 ReorderableDragStartListener 或者依然保留这个菜单图标。
          // 实际上 ReorderableListView 在桌面端/Web 端会把整个子组件作为可拖拽区域，移动端是长按整个子组件拖拽。
          Icon(MdiIcons.menu, color: const Color(0xFFD1D5DB), size: 20),
          const SizedBox(width: 16),
          Container(
            width: 36, // 缩小图标尺寸
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(IconMapper.getIcon(cat.iconName), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(cat.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, cat, provider),
            child: const Icon(Icons.delete_outline,
                color: Color(0xFFEF4444), size: 22),
          ),
        ],
      ),
    );
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

  Color _hexToColor(String code) {
    if (code.startsWith('#')) code = code.substring(1);
    if (code.length == 6) code = 'FF$code';
    return Color(int.parse(code, radix: 16));
  }
}
