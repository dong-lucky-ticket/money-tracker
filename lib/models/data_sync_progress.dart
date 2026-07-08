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
