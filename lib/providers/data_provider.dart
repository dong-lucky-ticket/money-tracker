import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/csv_import_result.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import '../services/category_catalog_service.dart';
import '../services/error_log_service.dart';
import '../services/record_import_service.dart';
import '../services/record_category_migration_service.dart';
import '../utils/category_rules.dart';

class DataProvider with ChangeNotifier {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String categoryGroupsBoxName = 'categoryGroupsBox';
  static const String settingsBoxName = 'settingsBox';
  static const String recordGroupMigrationVersionKey =
      'recordGroupMigrationVersion';
  static const int currentRecordGroupMigrationVersion = 5;

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

    await CategoryCatalogService.syncDefaultCategoryGroups(_categoryGroupsBox);
    await CategoryCatalogService.syncDefaultCategories(_categoriesBox);
    await RecordCategoryMigrationService.migrate(
      recordsBox: _recordsBox,
      categoriesBox: _categoriesBox,
      settingsBox: _settingsBox,
      versionKey: recordGroupMigrationVersionKey,
      currentVersion: currentRecordGroupMigrationVersion,
      onProgress: onProgress,
    );
    _invalidateAllCaches();
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
      ensureCategoryGroupId(category);
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
        ensureCategoryGroupId: ensureCategoryGroupId,
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
