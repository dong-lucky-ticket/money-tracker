import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/data_sync_progress.dart';
import '../models/record.dart';
import '../utils/category_rules.dart';

class RecordCategoryMigrationService {
  const RecordCategoryMigrationService._();

  static Future<void> migrate({
    required Box<Record> recordsBox,
    required Box<Category> categoriesBox,
    required Box settingsBox,
    required String versionKey,
    required int currentVersion,
    ValueChanged<DataSyncProgress>? onProgress,
  }) async {
    final records = recordsBox.values.toList(growable: false);
    final storedVersion = settingsBox.get(versionKey, defaultValue: 0) as int;
    final hasMissingGroupId = records.any((record) => record.category.groupId.isEmpty);

    if (storedVersion >= currentVersion && !hasMissingGroupId) {
      return;
    }

    if (records.isEmpty) {
      await settingsBox.put(versionKey, currentVersion);
      onProgress?.call(
        const DataSyncProgress(
          message: '本地数据已就绪',
          detail: '未发现需要补齐的历史记录',
          processed: 1,
          total: 1,
        ),
      );
      return;
    }

    var processed = 0;
    var updated = 0;
    final total = records.length;

    onProgress?.call(
      DataSyncProgress(
        message: '正在同步历史记录',
        detail: '检查并补齐历史记录的大类与分类信息',
        processed: 0,
        total: total,
      ),
    );

    for (final record in records) {
      var changed = false;
      final categories = categoriesBox.values;
      final normalizedLegacyCategory = resolveLegacyRecordCategory(
        category: record.category,
        categories: categories,
      );

      if (normalizedLegacyCategory != null &&
          !isSameCategorySnapshot(record.category, normalizedLegacyCategory)) {
        record.category = normalizedLegacyCategory;
        changed = true;
      }

      final mappedUtilityCategory = resolveUtilityCategoryFromRemark(
        category: record.category,
        remark: record.remark,
        categories: categories,
      );

      if (mappedUtilityCategory != null &&
          record.category.id != mappedUtilityCategory.id) {
        record.category = mappedUtilityCategory;
        changed = true;
      }

      final currentCategory = categoriesBox.get(record.category.id);
      if (currentCategory != null) {
        ensureCategoryGroupId(currentCategory);
        if (!isSameCategorySnapshot(record.category, currentCategory)) {
          record.category = currentCategory;
          changed = true;
        }
        if (record.category.groupId != currentCategory.groupId) {
          record.category.groupId = currentCategory.groupId;
          changed = true;
        }
      } else {
        final resolvedGroupId = resolveCategoryGroupId(record.category);
        if (record.category.groupId != resolvedGroupId) {
          record.category.groupId = resolvedGroupId;
          changed = true;
        }
      }

      if (changed) {
        await record.save();
        updated++;
      }

      processed++;
      if (onProgress != null &&
          (processed == 1 || processed == total || processed % 10 == 0)) {
        onProgress(
          DataSyncProgress(
            message: '正在同步历史记录',
            detail: '已处理 $processed / $total，已补齐 $updated 条记录',
            processed: processed,
            total: total,
          ),
        );
      }
    }

    await settingsBox.put(versionKey, currentVersion);
    onProgress?.call(
      DataSyncProgress(
        message: '本地数据已就绪',
        detail: updated > 0 ? '已补齐 $updated 条历史记录的大类信息' : '历史记录的大类信息已是最新状态',
        processed: total,
        total: total,
      ),
    );
  }
}
