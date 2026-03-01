import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/detected_group_record.dart';
import '../core/models/mute_schedule.dart';
import '../core/services/feature_gate_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/detected_groups_provider.dart';
import '../providers/schedules_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/day_chip_row.dart';
import 'paywall_screen.dart';

class ScheduleEditorScreen extends StatefulWidget {
  final String? scheduleId;

  const ScheduleEditorScreen({super.key, this.scheduleId});

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  final _nameController = TextEditingController();
  final _groupSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TimeOfDay? _start;
  TimeOfDay? _end;
  Set<int> _days = <int>{};
  Set<String> _selectedGroups = <String>{};
  bool _enabled = true;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    final schedules = context.read<SchedulesProvider>().schedules;
    final groupsProvider = context.read<DetectedGroupsProvider>();
    groupsProvider.load();

    if (widget.scheduleId != null) {
      final existing = schedules.where((s) => s.id == widget.scheduleId).first;
      _editingId = existing.id;
      _nameController.text = existing.name;
      _start = existing.startTime;
      _end = existing.endTime;
      _days = {...existing.days};
      _selectedGroups = {...existing.groups};
      _enabled = existing.enabled;
    } else {
      _applySmartDefaults();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _editingId != null;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Quiet Hours' : 'Create Quiet Hours')),
      body: SafeArea(
        child: Consumer<DetectedGroupsProvider>(
          builder: (context, groupsProvider, _) {
            final query = _groupSearchController.text.trim().toLowerCase();
            final allDetected = groupsProvider.groups;
            final filteredAll = query.isEmpty
                ? allDetected
                : allDetected
                    .where((g) => g.toLowerCase().contains(query))
                    .toList();
            final recentDetected = _filterRecent(groupsProvider.recentGroups, query);
            final chatResults = _mergeDetectedChats(recentDetected, filteredAll);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Quiet Hours name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.gap16),
                  Text(
                    'Time Range',
                    style: AppTypography.sectionTitle.copyWith(
                      color: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: true),
                          child: Text(
                            _start == null ? 'Start' : _formatTime(_start!),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: false),
                          child: Text(_end == null ? 'End' : _formatTime(_end!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gap16),
                  Text(
                    'Repeat Days',
                    style: AppTypography.sectionTitle.copyWith(
                      color: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  DayChipRow(
                    selectedDays: _days,
                    onToggleDay: (day) {
                      setState(() {
                        if (_days.contains(day)) {
                          _days.remove(day);
                        } else {
                          _days.add(day);
                        }
                      });
                    },
                    onSelectWeekdays: () => setState(() {
                      const weekdays = {1, 2, 3, 4, 5};
                      _days = _sameDays(_days, weekdays) ? <int>{} : weekdays;
                    }),
                    onSelectWeekend: () => setState(() {
                      const weekend = {6, 7};
                      _days = _sameDays(_days, weekend) ? <int>{} : weekend;
                    }),
                    onSelectEveryday: () => setState(() {
                      const everyday = {1, 2, 3, 4, 5, 6, 7};
                      _days = _sameDays(_days, everyday) ? <int>{} : everyday;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.gap16),
                  Text(
                    'Chats to Silence',
                    style: AppTypography.sectionTitle.copyWith(
                      color: tokens.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap8),
                  DecoratedBox(
                    decoration: AppDecorations.searchFieldContainer(context),
                    child: TextField(
                      controller: _groupSearchController,
                      onChanged: (_) => setState(() {}),
                      decoration: AppInputStyles.search(
                        context,
                        hintText: 'Search chats to silence',
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap12),
                  if (groupsProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (chatResults.isEmpty)
                    _HelperText(
                      text: query.isEmpty
                          ? 'Detected chats will appear here after notifications are seen.'
                          : 'No detected chats match your search.',
                    )
                  else
                    DecoratedBox(
                    decoration: AppDecorations.listRow(context),
                    child: Column(
                      children: [
                        for (var i = 0; i < chatResults.length; i++) ...[
                          _ChatSelectRow(
                            title: chatResults[i],
                            selected: _selectedGroups.contains(chatResults[i]),
                            onTap: () {
                              _toggleGroup(chatResults[i]);
                            },
                          ),
                          if (i != chatResults.length - 1)
                            Divider(height: 1, color: tokens.outline),
                        ],
                      ],
                    ),
                    ),
                  const SizedBox(height: AppSpacing.gap8),
                  DecoratedBox(
                    decoration: AppDecorations.listRow(context),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.listRow),
                      onTap: _showAddManualGroupDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add Chat to Silence',
                                style: AppTypography.bodyStrong.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: tokens.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.pagePadding),
        child: FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ),
    );
  }

  List<DetectedGroupRecord> _filterRecent(
    List<DetectedGroupRecord> records,
    String query,
  ) {
    if (query.isEmpty) return records;
    return records.where((r) => r.name.toLowerCase().contains(query)).toList();
  }

  void _applySmartDefaults() {
    final now = DateTime.now();
    final roundedMinute = now.minute % 30 == 0 ? now.minute : ((now.minute ~/ 30) + 1) * 30;
    var hour = now.hour;
    var minute = roundedMinute;
    if (roundedMinute >= 60) {
      hour = (hour + 1) % 24;
      minute = 0;
    }

    _start = TimeOfDay(hour: hour, minute: minute);
    final endTotalMinutes = (hour * 60 + minute + 120) % (24 * 60);
    _end = TimeOfDay(hour: endTotalMinutes ~/ 60, minute: endTotalMinutes % 60);
    _days = {now.weekday};
  }

  Future<void> _toggleGroup(String group) async {
    if (_selectedGroups.contains(group)) {
      setState(() {
        _selectedGroups.remove(group);
      });
      return;
    }

    final isPremium = context.read<AppSettingsProvider>().settings.isPremium;
    const gate = FeatureGateService();
    if (gate.exceedsChatLimitForFree(
      isPremium: isPremium,
      selectedChatsCount: _selectedGroups.length + 1,
    )) {
      final unlocked = await _openPaywall(GateViolation.chatLimit);
      if (!unlocked) return;
    }

    setState(() {
      _selectedGroups.add(group);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_start ?? const TimeOfDay(hour: 9, minute: 0))
        : (_end ?? const TimeOfDay(hour: 11, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _showAddManualGroupDialog() async {
    final controller = TextEditingController();
    final groupsProvider = context.read<DetectedGroupsProvider>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Chat to Silence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: AppInputStyles.search(
                  context,
                  hintText: 'Exact WhatsApp chat name',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the exact WhatsApp chat name.',
                style: AppTypography.secondaryBody.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) return;
    await groupsProvider.addManual(result);
    if (!mounted) return;
    setState(() {
      _selectedGroups.add(result);
    });
  }

  List<String> _mergeDetectedChats(
    List<DetectedGroupRecord> recentDetected,
    List<String> filteredAll,
  ) {
    final merged = <String>[];
    final seen = <String>{};

    void addName(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return;
      final key = value.toLowerCase();
      if (seen.add(key)) merged.add(value);
    }

    for (final item in recentDetected) {
      addName(item.name);
    }
    for (final item in filteredAll) {
      addName(item);
    }
    return merged;
  }

  bool _sameDays(Set<int> left, Set<int> right) {
    if (left.length != right.length) return false;
    for (final day in left) {
      if (!right.contains(day)) return false;
    }
    return true;
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      _showError('Start and end time are required');
      return;
    }
    if (_days.isEmpty) {
      _showError('Select at least one day');
      return;
    }
    if (_selectedGroups.isEmpty) {
      _showError('Select at least one chat');
      return;
    }

    final settings = context.read<AppSettingsProvider>().settings;
    final schedulesProvider = context.read<SchedulesProvider>();
    final schedules = schedulesProvider.schedules;
    const gate = FeatureGateService();
    final violation = gate.canSaveSchedule(
      isPremium: settings.isPremium,
      existingScheduleCount: schedules.length,
      isEditing: _editingId != null,
      selectedChatsCount: _selectedGroups.length,
    );
    if (violation != GateViolation.none) {
      final unlocked = await _openPaywall(violation);
      if (!unlocked) return;
      if (!mounted) return;
    }

    final schedule = MuteSchedule(
      id: _editingId,
      name: _nameController.text.trim(),
      startTime: _start!,
      endTime: _end!,
      days: _days,
      groups: _selectedGroups.toList()..sort(),
      enabled: _enabled,
    );

    await schedulesProvider.upsert(schedule);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _openPaywall(GateViolation reason) async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(reason: reason),
      ),
    );
    return unlocked == true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ChatSelectRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ChatSelectRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(color: tokens.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : tokens.divider,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;

  const _HelperText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.micro.copyWith(color: context.tokens.muted),
      ),
    );
  }
}
