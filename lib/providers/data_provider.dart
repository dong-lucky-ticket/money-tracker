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

    if (_categoriesBox.isEmpty) {
      _initDefaultCategories();
    }
  }

  void _initDefaultCategories() {
    final defaultCategories = [
      Category(id: const Uuid().v4(), name: '餐饮美食', iconName: 'food', colorHex: '#F97316', isExpense: true, sortOrder: 0),
      Category(id: const Uuid().v4(), name: '购物消费', iconName: 'shopping', colorHex: '#A855F7', isExpense: true, sortOrder: 1),
      Category(id: const Uuid().v4(), name: '交通出行', iconName: 'bus', colorHex: '#3B82F6', isExpense: true, sortOrder: 2),
      Category(id: const Uuid().v4(), name: '房屋居住', iconName: 'home-variant', colorHex: '#EF4444', isExpense: true, sortOrder: 3),
      Category(id: const Uuid().v4(), name: '休闲娱乐', iconName: 'movie', colorHex: '#EC4899', isExpense: true, sortOrder: 4),
      Category(id: const Uuid().v4(), name: '医疗保健', iconName: 'hospital', colorHex: '#14B8A6', isExpense: true, sortOrder: 5),
      Category(id: const Uuid().v4(), name: '教育培训', iconName: 'school', colorHex: '#F59E0B', isExpense: true, sortOrder: 6),
      Category(id: const Uuid().v4(), name: '工资收入', iconName: 'cash-multiple', colorHex: '#10B981', isExpense: false, sortOrder: 0),
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
