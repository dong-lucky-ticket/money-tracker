import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'error_log_service.dart';

class AppErrorHandlerService {
  const AppErrorHandlerService._();

  static void run({
    required Future<void> Function() appRunner,
    ErrorLogService? errorLogService,
  }) {
    final service = errorLogService ?? ErrorLogService.instance;

    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        _configureGlobalHandlers(service);
        await appRunner();
      },
      (error, stackTrace) {
        unawaited(
          service.record(
            error,
            stackTrace: stackTrace,
            source: 'zone_guarded',
          ),
        );
      },
    );
  }

  static void _configureGlobalHandlers(ErrorLogService errorLogService) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        errorLogService.recordFlutterError(
          details,
          source: 'flutter_framework',
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        errorLogService.record(
          error,
          stackTrace: stackTrace,
          source: 'platform_dispatcher',
        ),
      );
      return true;
    };

    ErrorWidget.builder = (details) {
      return AppErrorFallback(
        message: details.exceptionAsString(),
      );
    };
  }
}

class AppErrorFallback extends StatelessWidget {
  final String message;

  const AppErrorFallback({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '页面发生了错误',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
