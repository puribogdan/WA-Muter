import 'package:shared_preferences/shared_preferences.dart';

class DetectedGroupsService {
  static const _detectedGroupsKey = 'detected_groups_v1';

  Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final groups = prefs.getStringList(_detectedGroupsKey) ?? <String>[];
    groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return groups;
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final groups = await getAll();
    if (!groups.contains(trimmed)) {
      groups.add(trimmed);
      groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_detectedGroupsKey, groups);
    }
  }
}
