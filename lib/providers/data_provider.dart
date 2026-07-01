import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/record.dart';

class CsvImportResult {
  final int importedCount;
  final int updatedCount;
  final int skippedCount;
  final int createdCategoryCount;

  const CsvImportResult({
    required this.importedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.createdCategoryCount,
  });

  int get processedCount => importedCount + updatedCount;
}

class DataProvider with ChangeNotifier {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String settingsBoxName = 'settingsBox';

  late Box<Record> _recordsBox;
  late Box<Category> _categoriesBox;
  late Box _settingsBox;

  List<Record> get records =>
      _recordsBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  List<Category> get categories => _categoriesBox.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
      Category(
          id: const Uuid().v4(),
          name: '餐饮',
          iconName: 'food',
          colorHex: '#F97316',
          isExpense: true,
          sortOrder: 0),
      Category(
          id: const Uuid().v4(),
          name: '购物',
          iconName: 'shopping',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 1),
      Category(
          id: const Uuid().v4(),
          name: '日用',
          iconName: 'daily',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 2),
      Category(
          id: const Uuid().v4(),
          name: '交通',
          iconName: 'transport',
          colorHex: '#14B8A6',
          isExpense: true,
          sortOrder: 3),
      Category(
          id: const Uuid().v4(),
          name: '蔬菜',
          iconName: 'vegetables',
          colorHex: '#10B981',
          isExpense: true,
          sortOrder: 4),
      Category(
          id: const Uuid().v4(),
          name: '水果',
          iconName: 'fruit',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 5),
      Category(
          id: const Uuid().v4(),
          name: '零食',
          iconName: 'snacks',
          colorHex: '#EC4899',
          isExpense: true,
          sortOrder: 6),
      Category(
          id: const Uuid().v4(),
          name: '娱乐',
          iconName: 'entertainment',
          colorHex: '#A855F7',
          isExpense: true,
          sortOrder: 7),
      Category(
          id: const Uuid().v4(),
          name: '通讯',
          iconName: 'communication',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 8),
      Category(
          id: const Uuid().v4(),
          name: '服饰',
          iconName: 'clothing',
          colorHex: '#EC4899',
          isExpense: true,
          sortOrder: 9),
      Category(
          id: const Uuid().v4(),
          name: '住房',
          iconName: 'housing',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 10),
      Category(
          id: const Uuid().v4(),
          name: '孩子',
          iconName: 'child',
          colorHex: '#14B8A6',
          isExpense: true,
          sortOrder: 11),
      Category(
          id: const Uuid().v4(),
          name: '长辈',
          iconName: 'elders',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 12),
      Category(
          id: const Uuid().v4(),
          name: '社交',
          iconName: 'social',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 13),
      Category(
          id: const Uuid().v4(),
          name: '旅行',
          iconName: 'travel',
          colorHex: '#10B981',
          isExpense: true,
          sortOrder: 14),
      Category(
          id: const Uuid().v4(),
          name: '烟酒',
          iconName: 'alcohol',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 15),
      Category(
          id: const Uuid().v4(),
          name: '数码',
          iconName: 'digital',
          colorHex: '#6366F1',
          isExpense: true,
          sortOrder: 16),
      Category(
          id: const Uuid().v4(),
          name: '汽车',
          iconName: 'car',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 17),
      Category(
          id: const Uuid().v4(),
          name: '医疗',
          iconName: 'medical',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 18),
      Category(
          id: const Uuid().v4(),
          name: '书籍',
          iconName: 'books',
          colorHex: '#8B5CF6',
          isExpense: true,
          sortOrder: 19),
      Category(
          id: const Uuid().v4(),
          name: '学习',
          iconName: 'study',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 20),
      Category(
          id: const Uuid().v4(),
          name: '礼金',
          iconName: 'gift-money',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 21),
      Category(
          id: const Uuid().v4(),
          name: '礼物',
          iconName: 'gift',
          colorHex: '#EC4899',
          isExpense: true,
          sortOrder: 22),
      Category(
          id: const Uuid().v4(),
          name: '办公',
          iconName: 'office',
          colorHex: '#64748B',
          isExpense: true,
          sortOrder: 23),
      Category(
          id: const Uuid().v4(),
          name: '维修',
          iconName: 'repair',
          colorHex: '#64748B',
          isExpense: true,
          sortOrder: 24),
      Category(
          id: const Uuid().v4(),
          name: '彩票',
          iconName: 'lottery',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 25),
      Category(
          id: const Uuid().v4(),
          name: '亲友',
          iconName: 'relatives',
          colorHex: '#F97316',
          isExpense: true,
          sortOrder: 26),
      Category(
          id: const Uuid().v4(),
          name: '快递',
          iconName: 'express',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 27),
      Category(
          id: const Uuid().v4(),
          name: '星愿',
          iconName: 'wish',
          colorHex: '#A855F7',
          isExpense: true,
          sortOrder: 28),
      Category(
          id: const Uuid().v4(),
          name: '火车高铁',
          iconName: 'train',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 29),
      Category(
          id: const Uuid().v4(),
          name: '话费',
          iconName: 'phone-bill',
          colorHex: '#14B8A6',
          isExpense: true,
          sortOrder: 30),
      Category(
          id: const Uuid().v4(),
          name: '生活缴费',
          iconName: 'utility',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 31),

