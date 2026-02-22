import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

class PermissionService {
  static const MethodChannel _systemChannel =
      MethodChannel('wa_notifications_app/system');

  static Future<bool> hasNotificationAccess() async {
    try {
      return await NotificationsListener.hasPermission == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openNotificationAccessSettings() async {
    await NotificationsListener.openPermissionSettings();
  }

  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result =
          await _systemChannel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openBatteryOptimizationSettings() async {
    await _systemChannel.invokeMethod('openBatteryOptimizationSettings');
  }
}
