import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/mute_schedule.dart';
import '../core/services/blocked_events_repository.dart';
import '../core/services/feature_gate_service.dart';
import '../core/services/mute_log_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/mute_log_provider.dart';
import '../providers/schedules_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/weekly_blocked_chart.dart';
import 'paywall_screen.dart';
import 'schedule_editor_screen.dart';

class SchedulesDashboardScreen extends StatefulWidget {
  const SchedulesDashboardScreen({super.key});

  @override
  State<SchedulesDashboardScreen> createState() => _SchedulesDashboardScreenState();
}

class _SchedulesDashboardScreenState extends State<SchedulesDashboardScreen> {
  final Set<String> _expandedScheduleIds = <String>{};
  late final WeeklyBlockedCountsService _weeklyCountsService;

  @override
  void initState() {
    super.initState();
    _weeklyCountsService = WeeklyBlockedCountsService(
      MuteLogBlockedEventsRepository(MuteLogService()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.pagePadding,
        title: Text(
          'Quiet Hours',
          style: AppTypography.title.copyWith(color: tokens.textPrimary),
        ),
      ),
      body: Consumer3<AppSettingsProvider, SchedulesProvider, MuteLogProvider>(
        builder: (context, appSettings, schedulesProvider, _, __) {
          final schedules = schedulesProvider.schedules;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _StatusBanner(
                appSettings: appSettings,
              ),
              const SizedBox(height: AppSpacing.cardGap),
              _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your Schedules (${schedules.length})',
                            style: AppTypography.sectionHeader.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (schedulesProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (schedules.isEmpty)
                      _SchedulesEmptyState(onCreate: _openCreateSchedule)
                    else
                      ..._buildScheduleRows(
                        context,
                        schedulesProvider,
                        schedules,
                        isDark,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              FutureBuilder<List<int>>(
                future: _weeklyCountsService.getCurrentWeekMonToSun(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return WeeklyBlockedChartCard(countsMonToSun: snapshot.data!);
                  }
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppShadows.soft(context.isDarkTheme),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreateSchedule() async {
    final settings = context.read<AppSettingsProvider>().settings;
    final scheduleCount = context.read<SchedulesProvider>().schedules.length;
    const gate = FeatureGateService();
    final violation = gate.canCreateSchedule(
      isPremium: settings.isPremium,
      existingScheduleCount: scheduleCount,
    );

    if (violation != GateViolation.none) {
      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaywallScreen(reason: violation),
        ),
      );
      if (unlocked != true || !mounted) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScheduleEditorScreen(),
      ),
    );
  }

  List<Widget> _buildScheduleRows(
    BuildContext context,
    SchedulesProvider provider,
    List<MuteSchedule> schedules,
    bool isDark,
  ) {
    final tokens = context.tokens;
    final rows = <Widget>[];
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      final isExpanded = _expandedScheduleIds.contains(schedule.id);
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedScheduleIds.remove(schedule.id);
                          } else {
                            _expandedScheduleIds.add(schedule.id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    schedule.name,
                                    style: AppTypography.rowPrimary.copyWith(
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: tokens.inactiveIcon,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${schedule.daysSummary} - ${schedule.getFormattedTime()}',
                              style: AppTypography.rowSecondary.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${schedule.groups.length} chats silenced',
                              style: AppTypography.rowSecondary.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 1.0,
                    child: CupertinoSwitch(
                      value: schedule.enabled,
                      activeColor: isDark ? tokens.primaryAccent : tokens.success,
                      trackColor: tokens.outline,
                      onChanged: provider.isLoading
                          ? null
                          : (value) => provider.setEnabled(schedule.id, value),
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                _ExpandedSchedulePanel(
                  schedule: schedule,
                  onEdit: () => _openEditSchedule(schedule.id),
                  onDelete: () => _confirmDeleteSchedule(schedule),
                ),
              ],
            ],
          ),
        ),
      );
      if (i != schedules.length - 1) {
        rows.add(Divider(height: 1, color: tokens.outline));
      }
    }
    return rows;
  }

  Future<void> _openEditSchedule(String scheduleId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleEditorScreen(scheduleId: scheduleId),
      ),
    );
  }

  Future<void> _confirmDeleteSchedule(MuteSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiet Hours?'),
        content: Text('Delete "${schedule.name}" and its silenced chat targets?'),
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

    if (confirmed != true || !mounted) return;
    await context.read<SchedulesProvider>().delete(schedule.id);
    if (!mounted) return;
    setState(() {
      _expandedScheduleIds.remove(schedule.id);
    });
  }

}

class _StatusBanner extends StatelessWidget {
  final AppSettingsProvider appSettings;

  const _StatusBanner({
    required this.appSettings,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = context.isDarkTheme;
    final masterEnabled = appSettings.settings.masterMuteEnabled;

    late final IconData icon;
    late final Color tone;
    late final Color background;
    late final String title;
    const subtitle = 'Your time is yours.';

    if (!masterEnabled) {
      icon = Icons.pause_circle_outline;
      tone = tokens.danger;
      background = tokens.dangerContainer;
      title = 'Quiet Hours Inactive';
    } else {
      icon = Icons.notifications_off_outlined;
      tone = tokens.success;
      background = tokens.successContainer;
      title = 'Protection is Active';
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: tone.withOpacity(isDark ? 0.45 : 0.25)),
      ),
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withOpacity(isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.cardSubtitle.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                'Enable Protection',
                style: AppTypography.micro.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 4),
              CupertinoSwitch(
                value: masterEnabled,
                activeColor: isDark ? tokens.primaryAccent : tokens.success,
                trackColor: tokens.outline,
                onChanged: appSettings.isLoading
                    ? null
                    : (value) => appSettings.setMasterMuteEnabled(value),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ExpandedSchedulePanel extends StatelessWidget {
  final MuteSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpandedSchedulePanel({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final groups = [...schedule.groups]..sort();

    return Container(
      decoration: BoxDecoration(
        color: tokens.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groups.isEmpty)
            Text(
              'No chats selected yet.',
              style: AppTypography.rowSecondary.copyWith(
                color: tokens.textSecondary,
              ),
            )
          else
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.remove,
                        size: 14,
                        color: tokens.inactiveIcon,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        group,
                        style: AppTypography.rowSecondary.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchedulesEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _SchedulesEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your first quiet time',
            style: AppTypography.cardTitle.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Set times to silence selected chats automatically.',
            style: AppTypography.rowSecondary.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('+ Add Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card(context),
      padding: AppSpacing.cardPadding,
      child: child,
    );
  }
}
