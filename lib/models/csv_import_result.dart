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
