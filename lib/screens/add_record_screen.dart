import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../providers/data_provider.dart';
import '../models/category.dart';
import '../models/record.dart';
import '../utils/icon_mapper.dart';
import 'categories_screen.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

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

  void _saveRecord() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }
    
    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }

    final record = Record(
      id: const Uuid().v4(),
      amount: amount,
      category: _selectedCategory!,
      remark: _remarkController.text,
      date: _selectedDate,
      isExpense: _isExpense,
    );

    context.read<DataProvider>().addRecord(record);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<DataProvider>().categories.where((c) => c.isExpense == _isExpense).toList();
    if (_selectedCategory != null && !categories.any((c) => c.id == _selectedCategory!.id)) {
      _selectedCategory = null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          // 点击空白处收起系统键盘
          FocusScope.of(context).unfocus();
          // 隐藏已显示的功能控件
          if (_selectedCategory != null) {
            setState(() {
              _selectedCategory = null;
              _amountStr = '0.00';
              _selectedDate = DateTime.now();
              _remarkController.clear();
            });
          }
        },
        child: SafeArea(
          child: Column(
          children: [
            // 顶部导航
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton('支出', true),
                        _buildTabButton('收入', false),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saveRecord,
                    child: const Text('完成', style: TextStyle(color: Color(0xFF4A90E2), fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // 分类选择区
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return _buildAddCategoryBtn();
                  }
                  final cat = categories[index];
                  final isSelected = _selectedCategory?.id == cat.id;
                  return _buildCategoryItem(cat, isSelected);
                },
              ),
            ),
            
            if (_selectedCategory != null)
              // 底部功能区（金额、日期、备注）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // 拦截点击
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 金额显示
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                          ),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('金额 (CNY)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                              Row(
                                children: [
                                  Text(_amountStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                  Container(
                                    width: 4,
                                    height: 32,
                                    margin: const EdgeInsets.only(left: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A90E2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 备注和日期
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialEntryMode: DatePickerEntryMode.calendarOnly,
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(MdiIcons.calendarBlank, color: const Color(0xFF9CA3AF), size: 20),
                                const SizedBox(width: 12),
                                Text(DateFormat('yyyy年MM月dd日').format(_selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(MdiIcons.pencilOutline, color: const Color(0xFF9CA3AF), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _remarkController,
                                  focusNode: _remarkFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: '点击添加备注...',
                                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                                  onSubmitted: (_) {
                                    _remarkFocusNode.unfocus();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 数字键盘
            if (_selectedCategory != null && !_isKeyboardVisible)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // 拦截点击
                child: _buildKeypad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isExpense) {
    final isActive = _isExpense == isExpense;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpense = isExpense;
          _selectedCategory = null;
          _amountStr = '0.00';
          _selectedDate = DateTime.now();
          _remarkController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category cat, bool isSelected) {
    final color = _hexToColor(cat.colorHex);
    final key = _categoryKeys.putIfAbsent(cat.id, () => GlobalKey());

    return GestureDetector(
      key: key,
      onTap: () {
        setState(() => _selectedCategory = cat);
        // 延迟到下一帧，等待底部功能区出现、GridView 尺寸缩小后，确保选中的分类依然在可视区域内
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
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? color : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconMapper.getIcon(cat.iconName),
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(cat.name, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildAddCategoryBtn() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()));
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid, width: 1), // dashed usually requires custom painter, solid is fine
            ),
            child: Icon(MdiIcons.plus, color: const Color(0xFF9CA3AF), size: 28),
          ),
          const SizedBox(height: 8),
          const Text('添加', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      color: Colors.white,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildKey('1'), _buildKey('2'), _buildKey('3'), _buildKey('backspace', icon: MdiIcons.backspaceOutline, color: Colors.red),
          _buildKey('4'), _buildKey('5'), _buildKey('6'), _buildKey('C', color: Colors.grey),
          _buildKey('7'), _buildKey('8'), _buildKey('9'), _buildKey('', color: Colors.grey),
          _buildKey('00'), _buildKey('0'), _buildKey('.'), _buildKey('确定', isAction: true),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {IconData? icon, Color? color, bool isAction = false}) {
    if (value.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 0.5),
        ),
      );
    }
    return InkWell(
      onTap: isAction ? _saveRecord : () => _onKeypadTap(value),
      child: Container(
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFF4A90E2) : (color != null ? const Color(0xFFF9FAFB) : Colors.white),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 0.5),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: color)
            : Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: isAction ? Colors.white : (color ?? const Color(0xFF111827)),
                ),
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
