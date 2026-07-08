import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ErrorLogEntry {
  final String id;
  final DateTime timestamp;
  final String source;
  final String errorType;
  final String message;
  final String stackTrace;
  final String? scene;
  final String appVersion;
  final String platform;

  const ErrorLogEntry({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.errorType,
    required this.message,
    required this.stackTrace,
    required this.scene,
    required this.appVersion,
    required this.platform,
  });

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: json['source'] as String? ?? 'unknown',
      errorType: json['errorType'] as String? ?? 'UnknownError',
      message: json['message'] as String? ?? '',
      stackTrace: json['stackTrace'] as String? ?? '',
      scene: json['scene'] as String?,
      appVersion: json['appVersion'] as String? ?? '--',
      platform: json['platform'] as String? ?? Platform.operatingSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'scene': scene,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  String get sourceLabel {
    switch (source) {
      case 'flutter_framework':
        return 'Flutter 框架';
      case 'platform_dispatcher':
        return '平台回调';
      case 'zone_guarded':
        return '异步 Zone';
      case 'bootstrap_initialize':
        return '启动初始化';
      case 'data_add_record':
        return '保存流水';
      case 'data_delete_record':
        return '删除流水';
      case 'data_add_category':
        return '新增分类';
      case 'data_add_category_group':
        return '新增大类';
      case 'data_update_category_group':
        return '更新大类';
      case 'data_reorder_category_groups':
        return '重排大类';
      case 'data_delete_category':
        return '删除分类';
      case 'data_reorder_categories':
        return '重排分类';
      case 'data_reorder_categories_in_group':
        return '组内重排分类';
      case 'data_clear_all_records':
        return '清空账单';
      case 'data_import_records_csv':
        return '数据层 CSV 导入';
      case 'data_toggle_theme':
        return '切换主题';
      case 'settings_import_csv':
        return 'CSV 导入';
      case 'settings_export_csv':
        return 'CSV 导出';
      case 'settings_share_error_logs':
        return '日志导出';
      case 'settings_view_error_logs':
        return '日志查看';
      case 'settings_clear_error_logs':
        return '日志清空';
      default:
        return source;
    }
  }

  String toReadableText() {
    final buffer = StringBuffer()
      ..writeln('时间: ${timestamp.toIso8601String()}')
      ..writeln('来源: $sourceLabel')
      ..writeln('错误类型: $errorType')
      ..writeln('错误信息: $message')
      ..writeln('应用版本: $appVersion')
      ..writeln('平台信息: $platform');

    if (scene != null && scene!.trim().isNotEmpty) {
      buffer.writeln('场景: ${scene!.trim()}');
    }

    if (stackTrace.trim().isNotEmpty) {
      buffer
        ..writeln('堆栈信息:')
        ..writeln(stackTrace.trim());
    }

    return buffer.toString().trimRight();
  }
}

class ErrorLogService extends ChangeNotifier {
  static const String boxName = 'errorLogsBox';
  static const String entriesKey = 'entries';
  static const String lastViewedAtKey = 'lastViewedAt';
  static const int maxEntries = 120;

  static final ErrorLogService instance = ErrorLogService._();

  ErrorLogService._();

  Box<dynamic>? _box;
  String _appVersion = '--';
  final List<ErrorLogEntry> _pendingEntries = [];
  bool _isInitialized = false;

  List<ErrorLogEntry> get entries {
    final storedEntries = _readStoredEntries();
    final allEntries = [
      ..._pendingEntries,
      ...storedEntries,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEntries;
  }

  int get entryCount => entries.length;

  ErrorLogEntry? get latestEntry {
    final currentEntries = entries;
    if (currentEntries.isEmpty) {
      return null;
    }
    return currentEntries.first;
  }

  bool get hasUnreadEntries {
    if (_pendingEntries.isNotEmpty) {
      return true;
    }

    final latest = latestEntry;
    if (latest == null) {
      return false;
    }

    if (_box == null) {
      return true;
    }

    final lastViewedAtText = _box!.get(lastViewedAtKey) as String?;
    final lastViewedAt =
        lastViewedAtText == null ? null : DateTime.tryParse(lastViewedAtText);
    if (lastViewedAt == null) {
      return true;
    }

    return latest.timestamp.isAfter(lastViewedAt);
  }

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    _box = await Hive.openBox<dynamic>(boxName);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion =
          packageInfo.version.isEmpty ? '--' : 'v${packageInfo.version}';
    } catch (_) {
      _appVersion = '--';
    }

