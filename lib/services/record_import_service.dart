import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/csv_import_result.dart';
import '../models/record.dart';

class PreparedCsvImport {
  final Map<String, Record> recordsToImport;
  final List<Category> categoriesToCreate;
  final CsvImportResult result;

  const PreparedCsvImport({
    required this.recordsToImport,
    required this.categoriesToCreate,
    required this.result,
  });
}

class RecordImportService {
  const RecordImportService._();

  static PreparedCsvImport prepareCsvImport({
    required String csvContent,
    required Iterable<Category> existingCategories,
    required Iterable<Record> existingRecords,
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

    final existingCategoryList = existingCategories.toList(growable: false);
    final existingRecordIds = {
      for (final record in existingRecords) record.id,
    };
    final categoryCache = <String, Category>{
      for (final category in existingCategoryList)
        _categoryCacheKey(category.name, category.isExpense): category,
    };
    final nextSortOrders = <bool, int>{
      true: _nextCategorySortOrder(existingCategoryList, true),
      false: _nextCategorySortOrder(existingCategoryList, false),
    };

    final categoriesToCreate = <Category>[];
    final recordsToImport = <String, Record>{};
    var importedCount = 0;
    var updatedCount = 0;
    var skippedCount = 0;
    var createdCategoryCount = 0;

    for (final row in rows) {
      if (_isEmptyRow(row) || _isHeaderRow(row)) {
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
            sortOrder: nextSortOrders[isExpense]!,
          );
          nextSortOrders[isExpense] = category.sortOrder + 1;
          ensureCategoryGroupId(category);
          categoriesToCreate.add(category);
          categoryCache[cacheKey] = category;
          createdCategoryCount++;
        }

        final recordId = id.isEmpty ? const Uuid().v4() : id;
        final now = DateTime.now();
        final record = Record(
          id: recordId,
          amount: amount,
          category: category,
          remark: remark,
          date: _parseImportDate(dateText),
          isExpense: isExpense,
          createdAt: now,
          updatedAt: now,
        );

        if (recordsToImport.containsKey(recordId) || existingRecordIds.contains(recordId)) {
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

    return PreparedCsvImport(
      recordsToImport: recordsToImport,
      categoriesToCreate: categoriesToCreate,
      result: CsvImportResult(
        importedCount: importedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        createdCategoryCount: createdCategoryCount,
      ),
    );
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

  static bool _parseImportType(String value) {
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

  static DateTime _parseImportDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const FormatException('日期为空');
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
        // Keep trying other supported export-compatible formats.
      }
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }

    throw const FormatException('日期格式无效');
  }

  static String _categoryCacheKey(String name, bool isExpense) {
    return '${isExpense ? 'expense' : 'income'}::${name.trim()}';
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
}
