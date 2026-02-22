import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/mute_schedule.dart';
import 'native_bridge.dart';

class StorageService {
  static const String _selectedGroupsKey = 'selected_groups';
  static const String _scheduleStartHourKey = 'schedule_start_hour';
  static const String _scheduleStartMinuteKey = 'schedule_start_minute';
  static const String _scheduleEndHourKey = 'schedule_end_hour';
  static const String _scheduleEndMinuteKey = 'schedule_end_minute';
  static const String _hasPartialScheduleKey = 'has_partial_schedule';

  /// Get the list of selected group names from native SharedPreferences
  static Future<List<String>> getSelectedGroups() async {
    try {
      // Read directly from native storage (single source of truth)
      final nativeGroups = await NativeBridge.getMutedGroups();
      if (nativeGroups.isNotEmpty) {
        print(
            '[StorageService] ✅ Loaded ${nativeGroups.length} groups from native storage');
        return nativeGroups;
      }

      // Fallback to Flutter SharedPreferences if no native data exists
      print(
          '[StorageService] 📝 No groups in native storage, checking Flutter storage...');
      final prefs = await SharedPreferences.getInstance();
      final groupsList = prefs.getStringList(_selectedGroupsKey);

      if (groupsList != null && groupsList.isNotEmpty) {
        print(
            '[StorageService] 📝 Found ${groupsList.length} groups in Flutter storage, migrating to native...');
        // Migrate data to native storage
        await NativeBridge.saveMutedGroups(groupsList);
        return groupsList;
      }

      return [];
    } catch (e) {
      print('[StorageService] Error loading groups: $e');
      return [];
    }
  }

  /// Add a group name to the selected groups list
  static Future<void> addGroup(String groupName) async {
    try {
      final currentGroups = await getSelectedGroups();

      // Add the group if it doesn't already exist
      if (!currentGroups.contains(groupName)) {
        currentGroups.add(groupName);
        await NativeBridge.saveMutedGroups(currentGroups);
        print(
            '[StorageService] ✅ Group "$groupName" added and synced to native storage');
      }
    } catch (e) {
      print('[StorageService] Error adding group: $e');
      rethrow;
    }
  }

  /// Remove a group name from the selected groups list
  static Future<void> removeGroup(String groupName) async {
    try {
      final currentGroups = await getSelectedGroups();

      // Remove the group if it exists
      if (currentGroups.contains(groupName)) {
        currentGroups.remove(groupName);
        await NativeBridge.saveMutedGroups(currentGroups);
        print(
            '[StorageService] ✅ Group "$groupName" removed and synced to native storage');
      }
    } catch (e) {
      print('[StorageService] Error removing group: $e');
      rethrow;
    }
  }

  /// Check if a group name is in the selected groups list
  static Future<bool> isGroupSelected(String groupName) async {
    try {
      final currentGroups = await getSelectedGroups();
      return currentGroups.contains(groupName);
    } catch (e) {
      print('[StorageService] Error checking group selection: $e');
      return false;
    }
  }

  /// Save partial start time component
  static Future<void> saveStartTimeComponent(TimeOfDay time) async {
    try {
      print(
          '[StorageService] Saving start time component: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');

      final prefs = await SharedPreferences.getInstance();

      // Validate time values
      if (time.hour < 0 ||
          time.hour > 23 ||
          time.minute < 0 ||
          time.minute > 59) {
        throw ArgumentError('Invalid start time: ${time.hour}:${time.minute}');
      }

      await prefs.setInt(_scheduleStartHourKey, time.hour);
      await prefs.setInt(_scheduleStartMinuteKey, time.minute);
      await prefs.setBool(_hasPartialScheduleKey, true);

      print('[StorageService] Start time component saved to Flutter storage');
    } catch (e) {
      print('[StorageService] Error saving start time component: $e');
      rethrow;
    }
  }

  /// Save partial end time component
  static Future<void> saveEndTimeComponent(TimeOfDay time) async {
    try {
      print(
          '[StorageService] Saving end time component: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');

      final prefs = await SharedPreferences.getInstance();

      // Validate time values
      if (time.hour < 0 ||
          time.hour > 23 ||
          time.minute < 0 ||
          time.minute > 59) {
        throw ArgumentError('Invalid end time: ${time.hour}:${time.minute}');
      }

      await prefs.setInt(_scheduleEndHourKey, time.hour);
      await prefs.setInt(_scheduleEndMinuteKey, time.minute);
      await prefs.setBool(_hasPartialScheduleKey, true);

      print('[StorageService] End time component saved to Flutter storage');
    } catch (e) {
      print('[StorageService] Error saving end time component: $e');
      rethrow;
    }
  }

