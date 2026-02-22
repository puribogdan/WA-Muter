import 'package:flutter/foundation.dart';
import '../core/services/detected_groups_service.dart';

class DetectedGroupsProvider extends ChangeNotifier {
  final DetectedGroupsService _service;

  DetectedGroupsProvider(this._service);

  bool _isLoading = true;
  List<String> _groups = const [];

  bool get isLoading => _isLoading;
  List<String> get groups => _groups;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _groups = await _service.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addManual(String name) async {
    await _service.add(name);
    await load();
  }
}
