import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/models/mute_log_entry.dart';
import '../providers/mute_log_provider.dart';
import '../theme/app_tokens.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final Set<String> _expandedMuteGroups = <String>{};

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity',
          style: AppTypography.title.copyWith(color: tokens.textPrimary),
        ),
      ),
      body: Consumer<MuteLogProvider>(
        builder: (context, muteLogProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity',
                      style: AppTypography.sectionHeader.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  if (muteLogProvider.todayEntries.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearTodayMutes(context),
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (muteLogProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ..._buildMuteRows(context, tokens, muteLogProvider.todayEntries),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClearTodayMutes(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear today's activity?"),
        content: const Text('This removes only today\'s muted notification log entries.'),
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

  List<Widget> _buildMuteRows(
    BuildContext context,
    AppColorTokens tokens,
    List<MuteLogEntry> entries,
  ) {
    if (entries.isEmpty) {
      return [
        Container(
          decoration: AppDecorations.card(context),
          padding: AppSpacing.cardPadding,
          child: Text(
            'Silenced interruptions will appear here.',
            style: AppTypography.rowSecondary.copyWith(
              color: tokens.textSecondary,
            ),
          ),
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
        Container(
          decoration: AppDecorations.listRow(context),
          margin: const EdgeInsets.only(bottom: AppSpacing.gap8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
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
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: tokens.secondarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.outline),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
          ),
        ),
      );
      if (i != groups.length - 1) {
        rows.add(const SizedBox(height: 2));
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
