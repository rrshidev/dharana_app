import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// Общие анимированные компоненты графиков для админ-панели.
/// Все чарты плавно "вырастают" при смене данных (TweenAnimationBuilder).

class ChartCard extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget child;
  final EdgeInsets padding;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 12),
                  subtitle!,
                ],
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Мини-линия (sparkline) для карточек обзора.
class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;

  const Sparkline({
    super.key,
    required this.data,
    this.color = AppTheme.accent,
    this.height = 32,
    this.width = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Text('—', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(data: data, color: color, minV: minV, range: range),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minV;
  final double range;

  _SparklinePainter({required this.data, required this.color, required this.minV, required this.range});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (data.length == 1) ? size.width / 2 : (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minV) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.data != data || old.color != color || old.minV != minV || old.range != range;
}

/// Обёртка для анимации роста значения (0→full).
class _Grow extends StatelessWidget {
  final Widget Function(double t) builder;
  const _Grow({required this.builder});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(t),
    );
  }
}

/// Area-чарт: заполненная область (одна серия).
class AreaTrendChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final double height;
  final bool showBottomLabels;

  const AreaTrendChart({
    super.key,
    required this.data,
    required this.labels,
    this.color = AppTheme.accent,
    this.height = 180,
    this.showBottomLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return ChartEmpty(height: height);

    return _Grow(
      builder: (t) {
        final scaled = data.map((e) => e * t).toList();
        return SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
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
                  sideTitles: SideTitles(showTitles: false, reservedSize: 4),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showBottomLabels,
                    reservedSize: 22,
                    interval: _labelInterval(data.length),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _short(label: labels[i], n: data.length),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toInt()}',
                            const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                  getTooltipColor: (_) => AppTheme.textPrimary,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(scaled.length, (i) => FlSpot(i.toDouble(), scaled[i])),
                  color: color,
                  barWidth: 2.4,
                  isCurved: true,
                  dotData: FlDotData(show: data.length <= 31),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Линейный чарт с несколькими сериями.
class MultiLineChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<String> labels;
  final double height;

  const MultiLineChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final anyData = series.any((s) => s.data.isNotEmpty);
    if (!anyData) return ChartEmpty(height: height);

    return _Grow(
      builder: (t) {
        return SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _labelInterval(labels.length),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _short(label: labels[i], n: labels.length),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toInt()}',
                            const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                  getTooltipColor: (_) => AppTheme.textPrimary,
                ),
              ),
              lineBarsData: series.map((s) {
                return LineChartBarData(
                  spots: List.generate(
                    s.data.length,
                    (i) => FlSpot(i.toDouble(), s.data[i] * t),
                  ),
                  color: s.color,
                  barWidth: 2.2,
                  isCurved: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Стек-чарт (столбцы со слоями) — напр. заявки pending/confirmed/rejected.
class StackedBarChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<String> labels;
  final double height;

  const StackedBarChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return ChartEmpty(height: height);

    return _Grow(
      builder: (t) {
        return SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _labelInterval(labels.length),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _short(label: labels[i], n: labels.length),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.textPrimary,
                  getTooltipItem: (group, gi, rod, ri) {
                    final sum = group.barRods.fold<double>(0, (a, b) => a + b.toY);
                    return BarTooltipItem(
                      '${sum.toInt()}',
                      const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              barGroups: List.generate(labels.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: _stackRods(i, t),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  List<BarChartRodData> _stackRods(int index, double t) {
    final rods = <BarChartRodData>[];
    double cumulative = 0;
    for (final s in series) {
      final v = index < s.data.length ? s.data[index] * t : 0.0;
      rods.add(BarChartRodData(
        toY: cumulative + v,
        fromY: cumulative,
        color: s.color,
        width: 7,
        borderRadius: BorderRadius.circular(0),
      ));
      cumulative += v;
    }
    return rods;
  }
}

/// Простой столбчатый чарт (одна серия).
class BarChartSimple extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final double height;

  const BarChartSimple({
    super.key,
    required this.data,
    required this.labels,
    this.color = AppTheme.accent,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return ChartEmpty(height: height);

    return _Grow(
      builder: (t) {
        return SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _labelInterval(labels.length),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _short(label: labels[i], n: labels.length),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.textPrimary,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${rod.toY.toInt()}',
                    const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              barGroups: List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i] * t,
                      color: color,
                      width: _barWidth(data.length),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Круговая/кольцевая доля (например конверсия).
class DonutRate extends StatelessWidget {
  final double value; // 0..100
  final String centerLabel;
  final String? subLabel;
  final double size;

  const DonutRate({
    super.key,
    required this.value,
    this.centerLabel = '',
    this.subLabel,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return _Grow(
      builder: (t) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: size * 0.32,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: (value * t).clamp(0, 100),
                      color: AppTheme.accentGreen,
                      showTitle: false,
                      radius: size / 2,
                    ),
                    PieChartSectionData(
                      value: ((100 - value) * t).clamp(0, 100),
                      color: AppTheme.surfaceLight,
                      showTitle: false,
                      radius: size / 2,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel.isNotEmpty ? centerLabel : '${value.round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChartEmpty extends StatelessWidget {
  final double height;
  const ChartEmpty({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Text(
          'Нет данных за период',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

/// Серия данных для многосерийных чартов.
class ChartSeries {
  final String name;
  final Color color;
  final List<double> data;

  const ChartSeries({required this.name, required this.color, required this.data});
}

/// Горизонтальная легенда с точками.
class ChartLegend extends StatelessWidget {
  final List<ChartSeries> series;

  const ChartLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: series
          .map((s) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.name,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

double _labelInterval(int n) {
  if (n >= 90) return 14;
  if (n >= 31) return 5;
  if (n >= 15) return 3;
  if (n >= 7) return 1;
  return 1;
}

double _barWidth(int n) {
  if (n >= 90) return 2;
  if (n >= 31) return 4;
  if (n >= 15) return 6;
  return 14;
}

/// Короткая подпись даты вида «дд.мм».
String _short({required String label, required int n}) {
  if (label.length >= 10) {
    return label.substring(5, 10); // "MM-DD"
  }
  return label;
}