    _isInitialized = true;
    await _flushPendingEntries();
    notifyListeners();
  }

  Future<void> record(
    Object error, {
    StackTrace? stackTrace,
    required String source,
    String? scene,
  }) async {
    try {
      final entry = ErrorLogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}_$source',
        timestamp: DateTime.now(),
        source: source,
        errorType: error.runtimeType.toString(),
        message: _truncate(error.toString(), 800),
        stackTrace: _truncate(
          (stackTrace ?? StackTrace.current).toString(),
          6000,
        ),
        scene: scene == null ? null : _truncate(scene, 300),
        appVersion: _appVersion,
        platform:
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

      if (_box == null) {
        _enqueuePending(entry);
        return;
      }

      final storedEntries = _readStoredEntries();
      storedEntries.insert(0, entry);
      final limitedEntries =
          storedEntries.take(maxEntries).toList(growable: false);
      await _box!.put(
        entriesKey,
        limitedEntries.map((item) => jsonEncode(item.toJson())).toList(),
      );
      notifyListeners();
    } catch (_) {
      // Swallow logging failures to avoid recursive crashes.
    }
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    required String source,
  }) async {
    final sceneParts = <String>[
      if (details.library?.trim().isNotEmpty ?? false) details.library!.trim(),
      if (details.context != null) details.context.toString(),
    ];

    await record(
      details.exception,
      stackTrace: details.stack,
      source: source,
      scene: sceneParts.isEmpty ? null : sceneParts.join(' | '),
    );
  }

  Future<void> clear() async {
    try {
      _pendingEntries.clear();
      if (_box != null) {
        await _box!.put(entriesKey, <String>[]);
        await _box!.put(lastViewedAtKey, DateTime.now().toIso8601String());
      }
      notifyListeners();
    } catch (_) {
      // Ignore clearing failures to keep the UI safe.
    }
  }

  Future<void> markViewed() async {
    try {
      if (_box != null) {
        await _box!.put(lastViewedAtKey, DateTime.now().toIso8601String());
      }
      notifyListeners();
    } catch (_) {
      // Ignore marker failures to keep the UI safe.
    }
  }

  String buildExportText() {
    final currentEntries = entries;
    if (currentEntries.isEmpty) {
      return '暂无错误日志';
    }

    return currentEntries
        .map((entry) => entry.toReadableText())
        .join('\n\n====================\n\n');
  }

  List<ErrorLogEntry> _readStoredEntries() {
    if (_box == null) {
      return const [];
    }

    final rawEntries =
        _box!.get(entriesKey, defaultValue: <dynamic>[]) as List<dynamic>;
    final parsedEntries = <ErrorLogEntry>[];

    for (final item in rawEntries) {
      try {
        if (item is String) {
          parsedEntries.add(
            ErrorLogEntry.fromJson(jsonDecode(item) as Map<String, dynamic>),
          );
          continue;
        }

        if (item is Map) {
          parsedEntries.add(
            ErrorLogEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      } catch (_) {
        // Skip malformed entries silently.
      }
    }

    return parsedEntries;
  }

  void _enqueuePending(ErrorLogEntry entry) {
    _pendingEntries.insert(0, entry);
    if (_pendingEntries.length > maxEntries) {
      _pendingEntries.removeRange(maxEntries, _pendingEntries.length);
    }
    notifyListeners();
  }

  Future<void> _flushPendingEntries() async {
    if (_box == null || _pendingEntries.isEmpty) {
      return;
    }

    final storedEntries = _readStoredEntries();
    storedEntries.insertAll(0, _pendingEntries);
    final limitedEntries =
        storedEntries.take(maxEntries).toList(growable: false);
    _pendingEntries.clear();

    await _box!.put(
      entriesKey,
      limitedEntries.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}
