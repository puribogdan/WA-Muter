import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/mute_schedule.dart';
import '../providers/app_settings_provider.dart';
import '../providers/mute_log_provider.dart';
import '../providers/schedules_provider.dart';
import '../theme/app_tokens.dart';
import 'schedule_editor_screen.dart';

class SchedulesDashboardScreen extends StatefulWidget {
  const SchedulesDashboardScreen({super.key});

  @override
  State<SchedulesDashboardScreen> createState() =>
      _SchedulesDashboardScreenState();
}

class _SchedulesDashboardScreenState extends State<SchedulesDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadow = BoxShadow(
      color: tokens.textPrimary.withOpacity(isDark ? 0.32 : 0.08),
      blurRadius: 26,
      offset: const Offset(0, 8),
    );

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.pagePadding,
        title: Text(
          'Schedules',
          style: AppTypography.title.copyWith(color: tokens.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none, color: tokens.textPrimary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: tokens.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Consumer<AppSettingsProvider>(
            builder: (context, appSettings, _) => _SurfaceCard(
              shadow: cardShadow,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Mute',
                          style: AppTypography.cardTitle
                              .copyWith(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appSettings.settings.masterMuteEnabled
                              ? 'Scheduled muting is enabled'
                              : 'Muting is globally paused',
                          style: AppTypography.cardSubtitle
                              .copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 1.1,
                    child: CupertinoSwitch(
                      value: appSettings.settings.masterMuteEnabled,
                      activeColor:
                          isDark ? tokens.primaryAccent : tokens.success,
                      trackColor: tokens.outline,
                      onChanged: appSettings.isLoading
                          ? null
                          : (value) => appSettings.setMasterMuteEnabled(value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          Consumer<SchedulesProvider>(
            builder: (context, schedulesProvider, _) {
              final schedules = schedulesProvider.schedules;
              final enabledCount = schedules.where((s) => s.enabled).length;
              return _SurfaceCard(
                shadow: cardShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'All Schedules',
                            style: AppTypography.sectionHeader
                                .copyWith(color: tokens.textPrimary),
                          ),
                        ),
                        Text(
                          '${schedules.length} total - $enabledCount on',
                          style: AppTypography.rowSecondary
                              .copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (schedulesProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (schedules.isEmpty)
                      Text(
                        'No schedules yet. Create one to start muting selected users/groups.',
                        style: AppTypography.rowSecondary
                            .copyWith(color: tokens.textSecondary),
                      )
                    else
                      ..._buildScheduleRows(
                        context,
                        tokens,
                        schedulesProvider,
                        schedules,
                        isDark,
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _SurfaceCard(
            shadow: cardShadow,
            onTap: _openCreateSchedule,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create New Schedule',
                    style: AppTypography.cardTitle.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _SurfaceCard(
            shadow: cardShadow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Mutes",
                  style: AppTypography.sectionHeader
                      .copyWith(color: tokens.textPrimary),
                ),
                const SizedBox(height: 12),
                ..._buildMuteRows(context, tokens),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSchedule,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScheduleEditorScreen(),
      ),
    );
  }

  List<Widget> _buildScheduleRows(
    BuildContext context,
    AppColorTokens tokens,
    SchedulesProvider provider,
    List<MuteSchedule> schedules,
    bool isDark,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ScheduleEditorScreen(scheduleId: schedule.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.name,
                          style: AppTypography.rowPrimary
                              .copyWith(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${schedule.daysSummary} - ${schedule.getFormattedTime()}',
                          style: AppTypography.rowSecondary
                              .copyWith(color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${schedule.groups.length} muted users/groups',
                          style: AppTypography.rowSecondary
                              .copyWith(color: tokens.textSecondary),
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
        ),
      );
      if (i != schedules.length - 1) {
        rows.add(Divider(height: 1, color: tokens.outline));
      }
    }
    return rows;
  }

  List<Widget> _buildMuteRows(BuildContext context, AppColorTokens tokens) {
    final entries = context.watch<MuteLogProvider>().todayEntries;
    if (entries.isEmpty) {
      return [
        Text(
          'No muted notifications yet today.',
          style: AppTypography.rowSecondary.copyWith(color: tokens.textSecondary),
        ),
      ];
    }

    final rows = <Widget>[];
    final visible = entries.take(10).toList();
    final formatter = DateFormat('HH:mm');
    for (var i = 0; i < visible.length; i++) {
      final item = visible[i];
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  formatter.format(item.timestamp),
                  style: AppTypography.rowPrimary.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.groupName,
                      style:
                          AppTypography.rowPrimary.copyWith(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.status,
                      style: AppTypography.rowSecondary
                          .copyWith(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      if (i != visible.length - 1) {
        rows.add(Divider(height: 1, color: tokens.outline));
      }
    }
    return rows;
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final BoxShadow shadow;
  final VoidCallback? onTap;

  const _SurfaceCard({
    required this.child,
    required this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = Container(
      decoration: BoxDecoration(
        color: tokens.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: tokens.outline),
        boxShadow: [shadow],
      ),
      padding: AppSpacing.cardPadding,
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
