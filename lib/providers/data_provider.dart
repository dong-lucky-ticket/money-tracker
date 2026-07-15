import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/csv_import_result.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import '../services/data_bootstrap_service.dart';
import '../services/error_log_service.dart';
import '../services/record_import_service.dart';
import '../utils/category_rules.dart';

class DataProvider with ChangeNotifier {
  late Box<Record> _recordsBox;
  late Box<Record> _deletedRecordsBox;
  late Box<Category> _categoriesBox;
  late Box<Category> _deletedCategoriesBox;
  late Box<CategoryGroup> _categoryGroupsBox;
  late Box _settingsBox;

  List<Record>? _recordsCache;
  List<Record>? _deletedRecordsCache;
  List<Category>? _categoriesCache;
  List<Category>? _deletedCategoriesCache;
  List<CategoryGroup>? _categoryGroupsCache;

  List<Record> get records => _recordsCache ??= _buildSortedRecords();
  List<Record> get deletedRecords =>
      _deletedRecordsCache ??= _buildSortedDeletedRecords();
  List<CategoryGroup> get categoryGroups =>
      _categoryGroupsCache ??= _buildSortedCategoryGroups();
  List<Category> get categories => _categoriesCache ??= _buildSortedCategories();
  List<Category> get deletedCategories =>
      _deletedCategoriesCache ??= _buildSortedDeletedCategories();
  int get recycleBinItemCount => deletedRecords.length + deletedCategories.length;

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
    final snapshot = await DataBootstrapService.bootstrap(
      onProgress: onProgress,
    );

    _recordsBox = snapshot.recordsBox;
    _deletedRecordsBox = snapshot.deletedRecordsBox;
    _categoriesBox = snapshot.categoriesBox;
    _deletedCategoriesBox = snapshot.deletedCategoriesBox;
    _categoryGroupsBox = snapshot.categoryGroupsBox;
    _settingsBox = snapshot.settingsBox;
    _isDarkTheme = snapshot.isDarkTheme;
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
      final record = _recordsBox.get(id);
      if (record == null) {
        return;
      }

      final deletedRecord = _cloneRecord(
        record,
        updatedAt: DateTime.now(),
      );
      await _deletedRecordsBox.put(deletedRecord.id, deletedRecord);
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

