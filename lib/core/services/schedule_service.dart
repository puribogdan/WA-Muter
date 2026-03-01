import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mute_schedule.dart';
import 'native_bridge.dart';

class ScheduleService {
  static const _schedulesKey = 'schedules_v1';

  Future<List<MuteSchedule>> getAllSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schedulesKey);
    if (raw == null || raw.isEmpty) {
      await NativeBridge.saveSchedules(const <Map<String, dynamic>>[]);
      return <MuteSchedule>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final schedules = decoded
        .map((e) => MuteSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    await NativeBridge.saveSchedules(schedules.map((e) => e.toJson()).toList());
    return schedules;
  }

  Future<void> upsertSchedule(MuteSchedule schedule) async {
    final schedules = await getAllSchedules();
    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }
    await _saveAll(schedules);
  }

  Future<void> deleteSchedule(String id) async {
    final schedules = await getAllSchedules();
    schedules.removeWhere((s) => s.id == id);
    await _saveAll(schedules);
  }

  Future<void> duplicateSchedule(String id) async {
    final schedules = await getAllSchedules();
    MuteSchedule? original;
    for (final s in schedules) {
      if (s.id == id) {
        original = s;
        break;
      }
    }
    if (original == null) return;
    schedules.add(
      original.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '${original.name} (Copy)',
      ),
    );
    await _saveAll(schedules);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final schedules = await getAllSchedules();
    final index = schedules.indexWhere((s) => s.id == id);
    if (index < 0) return;
    schedules[index] = schedules[index].copyWith(enabled: enabled);
    await _saveAll(schedules);
  }

  Future<void> _saveAll(List<MuteSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = schedules.map((e) => e.toJson()).toList();
    await prefs.setString(
      _schedulesKey,
      jsonEncode(serialized),
    );
    await NativeBridge.saveSchedules(serialized);
  }
}
