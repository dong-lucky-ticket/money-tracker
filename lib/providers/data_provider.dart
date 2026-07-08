import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/csv_import_result.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import '../services/error_log_service.dart';
import '../services/record_import_service.dart';
import '../utils/record_queries.dart';

class DataProvider with ChangeNotifier {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String categoryGroupsBoxName = 'categoryGroupsBox';
  static const String settingsBoxName = 'settingsBox';
  static const String recordGroupMigrationVersionKey =
      'recordGroupMigrationVersion';
  static const int currentRecordGroupMigrationVersion = 5;
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

  List<Record>? _recordsCache;
  List<Category>? _categoriesCache;
  List<CategoryGroup>? _categoryGroupsCache;

  List<Record> get records => _recordsCache ??= _buildSortedRecords();
  List<CategoryGroup> get categoryGroups =>
      _categoryGroupsCache ??= _buildSortedCategoryGroups();
  List<Category> get categories => _categoriesCache ??= _buildSortedCategories();

  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  Future<void> _recordDataError(
    Object error, {
    StackTrace? stackTrace,
    required String source,
    String? scene,
  }) {
    return ErrorLogService.instance.record(
      error,
      stackTrace: stackTrace,
      source: source,
      scene: scene,
    );
  }

  Future<void> init({
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    _invalidateAllCaches();
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
    _invalidateAllCaches();
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
          name: '铁路',
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
          name: '考试',
          iconName: 'study',
          colorHex: '#2563EB',
          isExpense: true,
          sortOrder: 24),
      Category(
          id: const Uuid().v4(),
          name: '烟酒',
          iconName: 'alcohol',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 25),
      Category(
          id: const Uuid().v4(),
          name: '彩票',
          iconName: 'lottery',
          colorHex: '#EF4444',
          isExpense: true,
          sortOrder: 26),
      Category(
          id: const Uuid().v4(),
          name: '星愿',
          iconName: 'wish',
          colorHex: '#A855F7',
          isExpense: true,
          sortOrder: 27),

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

      if (_isLegacyRailCategory(category)) {
        category.name = '铁路';
        category.iconName = 'train';
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
    await _saveRecord(
      record,
      source: 'data_add_record',
      scene: '新增/保存流水: ${record.id}',
    );
  }

  Future<void> updateRecord(
    Record record, {
    required double amount,
    required Category category,
    required String remark,
    required DateTime date,
  }) async {
    record
      ..amount = amount
      ..category = category
      ..remark = remark
      ..date = date;

    await _saveRecord(
      record,
      source: 'data_update_record',
      scene: '编辑流水: ${record.id}',
    );
  }

  Future<void> toggleRecordVoided(Record record) async {
    record.isVoided = !record.isVoided;

    await _saveRecord(
      record,
      source: 'data_toggle_record_voided',
      scene: '切换流水作废状态: ${record.id}',
    );
  }

  Future<void> _saveRecord(
    Record record, {
    required String source,
    required String scene,
  }) async {
    try {
      final now = DateTime.now();
      record.updatedAt = now;
      await _recordsBox.put(record.id, record);
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: source,
        scene: scene,
      );
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _recordsBox.delete(id);
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_delete_record',
        scene: '删除流水: $id',
      );
      rethrow;
    }
  }

  // --- Category Methods ---
  Future<void> addCategory(Category category) async {
    try {
      _ensureCategoryGroupId(category);
      await _categoriesBox.put(category.id, category);
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_add_category',
        scene: '新增分类: ${category.name}',
      );
      rethrow;
    }
  }

  // --- Category Group Methods ---
  Future<void> addCategoryGroup(CategoryGroup group) async {
    try {
      if (group.sortOrder < 0) {
        group.sortOrder = _nextCategoryGroupSortOrder(group.isExpense);
      }
      await _categoryGroupsBox.put(group.id, group);
      _notifyCategoryGroupsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_add_category_group',
        scene: '新增大类: ${group.name}',
      );
      rethrow;
    }
  }

  Future<void> updateCategoryGroup(CategoryGroup group) async {
    try {
      await _categoryGroupsBox.put(group.id, group);
      _notifyCategoryGroupsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_update_category_group',
        scene: '更新大类: ${group.name}',
      );
      rethrow;
    }
  }

  Future<void> reorderCategoryGroups(List<CategoryGroup> newOrderList) async {
    try {
      for (int i = 0; i < newOrderList.length; i++) {
        newOrderList[i].sortOrder = i;
      }
      _notifyCategoryGroupsChanged();

      for (final group in newOrderList) {
        await _categoryGroupsBox.put(group.id, group);
      }
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_reorder_category_groups',
        scene: '重排大类顺序',
      );
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _categoriesBox.delete(id);
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_delete_category',
        scene: '删除分类: $id',
      );
      rethrow;
    }
  }

  Future<void> reorderCategories(List<Category> newOrderList) async {
    try {
      // 1. 立即在内存中更新排序，并同步通知UI刷新
      // 这样 ReorderableListView 能够立刻获取到最新顺序，避免拖拽松手后“回弹再动画”的冗余表现
      for (int i = 0; i < newOrderList.length; i++) {
        newOrderList[i].sortOrder = i;
      }
      _notifyCategoriesChanged();

      // 2. 随后在后台异步持久化到本地存储
      for (var cat in newOrderList) {
        await _categoriesBox.put(cat.id, cat);
      }
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_reorder_categories',
        scene: '重排分类顺序',
      );
      rethrow;
    }
  }

  Future<void> reorderCategoriesInGroup({
    required String groupId,
    required bool isExpense,
    required List<Category> newOrderList,
  }) async {
    try {
      for (int i = 0; i < newOrderList.length; i++) {
        newOrderList[i].sortOrder = i;
      }
      _notifyCategoriesChanged();

      for (final category in newOrderList) {
        await _categoriesBox.put(category.id, category);
      }
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_reorder_categories_in_group',
        scene: '组内重排分类: $groupId / ${isExpense ? '支出' : '收入'}',
      );
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      await _recordsBox.clear();
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_clear_all_records',
        scene: '清空所有账单数据',
      );
      rethrow;
    }
  }

  Future<CsvImportResult> importRecordsFromCsv(String csvContent) async {
    try {
      final preparedImport = RecordImportService.prepareCsvImport(
        csvContent: csvContent,
        existingCategories: _categoriesBox.values,
        existingRecords: _recordsBox.values,
        ensureCategoryGroupId: _ensureCategoryGroupId,
      );

      if (preparedImport.categoriesToCreate.isNotEmpty) {
        await _categoriesBox.putAll({
          for (final category in preparedImport.categoriesToCreate)
            category.id: category,
        });
      }

      await _recordsBox.putAll(preparedImport.recordsToImport);
      _invalidateCategoriesCache();
      _notifyRecordsChanged();

      return preparedImport.result;
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_import_records_csv',
        scene: 'DataProvider 导入 CSV',
      );
      rethrow;
    }
  }

  // --- Settings ---
  Future<void> toggleTheme() async {
    try {
      _isDarkTheme = !_isDarkTheme;
      await _settingsBox.put('isDarkTheme', _isDarkTheme);
      notifyListeners();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_toggle_theme',
        scene: '切换主题模式',
      );
      rethrow;
    }
  }

  // --- Stats ---
  double get monthlyExpense {
    final now = DateTime.now();
    return summarizeRecords(recordsForMonth(records, now)).expense;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return summarizeRecords(recordsForMonth(records, now)).income;
  }

  double get totalExpense => summarizeRecords(records).expense;
  double get totalIncome => summarizeRecords(records).income;

  int get activeCategoryCount => countActiveCategories(records);

  List<Record> recordsInMonth(DateTime month) {
    return recordsForMonth(records, month);
  }

  int recordCountInMonth(
    DateTime month, {
    bool includeVoided = true,
  }) {
    var count = 0;
    for (final record in records) {
      if (record.date.year != month.year || record.date.month != month.month) {
        continue;
      }
      if (!includeVoided && record.isVoided) {
        continue;
      }
      count++;
    }
    return count;
  }

  List<Category> categoriesForType(bool isExpense) {
    return categories
        .where((category) => category.isExpense == isExpense)
        .toList(growable: false);
  }

  List<CategoryGroup> categoryGroupsForType(bool isExpense) {
    return categoryGroups
        .where((group) => group.isExpense == isExpense)
        .toList(growable: false);
  }

  List<Category> recentCategories({
    required bool isExpense,
    int limit = 4,
  }) {
    return recentCategoriesFromRecords(
      records: records,
      categories: categories,
      isExpense: isExpense,
      limit: limit,
    );
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
        detail: '检查并补齐历史记录的大类与分类信息',
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
          !_isSameCategorySnapshot(record.category, normalizedLegacyCategory)) {
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
        if (!_isSameCategorySnapshot(record.category, currentCategory)) {
          record.category = currentCategory;
          changed = true;
        }
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

    if (_isLegacyRailCategory(category)) {
      return _findCategoryByName('铁路', isExpense: true);
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

  bool _isLegacyRailCategory(Category category) {
    if (!category.isExpense) {
      return false;
    }

    return category.iconName == 'train' && category.name == '火车高铁';
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

  bool _isSameCategorySnapshot(Category a, Category b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.iconName == b.iconName &&
        a.colorHex == b.colorHex &&
        a.groupId == b.groupId &&
        a.isExpense == b.isExpense &&
        a.sortOrder == b.sortOrder;
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

  int _nextCategoryGroupSortOrder(bool isExpense) {
    var maxSortOrder = -1;
    for (final group in _categoryGroupsBox.values) {
      if (group.isExpense == isExpense && group.sortOrder > maxSortOrder) {
        maxSortOrder = group.sortOrder;
      }
    }
    return maxSortOrder + 1;
  }

  List<Record> _buildSortedRecords() {
    return UnmodifiableListView(
      _recordsBox.values.toList()..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  List<Category> _buildSortedCategories() {
    return UnmodifiableListView(
      _categoriesBox.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  List<CategoryGroup> _buildSortedCategoryGroups() {
    return UnmodifiableListView(
      _categoryGroupsBox.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  void _invalidateAllCaches() {
    _invalidateRecordsCache();
    _invalidateCategoriesCache();
    _invalidateCategoryGroupsCache();
  }

  void _invalidateRecordsCache() {
    _recordsCache = null;
  }

  void _invalidateCategoriesCache() {
    _categoriesCache = null;
  }

  void _invalidateCategoryGroupsCache() {
    _categoryGroupsCache = null;
  }

  void _notifyRecordsChanged() {
    _invalidateRecordsCache();
    notifyListeners();
  }

  void _notifyCategoriesChanged() {
    _invalidateCategoriesCache();
    notifyListeners();
  }

  void _notifyCategoryGroupsChanged() {
    _invalidateCategoryGroupsCache();
    notifyListeners();
  }
}
