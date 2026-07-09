import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../providers/data_provider.dart';
import '../utils/color_utils.dart';
import '../utils/record_queries.dart';
import 'common/app_toast.dart';
import 'edit_record/edit_record_category_picker_sheet.dart';
import 'edit_record/edit_record_form_section.dart';

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
      AppToast.showError(context, '请输入大于 0 的金额');
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

  Future<void> _pickDate() async {
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
      setState(() {
        _selectedDate = picked;
      });
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
    final categories = categoriesForType(
      widget.provider.categories,
      isExpense: widget.record.isExpense,
    );
    final groups = categoryGroupsForType(
      widget.provider.categoryGroups,
      isExpense: widget.record.isExpense,
    );
    final recentCategories = recentCategoriesFromRecords(
      records: widget.provider.records,
      categories: widget.provider.categories,
      isExpense: widget.record.isExpense,
    );

    final selected = await EditRecordCategoryPickerSheet.show(
      context,
      isExpense: widget.record.isExpense,
      selectedCategory: _selectedCategory,
      categories: categories,
      groups: groups,
      recentCategories: recentCategories,
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: EditRecordFormSection(
        selectedCategory: _selectedCategory,
        categoryColor: colorFromHex(_selectedCategory.colorHex),
        categoryPath: _categoryPathFor(_selectedCategory),
        selectedDate: _selectedDate,
        amountController: _amountController,
        remarkController: _remarkController,
        onClose: () => Navigator.pop(context),
        onOpenCategoryPicker: _showCategoryPicker,
        onPickDate: _pickDate,
        onSave: _save,
      ),
    );
  }
}
