import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../utils/color_utils.dart';
import '../utils/icon_mapper.dart';

class EditRecordSheet extends StatefulWidget {
  final Record record;
  final DataProvider provider;

  const EditRecordSheet({
    super.key,
    required this.record,
    required this.provider,
  });

  @override
  State<EditRecordSheet> createState() => _EditRecordSheetState();
}

class _EditRecordSheetState extends State<EditRecordSheet> {
  late TextEditingController _amountController;
  late TextEditingController _remarkController;
  late Category _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.record.amount.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
    _remarkController = TextEditingController(text: widget.record.remark);
    _selectedCategory = widget.record.category;
    _selectedDate = widget.record.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入大于 0 的金额')),
      );
      return;
    }

    await widget.provider.updateRecord(
      widget.record,
      amount: amount,
      category: _selectedCategory,
      remark: _remarkController.text,
      date: _selectedDate,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _groupNameFor(Category category) {
    for (final group in widget.provider.categoryGroups) {
      if (group.id == category.groupId) {
        return group.name;
      }
    }
    return category.groupId.isEmpty ? '未分组' : '未命名大类';
  }

  String _categoryPathFor(Category category) {
    return '${_groupNameFor(category)} / ${category.name}';
  }

  Future<void> _showCategoryPicker() async {
    FocusScope.of(context).unfocus();
    final categories = widget.provider.categories
        .where((category) => category.isExpense == widget.record.isExpense)
        .toList();
    final groups = widget.provider.categoryGroups
        .where((group) => group.isExpense == widget.record.isExpense)
        .toList();
    final recentCategories = widget.provider.recentCategories(
      isExpense: widget.record.isExpense,
    );

    if (categories.isEmpty) {
      return;
    }

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

    final visibleGroups = groups
        .where((group) => (groupedCategories[group.id] ?? const []).isNotEmpty)
        .toList();

    final selected = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '选择分类',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.record.isExpense ? '支出分类' : '收入分类',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  children: [
                    if (recentCategories.isNotEmpty) ...[
                      _CategoryPickerSection(
                        title: '最近使用',
                        categories: recentCategories,
                        selectedCategory: _selectedCategory,
                        onTapCategory: (category) =>
                            Navigator.pop(sheetContext, category),
                      ),
                      const SizedBox(height: 20),
                    ],
                    for (final group in visibleGroups) ...[
                      _CategoryPickerSection(
                        title: group.name,
                        categories: groupedCategories[group.id] ?? const [],
                        selectedCategory: _selectedCategory,
                        onTapCategory: (category) =>
                            Navigator.pop(sheetContext, category),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (ungroupedCategories.isNotEmpty)
                      _CategoryPickerSection(
                        title: '未分组',
                        categories: ungroupedCategories,
                        selectedCategory: _selectedCategory,
                        onTapCategory: (category) =>
                            Navigator.pop(sheetContext, category),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = colorFromHex(_selectedCategory.colorHex);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '编辑账单',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconMapper.getIcon(_selectedCategory.iconName),
                        color: categoryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '账单分类',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _categoryPathFor(_selectedCategory),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '更换',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    MdiIcons.informationOutline,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '只能更换同类型分类，避免影响这条账单的收支属性。',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                labelText: '金额',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.normal,
                ),
                prefixText: '¥ ',
                prefixStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A90E2),
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4A90E2),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF1F2937),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                labelText: '备注',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A90E2),
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '保存修改',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final Category selectedCategory;
  final ValueChanged<Category> onTapCategory;

  const _CategoryPickerSection({
    required this.title,
    required this.categories,
    required this.selectedCategory,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 18,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedCategory.id;
            return _EditableCategoryItem(
              category: category,
              isSelected: isSelected,
              onTap: () => onTapCategory(category),
            );
          },
        ),
      ],
    );
  }
}

class _EditableCategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditableCategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.surfaceSoft,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              IconMapper.getIcon(category.iconName),
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
