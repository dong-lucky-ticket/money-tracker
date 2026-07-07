import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/record.dart';
import '../providers/data_provider.dart';
import '../widgets/add_record/add_record_header.dart';
import '../widgets/add_record/amount_keypad.dart';
import '../widgets/add_record/category_grid.dart';
import '../widgets/add_record/record_detail_panel.dart';
import 'categories_screen.dart';

class AddRecordScreen extends StatefulWidget {
  final Record? editRecord;

  const AddRecordScreen({super.key, this.editRecord});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  bool _isExpense = true;
  String _amountStr = '0.00';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _remarkController = TextEditingController();
  final FocusNode _remarkFocusNode = FocusNode();
  bool _isKeyboardVisible = false;
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();

    if (widget.editRecord != null) {
      _isExpense = widget.editRecord!.isExpense;
      _amountStr = widget.editRecord!.amount.toString();
      if (_amountStr.endsWith('.0')) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 2);
      }
      _selectedCategory = widget.editRecord!.category;
      _selectedDate = widget.editRecord!.date;
      _remarkController.text = widget.editRecord!.remark;
    }

    _remarkFocusNode.addListener(() {
      if (_remarkFocusNode.hasFocus) {
        setState(() {
          _isKeyboardVisible = true;
        });
      } else {
        // 延迟恢复自定义键盘，等待系统键盘收起动画完成，避免瞬间高度溢出
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() {
              _isKeyboardVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _remarkFocusNode.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (value == 'C') {
        _amountStr = '0';
      } else if (value == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else if (value == '00') {
        if (_amountStr != '0') {
          _amountStr += '00';
        }
      } else {
        if (_amountStr == '0' || _amountStr == '0.00') {
          _amountStr = value;
        } else {
          _amountStr += value;
        }
      }
    });
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFF59E0B), size: 48),
              const SizedBox(height: 16),
              Text(message,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('知道了',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveRecord() {
    if (_selectedCategory == null) {
      _showValidationDialog('请选择一个记账分类');
      return;
    }

    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      _showValidationDialog('请输入大于 0 的金额');
      return;
    }

    final now = DateTime.now();
    final record = Record(
      id: widget.editRecord?.id ?? const Uuid().v4(),
      amount: amount,
      category: _selectedCategory!,
      remark: _remarkController.text,
      date: _selectedDate,
      isExpense: _isExpense,
      isVoided: widget.editRecord?.isVoided ?? false,
      createdAt: widget.editRecord?.createdAt ?? now,
      updatedAt: now,
    );

    context.read<DataProvider>().addRecord(record);
    Navigator.pop(context);
  }

  void _resetSelection() {
    setState(() {
      _selectedCategory = null;
      _amountStr = '0.00';
      _selectedDate = DateTime.now();
      _remarkController.clear();
    });
  }

  void _handleTypeChanged(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      _selectedCategory = null;
      _amountStr = '0.00';
      _selectedDate = DateTime.now();
      _remarkController.clear();
    });
  }

  void _handleCategorySelected(Category category, String keyId) {
    final key = _categoryKeys.putIfAbsent(keyId, () => GlobalKey());
    setState(() => _selectedCategory = category);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _handleAmountFieldTap() {
    if (_remarkFocusNode.hasFocus) {
      _remarkFocusNode.unfocus();
    }
    if (_isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final categories =
        provider.categories.where((c) => c.isExpense == _isExpense).toList();
    final categoryGroups = provider.categoryGroups
        .where((group) => group.isExpense == _isExpense)
        .toList();
    final recentCategories = provider.recentCategories(
      isExpense: _isExpense,
    );
    if (_selectedCategory != null &&
        !categories.any((c) => c.id == _selectedCategory!.id)) {
      _selectedCategory = null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_selectedCategory != null) {
            _resetSelection();
          }
        },
        child: SafeArea(
            child: Column(children: [
          AddRecordHeader(
            isExpense: _isExpense,
            onTypeChanged: _handleTypeChanged,
            onCancel: () => Navigator.pop(context),
            onDone: _saveRecord,
          ),
          Expanded(
            child: CategoryGrid(
              categories: categories,
              categoryGroups: categoryGroups,
              recentCategories: recentCategories,
              selectedCategory: _selectedCategory,
              categoryKeys: _categoryKeys,
              onCategorySelected: _handleCategorySelected,
              onAddCategory: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoriesScreen(),
                  ),
                );
              },
            ),
          ),
          if (_selectedCategory != null)
            RecordDetailPanel(
              amountText: _amountStr,
              selectedDate: _selectedDate,
              remarkController: _remarkController,
              remarkFocusNode: _remarkFocusNode,
              isKeyboardVisible: _isKeyboardVisible,
              onAmountTap: _handleAmountFieldTap,
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
              },
            ),
          if (_selectedCategory != null && !_isKeyboardVisible)
            AmountKeypad(
              onKeyTap: _onKeypadTap,
              onSubmit: _saveRecord,
            ),
        ])),
      ),
    );
  }
}
