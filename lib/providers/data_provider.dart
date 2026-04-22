import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/record.dart';

class DataProvider with ChangeNotifier {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String settingsBoxName = 'settingsBox';

  late Box<Record> _recordsBox;
  late Box<Category> _categoriesBox;
  late Box _settingsBox;

  List<Record> get records => _recordsBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  List<Category> get categories => _categoriesBox.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  Future<void> init() async {
    _recordsBox = await Hive.openBox<Record>(recordsBoxName);
    _categoriesBox = await Hive.openBox<Category>(categoriesBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    _isDarkTheme = _settingsBox.get('isDarkTheme', defaultValue: false);

    // 如果分类太少，自动重新初始化（方便演示更新的分类）
    if (_categoriesBox.length < 15) {
      await _categoriesBox.clear();
      _initDefaultCategories();
    }
  }

  void _initDefaultCategories() {
    final defaultCategories = [
      // === 支出 ===
      Category(id: const Uuid().v4(), name: '餐饮', iconName: 'food', colorHex: '#F97316', isExpense: true, sortOrder: 0),
      Category(id: const Uuid().v4(), name: '购物', iconName: 'shopping', colorHex: '#EF4444', isExpense: true, sortOrder: 1),
      Category(id: const Uuid().v4(), name: '日用', iconName: 'daily', colorHex: '#3B82F6', isExpense: true, sortOrder: 2),
      Category(id: const Uuid().v4(), name: '交通', iconName: 'transport', colorHex: '#14B8A6', isExpense: true, sortOrder: 3),
      Category(id: const Uuid().v4(), name: '蔬菜', iconName: 'vegetables', colorHex: '#10B981', isExpense: true, sortOrder: 4),
      Category(id: const Uuid().v4(), name: '水果', iconName: 'fruit', colorHex: '#F59E0B', isExpense: true, sortOrder: 5),
      Category(id: const Uuid().v4(), name: '零食', iconName: 'snacks', colorHex: '#EC4899', isExpense: true, sortOrder: 6),
      Category(id: const Uuid().v4(), name: '娱乐', iconName: 'entertainment', colorHex: '#A855F7', isExpense: true, sortOrder: 7),
      Category(id: const Uuid().v4(), name: '通讯', iconName: 'communication', colorHex: '#3B82F6', isExpense: true, sortOrder: 8),
      Category(id: const Uuid().v4(), name: '服饰', iconName: 'clothing', colorHex: '#EC4899', isExpense: true, sortOrder: 9),
      Category(id: const Uuid().v4(), name: '住房', iconName: 'housing', colorHex: '#F59E0B', isExpense: true, sortOrder: 10),
      Category(id: const Uuid().v4(), name: '孩子', iconName: 'child', colorHex: '#14B8A6', isExpense: true, sortOrder: 11),
      Category(id: const Uuid().v4(), name: '长辈', iconName: 'elders', colorHex: '#EF4444', isExpense: true, sortOrder: 12),
      Category(id: const Uuid().v4(), name: '社交', iconName: 'social', colorHex: '#3B82F6', isExpense: true, sortOrder: 13),
      Category(id: const Uuid().v4(), name: '旅行', iconName: 'travel', colorHex: '#10B981', isExpense: true, sortOrder: 14),
      Category(id: const Uuid().v4(), name: '烟酒', iconName: 'alcohol', colorHex: '#EF4444', isExpense: true, sortOrder: 15),
      Category(id: const Uuid().v4(), name: '数码', iconName: 'digital', colorHex: '#6366F1', isExpense: true, sortOrder: 16),
      Category(id: const Uuid().v4(), name: '汽车', iconName: 'car', colorHex: '#3B82F6', isExpense: true, sortOrder: 17),
      Category(id: const Uuid().v4(), name: '医疗', iconName: 'medical', colorHex: '#EF4444', isExpense: true, sortOrder: 18),
      Category(id: const Uuid().v4(), name: '书籍', iconName: 'books', colorHex: '#8B5CF6', isExpense: true, sortOrder: 19),
      Category(id: const Uuid().v4(), name: '学习', iconName: 'study', colorHex: '#F59E0B', isExpense: true, sortOrder: 20),
      Category(id: const Uuid().v4(), name: '礼金', iconName: 'gift-money', colorHex: '#EF4444', isExpense: true, sortOrder: 21),
      Category(id: const Uuid().v4(), name: '礼物', iconName: 'gift', colorHex: '#EC4899', isExpense: true, sortOrder: 22),
      Category(id: const Uuid().v4(), name: '办公', iconName: 'office', colorHex: '#64748B', isExpense: true, sortOrder: 23),
      Category(id: const Uuid().v4(), name: '维修', iconName: 'repair', colorHex: '#64748B', isExpense: true, sortOrder: 24),
      Category(id: const Uuid().v4(), name: '彩票', iconName: 'lottery', colorHex: '#EF4444', isExpense: true, sortOrder: 25),
      Category(id: const Uuid().v4(), name: '亲友', iconName: 'relatives', colorHex: '#F97316', isExpense: true, sortOrder: 26),
      Category(id: const Uuid().v4(), name: '快递', iconName: 'express', colorHex: '#F59E0B', isExpense: true, sortOrder: 27),
      Category(id: const Uuid().v4(), name: '星愿', iconName: 'wish', colorHex: '#A855F7', isExpense: true, sortOrder: 28),
      Category(id: const Uuid().v4(), name: '火车高铁', iconName: 'train', colorHex: '#3B82F6', isExpense: true, sortOrder: 29),
      Category(id: const Uuid().v4(), name: '话费', iconName: 'phone-bill', colorHex: '#14B8A6', isExpense: true, sortOrder: 30),
      Category(id: const Uuid().v4(), name: '生活缴费', iconName: 'utility', colorHex: '#3B82F6', isExpense: true, sortOrder: 31),

      // === 收入 ===
      Category(id: const Uuid().v4(), name: '工资', iconName: 'salary', colorHex: '#10B981', isExpense: false, sortOrder: 0),
      Category(id: const Uuid().v4(), name: '兼职', iconName: 'part-time', colorHex: '#F59E0B', isExpense: false, sortOrder: 1),
      Category(id: const Uuid().v4(), name: '理财', iconName: 'investment', colorHex: '#3B82F6', isExpense: false, sortOrder: 2),
      Category(id: const Uuid().v4(), name: '礼金', iconName: 'gift-money-income', colorHex: '#EF4444', isExpense: false, sortOrder: 3),
      Category(id: const Uuid().v4(), name: '其它', iconName: 'other', colorHex: '#8B5CF6', isExpense: false, sortOrder: 4),
      Category(id: const Uuid().v4(), name: '彩票', iconName: 'lottery-income', colorHex: '#EF4444', isExpense: false, sortOrder: 5),
    ];
    for (var c in defaultCategories) {
      _categoriesBox.put(c.id, c);
    }
  }

  // --- Record Methods ---
  Future<void> addRecord(Record record) async {
    await _recordsBox.put(record.id, record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _recordsBox.delete(id);
    notifyListeners();
  }

  // --- Category Methods ---
  Future<void> addCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
    notifyListeners();
  }

  Future<void> reorderCategories(List<Category> newOrderList) async {
    // 1. 立即在内存中更新排序，并同步通知UI刷新
    // 这样 ReorderableListView 能够立刻获取到最新顺序，避免拖拽松手后“回弹再动画”的冗余表现
    for (int i = 0; i < newOrderList.length; i++) {
      newOrderList[i].sortOrder = i;
    }
    notifyListeners();

    // 2. 随后在后台异步持久化到本地存储
    for (var cat in newOrderList) {
      await _categoriesBox.put(cat.id, cat);
    }
  }
  
  Future<void> clearAllData() async {
    await _recordsBox.clear();
    notifyListeners();
  }

  // --- Settings ---
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _settingsBox.put('isDarkTheme', _isDarkTheme);
    notifyListeners();
  }
  
  // --- Stats ---
  double get monthlyExpense {
    final now = DateTime.now();
    return records
        .where((r) => r.isExpense && r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return records
        .where((r) => !r.isExpense && r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }
  
  double get totalExpense => records.where((r) => r.isExpense).fold(0.0, (sum, item) => sum + item.amount);
  double get totalIncome => records.where((r) => !r.isExpense).fold(0.0, (sum, item) => sum + item.amount);
  
  int get activeCategoryCount {
    final usedCategoryIds = records.map((e) => e.category.id).toSet();
    return usedCategoryIds.length;
  }
}
