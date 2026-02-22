import 'package:flutter/material.dart';

class DayChipRow extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onSelectWeekdays;
  final VoidCallback onSelectEveryday;

  const DayChipRow({
    super.key,
    required this.selectedDays,
    required this.onToggleDay,
    required this.onSelectWeekdays,
    required this.onSelectEveryday,
  });

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = selectedDays.contains(day);
            return FilterChip(
              label: Text(_labels[index]),
              selected: selected,
              onSelected: (_) => onToggleDay(day),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: onSelectWeekdays,
              child: const Text('Weekdays'),
            ),
            OutlinedButton(
              onPressed: onSelectEveryday,
              child: const Text('Every day'),
            ),
          ],
        ),
      ],
    );
  }
}
