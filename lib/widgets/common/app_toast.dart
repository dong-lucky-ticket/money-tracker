import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum AppToastType {
  info,
  success,
  error,
}

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    _show(
      context,
      message,
      type: AppToastType.info,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    _show(
      context,
      message,
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _show(
      context,
      message,
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _show(
    BuildContext context,
    String message, {
    required AppToastType type,
    required Duration duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    dismiss();

    final style = _ToastStyle.fromType(type);
    final entry = OverlayEntry(
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  bottomInset > 0 ? bottomInset + 20 : 84,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 12),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: style.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: style.borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x140F172A),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                style.icon,
                                size: 18,
                                color: style.iconColor,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: style.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _currentEntry = entry;
    _dismissTimer = Timer(duration, dismiss);
  }
}

class _ToastStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;

  const _ToastStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });

  factory _ToastStyle.fromType(AppToastType type) {
    switch (type) {
      case AppToastType.info:
        return const _ToastStyle(
          backgroundColor: Color(0xFFF3F8FF),
          borderColor: Color(0xFFD8E8FF),
          textColor: Color(0xFF1D4ED8),
          iconColor: AppColors.primary,
          icon: Icons.info_outline_rounded,
        );
      case AppToastType.success:
        return const _ToastStyle(
          backgroundColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
          textColor: Color(0xFF166534),
          iconColor: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case AppToastType.error:
        return const _ToastStyle(
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          textColor: Color(0xFFB91C1C),
          iconColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
    }
  }
}
