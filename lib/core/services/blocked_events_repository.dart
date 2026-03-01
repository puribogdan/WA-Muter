import 'package:flutter/foundation.dart';

import 'mute_log_service.dart';

abstract class BlockedEventsRepository {
  Future<List<DateTime>> getBlockedEvents({
    required DateTime start,
    required DateTime end,
  });
}

class MuteLogBlockedEventsRepository implements BlockedEventsRepository {
  final MuteLogService _muteLogService;

  const MuteLogBlockedEventsRepository(this._muteLogService);

  @override
  Future<List<DateTime>> getBlockedEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final entries = await _muteLogService.getAll();
    return entries
        .where((entry) {
          final ts = entry.timestamp;
          final inRange = !ts.isBefore(start) && ts.isBefore(end);
          final status = entry.status.toLowerCase();
          final isBlocked = status.contains('dismiss') || status.contains('block');
          return inRange && isBlocked;
        })
        .map((entry) => entry.timestamp)
        .toList();
  }
}

DateTime startOfWeekMonday(DateTime date) {
  final localDay = DateTime(date.year, date.month, date.day);
  final diff = localDay.weekday - DateTime.monday;
  return localDay.subtract(Duration(days: diff));
}

List<int> countsMonToSunFromEvents(List<DateTime> blockedEventTimes, DateTime now) {
  final start = startOfWeekMonday(now);
  final endExclusive = start.add(const Duration(days: 7));
  final counts = List<int>.filled(7, 0);

  for (final t in blockedEventTimes) {
    final dt = DateTime(t.year, t.month, t.day);
    if (dt.isBefore(start) || !dt.isBefore(endExclusive)) continue;
    final index = dt.difference(start).inDays;
    if (index >= 0 && index < 7) {
      counts[index]++;
    }
  }

  return counts;
}

class WeeklyBlockedCountsService {
  final BlockedEventsRepository _repository;

  const WeeklyBlockedCountsService(this._repository);

  Future<List<int>> getCurrentWeekMonToSun({DateTime? now}) async {
    final anchor = now ?? DateTime.now();
    final start = startOfWeekMonday(anchor);
    final end = start.add(const Duration(days: 7));
    final events = await _repository.getBlockedEvents(start: start, end: end);
    return countsMonToSunFromEvents(events, anchor);
  }
}
