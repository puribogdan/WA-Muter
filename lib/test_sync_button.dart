import 'package:flutter/material.dart';
import 'core/services/native_bridge.dart';
import 'core/services/storage_service.dart';

/// Simple test widget that can be added to any screen
class TestSyncButton extends StatelessWidget {
  const TestSyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        print('🧪 [TEST] Syncing data to native location...');
        try {
          final groups = await StorageService.getSelectedGroups();
          final schedule = await StorageService.getSchedule();

          print('🧪 [TEST] Current groups: $groups');
          print('🧪 [TEST] Current schedule: $schedule');

          // Call the native bridge
          await NativeBridge.saveMutedGroups(groups);
          if (schedule != null) {
            await NativeBridge.saveSchedule({
              'startHour': schedule.startTime.hour,
              'startMinute': schedule.startTime.minute,
              'endHour': schedule.endTime.hour,
              'endMinute': schedule.endTime.minute,
            });
          }

          print(
              '🧪 [TEST] ✅ Sync completed! Native code should now find the data.');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Data synced to native! Test notification blocking now.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('🧪 [TEST] ❌ Error syncing data: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.sync),
      label: const Text('🧪 Sync Data to Native (TEST)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
