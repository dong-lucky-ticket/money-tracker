import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/category_group.dart';
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

class DataSyncProgress {
  final String message;
  final String? detail;
  final int processed;
  final int total;
  final bool isIndeterminate;

  const DataSyncProgress({
    required this.message,
    this.detail,
    this.processed = 0,
    this.total = 0,
    this.isIndeterminate = false,
  });

  double? get value {
    if (isIndeterminate || total <= 0) {
      return null;
    }
    return processed / total;
  }
}

class DataProvider with ChangeNotifier {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String categoryGroupsBoxName = 'categoryGroupsBox';
  static const String settingsBoxName = 'settingsBox';
  static const String recordGroupMigrationVersionKey =
      'recordGroupMigrationVersion';
  static const int currentRecordGroupMigrationVersion = 4;
  static const _deprecatedDefaultCategoryKeys = {
    'expense::娱乐::entertainment',
    'expense::社交::social',
    'expense::学习::study',
    'expense::礼物::gift',
    'expense::维修::repair',
    'expense::亲友::relatives',
    'expense::快递::express',
    'expense::话费::phone-bill',
    'expense::生活缴费::utility',
  };

  late Box<Record> _recordsBox;
  late Box<Category> _categoriesBox;
  late Box<CategoryGroup> _categoryGroupsBox;
  late Box _settingsBox;

