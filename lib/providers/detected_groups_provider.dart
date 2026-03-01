import 'package:flutter/foundation.dart';
import '../core/models/detected_group_record.dart';
import '../core/services/detected_groups_service.dart';

class DetectedGroupsProvider extends ChangeNotifier {
  final DetectedGroupsService _service;

  DetectedGroupsProvider(this._service);

  bool _isLoading = true;
  List<String> _groups = const [];
  List<DetectedGroupRecord> _recentGroups = const [];

  bool get isLoading => _isLoading;
  List<String> get groups => _groups;
  List<DetectedGroupRecord> get recentGroups => _recentGroups;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final all = await _service.getAll();
    final recent = await _service.getRecent(limit: 12);
    _groups = all;
    _recentGroups = recent;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addManual(String name) async {
    await _service.add(name, source: 'manual');
    await load();
  }
}
