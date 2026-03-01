import 'package:flutter/material.dart';
import '../core/models/mute_schedule.dart';
import '../theme/app_tokens.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.listRow),
          ),
          title: Text(
            schedule.name,
            style: AppTypography.cardTitle.copyWith(color: context.tokens.primary),
          ),
          subtitle: Text(
            '${schedule.daysSummary}  ${schedule.getFormattedTime()}\n${schedule.groups.length} groups',
            style: AppTypography.secondaryBody.copyWith(
              color: context.tokens.secondary,
            ),
          ),
          isThreeLine: true,
          trailing: Switch(
            value: schedule.enabled,
            onChanged: onToggle,
          ),
        ),
      ),
    );
  }
}
