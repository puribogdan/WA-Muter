import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/schedules_provider.dart';
import '../widgets/schedule_card.dart';
import 'schedule_editor_screen.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SchedulesProvider, AppSettingsProvider>(
      builder: (context, provider, appSettings, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Schedules')),
          body: provider.schedules.isEmpty
              ? _EmptyState(
                  onCreate: () => _openEditor(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          SwitchListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            title: const Text('Master Mute'),
                            subtitle: Text(
                              appSettings.settings.masterMuteEnabled
                                  ? 'Scheduled muting is enabled'
                                  : 'All muting is paused',
                            ),
                            value: appSettings.settings.masterMuteEnabled,
                            onChanged: appSettings.isLoading
                                ? null
                                : appSettings.setMasterMuteEnabled,
                          ),
                          const SizedBox(height: 8),
                          _buildScheduleRow(context, provider, provider.schedules[0]),
                        ],
                      );
                    }
                    return _buildScheduleRow(
                      context,
                      provider,
                      provider.schedules[index],
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: provider.schedules.length,
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEditor(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    SchedulesProvider provider,
    dynamic schedule,
  ) {
    return Dismissible(
      key: ValueKey(schedule.id),
      background: _swipeBg(context, Icons.copy, 'Duplicate'),
      secondaryBackground: _swipeBg(context, Icons.delete, 'Delete', end: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await provider.duplicate(schedule.id);
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          await provider.delete(schedule.id);
          return true;
        }
        return false;
      },
      child: ScheduleCard(
        schedule: schedule,
        onToggle: (value) => provider.setEnabled(schedule.id, value),
        onTap: () => _openEditor(context, scheduleId: schedule.id),
      ),
    );
  }

  Widget _swipeBg(BuildContext context, IconData icon, String text,
      {bool end = false}) {
    return Container(
      alignment: end ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: end ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
            end ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {String? scheduleId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleEditorScreen(scheduleId: scheduleId),
      ),
    );
    if (context.mounted) {
      await context.read<SchedulesProvider>().load();
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_outlined, size: 72),
            const SizedBox(height: 12),
            const Text('No schedules yet', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
