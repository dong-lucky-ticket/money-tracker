import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import '../providers/data_provider.dart';
import 'error_log_service.dart';
import 'operation_log_service.dart';

class AppBootstrapSnapshot {
  final DataProvider dataProvider;
  final ErrorLogService errorLogService;
  final OperationLogService operationLogService;

  const AppBootstrapSnapshot({
    required this.dataProvider,
    required this.errorLogService,
    required this.operationLogService,
  });
}

class AppBootstrapService {
  static const DataSyncProgress initialProgress = DataSyncProgress(
    message: '正在启动应用',
    detail: '准备加载本地账本数据',
    isIndeterminate: true,
  );

  const AppBootstrapService._();

  static Future<AppBootstrapSnapshot> bootstrap({
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    await Hive.initFlutter();
    await ErrorLogService.instance.init();
    await OperationLogService.instance.init();
    _registerAdapters();

    final dataProvider = DataProvider();
    await dataProvider.init(onProgress: onProgress);

    return AppBootstrapSnapshot(
      dataProvider: dataProvider,
      errorLogService: ErrorLogService.instance,
      operationLogService: OperationLogService.instance,
    );
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryGroupAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RecordAdapter());
    }
  }
}
