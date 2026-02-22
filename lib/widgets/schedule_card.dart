import 'package:flutter/material.dart';
import '../core/models/mute_schedule.dart';

class ScheduleCard extends StatelessWidget {
  final MuteSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(schedule.name),
        subtitle: Text(
          '${schedule.daysSummary}  ${schedule.getFormattedTime()}\n${schedule.groups.length} groups',
        ),
        isThreeLine: true,
        trailing: Switch(
          value: schedule.enabled,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
