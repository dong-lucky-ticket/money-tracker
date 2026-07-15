import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/csv_import_result.dart';
import '../models/record.dart';
import 'csv_export_service.dart';

class PreparedCsvImport {
  final Map<String, Record> activeRecordsToImport;
  final Map<String, Record> deletedRecordsToImport;
  final Map<String, Category> activeCategoriesToImport;
  final Map<String, Category> deletedCategoriesToImport;
  final Map<String, CategoryGroup> categoryGroupsToImport;
  final CsvImportResult result;

  const PreparedCsvImport({
    required this.activeRecordsToImport,
    required this.deletedRecordsToImport,
    required this.activeCategoriesToImport,
    required this.deletedCategoriesToImport,
    required this.categoryGroupsToImport,
    required this.result,
  });
}

class RecordImportService {
  const RecordImportService._();

  static PreparedCsvImport prepareCsvImport({
    required String csvContent,
    required Iterable<Category> existingCategories,
    required Iterable<Category> existingDeletedCategories,
    required Iterable<CategoryGroup> existingCategoryGroups,
    required Iterable<Record> existingRecords,
    required Iterable<Record> existingDeletedRecords,
    required void Function(Category category) ensureCategoryGroupId,
  }) {
    final sanitizedContent = csvContent.trim();
    if (sanitizedContent.isEmpty) {
      throw const FormatException('CSV 内容为空');
    }

    final rows =
        const CsvToListConverter(shouldParseNumbers: false).convert(sanitizedContent);
    if (rows.isEmpty) {
      throw const FormatException('CSV 内容为空');
    }

    final existingActiveCategoriesById = {
      for (final category in existingCategories) category.id: category,
    };
    final existingDeletedCategoriesById = {
      for (final category in existingDeletedCategories) category.id: category,
    };
    final existingCategoryGroupsById = {
      for (final group in existingCategoryGroups) group.id: group,
    };
    final existingRecordIds = {
      for (final record in existingRecords) record.id,
    };
    final existingDeletedRecordIds = {
      for (final record in existingDeletedRecords) record.id,
    };

    final activeCategoriesToImport = <String, Category>{};
    final deletedCategoriesToImport = <String, Category>{};
    final categoryGroupsToImport = <String, CategoryGroup>{};
    final activeRecordsToImport = <String, Record>{};
    final deletedRecordsToImport = <String, Record>{};

    var importedCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;
    var createdCategoryCount = 0;

    final startIndex = _isHeaderRow(rows.first) ? 1 : 0;

    for (var rowIndex = startIndex; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (_isEmptyRow(row)) {
        continue;
      }

      try {
        if (_looksLikeExtendedRow(row)) {
          final createdCategories = _parseExtendedRow(
            row,
            activeCategoriesToImport: activeCategoriesToImport,
            deletedCategoriesToImport: deletedCategoriesToImport,
            categoryGroupsToImport: categoryGroupsToImport,
            activeRecordsToImport: activeRecordsToImport,
            deletedRecordsToImport: deletedRecordsToImport,
            existingActiveCategoriesById: existingActiveCategoriesById,
            existingDeletedCategoriesById: existingDeletedCategoriesById,
            existingCategoryGroupsById: existingCategoryGroupsById,
            existingRecordIds: existingRecordIds,
            existingDeletedRecordIds: existingDeletedRecordIds,
            ensureCategoryGroupId: ensureCategoryGroupId,
          );
          createdCategoryCount += createdCategories.createdCategoryCount;
          importedCount += createdCategories.importedCount;
          updatedCount += createdCategories.updatedCount;
          continue;
        }

        if (row.length < 6) {
          skippedCount++;
          continue;
        }

        final parsed = _parseLegacyRecordRow(
          row,
          activeCategoriesToImport: activeCategoriesToImport,
          existingActiveCategoriesById: existingActiveCategoriesById,
          ensureCategoryGroupId: ensureCategoryGroupId,
        );
        createdCategoryCount += parsed.createdCategoryCount;
        if (activeRecordsToImport.containsKey(parsed.record.id) ||
            existingRecordIds.contains(parsed.record.id)) {
          updatedCount++;
        } else {
          importedCount++;
        }
        activeRecordsToImport[parsed.record.id] = parsed.record;
      } catch (_) {
        skippedCount++;
      }
    }

    if (activeRecordsToImport.isEmpty &&
        deletedRecordsToImport.isEmpty &&
        activeCategoriesToImport.isEmpty &&
        deletedCategoriesToImport.isEmpty &&
        categoryGroupsToImport.isEmpty) {
      throw const FormatException('未识别到可导入的数据，请确认 CSV 格式与导出一致');
    }

    return PreparedCsvImport(
      activeRecordsToImport: activeRecordsToImport,
      deletedRecordsToImport: deletedRecordsToImport,
      activeCategoriesToImport: activeCategoriesToImport,
      deletedCategoriesToImport: deletedCategoriesToImport,
      categoryGroupsToImport: categoryGroupsToImport,
      result: CsvImportResult(
        importedCount: importedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        createdCategoryCount: createdCategoryCount,
      ),
    );
  }

