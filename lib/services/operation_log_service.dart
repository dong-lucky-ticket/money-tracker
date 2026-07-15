import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OperationLogEntry {
  final String id;
  final DateTime timestamp;
  final String title;
  final String detail;
  final String category;
  final String appVersion;
  final String platform;

  const OperationLogEntry({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.detail,
    required this.category,
    required this.appVersion,
    required this.platform,
  });

  factory OperationLogEntry.fromJson(Map<String, dynamic> json) {
    return OperationLogEntry(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      title: json['title'] as String? ?? '未知操作',
      detail: json['detail'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      appVersion: json['appVersion'] as String? ?? '--',
      platform: json['platform'] as String? ?? Platform.operatingSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'detail': detail,
      'category': category,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  String toReadableText() {
    final buffer = StringBuffer()
      ..writeln('时间: ${timestamp.toIso8601String()}')
      ..writeln('操作: $title')
      ..writeln('分类: $category')
      ..writeln('应用版本: $appVersion')
      ..writeln('平台信息: $platform');

    if (detail.trim().isNotEmpty) {
      buffer.writeln('详情: ${detail.trim()}');
    }

    return buffer.toString().trimRight();
  }
}

class OperationLogService extends ChangeNotifier {
  static const String boxName = 'operationLogsBox';
  static const String entriesKey = 'entries';
  static const String lastViewedAtKey = 'lastViewedAt';
  static const int maxEntries = 200;

  static final OperationLogService instance = OperationLogService._();

  OperationLogService._();

  Box<dynamic>? _box;
  String _appVersion = '--';
  final List<OperationLogEntry> _pendingEntries = [];
  bool _isInitialized = false;

  List<OperationLogEntry> get entries {
    final storedEntries = _readStoredEntries();
    final allEntries = [
      ..._pendingEntries,
      ...storedEntries,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEntries;
  }

  int get entryCount => entries.length;

  OperationLogEntry? get latestEntry {
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

  Future<void> record({
    required String title,
    String detail = '',
    String category = 'general',
  }) async {
    try {
      final entry = OperationLogEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}_$category',
        timestamp: DateTime.now(),
        title: _truncate(title, 80),
        detail: _truncate(detail, 500),
        category: _truncate(category, 40),
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
      // Swallow logging failures to avoid breaking the main flow.
    }
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

  List<OperationLogEntry> _readStoredEntries() {
    if (_box == null) {
      return const [];
    }

    final rawEntries =
        _box!.get(entriesKey, defaultValue: <dynamic>[]) as List<dynamic>;
    final parsedEntries = <OperationLogEntry>[];

    for (final item in rawEntries) {
      try {
        if (item is String) {
          parsedEntries.add(
            OperationLogEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            ),
          );
          continue;
        }

        if (item is Map) {
          parsedEntries.add(
            OperationLogEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      } catch (_) {
        // Skip malformed entries silently.
      }
    }

    return parsedEntries;
  }

  void _enqueuePending(OperationLogEntry entry) {
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
