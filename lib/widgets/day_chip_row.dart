import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class DayChipRow extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onSelectWeekdays;
  final VoidCallback onSelectWeekend;
  final VoidCallback onSelectEveryday;

  const DayChipRow({
    super.key,
    required this.selectedDays,
    required this.onToggleDay,
    required this.onSelectWeekdays,
    required this.onSelectWeekend,
    required this.onSelectEveryday,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _weekend = {6, 7};
  static const _everyday = {1, 2, 3, 4, 5, 6, 7};

  bool _matches(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final day in a) {
      if (!b.contains(day)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 0,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PresetButton(
                    label: 'Weekdays',
                    selected: _matches(selectedDays, _weekdays),
                    onTap: onSelectWeekdays,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetButton(
                    label: 'Weekend',
                    selected: _matches(selectedDays, _weekend),
                    onTap: onSelectWeekend,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetButton(
                    label: 'Every day',
                    selected: _matches(selectedDays, _everyday),
                    onTap: onSelectEveryday,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = selectedDays.contains(day);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onToggleDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? theme.colorScheme.primary : tokens.surface,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : tokens.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _labels[index],
                      style: AppTypography.secondaryBodyStrong.copyWith(
                        color: selected ? Colors.white : tokens.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? accent.withOpacity(0.14) : tokens.surface,
          side: BorderSide(color: selected ? accent : tokens.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.secondaryBodyStrong.copyWith(
            color: selected ? accent : tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