      // === 收入 ===
      Category(
          id: const Uuid().v4(),
          name: '工资',
          iconName: 'salary',
          colorHex: '#10B981',
          isExpense: false,
          sortOrder: 0),
      Category(
          id: const Uuid().v4(),
          name: '兼职',
          iconName: 'part-time',
          colorHex: '#F59E0B',
          isExpense: false,
          sortOrder: 1),
      Category(
          id: const Uuid().v4(),
          name: '理财',
          iconName: 'investment',
          colorHex: '#3B82F6',
          isExpense: false,
          sortOrder: 2),
      Category(
          id: const Uuid().v4(),
          name: '礼金',
          iconName: 'gift-money-income',
          colorHex: '#EF4444',
          isExpense: false,
          sortOrder: 3),
      Category(
          id: const Uuid().v4(),
          name: '其它',
          iconName: 'other',
          colorHex: '#8B5CF6',
          isExpense: false,
          sortOrder: 4),
      Category(
          id: const Uuid().v4(),
          name: '彩票',
          iconName: 'lottery-income',
          colorHex: '#EF4444',
          isExpense: false,
          sortOrder: 5),
    ];
    for (var c in defaultCategories) {
      _categoriesBox.put(c.id, c);
    }
  }

  // --- Record Methods ---
  Future<void> addRecord(Record record) async {
    final now = DateTime.now();
    record.updatedAt = now;
    await _recordsBox.put(record.id, record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _recordsBox.delete(id);
    notifyListeners();
  }

  void refreshUI() {
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

  Future<CsvImportResult> importRecordsFromCsv(String csvContent) async {
    final sanitizedContent = csvContent.trim();
    if (sanitizedContent.isEmpty) {
      throw const FormatException('CSV 内容为空');
    }

    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(sanitizedContent);

    if (rows.isEmpty) {
      throw const FormatException('CSV 内容为空');
    }

    final categoryCache = <String, Category>{
      for (final category in _categoriesBox.values)
        _categoryCacheKey(category.name, category.isExpense): category,
    };

    final recordsToImport = <String, Record>{};
    var importedCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;
    var createdCategoryCount = 0;

    for (final row in rows) {
      if (_isEmptyRow(row)) {
        continue;
      }

      if (_isHeaderRow(row)) {
        continue;
      }

      if (row.length < 6) {
        skippedCount++;
        continue;
      }

      try {
        final id = _cellValue(row, 0).trim();
        final typeLabel = _cellValue(row, 1).trim();
        final amountText = _cellValue(row, 2).trim().replaceAll(',', '');
        final categoryName = _cellValue(row, 3).trim();
        final remark = _cellValue(row, 4);
        final dateText = _cellValue(row, 5).trim();

        final isExpense = _parseImportType(typeLabel);
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          throw const FormatException('金额无效');
        }

        final normalizedCategoryName =
            categoryName.isEmpty ? (isExpense ? '其他支出' : '其他收入') : categoryName;
        final cacheKey = _categoryCacheKey(normalizedCategoryName, isExpense);
        var category = categoryCache[cacheKey];

        if (category == null) {
          category = Category(
            id: const Uuid().v4(),
            name: normalizedCategoryName,
            iconName: 'other',
            colorHex: isExpense ? '#64748B' : '#10B981',
            isExpense: isExpense,
            sortOrder: _nextCategorySortOrder(isExpense),
          );
          await _categoriesBox.put(category.id, category);
          categoryCache[cacheKey] = category;
          createdCategoryCount++;
        }

        final recordId = id.isEmpty ? const Uuid().v4() : id;
        final record = Record(
          id: recordId,
          amount: amount,
          category: category,
          remark: remark,
          date: _parseImportDate(dateText),
          isExpense: isExpense,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (recordsToImport.containsKey(recordId) ||
            _recordsBox.containsKey(recordId)) {
          updatedCount++;
        } else {
          importedCount++;
        }

        recordsToImport[recordId] = record;
      } catch (_) {
        skippedCount++;
      }
    }

    if (recordsToImport.isEmpty) {
      throw const FormatException('未识别到可导入的记录，请确认 CSV 格式与导出一致');
    }

    await _recordsBox.putAll(recordsToImport);
    notifyListeners();

    return CsvImportResult(
      importedCount: importedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
      createdCategoryCount: createdCategoryCount,
    );
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
        .where((r) =>
            r.isExpense &&
            !r.isVoided &&
            r.date.year == now.year &&
            r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return records
        .where((r) =>
            !r.isExpense &&
            !r.isVoided &&
            r.date.year == now.year &&
            r.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense => records
      .where((r) => r.isExpense && !r.isVoided)
      .fold(0.0, (sum, item) => sum + item.amount);
  double get totalIncome => records
      .where((r) => !r.isExpense && !r.isVoided)
      .fold(0.0, (sum, item) => sum + item.amount);

  int get activeCategoryCount {
    final usedCategoryIds =
        records.where((record) => !record.isVoided).map((e) => e.category.id).toSet();
    return usedCategoryIds.length;
  }

  bool _isEmptyRow(List<dynamic> row) {
    return row.every((cell) => cell.toString().trim().isEmpty);
  }

  bool _isHeaderRow(List<dynamic> row) {
    return row.isNotEmpty && _normalizeHeader(row.first.toString()) == 'id';
  }

  String _cellValue(List<dynamic> row, int index) {
    if (index >= row.length) {
      return '';
    }
    return row[index]?.toString() ?? '';
  }

  String _normalizeHeader(String value) {
    return value.replaceFirst('\uFEFF', '').trim().toLowerCase();
  }

  bool _parseImportType(String value) {
    final normalized = value.trim().toLowerCase();
    const expenseValues = {'支出', 'expense', 'exp', 'out', '1', 'true', '鏀嚭'};
    const incomeValues = {'收入', 'income', 'in', '0', 'false', '鏀跺叆'};

    if (expenseValues.contains(normalized)) {
      return true;
    }
    if (incomeValues.contains(normalized)) {
      return false;
    }
    throw const FormatException('类型无效');
  }

  DateTime _parseImportDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const FormatException('日期为空');
    }

    final formats = [
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('yyyy-MM-dd'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(normalized);
      } catch (_) {
        // Keep trying other supported export-compatible formats.
      }
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }

    throw const FormatException('日期格式无效');
  }

  String _categoryCacheKey(String name, bool isExpense) {
    return '${isExpense ? 'expense' : 'income'}::${name.trim()}';
  }

  int _nextCategorySortOrder(bool isExpense) {
    var maxSortOrder = -1;
    for (final category in _categoriesBox.values) {
      if (category.isExpense == isExpense &&
          category.sortOrder > maxSortOrder) {
        maxSortOrder = category.sortOrder;
      }
    }
    return maxSortOrder + 1;
  }
}
