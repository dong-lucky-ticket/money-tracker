import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/record.dart';

class CsvExportColumns {
  CsvExportColumns._();

  static const String exportVersion = 'v2';
  static const String utf8Bom = '\uFEFF';

  static const int legacyId = 0;
  static const int legacyType = 1;
  static const int legacyAmount = 2;
  static const int legacyCategoryName = 3;
  static const int legacyRemark = 4;
  static const int legacyDate = 5;

  static const int exportVersionIndex = 6;
  static const int entityType = 7;
  static const int scope = 8;
  static const int recordId = 9;
  static const int recordType = 10;
  static const int recordAmount = 11;
  static const int recordCategoryId = 12;
  static const int recordCategoryName = 13;
  static const int recordRemark = 14;
  static const int recordDate = 15;
  static const int recordIsVoided = 16;
  static const int recordCreatedAt = 17;
  static const int recordUpdatedAt = 18;
  static const int categoryId = 19;
  static const int categoryName = 20;
  static const int categoryIconName = 21;
  static const int categoryColorHex = 22;
  static const int categoryGroupId = 23;
  static const int categorySortOrder = 24;
  static const int categoryIsExpense = 25;
  static const int groupId = 26;
  static const int groupName = 27;
  static const int groupIsExpense = 28;
  static const int groupSortOrder = 29;

  static const int columnCount = 30;

  static const String entityRecord = 'record';
  static const String entityCategory = 'category';
  static const String entityCategoryGroup = 'category_group';
  static const String scopeActive = 'active';
  static const String scopeDeleted = 'deleted';

  static const List<String> headers = [
    'ID',
    '类型',
    '金额',
    '分类',
    '备注',
    '日期',
    '导出版本',
    '实体类型',
    '数据范围',
    '记录ID',
    '记录类型',
    '记录金额',
    '记录分类ID',
    '记录分类名',
    '记录备注',
    '记录日期',
    '记录作废',
    '记录创建时间',
    '记录更新时间',
    '分类ID',
    '分类名称',
    '分类图标',
    '分类颜色',
    '分类大类ID',
    '分类排序',
    '分类是否支出',
    '大类ID',
    '大类名称',
    '大类是否支出',
    '大类排序',
  ];
}

class CsvExportService {
  CsvExportService._();

  static String buildCsv({
    required Iterable<Record> activeRecords,
    required Iterable<Record> deletedRecords,
    required Iterable<Category> activeCategories,
    required Iterable<Category> deletedCategories,
    required Iterable<CategoryGroup> categoryGroups,
  }) {
    final rows = <List<dynamic>>[
      CsvExportColumns.headers,
      for (final record in activeRecords)
        _recordRow(record, scope: CsvExportColumns.scopeActive),
      for (final record in deletedRecords)
        _recordRow(record, scope: CsvExportColumns.scopeDeleted),
      for (final category in activeCategories)
        _categoryRow(category, scope: CsvExportColumns.scopeActive),
      for (final category in deletedCategories)
        _categoryRow(category, scope: CsvExportColumns.scopeDeleted),
      for (final group in categoryGroups) _groupRow(group),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    return '${CsvExportColumns.utf8Bom}$csv';
  }

  static List<dynamic> _recordRow(
    Record record, {
    required String scope,
  }) {
    final fillLegacyColumns = scope == CsvExportColumns.scopeActive;
    return [
      fillLegacyColumns ? record.id : '',
      fillLegacyColumns ? _recordTypeLabel(record.isExpense) : '',
      fillLegacyColumns ? record.amount : '',
      fillLegacyColumns ? record.category.name : '',
      fillLegacyColumns ? record.remark : '',
      fillLegacyColumns ? _formatDateTime(record.date) : '',
      CsvExportColumns.exportVersion,
      CsvExportColumns.entityRecord,
      scope,
      record.id,
      _recordTypeLabel(record.isExpense),
      record.amount,
      record.category.id,
      record.category.name,
      record.remark,
      _formatDateTime(record.date),
      record.isVoided ? 'true' : 'false',
      _formatDateTime(record.createdAt),
      _formatDateTime(record.updatedAt),
      record.category.id,
      record.category.name,
      record.category.iconName,
      record.category.colorHex,
      record.category.groupId,
      record.category.sortOrder,
      record.category.isExpense ? 'true' : 'false',
      '',
      '',
      '',
      '',
    ];
  }

  static List<dynamic> _categoryRow(
    Category category, {
    required String scope,
  }) {
    return [
      '',
      '',
      '',
      '',
      '',
      '',
      CsvExportColumns.exportVersion,
      CsvExportColumns.entityCategory,
      scope,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      category.id,
      category.name,
      category.iconName,
      category.colorHex,
      category.groupId,
      category.sortOrder,
      category.isExpense ? 'true' : 'false',
      '',
      '',
      '',
      '',
    ];
  }

  static List<dynamic> _groupRow(CategoryGroup group) {
    return [
      '',
      '',
      '',
      '',
      '',
      '',
      CsvExportColumns.exportVersion,
      CsvExportColumns.entityCategoryGroup,
      CsvExportColumns.scopeActive,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      group.id,
      group.name,
      group.isExpense ? 'true' : 'false',
      group.sortOrder,
    ];
  }

  static String _recordTypeLabel(bool isExpense) {
    return isExpense ? '支出' : '收入';
  }

  static String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
  }
}
