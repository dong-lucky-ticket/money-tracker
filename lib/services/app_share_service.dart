import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/common/app_toast.dart';

class AppShareService {
  static bool _isSharing = false;

  static Future<bool> shareXFiles(
    BuildContext context,
    List<XFile> files, {
    String? subject,
    Rect? sharePositionOrigin,
    String busyMessage = '分享面板尚未关闭，请稍后再试',
  }) async {
    if (_isSharing) {
      if (context.mounted) {
        AppToast.showInfo(context, busyMessage);
      }
      return false;
    }

    _isSharing = true;
    try {
      await Share.shareXFiles(
        files,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } on PlatformException catch (error) {
      if (_isShareCallbackConflict(error)) {
        if (context.mounted) {
          AppToast.showInfo(context, busyMessage);
        }
        return false;
      }
      rethrow;
    } finally {
      _isSharing = false;
    }
  }

  static bool _isShareCallbackConflict(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    return code.contains('share callback error') ||
        message.contains('prior share-sheet did not call back');
  }
}