  static _RowStats _parseExtendedRow(
    List<dynamic> row, {
    required Map<String, Category> activeCategoriesToImport,
    required Map<String, Category> deletedCategoriesToImport,
    required Map<String, CategoryGroup> categoryGroupsToImport,
    required Map<String, Record> activeRecordsToImport,
    required Map<String, Record> deletedRecordsToImport,
    required Map<String, Category> existingActiveCategoriesById,
    required Map<String, Category> existingDeletedCategoriesById,
    required Map<String, CategoryGroup> existingCategoryGroupsById,
    required Set<String> existingRecordIds,
    required Set<String> existingDeletedRecordIds,
    required void Function(Category category) ensureCategoryGroupId,
  }) {
    final entityType = _cellValue(row, CsvExportColumns.entityType).trim();
    final scope = _normalizedScope(
      _cellValue(row, CsvExportColumns.scope).trim(),
    );

    switch (entityType) {
      case CsvExportColumns.entityRecord:
        final categoryResolution = _resolveCategoryForRecordRow(
          row,
          scope: scope,
          activeCategoriesToImport: activeCategoriesToImport,
          deletedCategoriesToImport: deletedCategoriesToImport,
          categoryGroupsToImport: categoryGroupsToImport,
          existingActiveCategoriesById: existingActiveCategoriesById,
          existingDeletedCategoriesById: existingDeletedCategoriesById,
          existingCategoryGroupsById: existingCategoryGroupsById,
          ensureCategoryGroupId: ensureCategoryGroupId,
        );

        final recordId = _preferredValue(
          _cellValue(row, CsvExportColumns.recordId),
          _cellValue(row, CsvExportColumns.legacyId),
        );
        final isExpense = _parseImportType(
          _preferredValue(
            _cellValue(row, CsvExportColumns.recordType),
            _cellValue(row, CsvExportColumns.legacyType),
          ),
        );
        final amount = _parseAmount(
          _preferredValue(
            _cellValue(row, CsvExportColumns.recordAmount),
            _cellValue(row, CsvExportColumns.legacyAmount),
          ),
        );
        final record = Record(
          id: recordId.isEmpty ? const Uuid().v4() : recordId,
          amount: amount,
          category: categoryResolution.category,
          remark: _preferredValue(
            _cellValue(row, CsvExportColumns.recordRemark),
            _cellValue(row, CsvExportColumns.legacyRemark),
          ),
          date: _parseImportDate(
            _preferredValue(
              _cellValue(row, CsvExportColumns.recordDate),
              _cellValue(row, CsvExportColumns.legacyDate),
            ),
          ),
          isExpense: isExpense,
          isVoided: _parseBool(
            _cellValue(row, CsvExportColumns.recordIsVoided),
            defaultValue: false,
          ),
          createdAt: _parseOptionalDateTime(
                _cellValue(row, CsvExportColumns.recordCreatedAt),
              ) ??
              _parseImportDate(
                _preferredValue(
                  _cellValue(row, CsvExportColumns.recordDate),
                  _cellValue(row, CsvExportColumns.legacyDate),
                ),
              ),
          updatedAt: _parseOptionalDateTime(
                _cellValue(row, CsvExportColumns.recordUpdatedAt),
              ) ??
              _parseImportDate(
                _preferredValue(
                  _cellValue(row, CsvExportColumns.recordDate),
                  _cellValue(row, CsvExportColumns.legacyDate),
                ),
              ),
        );

        if (scope == CsvExportColumns.scopeDeleted) {
          final exists =
              deletedRecordsToImport.containsKey(record.id) ||
                  existingDeletedRecordIds.contains(record.id);
          deletedRecordsToImport[record.id] = record;
          return _RowStats(
            importedCount: exists ? 0 : 1,
            updatedCount: exists ? 1 : 0,
            createdCategoryCount: categoryResolution.createdCategoryCount,
          );
        }

        final exists =
            activeRecordsToImport.containsKey(record.id) ||
                existingRecordIds.contains(record.id);
        activeRecordsToImport[record.id] = record;
        return _RowStats(
          importedCount: exists ? 0 : 1,
          updatedCount: exists ? 1 : 0,
          createdCategoryCount: categoryResolution.createdCategoryCount,
        );
      case CsvExportColumns.entityCategory:
        final category = _buildCategoryFromExtendedRow(row);
        ensureCategoryGroupId(category);
        var createdCategoryCount = 0;
        if (category.groupId.isNotEmpty &&
            !categoryGroupsToImport.containsKey(category.groupId) &&
            !existingCategoryGroupsById.containsKey(category.groupId)) {
          categoryGroupsToImport[category.groupId] = CategoryGroup(
            id: category.groupId,
            name: category.isExpense ? '未命名支出大类' : '未命名收入大类',
            isExpense: category.isExpense,
            sortOrder: 0,
          );
        }
        if (scope == CsvExportColumns.scopeDeleted) {
          if (!deletedCategoriesToImport.containsKey(category.id) &&
              !existingDeletedCategoriesById.containsKey(category.id)) {
            createdCategoryCount = 1;
          }
          deletedCategoriesToImport[category.id] = category;
        } else {
          if (!activeCategoriesToImport.containsKey(category.id) &&
              !existingActiveCategoriesById.containsKey(category.id)) {
            createdCategoryCount = 1;
          }
          activeCategoriesToImport[category.id] = category;
        }
        return _RowStats(createdCategoryCount: createdCategoryCount);
      case CsvExportColumns.entityCategoryGroup:
        final group = _buildGroupFromExtendedRow(row);
        categoryGroupsToImport[group.id] = group;
        return const _RowStats();
      default:
        throw const FormatException('未识别的实体类型');
    }
  }

