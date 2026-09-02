import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// Переключатель периода для графиков: 7 / 30 / 90 дней.
class PeriodSelector extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChanged;

  const PeriodSelector({super.key, required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [7, 30, 90];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final d in options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$d д'),
              selected: days == d,
              onSelected: (_) => onChanged(d),
              selectedColor: AppTheme.Accent,
              labelStyle: TextStyle(
                fontSize: 12,
                color: days == d ? AppTheme.Background : AppTheme.TextPrimary,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
