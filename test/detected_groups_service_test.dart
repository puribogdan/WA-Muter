import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wa_notifications_app/core/services/detected_groups_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetectedGroupsService', () {
    test('deduplicates notification titles with message-count suffixes', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = DetectedGroupsService();

      await service.add('Family', source: 'notification');
      await service.add('Family (2 messages)', source: 'notification');
      await service.add('Family (3 messages)', source: 'notification');

      final groups = await service.getAll();
      expect(groups, <String>['Family']);
    });

    test('normalizes and merges existing detected_groups_v2 entries on read', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(minutes: 5)).toIso8601String();
      final latest = now.toIso8601String();
      final seeded = jsonEncode(<Map<String, String>>[
        <String, String>{
          'name': 'Family',
          'lastSeenAt': old,
          'source': 'notification',
        },
        <String, String>{
          'name': 'Family (3 messages)',
          'lastSeenAt': latest,
          'source': 'notification',
        },
        <String, String>{
          'name': 'Work',
          'lastSeenAt': latest,
          'source': 'notification',
        },
      ]);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'detected_groups_v2': seeded,
      });
      final service = DetectedGroupsService();

      final records = await service.getAllRecords();
      expect(records.map((r) => r.name).toList(), <String>['Family', 'Work']);

      final prefs = await SharedPreferences.getInstance();
      final storedRaw = prefs.getString('detected_groups_v2');
      expect(storedRaw, isNotNull);
      final storedDecoded = jsonDecode(storedRaw!) as List<dynamic>;
      expect(storedDecoded.length, 2);
      final storedNames = storedDecoded
          .map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList();
      expect(storedNames, <String>['Family', 'Work']);
    });

    test('keeps manual names intact while normalizing notification entries', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = DetectedGroupsService();

      await service.add('Project (2026)', source: 'manual');
      await service.add('Project (2 messages)', source: 'notification');

      final groups = await service.getAll();
      expect(groups, <String>['Project', 'Project (2026)']);
    });
  });
}
