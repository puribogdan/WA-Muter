import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wa_notifications_app/core/models/mute_schedule.dart';
import 'package:wa_notifications_app/core/services/time_check_service.dart';

void main() {
  test('MuteSchedule formats time correctly', () {
    final schedule = MuteSchedule(
      startTime: const TimeOfDay(hour: 22, minute: 30),
      endTime: const TimeOfDay(hour: 7, minute: 45),
    );

    expect(schedule.getFormattedTime(), '22:30 - 07:45');
  });

  test('TimeCheckService handles overnight duration', () {
    final duration = TimeCheckService.getDurationHours(
      const TimeOfDay(hour: 22, minute: 0),
      const TimeOfDay(hour: 6, minute: 0),
    );

    expect(duration, 8);
  });

  test('TimeCheckService detects long schedules', () {
    final isLong = TimeCheckService.isLongSchedule(
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 22, minute: 0),
    );

    expect(isLong, isTrue);
  });
}
