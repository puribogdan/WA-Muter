import 'package:flutter/services.dart';
import 'dart:convert';

/// Bridge to save data in a way that native Android code can access
class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel('flutter_notification_listener/native_prefs');
  static const EventChannel _muteLogEventsChannel =
      EventChannel('flutter_notification_listener/mute_log_events');

  /// Save muted groups to native-accessible SharedPreferences
  static Future<void> saveMutedGroups(List<String> groups) async {
    try {
      await _channel.invokeMethod('saveMutedGroups', {
        'groups': groups,
      });
      print(
          '[NativeBridge] Saved ${groups.length} muted groups for native access');
    } catch (e) {
      print('[NativeBridge] Error saving groups for native access: $e');
    }
  }

  /// Save schedule to native-accessible SharedPreferences
  static Future<void> saveSchedule(Map<String, dynamic> schedule) async {
    try {
      await _channel.invokeMethod('saveSchedule', schedule);
      print('[NativeBridge] Saved schedule for native access: $schedule');
    } catch (e) {
      print('[NativeBridge] Error saving schedule for native access: $e');
    }
  }

  /// Get schedule from native-accessible SharedPreferences
  static Future<Map<String, dynamic>?> getSchedule() async {
    try {
      final result = await _channel.invokeMethod('getSchedule');
      if (result != null) {
        print('[NativeBridge] Retrieved schedule from native access: $result');
        return Map<String, dynamic>.from(result);
      }
      print('[NativeBridge] No schedule found in native storage');
      return null;
    } catch (e) {
      print('[NativeBridge] Error getting schedule from native access: $e');
      return null;
    }
  }

  /// Get muted groups from native-accessible SharedPreferences
  static Future<List<String>> getMutedGroups() async {
    try {
      final result = await _channel.invokeMethod('getMutedGroups');
      if (result != null && result is List) {
        print(
            '[NativeBridge] Retrieved ${result.length} groups from native access');
        return List<String>.from(result);
      }
      print('[NativeBridge] No groups found in native storage');
      return [];
    } catch (e) {
      print('[NativeBridge] Error getting groups from native access: $e');
      return [];
    }
  }

  /// Save full schedules payload for native schedule evaluation.
  static Future<void> saveSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      await _channel.invokeMethod('saveSchedules', {
        'schedulesJson': jsonEncode(schedules),
      });
    } catch (e) {
      print('[NativeBridge] Error saving schedules for native access: $e');
    }
  }

  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      await _channel.invokeMethod('saveAppSettings', {
        'settingsJson': jsonEncode(settings),
      });
    } catch (e) {
      print('[NativeBridge] Error saving app settings for native access: $e');
    }
  }

  /// Append a mute log entry in native storage.
  static Future<void> saveMuteLog({
    required String groupName,
    required String status,
  }) async {
    try {
      await _channel.invokeMethod('saveMuteLog', {
        'groupName': groupName,
        'status': status,
      });
    } catch (e) {
      print('[NativeBridge] Error saving mute log: $e');
    }
  }

  /// Read mute log entries from native storage.
  static Future<List<Map<String, dynamic>>> getMuteLogs() async {
    try {
      final result = await _channel.invokeMethod('getMuteLogs');
      if (result is List) {
        return result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e) {
      print('[NativeBridge] Error getting mute logs: $e');
      return [];
    }
  }

  /// Stream native mute-log append events for real-time dashboard updates.
  static Stream<Map<String, dynamic>> muteLogEvents() {
    return _muteLogEventsChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }
}
