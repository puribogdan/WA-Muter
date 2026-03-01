import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detected_group_record.dart';

class DetectedGroupsService {
  static const _legacyDetectedGroupsKey = 'detected_groups_v1';
  static const _detectedGroupsKey = 'detected_groups_v2';

  Future<List<String>> getAll() async {
    final records = await getAllRecords();
    final groups = records.map((e) => e.name).toList();
    groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return groups;
  }

  Future<List<DetectedGroupRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final raw = prefs.getString(_detectedGroupsKey);
    if (raw == null || raw.isEmpty) return <DetectedGroupRecord>[];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = decoded
          .map((e) => DetectedGroupRecord.fromJson(e as Map<String, dynamic>))
          .where((e) => e.name.trim().isNotEmpty)
          .toList();

      records.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return records;
    } catch (_) {
      return <DetectedGroupRecord>[];
    }
  }

  Future<List<DetectedGroupRecord>> getRecent({int? limit}) async {
    final records = await getAllRecords();
    records.sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    if (limit != null && limit >= 0 && records.length > limit) {
      return records.take(limit).toList();
    }
    return records;
  }

  Future<void> add(String name, {String source = 'notification'}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final records = await getAllRecords();
    final now = DateTime.now();
    final existingIndex = records.indexWhere(
      (e) => e.name.toLowerCase() == trimmed.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = records[existingIndex];
      records[existingIndex] = existing.copyWith(
        name: trimmed,
        lastSeenAt: now,
        source: source,
      );
    } else {
      records.add(
        DetectedGroupRecord(
          name: trimmed,
          lastSeenAt: now,
          source: source,
        ),
      );
    }

    records.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await prefs.setString(
      _detectedGroupsKey,
      jsonEncode(records.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    if (prefs.containsKey(_detectedGroupsKey)) return;

    final legacy = prefs.getStringList(_legacyDetectedGroupsKey);
    if (legacy == null || legacy.isEmpty) {
      await prefs.setString(_detectedGroupsKey, '[]');
      return;
    }

    final now = DateTime.now();
    final records = legacy
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .map(
          (name) => DetectedGroupRecord(
            name: name,
            lastSeenAt: now,
            source: 'migration',
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    await prefs.setString(
      _detectedGroupsKey,
      jsonEncode(records.map((e) => e.toJson()).toList()),
    );
  }
}