  static _LegacyRecordParseResult _parseLegacyRecordRow(
    List<dynamic> row, {
    required Map<String, Category> activeCategoriesToImport,
    required Map<String, Category> existingActiveCategoriesById,
    required void Function(Category category) ensureCategoryGroupId,
  }) {
    final id = _cellValue(row, CsvExportColumns.legacyId).trim();
    final typeLabel = _cellValue(row, CsvExportColumns.legacyType).trim();
    final amount = _parseAmount(_cellValue(row, CsvExportColumns.legacyAmount));
    final isExpense = _parseImportType(typeLabel);
    final categoryName = _cellValue(
      row,
      CsvExportColumns.legacyCategoryName,
    ).trim();
    final normalizedCategoryName =
        categoryName.isEmpty ? (isExpense ? '其他支出' : '其他收入') : categoryName;

    Category? category;
    for (final existing in existingActiveCategoriesById.values) {
      if (existing.isExpense == isExpense && existing.name == normalizedCategoryName) {
        category = existing;
        break;
      }
    }
    category ??= _findCategoryInMapByName(
      activeCategoriesToImport,
      normalizedCategoryName,
      isExpense,
    );

    var createdCategoryCount = 0;
    if (category == null) {
      category = Category(
        id: const Uuid().v4(),
        name: normalizedCategoryName,
        iconName: 'other',
        colorHex: isExpense ? '#64748B' : '#10B981',
        isExpense: isExpense,
        sortOrder: _nextCategorySortOrder(
          activeCategoriesToImport.values.followedBy(existingActiveCategoriesById.values),
          isExpense,
        ),
      );
      ensureCategoryGroupId(category);
      activeCategoriesToImport[category.id] = category;
      createdCategoryCount = 1;
    }

    final recordId = id.isEmpty ? const Uuid().v4() : id;
    final date = _parseImportDate(_cellValue(row, CsvExportColumns.legacyDate));
    final record = Record(
      id: recordId,
      amount: amount,
      category: category,
      remark: _cellValue(row, CsvExportColumns.legacyRemark),
      date: date,
      isExpense: isExpense,
      createdAt: date,
      updatedAt: date,
    );

    return _LegacyRecordParseResult(
      record: record,
      createdCategoryCount: createdCategoryCount,
    );
  }