  Future<void> restoreRecord(String id) async {
    try {
      final record = _deletedRecordsBox.get(id);
      if (record == null) {
        return;
      }

      final restoredRecord = _cloneRecord(
        record,
        updatedAt: DateTime.now(),
      );
      await _recordsBox.put(restoredRecord.id, restoredRecord);
      await _deletedRecordsBox.delete(id);
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_restore_record',
        scene: '恢复流水: $id',
      );
      rethrow;
    }
  }

  Future<void> permanentlyDeleteRecord(String id) async {
    try {
      await _deletedRecordsBox.delete(id);
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_permanently_delete_record',
        scene: '彻底删除流水: $id',
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
      final category = _categoriesBox.get(id);
      if (category == null) {
        return;
      }

      final deletedCategory = _cloneCategory(category);
      await _deletedCategoriesBox.put(deletedCategory.id, deletedCategory);
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

  Future<void> restoreCategory(String id) async {
    try {
      final category = _deletedCategoriesBox.get(id);
      if (category == null) {
        return;
      }

      final restoredCategory = _cloneCategory(category);
      ensureCategoryGroupId(restoredCategory);
      await _categoriesBox.put(restoredCategory.id, restoredCategory);
      await _deletedCategoriesBox.delete(id);
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_restore_category',
        scene: '恢复分类: $id',
      );
      rethrow;
    }
  }

  Future<void> permanentlyDeleteCategory(String id) async {
    try {
      await _deletedCategoriesBox.delete(id);
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_permanently_delete_category',
        scene: '彻底删除分类: $id',
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
      await _deletedRecordsBox.clear();
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

  Future<void> clearRecycleBin() async {
    try {
      await _deletedRecordsBox.clear();
      await _deletedCategoriesBox.clear();
      _notifyRecordsChanged();
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_clear_recycle_bin',
        scene: '清空回收站',
      );
      rethrow;
    }
  }

  Future<void> clearDeletedRecords() async {
    try {
      await _deletedRecordsBox.clear();
      _notifyRecordsChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_clear_deleted_records',
        scene: '清空已删除流水',
      );
      rethrow;
    }
  }

  Future<void> clearDeletedCategories() async {
    try {
      await _deletedCategoriesBox.clear();
      _notifyCategoriesChanged();
    } catch (e, stackTrace) {
      await _recordDataError(
        e,
        stackTrace: stackTrace,
        source: 'data_clear_deleted_categories',
        scene: '清空已删除分类',
      );
      rethrow;
    }
  }

  Future<CsvImportResult> importRecordsFromCsv(String csvContent) async {
    try {
      final preparedImport = RecordImportService.prepareCsvImport(
        csvContent: csvContent,
        existingCategories: _categoriesBox.values,
        existingDeletedCategories: _deletedCategoriesBox.values,
        existingCategoryGroups: _categoryGroupsBox.values,
        existingRecords: _recordsBox.values,
        existingDeletedRecords: _deletedRecordsBox.values,
        ensureCategoryGroupId: ensureCategoryGroupId,
      );

      if (preparedImport.categoryGroupsToImport.isNotEmpty) {
        await _categoryGroupsBox.putAll(preparedImport.categoryGroupsToImport);
      }

      if (preparedImport.activeCategoriesToImport.isNotEmpty) {
        await _categoriesBox.putAll({
          for (final category in preparedImport.activeCategoriesToImport.values)
            category.id: category,
        });
      }

      if (preparedImport.deletedCategoriesToImport.isNotEmpty) {
        await _deletedCategoriesBox.putAll({
          for (final category in preparedImport.deletedCategoriesToImport.values)
            category.id: category,
        });
      }

      if (preparedImport.activeRecordsToImport.isNotEmpty) {
        await _recordsBox.putAll(preparedImport.activeRecordsToImport);
      }

      if (preparedImport.deletedRecordsToImport.isNotEmpty) {
        await _deletedRecordsBox.putAll(preparedImport.deletedRecordsToImport);
      }

      _invalidateCategoriesCache();
      _invalidateCategoryGroupsCache();
      _notifyRecordsChanged();
      _notifyCategoriesChanged();

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

  Record _cloneRecord(
    Record source, {
    DateTime? updatedAt,
  }) {
    return Record(
      id: source.id,
      amount: source.amount,
      category: _cloneCategory(source.category),
      remark: source.remark,
      date: source.date,
      isExpense: source.isExpense,
      isVoided: source.isVoided,
      createdAt: source.createdAt,
      updatedAt: updatedAt ?? source.updatedAt,
    );
  }

  Category _cloneCategory(Category source) {
    return Category(
      id: source.id,
      name: source.name,
      iconName: source.iconName,
      colorHex: source.colorHex,
      isExpense: source.isExpense,
      sortOrder: source.sortOrder,
      groupId: source.groupId,
    );
  }

  List<Record> _buildSortedRecords() {
    return UnmodifiableListView(
      _recordsBox.values.toList()..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  List<Record> _buildSortedDeletedRecords() {
    return UnmodifiableListView(
      _deletedRecordsBox.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  List<Category> _buildSortedCategories() {
    return UnmodifiableListView(
      _categoriesBox.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  List<Category> _buildSortedDeletedCategories() {
    return UnmodifiableListView(
      _deletedCategoriesBox.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
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
    _deletedRecordsCache = null;
  }

  void _invalidateCategoriesCache() {
    _categoriesCache = null;
    _deletedCategoriesCache = null;
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
