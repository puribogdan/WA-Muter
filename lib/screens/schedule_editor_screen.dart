import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/mute_schedule.dart';
import '../providers/detected_groups_provider.dart';
import '../providers/schedules_provider.dart';
import '../widgets/day_chip_row.dart';

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
  Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  Set<String> _selectedGroups = {};
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
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Schedule' : 'Create Schedule')),
      body: SafeArea(
        child: Consumer<DetectedGroupsProvider>(
          builder: (context, groupsProvider, _) {
            final query = _groupSearchController.text.trim().toLowerCase();
            final filteredGroups = groupsProvider.groups
                .where((g) => g.toLowerCase().contains(query))
                .toList();

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Schedule name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Time range',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(isStart: false),
                          child:
                              Text(_end == null ? 'End' : _formatTime(_end!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Repeat days',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
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
                      _days = {1, 2, 3, 4, 5};
                    }),
                    onSelectEveryday: () => setState(() {
                      _days = {1, 2, 3, 4, 5, 6, 7};
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text('Groups',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search groups',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredGroups.map(
                    (group) => CheckboxListTile(
                      value: _selectedGroups.contains(group),
                      title: Text(group),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedGroups.add(group);
                          } else {
                            _selectedGroups.remove(group);
                          }
                        });
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddManualGroupDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add manually'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_start ?? const TimeOfDay(hour: 22, minute: 0))
        : (_end ?? const TimeOfDay(hour: 8, minute: 0));
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter group name'),
          content: TextField(controller: controller),
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
    await context.read<DetectedGroupsProvider>().addManual(result);
    setState(() {
      _selectedGroups.add(result);
    });
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
      _showError('Select at least one group');
      return;
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

    await context.read<SchedulesProvider>().upsert(schedule);
    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
