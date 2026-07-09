import 'dart:async';

import 'package:flutter/material.dart';

import '../models/data_sync_progress.dart';
import '../providers/data_provider.dart';
import '../services/app_bootstrap_service.dart';
import '../services/error_log_service.dart';

class AppBootstrapController extends ChangeNotifier {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1500);
  static const Duration _slowHintDelay = Duration(milliseconds: 1800);

  DataProvider? _dataProvider;
  ErrorLogService? _errorLogService;
  DataSyncProgress _progress = AppBootstrapService.initialProgress;
  String? _errorMessage;
  bool _showSlowHint = false;
  Timer? _slowHintTimer;
  int _bootstrapToken = 0;
  bool _isDisposed = false;

  DataProvider? get dataProvider => _dataProvider;
  ErrorLogService? get errorLogService => _errorLogService;
  DataSyncProgress get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get showSlowHint => _showSlowHint;
  bool get isReady => _dataProvider != null && _errorLogService != null;

  void startBootstrap() {
    final bootstrapToken = ++_bootstrapToken;
    final minimumSplashFuture = Future<void>.delayed(_minimumSplashDuration);

    _slowHintTimer?.cancel();
    _dataProvider = null;
    _errorLogService = null;
    _errorMessage = null;
    _showSlowHint = false;
    _progress = AppBootstrapService.initialProgress;
    _notifySafely();

    _slowHintTimer = Timer(_slowHintDelay, () {
      if (!_canUpdate(bootstrapToken) || isReady || _errorMessage != null) {
        return;
      }

      _showSlowHint = true;
      _notifySafely();
    });

    _initialize(
      bootstrapToken: bootstrapToken,
      minimumSplashFuture: minimumSplashFuture,
    );
  }

  Future<void> _initialize({
    required int bootstrapToken,
    required Future<void> minimumSplashFuture,
  }) async {
    try {
      final snapshot = await AppBootstrapService.bootstrap(
        onProgress: (progress) {
          if (!_canUpdate(bootstrapToken)) {
            return;
          }

          _progress = progress;
          _notifySafely();
        },
      );

      await minimumSplashFuture;
      if (!_canUpdate(bootstrapToken)) {
        return;
      }

      _slowHintTimer?.cancel();
      _dataProvider = snapshot.dataProvider;
      _errorLogService = snapshot.errorLogService;
      _notifySafely();
    } catch (e, stackTrace) {
      await ErrorLogService.instance.record(
        e,
        stackTrace: stackTrace,
        source: 'bootstrap_initialize',
      );
      await minimumSplashFuture;

      if (!_canUpdate(bootstrapToken)) {
        return;
      }

      _slowHintTimer?.cancel();
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  bool _canUpdate(int bootstrapToken) {
    return !_isDisposed && bootstrapToken == _bootstrapToken;
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _slowHintTimer?.cancel();
    super.dispose();
  }
}
