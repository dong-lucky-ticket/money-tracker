import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../../providers/data_provider.dart';
import '../../utils/category_icons.dart';

class CategoryEditorPanel extends StatefulWidget {
  final bool isExpense;
  final VoidCallback onClose;

  const CategoryEditorPanel({
    super.key,
    required this.isExpense,
    required this.onClose,
  });

  @override
  State<CategoryEditorPanel> createState() => _CategoryEditorPanelState();
}

class _CategoryEditorPanelState extends State<CategoryEditorPanel> {
  final TextEditingController _nameController = TextEditingController();
  final Color _themeColor = const Color(0xFF4A90E2);
  String _selectedIcon = 'gamepad-variant-outline';

  @override
  void initState() {
    super.initState();
    _selectedIcon =
        widget.isExpense ? 'silverware-fork-knife' : 'cash-multiple';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _restoreHistoryCategory(
    DataProvider provider,
    Category historyCategory,
  ) {
    final restoredCategory = Category(
      id: historyCategory.id,
      name: historyCategory.name,
      iconName: historyCategory.iconName,
      colorHex: historyCategory.colorHex,
      isExpense: historyCategory.isExpense,
      sortOrder: 99,
    );
    provider.addCategory(restoredCategory);
    widget.onClose();
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('请输入类别名称');
      return;
    }
    if (name.length > 4) {
      _showMessage('类别名称不能超过4个字');
      return;
    }

    final provider = context.read<DataProvider>();
    final isAlreadyActive = provider.categories.any((category) =>
        category.isExpense == widget.isExpense &&
        category.name == name &&
        category.iconName == _selectedIcon);

    if (isAlreadyActive) {
      _showMessage('该分类已存在，请修改名称或图标');
      return;
    }

    Category? historyCategory;
    for (final record in provider.records) {
      if (record.category.isExpense == widget.isExpense &&
          record.category.name == name &&
          record.category.iconName == _selectedIcon) {
        historyCategory = record.category;
        break;
      }
    }

    if (historyCategory != null) {
      final categoryToRestore = historyCategory;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '发现历史同名分类',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            content: const Text(
              '检测到历史记账数据中曾使用过该分类。\n\n是否与历史数据关联？\n选择【关联】将恢复该分类；\n选择【不关联】则必须修改当前分类的名称或图标才能添加。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  '取消',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showMessage('为了避免数据混乱，请修改分类名称或图标');
                },
                child: const Text(
                  '不关联',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _restoreHistoryCategory(provider, categoryToRestore);
                },
                child: const Text(
                  '关联并添加',
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
      return;
    }

    final category = Category(
      id: const Uuid().v4(),
      name: name,
      iconName: _selectedIcon,
      colorHex: widget.isExpense ? '#F97316' : '#10B981',
      isExpense: widget.isExpense,
      sortOrder: 99,
    );
    provider.addCategory(category);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.isExpense ? '添加支出类别' : '添加收入类别',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    '完成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomInset + 40),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
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
                ),
                const SizedBox(height: 16),
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
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                for (final group in categoryIconGroups) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      group.groupName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: group.icons.length,
                    itemBuilder: (context, index) {
                      final iconName = group.icons[index];
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
                              color: isSelected
                                  ? _themeColor
                                  : const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              getIconData(iconName),
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
