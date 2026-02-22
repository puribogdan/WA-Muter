import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/mute_schedule.dart';
import '../providers/schedules_provider.dart';
import 'schedule_editor_screen.dart';

class ScheduleGroupDetailScreen extends StatelessWidget {
  final String scheduleId;

  const ScheduleGroupDetailScreen({
    super.key,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulesProvider>(
      builder: (context, schedulesProvider, _) {
        final schedules = schedulesProvider.schedules;
        MuteSchedule? schedule;
        for (final item in schedules) {
          if (item.id == scheduleId) {
            schedule = item;
            break;
          }
        }

        if (schedule == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Details')),
            body: const Center(
              child: Text('This schedule group no longer exists.'),
            ),
          );
        }

        final currentSchedule = schedule;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentSchedule.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScheduleEditorScreen(scheduleId: currentSchedule.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, currentSchedule.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: Icon(
                              currentSchedule.enabled ? Icons.toggle_on : Icons.toggle_off,
                              size: 18,
                            ),
                            label: Text(currentSchedule.enabled ? 'Enabled' : 'Disabled'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text(currentSchedule.getFormattedTime()),
                          ),
                          Chip(
                            avatar: const Icon(Icons.repeat, size: 18),
                            label: Text(currentSchedule.daysSummary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${currentSchedule.groups.length} muted users/groups',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Muted Users / Groups',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (currentSchedule.groups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No users/groups added yet.'),
                  ),
                )
              else
                ...currentSchedule.groups.map(
                  (target) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_off_outlined),
                      ),
                      title: Text(target),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule group?'),
        content: const Text('This will remove the schedule and its muted users/groups.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await context.read<SchedulesProvider>().delete(id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
