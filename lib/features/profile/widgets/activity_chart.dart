import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dharana_app/app/theme.dart';

class ActivityDaily {
  final DateTime date;
  final double minutes;
  final double sessions;
  final double asanas;

  const ActivityDaily({
    required this.date,
    required this.minutes,
    required this.sessions,
    required this.asanas,
  });
}

class ActivityChart extends StatelessWidget {
  final List<ActivityDaily> days;

  const ActivityChart({super.key, required this.days});

  List<String> _thinnedLabels() {
    final n = days.length;
    final step = n <= 14 ? 1 : (n / 6).ceil();
    final out = <String>[];
    for (var i = 0; i < n; i++) {
      out.add(i % step == 0 ? '${days[i].date.day}.${days[i].date.month}' : '');
    }
    return out;
  }

  double _maxOf(double Function(ActivityDaily) f) {
    var m = 1.0;
    for (final d in days) {
      final v = f(d);
      if (v > m) m = v;
    }
    return m;
  }

  List<FlSpot> _spots(double Function(ActivityDaily) f, double scale) {
    return [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), f(days[i]) / scale),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Нет данных за период', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final maxMin = _maxOf((d) => d.minutes);
    final maxSes = _maxOf((d) => d.sessions);
    final maxAsa = _maxOf((d) => d.asanas);
    final labels = _thinnedLabels();
    final n = days.length;

    final lineColors = [
      AppTheme.accent,
      AppTheme.accentGreen,
      const Color(0xFF6FA8DC),
    ];

    final lines = <LineChartBarData>[
      LineChartBarData(
        spots: _spots((d) => d.minutes, maxMin),
        isCurved: true,
        curveSmoothness: 0.35,
        color: lineColors[0],
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: lineColors[0].withOpacity(0.15),
        ),
      ),
      LineChartBarData(
        spots: _spots((d) => d.sessions, maxSes),
        isCurved: true,
        curveSmoothness: 0.35,
        color: lineColors[1],
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: _spots((d) => d.asanas, maxAsa),
        isCurved: true,
        curveSmoothness: 0.35,
        color: lineColors[2],
        barWidth: 2,
        dotData: const FlDotData(show: false),
      ),
    ];

    final totalMin = days.fold<double>(0, (a, b) => a + b.minutes);
    final totalSes = days.fold<double>(0, (a, b) => a + b.sessions);
    final totalAsa = days.fold<double>(0, (a, b) => a + b.asanas);

    final lineValues = [
      '${totalMin.round()} мин',
      '${totalSes.round()} сессий',
      '${totalAsa.round()} асан',
    ];
    final lineNames = ['Минуты', 'Сессии', 'Асаны'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (n - 1).toDouble(),
              minY: 0,
              maxY: 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.25,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppTheme.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= labels.length || labels[i].isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[i],
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    final names = ['Минуты', 'Сессии', 'Асаны'];
                    return spots.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final value = s.y < 0.0001
                          ? 0.0
                          : s.y * [maxMin, maxSes, maxAsa][i];
                      return LineTooltipItem(
                        '${names[i]}: ${value.toStringAsFixed(value >= 10 ? 0 : 1)}',
                        TextStyle(color: lineColors[i], fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: lines,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < lineNames.length; i++)
              _LegendDot(color: lineColors[i], label: lineNames[i], value: lineValues[i]),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
