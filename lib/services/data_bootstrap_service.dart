import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/category_group.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import 'category_catalog_service.dart';
import 'record_category_migration_service.dart';

class DataBootstrapSnapshot {
  final Box<Record> recordsBox;
  final Box<Category> categoriesBox;
  final Box<CategoryGroup> categoryGroupsBox;
  final Box settingsBox;
  final bool isDarkTheme;

  const DataBootstrapSnapshot({
    required this.recordsBox,
    required this.categoriesBox,
    required this.categoryGroupsBox,
    required this.settingsBox,
    required this.isDarkTheme,
  });
}

class DataBootstrapService {
  static const String recordsBoxName = 'recordsBox';
  static const String categoriesBoxName = 'categoriesBox';
  static const String categoryGroupsBoxName = 'categoryGroupsBox';
  static const String settingsBoxName = 'settingsBox';
  static const String recordGroupMigrationVersionKey =
      'recordGroupMigrationVersion';
  static const int currentRecordGroupMigrationVersion = 6;

  const DataBootstrapService._();

  static Future<DataBootstrapSnapshot> bootstrap({
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    onProgress?.call(
      const DataSyncProgress(
        message: '正在准备本地数据',
        detail: '初始化账本与分类信息',
        isIndeterminate: true,
      ),
    );

    final recordsBox = await Hive.openBox<Record>(recordsBoxName);
    final categoriesBox = await Hive.openBox<Category>(categoriesBoxName);
    final categoryGroupsBox =
        await Hive.openBox<CategoryGroup>(categoryGroupsBoxName);
    final settingsBox = await Hive.openBox(settingsBoxName);
    final isDarkTheme = settingsBox.get('isDarkTheme', defaultValue: false);

    await CategoryCatalogService.syncDefaultCategoryGroups(categoryGroupsBox);
    await CategoryCatalogService.syncDefaultCategories(categoriesBox);
    await RecordCategoryMigrationService.migrate(
      recordsBox: recordsBox,
      categoriesBox: categoriesBox,
      settingsBox: settingsBox,
      versionKey: recordGroupMigrationVersionKey,
      currentVersion: currentRecordGroupMigrationVersion,
      onProgress: onProgress,
    );

    return DataBootstrapSnapshot(
      recordsBox: recordsBox,
      categoriesBox: categoriesBox,
      categoryGroupsBox: categoryGroupsBox,
      settingsBox: settingsBox,
      isDarkTheme: isDarkTheme,
    );
  }
}