  /// Save schedule times to native SharedPreferences (SINGLE STORAGE)
  static Future<void> saveSchedule(TimeOfDay start, TimeOfDay end) async {
    try {
      print(
          '[StorageService] Saving complete schedule: Start=${start.hour}:${start.minute.toString().padLeft(2, '0')}, End=${end.hour}:${end.minute.toString().padLeft(2, '0')}');

      // Validate time values
      if (start.hour < 0 ||
          start.hour > 23 ||
          start.minute < 0 ||
          start.minute > 59) {
        throw ArgumentError(
            'Invalid start time: ${start.hour}:${start.minute}');
      }
      if (end.hour < 0 || end.hour > 23 || end.minute < 0 || end.minute > 59) {
        throw ArgumentError('Invalid end time: ${end.hour}:${end.minute}');
      }

      // Save directly to native storage (single source of truth)
      await NativeBridge.saveSchedule({
        'startHour': start.hour,
        'startMinute': start.minute,
        'endHour': end.hour,
        'endMinute': end.minute,
      });

      print(
          '[StorageService] ✅ Complete schedule saved to native storage (SINGLE STORAGE)');
    } catch (e) {
      print('[StorageService] Error saving schedule: $e');
      rethrow;
    }
  }

  /// Get schedule from native SharedPreferences (SINGLE STORAGE)
  static Future<MuteSchedule?> getSchedule() async {
    try {
      // Read directly from native storage (single source of truth)
      final nativeSchedule = await NativeBridge.getSchedule();

      if (nativeSchedule != null) {
        final startHour = nativeSchedule['startHour'] as int;
        final startMinute = nativeSchedule['startMinute'] as int;
        final endHour = nativeSchedule['endHour'] as int;
        final endMinute = nativeSchedule['endMinute'] as int;

        final isValid = startHour >= 0 &&
            startHour <= 23 &&
            startMinute >= 0 &&
            startMinute <= 59 &&
            endHour >= 0 &&
            endHour <= 23 &&
            endMinute >= 0 &&
            endMinute <= 59;

        if (!isValid) {
          return null;
        }

        final schedule = MuteSchedule(
          startTime: TimeOfDay(
            hour: startHour,
            minute: startMinute,
          ),
          endTime: TimeOfDay(
            hour: endHour,
            minute: endMinute,
          ),
        );
        print(
            '[StorageService] ✅ Schedule loaded from native storage: ${schedule.getFormattedTime()}');
        return schedule;
      }

      // Fallback to Flutter SharedPreferences if no native data exists
      print(
          '[StorageService] 📝 No schedule in native storage, checking Flutter storage...');
      final prefs = await SharedPreferences.getInstance();

      final startHour = prefs.getInt(_scheduleStartHourKey);
      final startMinute = prefs.getInt(_scheduleStartMinuteKey);
      final endHour = prefs.getInt(_scheduleEndHourKey);
      final endMinute = prefs.getInt(_scheduleEndMinuteKey);

      // Check if all values are present
      if (startHour != null &&
          startMinute != null &&
          endHour != null &&
          endMinute != null) {
        final schedule = MuteSchedule(
          startTime: TimeOfDay(hour: startHour, minute: startMinute),
          endTime: TimeOfDay(hour: endHour, minute: endMinute),
        );
        print(
            '[StorageService] 📝 Found schedule in Flutter storage, migrating to native...');

        // Migrate data to native storage
        await NativeBridge.saveSchedule({
          'startHour': startHour,
          'startMinute': startMinute,
          'endHour': endHour,
          'endMinute': endMinute,
        });

        print('[StorageService] ✅ Schedule migrated to native storage');
        return schedule;
      }

      print('[StorageService] 📝 No complete schedule found');
      return null;
    } catch (e) {
      print('[StorageService] Error loading schedule: $e');
      return null;
    }
  }

  /// Get partial schedule information
  static Future<Map<String, dynamic>?> getPartialScheduleInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final startHour = prefs.getInt(_scheduleStartHourKey);
      final startMinute = prefs.getInt(_scheduleStartMinuteKey);
      final endHour = prefs.getInt(_scheduleEndHourKey);
      final endMinute = prefs.getInt(_scheduleEndMinuteKey);
      final hasPartial = prefs.getBool(_hasPartialScheduleKey) ?? false;

      print(
          '[StorageService] Partial schedule info - Start: $startHour:$startMinute, End: $endHour:$endMinute, Has partial: $hasPartial');

      if (hasPartial) {
        return {
          'startHour': startHour,
          'startMinute': startMinute,
          'endHour': endHour,
          'endMinute': endMinute,
        };
      }

      return null;
    } catch (e) {
      print('[StorageService] Error getting partial schedule info: $e');
      return null;
    }
  }

  /// Clear schedule from native SharedPreferences
  static Future<void> clearSchedule() async {
    try {
      // For now, we'll clear both locations to ensure cleanup
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scheduleStartHourKey);
      await prefs.remove(_scheduleStartMinuteKey);
      await prefs.remove(_scheduleEndHourKey);
      await prefs.remove(_scheduleEndMinuteKey);
      await prefs.remove(_hasPartialScheduleKey);

      // Clear from native storage by saving empty schedule
      await NativeBridge.saveSchedule({
        'startHour': -1,
        'startMinute': -1,
        'endHour': -1,
        'endMinute': -1,
      });

      print('[StorageService] Schedule cleared from all storage locations');
    } catch (e) {
      print('[StorageService] Error clearing schedule: $e');
      rethrow;
    }
  }
}