  List<Record> get records =>
      _recordsBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  List<CategoryGroup> get categoryGroups => _categoryGroupsBox.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  List<Category> get categories => _categoriesBox.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  Future<void> init({
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    onProgress?.call(
      const DataSyncProgress(
        message: '正在准备本地数据',
        detail: '初始化账本与分类信息',
        isIndeterminate: true,
      ),
    );

    _recordsBox = await Hive.openBox<Record>(recordsBoxName);
    _categoriesBox = await Hive.openBox<Category>(categoriesBoxName);
    _categoryGroupsBox =
        await Hive.openBox<CategoryGroup>(categoryGroupsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    _isDarkTheme = _settingsBox.get('isDarkTheme', defaultValue: false);

    await _syncDefaultCategoryGroups();
    await _syncDefaultCategories();
    await _migrateRecordCategoryGroups(onProgress: onProgress);
  }

  Future<void> _syncDefaultCategoryGroups() async {
    final defaultGroups = buildDefaultCategoryGroups();

    for (final group in defaultGroups) {
      final existing = _categoryGroupsBox.get(group.id);
      if (existing == null) {
        await _categoryGroupsBox.put(group.id, group);
        continue;
      }

      var changed = false;
      if (existing.name != group.name) {
        existing.name = group.name;
        changed = true;
      }
      if (existing.isExpense != group.isExpense) {
        existing.isExpense = group.isExpense;
        changed = true;
      }
      if (existing.sortOrder != group.sortOrder) {
        existing.sortOrder = group.sortOrder;
        changed = true;
      }

      if (changed) {
        await _categoryGroupsBox.put(existing.id, existing);
      }
    }
  }

  Future<void> _syncDefaultCategories() async {
    final defaultCategories = _buildDefaultCategories();

    if (_categoriesBox.isEmpty) {
      for (final category in defaultCategories) {
        await _categoriesBox.put(category.id, category);
      }
    } else {
      await _syncLegacyDefaultCategories();
      await _removeDeprecatedDefaultCategories();
      await _addMissingDefaultCategories(defaultCategories);
    }

    await _backfillCategoryGroupIds();
  }

  List<Category> _buildDefaultCategories() {
    final categories = [
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
          name: '蔬菜',
          iconName: 'vegetables',
          colorHex: '#10B981',
          isExpense: true,
          sortOrder: 1),
      Category(
          id: const Uuid().v4(),
          name: '水果',
          iconName: 'fruit',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 2),
      Category(
          id: const Uuid().v4(),
          name: '零食',
          iconName: 'snacks',
          colorHex: '#EC4899',
          isExpense: true,
          sortOrder: 3),
      Category(
          id: const Uuid().v4(),
          name: '话费',
          iconName: 'phone-bill',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 4),
      Category(
          id: const Uuid().v4(),
          name: '住房',
          iconName: 'housing',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 5),
      Category(
          id: const Uuid().v4(),
          name: '办公',
          iconName: 'office',
          colorHex: '#64748B',
          isExpense: true,
          sortOrder: 6),
      Category(
          id: const Uuid().v4(),
          name: '水费',
          iconName: 'water-outline',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 7),
      Category(
          id: const Uuid().v4(),
          name: '电费',
          iconName: 'lightning-bolt-outline',
          colorHex: '#F59E0B',
          isExpense: true,
          sortOrder: 8),
      Category(
          id: const Uuid().v4(),
          name: '燃气费',
          iconName: 'fire',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 9),
      Category(
          id: const Uuid().v4(),
          name: '交通',
          iconName: 'transport',
          colorHex: '#14B8A6',
          isExpense: true,
          sortOrder: 10),
      Category(
          id: const Uuid().v4(),
          name: '旅行',
          iconName: 'travel',
          colorHex: '#10B981',
          isExpense: true,
          sortOrder: 11),
      Category(
          id: const Uuid().v4(),
          name: '汽车',
          iconName: 'car',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 12),
      Category(
          id: const Uuid().v4(),
          name: '摩托',
          iconName: 'motorcycle',
          colorHex: '#0EA5E9',
          isExpense: true,
          sortOrder: 13),
      Category(
          id: const Uuid().v4(),
          name: '火车高铁',
          iconName: 'train',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 14),
      Category(
          id: const Uuid().v4(),
          name: '购物',
          iconName: 'shopping',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 15),
      Category(
          id: const Uuid().v4(),
          name: '日用',
          iconName: 'daily',
          colorHex: '#3B82F6',
          isExpense: true,
          sortOrder: 16),
      Category(
          id: const Uuid().v4(),
          name: '服饰',
          iconName: 'clothing',
          colorHex: '#EC4899',
          isExpense: true,
          sortOrder: 17),
      Category(
          id: const Uuid().v4(),
          name: '数码',
          iconName: 'digital',
          colorHex: '#6366F1',
          isExpense: true,
          sortOrder: 18),
      Category(
          id: const Uuid().v4(),
          name: '孩子',
          iconName: 'child',
          colorHex: '#14B8A6',
          isExpense: true,
          sortOrder: 19),
      Category(
          id: const Uuid().v4(),
          name: '长辈',
          iconName: 'elders',
          colorHex: '#EF4444',
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
          name: '医疗',
          iconName: 'medical',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 22),
      Category(
          id: const Uuid().v4(),
          name: '书籍',
          iconName: 'books',
          colorHex: '#8B5CF6',
          isExpense: true,
          sortOrder: 23),
      Category(
          id: const Uuid().v4(),
          name: '烟酒',
          iconName: 'alcohol',
          colorHex: '#EF4444',
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
          name: '星愿',
          iconName: 'wish',
          colorHex: '#A855F7',
          isExpense: true,
          sortOrder: 26),

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

    for (final category in categories) {
      _ensureCategoryGroupId(category);
    }

    return categories;
  }

  Future<void> _removeDeprecatedDefaultCategories() async {
    final categoriesToDelete = _categoriesBox.values.where((category) {
      return _deprecatedDefaultCategoryKeys.contains(
        _defaultCategoryKey(
          name: category.name,
          iconName: category.iconName,
          isExpense: category.isExpense,
        ),
      );
    }).toList();

    for (final category in categoriesToDelete) {
      await _categoriesBox.delete(category.id);
    }
  }

  Future<void> _syncLegacyDefaultCategories() async {
    for (final category in _categoriesBox.values) {
      var changed = false;

      if (_isLegacyCommunicationCategory(category)) {
        category.name = '话费';
        category.iconName = 'phone-bill';
        changed = true;
      }

      if (_isDefaultDailyCategory(category) &&
          category.groupId != CategoryGroupIds.expenseShopping) {
        category.groupId = CategoryGroupIds.expenseShopping;
        changed = true;
      }

      if (!changed) {
        continue;
      }

      _ensureCategoryGroupId(category);
      await _categoriesBox.put(category.id, category);
    }
  }

  Future<void> _addMissingDefaultCategories(
      List<Category> defaultCategories) async {
    final existingKeys = {
      for (final category in _categoriesBox.values)
        _defaultCategoryKey(
          name: category.name,
          iconName: category.iconName,
          isExpense: category.isExpense,
        ),
    };

    for (final category in defaultCategories) {
      final key = _defaultCategoryKey(
        name: category.name,
        iconName: category.iconName,
        isExpense: category.isExpense,
      );
      if (!existingKeys.contains(key)) {
        await _categoriesBox.put(category.id, category);
      }
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
    _ensureCategoryGroupId(category);
    await _categoriesBox.put(category.id, category);
    notifyListeners();
  }

  // --- Category Group Methods ---
  Future<void> addCategoryGroup(CategoryGroup group) async {
    if (group.sortOrder < 0) {
      group.sortOrder = _nextCategoryGroupSortOrder(group.isExpense);
    }
    await _categoryGroupsBox.put(group.id, group);
    notifyListeners();
  }

  Future<void> updateCategoryGroup(CategoryGroup group) async {
    await _categoryGroupsBox.put(group.id, group);
    notifyListeners();
  }

  Future<void> reorderCategoryGroups(List<CategoryGroup> newOrderList) async {
    for (int i = 0; i < newOrderList.length; i++) {
      newOrderList[i].sortOrder = i;
    }
    notifyListeners();

    for (final group in newOrderList) {
      await _categoryGroupsBox.put(group.id, group);
    }
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

  Future<void> reorderCategoriesInGroup({
    required String groupId,
    required bool isExpense,
    required List<Category> newOrderList,
  }) async {
    for (int i = 0; i < newOrderList.length; i++) {
      newOrderList[i].sortOrder = i;
    }
    notifyListeners();

    for (final category in newOrderList) {
      await _categoriesBox.put(category.id, category);
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
          _ensureCategoryGroupId(category);
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
    final usedCategoryIds = records
        .where((record) => !record.isVoided)
        .map((e) => e.category.id)
        .toSet();
    return usedCategoryIds.length;
  }

  List<Category> recentCategories({
    required bool isExpense,
    int limit = 4,
  }) {
    final activeCategories = {
      for (final category in _categoriesBox.values)
        if (category.isExpense == isExpense) category.id: category,
    };

    final sortedRecords = _recordsBox.values
        .where((record) => !record.isVoided && record.isExpense == isExpense)
        .toList()
      ..sort((a, b) {
        final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        return b.date.compareTo(a.date);
      });

    final result = <Category>[];
    final seenIds = <String>{};

    for (final record in sortedRecords) {
      final currentCategory = activeCategories[record.category.id];
      if (currentCategory == null || !seenIds.add(currentCategory.id)) {
        continue;
      }

      result.add(currentCategory);
      if (result.length >= limit) {
        break;
      }
    }

    return result;
  }

  Future<void> _migrateRecordCategoryGroups({
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    final records = _recordsBox.values.toList();
    final storedVersion = _settingsBox.get(
      recordGroupMigrationVersionKey,
      defaultValue: 0,
    ) as int;
    final hasMissingGroupId = records.any(
      (record) => record.category.groupId.isEmpty,
    );

    if (storedVersion >= currentRecordGroupMigrationVersion &&
        !hasMissingGroupId) {
      return;
    }

    if (records.isEmpty) {
      await _settingsBox.put(
        recordGroupMigrationVersionKey,
        currentRecordGroupMigrationVersion,
      );
      onProgress?.call(
        const DataSyncProgress(
          message: '本地数据已就绪',
          detail: '未发现需要补齐的历史记录',
          processed: 1,
          total: 1,
        ),
      );
      return;
    }

    var processed = 0;
    var updated = 0;
    final total = records.length;

    onProgress?.call(
      DataSyncProgress(
        message: '正在同步历史记录',
        detail: '检查并补齐历史记录的大类信息',
        processed: 0,
        total: total,
      ),
    );

    for (final record in records) {
      var changed = false;
      final normalizedLegacyCategory = _resolveLegacyRecordCategory(
        category: record.category,
      );

      if (normalizedLegacyCategory != null &&
          record.category.id != normalizedLegacyCategory.id) {
        record.category = normalizedLegacyCategory;
        changed = true;
      }

      final mappedUtilityCategory = _resolveUtilityCategoryFromRemark(
        category: record.category,
        remark: record.remark,
      );

      if (mappedUtilityCategory != null &&
          record.category.id != mappedUtilityCategory.id) {
        record.category = mappedUtilityCategory;
        changed = true;
      }

      final currentCategory = _categoriesBox.get(record.category.id);
      if (currentCategory != null) {
        _ensureCategoryGroupId(currentCategory);
        if (record.category.groupId != currentCategory.groupId) {
          record.category.groupId = currentCategory.groupId;
          changed = true;
        }
      } else {
        final resolvedGroupId = _resolveCategoryGroupId(record.category);
        if (record.category.groupId != resolvedGroupId) {
          record.category.groupId = resolvedGroupId;
          changed = true;
        }
      }

      if (changed) {
        await record.save();
        updated++;
      }

      processed++;
      if (onProgress != null &&
          (processed == 1 || processed == total || processed % 10 == 0)) {
        onProgress(
          DataSyncProgress(
            message: '正在同步历史记录',
            detail: '已处理 $processed / $total，已补齐 $updated 条记录',
            processed: processed,
            total: total,
          ),
        );
      }
    }

    await _settingsBox.put(
      recordGroupMigrationVersionKey,
      currentRecordGroupMigrationVersion,
    );

    onProgress?.call(
      DataSyncProgress(
        message: '本地数据已就绪',
        detail: updated > 0 ? '已补齐 $updated 条历史记录的大类信息' : '历史记录的大类信息已是最新状态',
        processed: total,
        total: total,
      ),
    );
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

  String _defaultCategoryKey({
    required String name,
    required String iconName,
    required bool isExpense,
  }) {
    return '${isExpense ? 'expense' : 'income'}::${name.trim()}::${iconName.trim()}';
  }

  Future<void> _backfillCategoryGroupIds() async {
    for (final category in _categoriesBox.values) {
      if (category.groupId.isNotEmpty) {
        continue;
      }

      _ensureCategoryGroupId(category);
      await _categoriesBox.put(category.id, category);
    }
  }

  Category? _resolveUtilityCategoryFromRemark({
    required Category category,
    required String remark,
  }) {
    if (!_isLegacyUtilityCategory(category)) {
      return null;
    }

    if (remark.contains('水费')) {
      return _findCategoryByName('水费', isExpense: true);
    }

    if (remark.contains('电费')) {
      return _findCategoryByName('电费', isExpense: true);
    }

    if (remark.contains('燃气费') || remark.contains('燃气')) {
      return _findCategoryByName('燃气费', isExpense: true);
    }

    return null;
  }

  Category? _resolveLegacyRecordCategory({
    required Category category,
  }) {
    if (_isLegacyCommunicationCategory(category)) {
      return _findCategoryByName('话费', isExpense: true);
    }

    return null;
  }

  bool _isLegacyUtilityCategory(Category category) {
    if (!category.isExpense) {
      return false;
    }

    return category.iconName == 'utility' || category.name == '生活缴费';
  }

  bool _isLegacyCommunicationCategory(Category category) {
    if (!category.isExpense) {
      return false;
    }

    return category.iconName == 'communication' || category.name == '通讯';
  }

  bool _isDefaultDailyCategory(Category category) {
    if (!category.isExpense) {
      return false;
    }

    return category.iconName == 'daily' || category.name == '日用';
  }

  Category? _findCategoryByName(String name, {required bool isExpense}) {
    for (final category in _categoriesBox.values) {
      if (category.isExpense == isExpense && category.name == name) {
        return category;
      }
    }

    return null;
  }

  void _ensureCategoryGroupId(Category category) {
    if (category.groupId.isNotEmpty) {
      return;
    }

    category.groupId = _resolveCategoryGroupId(category);
  }

  String _resolveCategoryGroupId(Category category) {
    switch (_categoryTypeKey(category.iconName, category.isExpense)) {
      case 'expense::food':
      case 'expense::vegetables':
      case 'expense::fruit':
      case 'expense::snacks':
        return CategoryGroupIds.expenseFood;
      case 'expense::communication':
      case 'expense::housing':
      case 'expense::office':
      case 'expense::repair':
      case 'expense::express':
      case 'expense::phone-bill':
      case 'expense::utility':
      case 'expense::water-outline':
      case 'expense::lightning-bolt-outline':
      case 'expense::fire':
        return CategoryGroupIds.expenseHome;
      case 'expense::transport':
      case 'expense::car':
      case 'expense::motorcycle':
      case 'expense::train':
      case 'expense::travel':
        return CategoryGroupIds.expenseTransport;
      case 'expense::daily':
      case 'expense::shopping':
      case 'expense::clothing':
      case 'expense::digital':
        return CategoryGroupIds.expenseShopping;
      case 'expense::child':
      case 'expense::elders':
      case 'expense::gift-money':
      case 'expense::gift':
      case 'expense::relatives':
        return CategoryGroupIds.expenseFamily;
      case 'expense::medical':
      case 'expense::books':
      case 'expense::study':
        return CategoryGroupIds.expenseHealth;
      case 'expense::lottery':
      case 'expense::wish':
      case 'expense::alcohol':
      case 'expense::social':
      case 'expense::entertainment':
        return CategoryGroupIds.expenseEntertainment;
      case 'income::salary':
      case 'income::part-time':
        return CategoryGroupIds.incomeWork;
      case 'income::investment':
        return CategoryGroupIds.incomeInvestment;
      case 'income::gift-money-income':
        return CategoryGroupIds.incomeRelationship;
      case 'income::lottery-income':
      case 'income::other':
        return CategoryGroupIds.incomeWindfall;
      default:
        return category.isExpense
            ? CategoryGroupIds.expenseHome
            : CategoryGroupIds.incomeWindfall;
    }
  }

  String _categoryTypeKey(String iconName, bool isExpense) {
    return '${isExpense ? 'expense' : 'income'}::${iconName.trim()}';
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

  int _nextCategoryGroupSortOrder(bool isExpense) {
    var maxSortOrder = -1;
    for (final group in _categoryGroupsBox.values) {
      if (group.isExpense == isExpense && group.sortOrder > maxSortOrder) {
        maxSortOrder = group.sortOrder;
      }
    }
    return maxSortOrder + 1;
  }
}
