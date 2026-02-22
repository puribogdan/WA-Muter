import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/models/mute_schedule.dart';

class ScheduleProvider with ChangeNotifier {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  ScheduleProvider() {
    // Automatically load schedule when provider is created
    _initialize();
  }

  // Getters
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  bool get isLoading => _isLoading;

  /// Check if schedule is set (both start and end times are available)
  bool get hasSchedule => _startTime != null && _endTime != null;

  /// Get schedule preview string (e.g., "22:00 - 08:00")
  String get schedulePreview {
    if (!hasSchedule) return '';
    
    final startFormatted = _formatTime(_startTime!);
    final endFormatted = _formatTime(_endTime!);
    return '$startFormatted - $endFormatted';
  }

  /// Format TimeOfDay as HH:mm string
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Initialize provider by loading stored schedule
  Future<void> _initialize() async {
    await loadSchedule();
  }

  /// Load schedule from storage
  Future<void> loadSchedule() async {
    try {
      print('[ScheduleProvider] Loading schedule from storage...');
      _isLoading = true;
      notifyListeners();
      
      // First try to load complete schedule
      final schedule = await StorageService.getSchedule();
      if (schedule != null) {
        _startTime = schedule.startTime;
        _endTime = schedule.endTime;
        print('[ScheduleProvider] Complete schedule loaded: ${schedule.getFormattedTime()}');
      } else {
        print('[ScheduleProvider] No complete schedule found, checking for partial schedule...');
        
        // Try to load partial schedule info
        final partialInfo = await StorageService.getPartialScheduleInfo();
        if (partialInfo != null) {
          if (partialInfo['startHour'] != null && partialInfo['startMinute'] != null) {
            _startTime = TimeOfDay(hour: partialInfo['startHour'], minute: partialInfo['startMinute']);
            print('[ScheduleProvider] Partial start time loaded: ${_formatTime(_startTime!)}');
          }
          if (partialInfo['endHour'] != null && partialInfo['endMinute'] != null) {
            _endTime = TimeOfDay(hour: partialInfo['endHour'], minute: partialInfo['endMinute']);
            print('[ScheduleProvider] Partial end time loaded: ${_formatTime(_endTime!)}');
          }
        } else {
          print('[ScheduleProvider] No schedule data found in storage');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ScheduleProvider] Error loading schedule: $e');
      _isLoading = false;
      _startTime = null;
      _endTime = null;
      notifyListeners();
    }
  }

  /// Set start time and save immediately
  Future<void> setStartTime(TimeOfDay time) async {
    try {
      print('[ScheduleProvider] Setting start time to: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
      _startTime = time;
      
      // FIXED: Save start time component immediately for partial schedule support
      await StorageService.saveStartTimeComponent(time);
      
      // If both times are now set, save complete schedule
      if (_endTime != null) {
        print('[ScheduleProvider] Both times set, saving complete schedule');
        await StorageService.saveSchedule(time, _endTime!);
      }
      
      notifyListeners();
      print('[ScheduleProvider] Start time set and saved successfully');
    } catch (e) {
      print('[ScheduleProvider] Error setting start time: $e');
      rethrow;
    }
  }

  /// Set end time and save immediately
  Future<void> setEndTime(TimeOfDay time) async {
    try {
      print('[ScheduleProvider] Setting end time to: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
      _endTime = time;
      
      // FIXED: Save end time component immediately for partial schedule support
      await StorageService.saveEndTimeComponent(time);
      
      // If both times are now set, save complete schedule
      if (_startTime != null) {
        print('[ScheduleProvider] Both times set, saving complete schedule');
        await StorageService.saveSchedule(_startTime!, time);
      }
      
      notifyListeners();
      print('[ScheduleProvider] End time set and saved successfully');
    } catch (e) {
      print('[ScheduleProvider] Error setting end time: $e');
      rethrow;
    }
  }

  /// Clear schedule from storage and local state
  Future<void> clearSchedule() async {
    try {
      print('[ScheduleProvider] Clearing schedule');
      await StorageService.clearSchedule();
      _startTime = null;
      _endTime = null;
      notifyListeners();
      print('[ScheduleProvider] Schedule cleared successfully');
    } catch (e) {
      print('[ScheduleProvider] Error clearing schedule: $e');
      rethrow;
    }
  }

  /// Get duration in hours between start and end time
  int getDurationHours() {
    if (!hasSchedule) return 0;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 09:00 - 17:00)
      return (endMinutes - startMinutes) ~/ 60;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      final totalMinutes = (24 * 60 - startMinutes) + endMinutes;
      return totalMinutes ~/ 60;
    }
  }

  /// Check if current time is within the set schedule
  bool isWithinSchedule() {
    if (!hasSchedule) return false;
    
    final schedule = MuteSchedule(
      startTime: _startTime!,
      endTime: _endTime!,
    );
    
    return schedule.isWithinSchedule();
  }
}