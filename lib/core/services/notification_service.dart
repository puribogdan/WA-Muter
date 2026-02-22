import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

import '../constants.dart';
import 'detected_groups_service.dart';
import 'schedule_service.dart';

void _enhancedLog(String message, {String level = 'INFO'}) {
  if (!kDebugMode && level != 'WARNING' && level != 'ERROR') return;
  final timestamp = DateTime.now().toIso8601String();
  developer.log('[$timestamp] [$level] $message');
}

@pragma('vm:entry-point')
void _callback(NotificationEvent evt) {
  _enhancedLog('[BACKGROUND] Received: ${evt.packageName} - ${evt.title}');
  final SendPort? send = IsolateNameServer.lookupPortByName('_listener_');
  if (send == null) {
    _enhancedLog('[BACKGROUND] Cannot find sender port', level: 'ERROR');
    return;
  }
  send.send(evt);
}

class NotificationService {
  static final DetectedGroupsService _detectedGroupsService =
      DetectedGroupsService();
  static final ScheduleService _scheduleService = ScheduleService();

  static bool _isListening = false;
  static ReceivePort? _port;
  static DateTime? _serviceStartTime;
  static bool _isForegroundMode = false;
  static bool _serviceInitialized = false;
  static bool _uiMonitoringActive = false;

  static Future<void> startListening() async {
    final nativeServiceRunning = await checkServiceStatus();

    if (_isListening && nativeServiceRunning) {
      if (!_uiMonitoringActive) {
        _uiMonitoringActive = true;
      }
      return;
    }

    if (_isListening && !nativeServiceRunning) {
      _isListening = false;
      _isForegroundMode = false;
      _uiMonitoringActive = false;
      _serviceStartTime = null;
    }

    try {
      if (!_serviceInitialized) {
        try {
          IsolateNameServer.removePortNameMapping('_listener_');
        } catch (_) {}

        _port = ReceivePort();
        if (!IsolateNameServer.registerPortWithName(
          _port!.sendPort,
          '_listener_',
        )) {
          _enhancedLog('Failed to register listener port', level: 'ERROR');
          return;
        }

        _port!.listen((message) {
          if (!_uiMonitoringActive) return;
          if (message is NotificationEvent) {
            _handleNotificationInUI(message);
          }
        });

        NotificationsListener.initialize(callbackHandle: _callback);
        _serviceInitialized = true;
      }

      final selectedGroupsCount = await _getConfiguredGroupCount();
      final isScheduleActive = await _hasAnyActiveScheduleNow();

      await NotificationsListener.startService(
        title: _getNotificationTitle(selectedGroupsCount, isScheduleActive),
        description:
            _getNotificationDescription(selectedGroupsCount, isScheduleActive),
      );

      _serviceStartTime = DateTime.now();
      _isListening = true;
      _isForegroundMode = true;
      _uiMonitoringActive = true;
    } catch (e) {
      _enhancedLog('Failed to start notification service: $e', level: 'ERROR');
      rethrow;
    }
  }

  static Future<void> updateForegroundNotification() async {
    if (!_isListening || !_isForegroundMode) return;

    try {
      final selectedGroupsCount = await _getConfiguredGroupCount();
      final isScheduleActive = await _hasAnyActiveScheduleNow();
      final newTitle = _getNotificationTitle(selectedGroupsCount, isScheduleActive);
      _getNotificationDescription(selectedGroupsCount, isScheduleActive);
      _enhancedLog('Service state: $newTitle');
    } catch (e) {
      _enhancedLog('Notification update not supported: $e', level: 'WARNING');
    }
  }

  static String _getNotificationTitle(int groupCount, bool isScheduleActive) {
    if (groupCount == 0) return 'WhatsApp Scheduler Active';
    return isScheduleActive
        ? 'Active - $groupCount groups muted'
        : 'Paused - $groupCount groups configured';
  }

  static String _getNotificationDescription(
    int groupCount,
    bool isScheduleActive,
  ) {
    if (groupCount == 0) return 'No groups configured';
    return isScheduleActive
        ? 'Blocking notifications from muted groups'
        : 'Schedule inactive - notifications allowed';
  }

  // Native Android enforces muting. Flutter only collects lightweight telemetry.
  static void _handleNotificationInUI(NotificationEvent event) async {
    final start = DateTime.now();

    if (event.packageName == AppConstants.whatsappPackage ||
        event.packageName == AppConstants.whatsappBusinessPackage) {
      final notificationTitle = (event.title ?? '').trim();
      if (notificationTitle.isNotEmpty) {
        await _detectedGroupsService.add(notificationTitle);
      }
      final duration = DateTime.now().difference(start).inMilliseconds;
      _enhancedLog(
        '[UI] Native layer enforces mute policy; Flutter processed telemetry in ${duration}ms',
      );
      return;
    }

    _enhancedLog('[UI] Non-WhatsApp notification ignored: ${event.packageName}');
  }

  static Future<void> stopListening() async {
    _uiMonitoringActive = false;
  }

  static Future<void> resumeListening() async {
    _uiMonitoringActive = true;
  }

  static Future<void> stopForegroundService() async {
    try {
      await NotificationsListener.stopService();
      _uiMonitoringActive = false;
      _isListening = false;
      _isForegroundMode = false;
      _serviceStartTime = null;
      _port?.close();
      _port = null;
      _serviceInitialized = false;
    } catch (e) {
      _enhancedLog('Failed to stop foreground service: $e', level: 'ERROR');
      rethrow;
    }
  }

  static bool get isListening => _uiMonitoringActive;
  static bool get isForegroundMode => _isForegroundMode;

  static String get serviceUptime {
    if (_serviceStartTime == null) return 'Not running';
    final duration = DateTime.now().difference(_serviceStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  static DateTime? get serviceStartTime => _serviceStartTime;
  static bool get isServiceRunning => _isListening;

  static Future<bool> checkServiceStatus() async {
    try {
      final hasPermission = await NotificationsListener.hasPermission;
      if (hasPermission != true) return false;
      final isRunning = await NotificationsListener.isRunning;
      return isRunning == true;
    } catch (e) {
      _enhancedLog('Service status check failed: $e', level: 'ERROR');
      return false;
    }
  }

  static Future<bool> ensureServiceRunning() async {
    final serviceIsRunning = await checkServiceStatus();
    if (!serviceIsRunning) {
      try {
        await startListening();
        return true;
      } catch (_) {
        return false;
      }
    }
    if (!_uiMonitoringActive) {
      await resumeListening();
    }
    return true;
  }

  static Future<void> handleAppLifecycle() async {
    await ensureServiceRunning();
  }

  static void testLogging() {
    _enhancedLog('TEST LOG');
  }

  static Future<int> _getConfiguredGroupCount() async {
    final schedules = await _scheduleService.getAllSchedules();
    final groups = <String>{};
    for (final schedule in schedules.where((s) => s.enabled)) {
      for (final group in schedule.groups) {
        final trimmed = group.trim();
        if (trimmed.isNotEmpty) groups.add(trimmed);
      }
    }
    return groups.length;
  }

  static Future<bool> _hasAnyActiveScheduleNow() async {
    final schedules = await _scheduleService.getAllSchedules();
    return schedules.any((s) => s.isActiveNow());
  }
}
