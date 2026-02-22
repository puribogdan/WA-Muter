import 'package:flutter/foundation.dart';
import '../core/models/mute_schedule.dart';
import '../core/services/schedule_service.dart';

class SchedulesProvider extends ChangeNotifier {
  final ScheduleService _service;

  SchedulesProvider(this._service);

  bool _isLoading = true;
  List<MuteSchedule> _schedules = const [];

  bool get isLoading => _isLoading;
  List<MuteSchedule> get schedules => _schedules;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _schedules = await _service.getAllSchedules();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> upsert(MuteSchedule schedule) async {
    await _service.upsertSchedule(schedule);
    await load();
  }

  Future<void> delete(String id) async {
    await _service.deleteSchedule(id);
    await load();
  }

  Future<void> duplicate(String id) async {
    await _service.duplicateSchedule(id);
    await load();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await _service.setEnabled(id, enabled);
    await load();
  }
}
