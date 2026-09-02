import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// РћР±С‰РёРµ Р°РЅРёРјРёСЂРѕРІР°РЅРЅС‹Рµ РєРѕРјРїРѕРЅРµРЅС‚С‹ РіСЂР°С„РёРєРѕРІ РґР»СЏ Р°РґРјРёРЅ-РїР°РЅРµР»Рё.
/// Р’СЃРµ С‡Р°СЂС‚С‹ РїР»Р°РІРЅРѕ "РІС‹СЂР°СЃС‚Р°СЋС‚" РїСЂРё СЃРјРµРЅРµ РґР°РЅРЅС‹С… (TweenAnimationBuilder).

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
      color: AppTheme.Surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.CardBorder),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.TextPrimary,
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

/// РњРёРЅРё-Р»РёРЅРёСЏ (sparkline) РґР»СЏ РєР°СЂС‚РѕС‡РµРє РѕР±Р·РѕСЂР°.
class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;

  Sparkline({
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
        child: Center(
          child: Text('вЂ”', style: TextStyle(color: AppTheme.TextSecondary)),
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

/// РћР±С‘СЂС‚РєР° РґР»СЏ Р°РЅРёРјР°С†РёРё СЂРѕСЃС‚Р° Р·РЅР°С‡РµРЅРёСЏ (0в†’full).
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

/// Area-С‡Р°СЂС‚: Р·Р°РїРѕР»РЅРµРЅРЅР°СЏ РѕР±Р»Р°СЃС‚СЊ (РѕРґРЅР° СЃРµСЂРёСЏ).
class AreaTrendChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final double height;
  final bool showBottomLabels;

  AreaTrendChart({
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
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppTheme.CardBorder,
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
                          style: TextStyle(color: AppTheme.TextSecondary, fontSize: 9),
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
                            TextStyle(color: AppTheme.Background, fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                  getTooltipColor: (_) => AppTheme.TextPrimary,
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

/// Р›РёРЅРµР№РЅС‹Р№ С‡Р°СЂС‚ СЃ РЅРµСЃРєРѕР»СЊРєРёРјРё СЃРµСЂРёСЏРјРё.
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
                    FlLine(color: AppTheme.CardBorder, strokeWidth: 1),
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
                          style: TextStyle(color: AppTheme.TextSecondary, fontSize: 9),
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
                            TextStyle(color: AppTheme.Background, fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                  getTooltipColor: (_) => AppTheme.TextPrimary,
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

/// РЎС‚РµРє-С‡Р°СЂС‚ (СЃС‚РѕР»Р±С†С‹ СЃРѕ СЃР»РѕСЏРјРё) вЂ” РЅР°РїСЂ. Р·Р°СЏРІРєРё pending/confirmed/rejected.
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
                    FlLine(color: AppTheme.CardBorder, strokeWidth: 1),
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
                          style: TextStyle(color: AppTheme.TextSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.TextPrimary,
                  getTooltipItem: (group, gi, rod, ri) {
                    final sum = group.barRods.fold<double>(0, (a, b) => a + b.toY);
                    return BarTooltipItem(
                      '${sum.toInt()}',
                      TextStyle(color: AppTheme.Background, fontWeight: FontWeight.bold),
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

/// РџСЂРѕСЃС‚РѕР№ СЃС‚РѕР»Р±С‡Р°С‚С‹Р№ С‡Р°СЂС‚ (РѕРґРЅР° СЃРµСЂРёСЏ).
class BarChartSimple extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final double height;

  BarChartSimple({
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
                    FlLine(color: AppTheme.CardBorder, strokeWidth: 1),
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
                          style: TextStyle(color: AppTheme.TextSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.TextPrimary,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${rod.toY.toInt()}',
                    TextStyle(color: AppTheme.Background, fontWeight: FontWeight.bold),
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

/// РљСЂСѓРіРѕРІР°СЏ/РєРѕР»СЊС†РµРІР°СЏ РґРѕР»СЏ (РЅР°РїСЂРёРјРµСЂ РєРѕРЅРІРµСЂСЃРёСЏ).
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
              ClipOval(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: size * 0.30,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: (value * t).clamp(0, 100),
                        color: AppTheme.AccentGreen,
                        showTitle: false,
                        radius: size * 0.46,
                      ),
                      PieChartSectionData(
                        value: ((100 - value) * t).clamp(0, 100),
                        color: AppTheme.SurfaceLight,
                        showTitle: false,
                        radius: size * 0.46,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel.isNotEmpty ? centerLabel : '${value.round()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.TextPrimary,
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      style: TextStyle(color: AppTheme.TextSecondary, fontSize: 10),
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
      child: Center(
        child: Text(
          'РќРµС‚ РґР°РЅРЅС‹С… Р·Р° РїРµСЂРёРѕРґ',
          style: TextStyle(color: AppTheme.TextSecondary),
        ),
      ),
    );
  }
}

/// РЎРµСЂРёСЏ РґР°РЅРЅС‹С… РґР»СЏ РјРЅРѕРіРѕСЃРµСЂРёР№РЅС‹С… С‡Р°СЂС‚РѕРІ.
class ChartSeries {
  final String name;
  final Color color;
  final List<double> data;

  const ChartSeries({required this.name, required this.color, required this.data});
}

/// Р“РѕСЂРёР·РѕРЅС‚Р°Р»СЊРЅР°СЏ Р»РµРіРµРЅРґР° СЃ С‚РѕС‡РєР°РјРё.
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
                    style: TextStyle(color: AppTheme.TextSecondary, fontSize: 12),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

double _labelInterval(int n) {
  if (n <= 14) return 1;
  final step = (n / 6).ceil();
  return step.toDouble();
}

double _barWidth(int n) {
  if (n >= 90) return 3;
  if (n >= 31) return 5;
  if (n >= 15) return 8;
  return 16;
}

/// РљРѕСЂРѕС‚РєР°СЏ РїРѕРґРїРёСЃСЊ РґР°С‚С‹ РІРёРґР° В«РґРґ.РјРјВ».
String _short({required String label, required int n}) {
  if (label.length >= 10) {
    // ISO "YYYY-MM-DD" -> "РґРґ.РјРј"
    return '${label.substring(8, 10)}.${label.substring(5, 7)}';
  }
  return label;
}
