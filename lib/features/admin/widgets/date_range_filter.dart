import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// Результат выбора периода.
class DateRangeSelection {
  final DateTime? start;
  final DateTime? end;
  final String label;

  const DateRangeSelection({this.start, this.end, required this.label});
}

/// Панель выбора диапазона дат: быстрые пресеты + календарь.
class DateRangeFilter extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateRangeSelection> onChanged;
  final String customLabel;
  final bool showCustom;

  const DateRangeFilter({
    super.key,
    this.start,
    this.end,
    required this.onChanged,
    this.customLabel = 'Календарь',
    this.showCustom = true,
  });

  void _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = start ?? now.subtract(const Duration(days: 29));
    final initialEnd = end ?? now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      currentDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            onPrimary: AppTheme.background,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(DateRangeSelection(
        start: picked.start,
        end: picked.end,
        label: '${_fmt(picked.start)} – ${_fmt(picked.end)}',
      ));
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  bool _isActive(int days) {
    if (start == null || end == null) return false;
    final len = end!.difference(start!).inDays + 1;
    return len == days;
  }

  @override
  Widget build(BuildContext context) {
    final presets = <(String, int)>[
      ('7 д', 7),
      ('30 д', 30),
      ('90 д', 90),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in presets)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(p.$1),
                selected: _isActive(p.$2),
                onSelected: (_) {
                  final end = DateTime.now();
                  final start = end.subtract(Duration(days: p.$2 - 1));
                  onChanged(DateRangeSelection(start: start, end: end, label: p.$1));
                },
                selectedColor: AppTheme.accent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _isActive(p.$2) ? AppTheme.background : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (showCustom) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 16, color: AppTheme.accent),
                label: Text(customLabel),
                onPressed: () => _pickRange(context),
                labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              ),
            ),
          ],
          if (start != null && end != null && customLabel != '7 д' && customLabel != '30 д' && customLabel != '90 д')
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                customLabel,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
