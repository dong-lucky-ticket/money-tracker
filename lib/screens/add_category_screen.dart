import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../providers/data_provider.dart';
import '../utils/category_icons.dart';

class AddCategoryScreen extends StatefulWidget {
  final bool isExpense;

  const AddCategoryScreen({super.key, required this.isExpense});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = 'gamepad-variant-outline';
  final Color _themeColor = const Color(0xFFFACC15); // Yellow from image

  @override
  void initState() {
    super.initState();
    // Default icon based on type
    _selectedIcon = widget.isExpense ? 'silverware-fork-knife' : 'cash-multiple';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入类别名称')));
      return;
    }
    if (name.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('类别名称不能超过4个字')));
      return;
    }

    final newCat = Category(
      id: const Uuid().v4(),
      name: name,
      iconName: _selectedIcon,
      colorHex: widget.isExpense ? '#F97316' : '#10B981', // Just default colors or yellow
      isExpense: widget.isExpense,
      sortOrder: 99,
    );
    context.read<DataProvider>().addCategory(newCat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 80, // Prevent folding
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF4B5563), fontSize: 16)),
        ),
        title: Text(
          widget.isExpense ? '添加支出类别' : '添加收入类别',
          style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('完成', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Selected Icon
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _themeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              getIconData(_selectedIcon),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: '输入类别名称 (不超过4个汉字)',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Icon Library
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: categoryIconGroups.length,
              itemBuilder: (context, index) {
                final group = categoryIconGroups[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        group.groupName,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24), // 左右边距
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 一行5个
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: group.icons.length,
                      itemBuilder: (context, idx) {
                        final iconName = group.icons[idx];
                        final isSelected = _selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = iconName;
                            });
                          },
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? _themeColor : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getIconData(iconName),
                                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}