  static _CategoryResolution _resolveCategoryForRecordRow(
    List<dynamic> row, {
    required String scope,
    required Map<String, Category> activeCategoriesToImport,
    required Map<String, Category> deletedCategoriesToImport,
    required Map<String, CategoryGroup> categoryGroupsToImport,
    required Map<String, Category> existingActiveCategoriesById,
    required Map<String, Category> existingDeletedCategoriesById,
    required Map<String, CategoryGroup> existingCategoryGroupsById,
    required void Function(Category category) ensureCategoryGroupId,
  }) {
    final categoryId = _preferredValue(
      _cellValue(row, CsvExportColumns.recordCategoryId),
      _cellValue(row, CsvExportColumns.categoryId),
    );
    final categoryName = _preferredValue(
      _cellValue(row, CsvExportColumns.recordCategoryName),
      _cellValue(row, CsvExportColumns.categoryName),
      fallback: _cellValue(row, CsvExportColumns.legacyCategoryName),
    );
    final isExpense = _parseBool(
      _cellValue(row, CsvExportColumns.categoryIsExpense),
      defaultValue: _parseImportType(
        _preferredValue(
          _cellValue(row, CsvExportColumns.recordType),
          _cellValue(row, CsvExportColumns.legacyType),
        ),
      ),
    );

    Category? category;
    if (scope == CsvExportColumns.scopeDeleted) {
      category = deletedCategoriesToImport[categoryId];
      category ??= existingDeletedCategoriesById[categoryId];
    } else {
      category = activeCategoriesToImport[categoryId];
      category ??= existingActiveCategoriesById[categoryId];
    }

    category ??= _findCategoryInMapByName(
      scope == CsvExportColumns.scopeDeleted
          ? deletedCategoriesToImport
          : activeCategoriesToImport,
      categoryName,
      isExpense,
    );

    category ??= _findCategoryInMapByName(
      scope == CsvExportColumns.scopeDeleted
          ? existingDeletedCategoriesById
          : existingActiveCategoriesById,
      categoryName,
      isExpense,
    );

    var createdCategoryCount = 0;
    if (category == null) {
      category = _buildCategoryFromRecordRow(
        row,
        fallbackName: categoryName,
        fallbackIsExpense: isExpense,
      );
      ensureCategoryGroupId(category);

      if (category.groupId.isNotEmpty &&
          !categoryGroupsToImport.containsKey(category.groupId) &&
          !existingCategoryGroupsById.containsKey(category.groupId)) {
        categoryGroupsToImport[category.groupId] = CategoryGroup(
          id: category.groupId,
          name: category.isExpense ? '未命名支出大类' : '未命名收入大类',
          isExpense: category.isExpense,
          sortOrder: 0,
        );
      }

      if (scope == CsvExportColumns.scopeDeleted) {
        deletedCategoriesToImport[category.id] = category;
      } else {
        activeCategoriesToImport[category.id] = category;
      }
      createdCategoryCount = 1;
    }

    return _CategoryResolution(
      category: category,
      createdCategoryCount: createdCategoryCount,
    );
  }

