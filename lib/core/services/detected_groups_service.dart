import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detected_group_record.dart';

class DetectedGroupsService {
  static const _legacyDetectedGroupsKey = 'detected_groups_v1';
  static const _detectedGroupsKey = 'detected_groups_v2';
  static final RegExp _messageCountSuffixPattern = RegExp(
    r'\s*\(\s*\d+\s+messages?\s*\)\s*$',
    caseSensitive: false,
  );

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

      final normalized = _normalizeAndMergeRecords(records);
      if (normalized.didChange) {
        await prefs.setString(
          _detectedGroupsKey,
          jsonEncode(normalized.records.map((e) => e.toJson()).toList()),
        );
      }

      return normalized.records;
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
    final normalizedName = source == 'notification'
        ? _normalizeNotificationChatName(name)
        : _normalizeGeneralName(name);
    if (normalizedName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final records = await getAllRecords();
    final now = DateTime.now();
    final existingIndex = records.indexWhere(
      (e) => e.name.toLowerCase() == normalizedName.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = records[existingIndex];
      records[existingIndex] = existing.copyWith(
        name: normalizedName,
        lastSeenAt: now,
        source: source,
      );
    } else {
      records.add(
        DetectedGroupRecord(
          name: normalizedName,
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

  _NormalizeMergeResult _normalizeAndMergeRecords(
    List<DetectedGroupRecord> records,
  ) {
    final mergedByKey = <String, DetectedGroupRecord>{};
    var didChange = false;

    for (final record in records) {
      final cleanedName = record.source == 'notification'
          ? _normalizeNotificationChatName(record.name)
          : _normalizeGeneralName(record.name);
      if (cleanedName.isEmpty) {
        didChange = true;
        continue;
      }

      if (cleanedName != record.name.trim()) {
        didChange = true;
      }

      final canonical = record.copyWith(name: cleanedName);
      final key = cleanedName.toLowerCase();
      final existing = mergedByKey[key];
      if (existing == null) {
        mergedByKey[key] = canonical;
        continue;
      }

      didChange = true;
      final latest = canonical.lastSeenAt.isAfter(existing.lastSeenAt)
          ? canonical
          : existing;
      mergedByKey[key] = latest.copyWith(
        name: _preferredDisplayName(existing.name, canonical.name),
        lastSeenAt: latest.lastSeenAt,
        source: latest.source,
      );
    }

    final normalizedRecords = mergedByKey.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (!didChange && normalizedRecords.length != records.length) {
      didChange = true;
    }

    return _NormalizeMergeResult(records: normalizedRecords, didChange: didChange);
  }

  String _normalizeNotificationChatName(String raw) {
    final collapsed = _normalizeGeneralName(raw);
    if (collapsed.isEmpty) return '';
    final withoutSuffix = collapsed.replaceFirst(_messageCountSuffixPattern, '');
    return _normalizeGeneralName(withoutSuffix);
  }

  String _normalizeGeneralName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _preferredDisplayName(String first, String second) {
    final left = _normalizeGeneralName(first);
    final right = _normalizeGeneralName(second);
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    final leftHasSuffix = _messageCountSuffixPattern.hasMatch(left);
    final rightHasSuffix = _messageCountSuffixPattern.hasMatch(right);
    if (leftHasSuffix != rightHasSuffix) {
      return leftHasSuffix ? right : left;
    }
    return left;
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

class _NormalizeMergeResult {
  final List<DetectedGroupRecord> records;
  final bool didChange;

  const _NormalizeMergeResult({
    required this.records,
    required this.didChange,
  });
}
