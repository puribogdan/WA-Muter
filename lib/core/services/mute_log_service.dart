import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mute_log_entry.dart';
import 'native_bridge.dart';

class MuteLogService {
  static const _key = 'mute_log_entries_v1';
  static const _maxEntries = 200;

  Future<List<MuteLogEntry>> getAll() async {
    final native = await NativeBridge.getMuteLogs();
    if (native.isNotEmpty) {
      return native.map((e) {
        final millis = (e['timestamp'] as num?)?.toInt() ?? 0;
        return MuteLogEntry(
          timestamp: DateTime.fromMillisecondsSinceEpoch(millis),
          groupName: (e['groupName'] as String?) ?? 'Unknown',
          status: (e['status'] as String?) ?? 'Muted',
          messageText: (e['messageText'] as String?) ?? '',
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Fallback for older locally stored entries.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((e) => MuteLogEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<MuteLogEntry>> getToday() async {
    final all = await getAll();
    final now = DateTime.now();
    return all.where((e) {
      return e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day;
    }).toList();
  }

  Future<void> add({
    required String groupName,
    required String status,
    String? messageText,
  }) async {
    final trimmed = groupName.trim();
    if (trimmed.isEmpty) return;

    await NativeBridge.saveMuteLog(
      groupName: trimmed,
      status: status,
      messageText: messageText,
    );

    // Keep fallback local storage for compatibility.
    final all = await getAll();
    all.insert(
      0,
      MuteLogEntry(
        timestamp: DateTime.now(),
        groupName: trimmed,
        status: status,
        messageText: messageText ?? '',
      ),
    );

    final trimmedList = all.take(_maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(trimmedList.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearToday() async {
    final now = DateTime.now();

    await NativeBridge.clearTodayMuteLogs();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;

    final data = (jsonDecode(raw) as List<dynamic>)
        .map((e) => MuteLogEntry.fromJson(e as Map<String, dynamic>))
        .where((e) {
          final isToday = e.timestamp.year == now.year &&
              e.timestamp.month == now.month &&
              e.timestamp.day == now.day;
          return !isToday;
        })
        .toList();

    await prefs.setString(
      _key,
      jsonEncode(data.map((e) => e.toJson()).toList()),
    );
  }
}
