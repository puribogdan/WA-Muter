import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedules_provider.dart';
import 'schedule_editor_screen.dart';
import 'schedule_group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<SchedulesProvider>(
      builder: (context, schedulesProvider, _) {
        final filtered = schedulesProvider.schedules
            .where(
              (s) =>
                  s.name.toLowerCase().contains(_query.toLowerCase()) ||
                  s.groups.any(
                    (target) =>
                        target.toLowerCase().contains(_query.toLowerCase()),
                  ),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Groups'),
            actions: [
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ScheduleEditorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search groups, users, or schedules',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              if (schedulesProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No groups created yet',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a schedule group, then add multiple WhatsApp groups/users to mute.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ScheduleEditorScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Schedule Group'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map(
                  (schedule) => Card(
                    child: ListTile(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScheduleGroupDetailScreen(
                              scheduleId: schedule.id,
                            ),
                          ),
                        );
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.folder_outlined),
                      ),
                      title: Text(schedule.name),
                      subtitle: Text(
                        '${schedule.groups.length} muted users/groups - ${schedule.daysSummary}\n${schedule.getFormattedTime()}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        schedule.enabled
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_outlined,
                        color: schedule.enabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                        size: 30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
