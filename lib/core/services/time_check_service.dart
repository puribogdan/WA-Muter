import 'package:flutter/material.dart';

class TimeCheckService {
  /// Check if current time is within the specified schedule range
  /// 
  /// Handles both same-day ranges (e.g., 09:00 - 17:00) and overnight ranges (e.g., 22:00 - 08:00)
  /// 
  /// [start] - Start time of the mute schedule
  /// [end] - End time of the mute schedule
  /// 
  /// Returns true if current time is within the mute schedule, false otherwise
  static bool isWithinSchedule(TimeOfDay start, TimeOfDay end) {
    final now = TimeOfDay.now();
    
    // Convert times to minutes since midnight for easier comparison
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);
    final nowMinutes = _timeToMinutes(now);
    
    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 09:00 - 17:00)
      // Current time is within schedule if it's >= start AND < end
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      // Current time is within schedule if it's >= start OR < end
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
  
  /// Alternative method that takes individual hour and minute values
  /// 
  /// [startHour] - Start hour (0-23)
  /// [startMinute] - Start minute (0-59)
  /// [endHour] - End hour (0-23)
  /// [endMinute] - End minute (0-59)
  /// 
  /// Returns true if current time is within the specified time range
  static bool isWithinScheduleByValues(
    int startHour, 
    int startMinute, 
    int endHour, 
    int endMinute
  ) {
    final start = TimeOfDay(hour: startHour, minute: startMinute);
    final end = TimeOfDay(hour: endHour, minute: endMinute);
    return isWithinSchedule(start, end);
  }
  
  /// Get duration in hours between start and end time
  /// 
  /// [start] - Start time
  /// [end] - End time
  /// 
  /// Returns the duration in hours (handles overnight ranges correctly)
  static int getDurationHours(TimeOfDay start, TimeOfDay end) {
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);
    
    if (startMinutes <= endMinutes) {
      // Same day range
      return (endMinutes - startMinutes) ~/ 60;
    } else {
      // Overnight range
      final totalMinutes = (24 * 60 - startMinutes) + endMinutes;
      return totalMinutes ~/ 60;
    }
  }
  
  /// Check if a time range is considered "long" (over 12 hours)
  /// 
  /// [start] - Start time
  /// [end] - End time
  /// 
  /// Returns true if the duration is more than 12 hours
  static bool isLongSchedule(TimeOfDay start, TimeOfDay end) {
    return getDurationHours(start, end) > 12;
  }
  
  /// Convert TimeOfDay to total minutes since midnight
  static int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
  
  /// Format TimeOfDay as HH:mm string
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Get formatted schedule string (e.g., "22:00 - 08:00")
  static String getFormattedSchedule(TimeOfDay start, TimeOfDay end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }
}