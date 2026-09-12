import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/models/category_group.dart';
import 'package:expensetracker/models/record.dart';
import 'package:expensetracker/services/csv_export_service.dart';
import 'package:expensetracker/services/record_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reuses an existing category when backup ID differs', () {
    final existing = Category(
      id: 'local-id',
      name: '餐饮',
      iconName: 'food',
      colorHex: '#F97316',
      isExpense: true,
      groupId: CategoryGroupIds.expenseFood,
    );
    final backup = Category(
      id: 'backup-id',
      name: '餐饮',
      iconName: 'food',
      colorHex: '#F97316',
      isExpense: true,
      groupId: CategoryGroupIds.expenseFood,
    );
    final backupRecord = Record(
      id: 'record-id',
      amount: 12,
      category: backup,
      remark: '早餐',
      date: DateTime(2026, 1, 1),
      isExpense: true,
    );

    final csv = CsvExportService.buildCsv(
      activeRecords: [backupRecord],
      deletedRecords: const [],
      activeCategories: [backup],
      deletedCategories: const [],
      categoryGroups: const [],
    );

    final prepared = RecordImportService.prepareCsvImport(
      csvContent: csv,
      existingCategories: [existing],
      existingDeletedCategories: const [],
      existingCategoryGroups: const [],
      existingRecords: const [],
      existingDeletedRecords: const [],
      ensureCategoryGroupId: (_) {},
    );

    expect(prepared.activeCategoriesToImport, isEmpty);
    expect(prepared.result.createdCategoryCount, 0);
    expect(
        prepared.activeRecordsToImport['record-id']?.category.id, 'local-id');
  });
}
