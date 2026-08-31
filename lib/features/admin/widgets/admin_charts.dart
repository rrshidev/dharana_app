import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

class AdminCharts extends StatelessWidget {
  final Map<String, dynamic>? series;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final bool loading;

  const AdminCharts({
    super.key,
    required this.series,
    required this.days,
    required this.onDaysChanged,
    this.loading = false,
  });

  static const _periods = [7, 30, 90];

  List<double> _ints(String key) {
    final raw = series?[key];
    if (raw is List) {
      return raw.map((e) => (e is num) ? e.toDouble() : 0.0).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading || series == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final practices = _ints('practices');
    final newUsers = _ints('new_users');
    final newPremium = _ints('new_premium');

    return RefreshIndicator(
      onRefresh: () async => onDaysChanged(days),
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _periods.map((p) {
              final active = p == days;
              return ChoiceChip(
                label: Text('$p дн'),
                selected: active,
                selectedColor: AppTheme.accent,
                labelStyle: TextStyle(
                  color: active ? AppTheme.background : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onDaysChanged(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _chartCard(
            title: 'Практики по дням',
            child: SizedBox(
              height: 220,
              child: practices.isEmpty
                  ? _empty()
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppTheme.cardBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                              reservedSize: 28,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: _labelInterval(practices.length),
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= practices.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _shortDay(i),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          practices.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: practices[i],
                                color: AppTheme.accent,
                                width: _barWidth(practices.length),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _chartCard(
            title: 'Новые пользователи / премиум',
            child: SizedBox(
              height: 220,
              child: newUsers.isEmpty
                  ? _empty()
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppTheme.cardBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: _labelInterval(newUsers.length),
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= newUsers.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _shortDay(i),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          _line(newUsers, AppTheme.accent),
                          _line(newPremium, AppTheme.accentGreen),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text(
        'Нет данных за период',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i]),
      ),
      color: color,
      barWidth: 2,
      isCurved: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.12),
      ),
    );
  }

  double _barWidth(int n) {
    if (n >= 90) return 2;
    if (n >= 30) return 4;
    return 10;
  }

  double _labelInterval(int n) {
    if (n >= 90) return 14;
    if (n >= 30) return 5;
    return 1;
  }

  String _shortDay(int index) {
    final raw = series?['days'];
    if (raw is! List || index >= raw.length) return '';
    final s = raw[index].toString();
    if (s.length >= 10) return s.substring(5, 10);
    return s;
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendDot(color: AppTheme.accent, label: 'Новые пользователи'),
        SizedBox(width: 16),
        _LegendDot(color: AppTheme.accentGreen, label: 'Новые премиум'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