  static Category _buildCategoryFromExtendedRow(List<dynamic> row) {
    final isExpense = _parseBool(
      _cellValue(row, CsvExportColumns.categoryIsExpense),
      defaultValue: false,
    );
    return Category(
      id: _nonEmptyOrUuid(_cellValue(row, CsvExportColumns.categoryId)),
      name: _preferredValue(
        _cellValue(row, CsvExportColumns.categoryName),
        _cellValue(row, CsvExportColumns.recordCategoryName),
      ),
      iconName: _cellValue(row, CsvExportColumns.categoryIconName).trim().isEmpty
          ? 'other'
          : _cellValue(row, CsvExportColumns.categoryIconName).trim(),
      colorHex: _normalizedColorHex(
        _cellValue(row, CsvExportColumns.categoryColorHex),
        isExpense: isExpense,
      ),
      isExpense: isExpense,
      sortOrder: _parseInt(
        _cellValue(row, CsvExportColumns.categorySortOrder),
        defaultValue: 0,
      ),
      groupId: _cellValue(row, CsvExportColumns.categoryGroupId).trim(),
    );
  }

  static Category _buildCategoryFromRecordRow(
    List<dynamic> row, {
    required String fallbackName,
    required bool fallbackIsExpense,
  }) {
    return Category(
      id: _nonEmptyOrUuid(
        _preferredValue(
          _cellValue(row, CsvExportColumns.recordCategoryId),
          _cellValue(row, CsvExportColumns.categoryId),
        ),
      ),
      name: fallbackName.isEmpty ? (fallbackIsExpense ? '其他支出' : '其他收入') : fallbackName,
      iconName: _cellValue(row, CsvExportColumns.categoryIconName).trim().isEmpty
          ? 'other'
          : _cellValue(row, CsvExportColumns.categoryIconName).trim(),
      colorHex: _normalizedColorHex(
        _cellValue(row, CsvExportColumns.categoryColorHex),
        isExpense: fallbackIsExpense,
      ),
      isExpense: fallbackIsExpense,
      sortOrder: _parseInt(
        _cellValue(row, CsvExportColumns.categorySortOrder),
        defaultValue: 0,
      ),
      groupId: _cellValue(row, CsvExportColumns.categoryGroupId).trim(),
    );
  }

  static CategoryGroup _buildGroupFromExtendedRow(List<dynamic> row) {
    final isExpense = _parseBool(
      _cellValue(row, CsvExportColumns.groupIsExpense),
      defaultValue: true,
    );
    return CategoryGroup(
      id: _nonEmptyOrUuid(_cellValue(row, CsvExportColumns.groupId)),
      name: _preferredValue(
        _cellValue(row, CsvExportColumns.groupName),
        '',
        fallback: isExpense ? '未命名支出大类' : '未命名收入大类',
      ),
      isExpense: isExpense,
      sortOrder: _parseInt(
        _cellValue(row, CsvExportColumns.groupSortOrder),
        defaultValue: 0,
      ),
    );
  }

  static bool _looksLikeExtendedRow(List<dynamic> row) {
    if (row.length <= CsvExportColumns.entityType) {
      return false;
    }

    final entityType = _cellValue(row, CsvExportColumns.entityType).trim();
    return entityType == CsvExportColumns.entityRecord ||
        entityType == CsvExportColumns.entityCategory ||
        entityType == CsvExportColumns.entityCategoryGroup;
  }

  static bool _isEmptyRow(List<dynamic> row) {
    return row.every((cell) => cell.toString().trim().isEmpty);
  }

