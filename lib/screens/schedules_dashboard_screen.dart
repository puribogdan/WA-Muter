import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/mute_log_entry.dart';
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
  final Set<String> _expandedMuteGroups = <String>{};

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
          Consumer<MuteLogProvider>(
            builder: (context, muteLogProvider, _) => _SurfaceCard(
              shadow: cardShadow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Today's Mutes",
                          style: AppTypography.sectionHeader
                              .copyWith(color: tokens.textPrimary),
                        ),
                      ),
                      if (muteLogProvider.todayEntries.isNotEmpty)
                        TextButton(
                          onPressed: () => _confirmClearTodayMutes(context),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildMuteRows(context, tokens),
                ],
              ),
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

  Future<void> _confirmClearTodayMutes(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear today's mutes?"),
        content: const Text('This removes only today\'s mute log entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<MuteLogProvider>().clearToday();
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

    final groups = _groupMuteEntries(entries);
    final rows = <Widget>[];
    final formatter = DateFormat('HH:mm');
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final isExpanded = _expandedMuteGroups.contains(group.senderKey);
      final latest = group.entries.first;
      final latestMessage = latest.messageText.trim();

      rows.add(
        Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedMuteGroups.remove(group.senderKey);
                  } else {
                    _expandedMuteGroups.add(group.senderKey);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.senderName,
                                  style: AppTypography.rowPrimary.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${group.entries.length}x',
                                style: AppTypography.rowSecondary.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatter.format(latest.timestamp),
                                style: AppTypography.rowSecondary.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latestMessage.isEmpty
                                ? 'No message preview'
                                : latestMessage,
                            style: AppTypography.rowSecondary.copyWith(
                              color: tokens.textSecondary,
                            ),
                            maxLines: isExpanded ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: tokens.inactiveIcon,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: tokens.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.outline),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  children: [
                    for (var j = 0; j < group.entries.length; j++) ...[
                      _MuteLogDetailRow(
                        entry: group.entries[j],
                        formatter: formatter,
                        tokens: tokens,
                      ),
                      if (j != group.entries.length - 1)
                        Divider(height: 10, color: tokens.outline),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
      if (i != groups.length - 1) {
        rows.add(Divider(height: 1, color: tokens.outline));
      }
    }
    return rows;
  }

  List<_MuteEntryGroup> _groupMuteEntries(List<MuteLogEntry> entries) {
    final grouped = <String, List<MuteLogEntry>>{};
    final labels = <String, String>{};
    for (final entry in entries) {
      final key = entry.groupName.trim().toLowerCase();
      final normalizedKey = key.isEmpty ? 'unknown' : key;
      grouped.putIfAbsent(normalizedKey, () => <MuteLogEntry>[]).add(entry);
      labels.putIfAbsent(normalizedKey, () {
        final name = entry.groupName.trim();
        return name.isEmpty ? 'Unknown' : name;
      });
    }

    final result = grouped.entries
        .map(
          (e) => _MuteEntryGroup(
            senderKey: e.key,
            senderName: labels[e.key] ?? 'Unknown',
            entries: e.value..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
          ),
        )
        .toList();
    result.sort((a, b) => b.entries.first.timestamp.compareTo(a.entries.first.timestamp));
    return result;
  }
}

class _MuteLogDetailRow extends StatelessWidget {
  final MuteLogEntry entry;
  final DateFormat formatter;
  final AppColorTokens tokens;

  const _MuteLogDetailRow({
    required this.entry,
    required this.formatter,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final message = entry.messageText.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Text(
            formatter.format(entry.timestamp),
            style: AppTypography.rowSecondary.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message.isEmpty ? 'No message preview' : message,
            style: AppTypography.rowSecondary.copyWith(color: tokens.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _MuteEntryGroup {
  final String senderKey;
  final String senderName;
  final List<MuteLogEntry> entries;

  const _MuteEntryGroup({
    required this.senderKey,
    required this.senderName,
    required this.entries,
  });
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
