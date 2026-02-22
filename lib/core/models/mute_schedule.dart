import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class MuteSchedule {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Set<int> days; // 1=Mon ... 7=Sun
  final List<String> groups;
  final bool enabled;

  MuteSchedule({
    String? id,
    String? name,
    required this.startTime,
    required this.endTime,
    Set<int>? days,
    List<String>? groups,
    this.enabled = true,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name = name?.trim().isNotEmpty == true ? name!.trim() : 'Schedule',
        days = days ?? <int>{1, 2, 3, 4, 5, 6, 7},
        groups = groups ?? const [];

  TimeOfDay get start => startTime;
  TimeOfDay get end => endTime;

  MuteSchedule copyWith({
    String? id,
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Set<int>? days,
    List<String>? groups,
    bool? enabled,
  }) {
    return MuteSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
      groups: groups ?? this.groups,
      enabled: enabled ?? this.enabled,
    );
  }

  bool isDayActive(int dayOfWeek) {
    return days.contains(dayOfWeek);
  }

  bool isActiveNow() {
    final now = DateTime.now();
    if (!enabled) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);

    if (startMinutes <= endMinutes) {
      return isDayActive(now.weekday) &&
          nowMinutes >= startMinutes &&
          nowMinutes < endMinutes;
    }

    // Overnight: after midnight belongs to the previous selected day.
    if (nowMinutes >= startMinutes) {
      return isDayActive(now.weekday);
    }
    final previousDay = now.weekday == DateTime.monday ? DateTime.sunday : now.weekday - 1;
    return isDayActive(previousDay) && nowMinutes < endMinutes;
  }

  String get daysSummary {
    if (setEquals(days, {1, 2, 3, 4, 5, 6, 7})) return 'Every day';
    if (setEquals(days, {1, 2, 3, 4, 5})) return 'Weekdays';
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => labels[d - 1]).join(' ');
  }

  /// Convert TimeOfDay to total minutes since midnight
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Get duration in hours between start and end time
  int getDurationHours() {
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);
    
    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 09:00 - 17:00)
      return (endMinutes - startMinutes) ~/ 60;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      final totalMinutes = (24 * 60 - startMinutes) + endMinutes;
      return totalMinutes ~/ 60;
    }
  }

  /// Check if current time is within this schedule
  bool isWithinSchedule() {
    final now = TimeOfDay.now();
    final nowMinutes = _timeToMinutes(now);
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);

    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 09:00 - 17:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 08:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// Format time as HH:mm string
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get formatted schedule string (e.g., "22:00 - 08:00")
  String getFormattedTime() {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'days': days.toList(),
      'groups': groups,
      'enabled': enabled,
    };
  }

  /// Create from JSON data
  factory MuteSchedule.fromJson(Map<String, dynamic> json) {
    return MuteSchedule(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      startTime: TimeOfDay(
        hour: (json['startHour'] as num).toInt(),
        minute: (json['startMinute'] as num).toInt(),
      ),
      endTime: TimeOfDay(
        hour: (json['endHour'] as num).toInt(),
        minute: (json['endMinute'] as num).toInt(),
      ),
      days: ((json['days'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7])
          .map((e) => (e as num).toInt())
          .toSet(),
      groups: ((json['groups'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());

  static MuteSchedule decode(String source) {
    return MuteSchedule.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MuteSchedule &&
        other.id == id &&
        other.name == name &&
        other.startTime.hour == startTime.hour &&
        other.startTime.minute == startTime.minute &&
        other.endTime.hour == endTime.hour &&
        other.endTime.minute == endTime.minute &&
        setEquals(other.days, days) &&
        listEquals(other.groups, groups) &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      startTime.hour,
      startTime.minute,
      endTime.hour,
      endTime.minute,
      Object.hashAll(days),
      Object.hashAll(groups),
      enabled,
    );
  }

  @override
  String toString() {
    return 'MuteSchedule(id: $id, name: $name, time: ${getFormattedTime()}, days: ${daysSummary}, groups: ${groups.length}, enabled: $enabled)';
  }
}