  static bool _isHeaderRow(List<dynamic> row) {
    return row.isNotEmpty && _normalizeHeader(row.first.toString()) == 'id';
  }

  static String _cellValue(List<dynamic> row, int index) {
    if (index >= row.length) {
      return '';
    }
    return row[index]?.toString() ?? '';
  }

  static String _normalizeHeader(String value) {
    return value.replaceFirst('\uFEFF', '').trim().toLowerCase();
  }

  static String _preferredValue(
    String primary,
    String secondary, {
    String fallback = '',
  }) {
    final normalizedPrimary = primary.trim();
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }
    final normalizedSecondary = secondary.trim();
    if (normalizedSecondary.isNotEmpty) {
      return normalizedSecondary;
    }
    return fallback.trim();
  }

  static String _normalizedScope(String value) {
    return value == CsvExportColumns.scopeDeleted
        ? CsvExportColumns.scopeDeleted
        : CsvExportColumns.scopeActive;
  }

  static bool _parseImportType(String value) {
    final normalized = value.trim().toLowerCase();
    const expenseValues = {'支出', 'expense', 'exp', 'out', '1', 'true'};
    const incomeValues = {'收入', 'income', 'in', '0', 'false'};

    if (expenseValues.contains(normalized)) {
      return true;
    }
    if (incomeValues.contains(normalized)) {
      return false;
    }
    throw const FormatException('类型无效');
  }

  static double _parseAmount(String value) {
    final amountText = value.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      throw const FormatException('金额无效');
    }
    return amount;
  }

  static bool _parseBool(String value, {required bool defaultValue}) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return defaultValue;
    }

    const truthy = {'true', '1', 'yes', 'y', '支出', '是'};
    const falsy = {'false', '0', 'no', 'n', '收入', '否'};
    if (truthy.contains(normalized)) {
      return true;
    }
    if (falsy.contains(normalized)) {
      return false;
    }
    return defaultValue;
  }

  static int _parseInt(String value, {required int defaultValue}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return defaultValue;
    }
    return int.tryParse(normalized) ?? defaultValue;
  }

  static DateTime _parseImportDate(String value) {
    final parsed = _parseOptionalDateTime(value);
    if (parsed != null) {
      return parsed;
    }
    throw const FormatException('日期格式无效');
  }

  static DateTime? _parseOptionalDateTime(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    const formats = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
    ];

    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(normalized);
      } catch (_) {
        // Try next format.
      }
    }

    return DateTime.tryParse(normalized);
  }

  static String _nonEmptyOrUuid(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? const Uuid().v4() : normalized;
  }

  static String _normalizedColorHex(String value, {required bool isExpense}) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return isExpense ? '#64748B' : '#10B981';
  }

  static int _nextCategorySortOrder(
    Iterable<Category> categories,
    bool isExpense,
  ) {
    var maxSortOrder = -1;
    for (final category in categories) {
      if (category.isExpense == isExpense && category.sortOrder > maxSortOrder) {
        maxSortOrder = category.sortOrder;
      }
    }
    return maxSortOrder + 1;
  }

  static Category? _findCategoryInMapByName(
    Map<String, Category> categories,
    String name,
    bool isExpense,
  ) {
    for (final category in categories.values) {
      if (category.name == name && category.isExpense == isExpense) {
        return category;
      }
    }
    return null;
  }
}

class _RowStats {
  final int importedCount;
  final int updatedCount;
  final int createdCategoryCount;

  const _RowStats({
    this.importedCount = 0,
    this.updatedCount = 0,
    this.createdCategoryCount = 0,
  });
}

class _LegacyRecordParseResult {
  final Record record;
  final int createdCategoryCount;

  const _LegacyRecordParseResult({
    required this.record,
    required this.createdCategoryCount,
  });
}

class _CategoryResolution {
  final Category category;
  final int createdCategoryCount;

  const _CategoryResolution({
    required this.category,
    required this.createdCategoryCount,
  });
}
