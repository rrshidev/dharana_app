import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/features/admin/widgets/period_selector.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _series;
  List<dynamic> _activity = [];
  bool _loading = true;

  int _rangeDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  List<String>? get _days {
    final raw = _series?['days'];
    return raw is List ? raw.cast<String>() : null;
  }

  List<double> _ints(String key) {
    final raw = _series?[key];
    if (raw is List) return raw.map((e) => (e as num).toDouble()).toList();
    return [];
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final stats = await _api.getAdminStats();
      final series = await _api.getAdminStatsSeries(days: _rangeDays);
      final activity = await _api.getAdminActivity();
      if (mounted) {
        setState(() {
          _stats = stats;
          _series = series;
          _activity = activity;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обзор'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppTheme.accent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PeriodSelector(days: _rangeDays, onChanged: (d) {
                      setState(() => _rangeDays = d);
                      _loadAll();
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCards(),
                  const SizedBox(height: 12),
                  _buildPracticesChart(),
                  _buildUsersChart(),
                  _buildConversion(),
                  const SizedBox(height: 4),
                  _buildActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCards() {
    final s = _stats ?? {};
    final practicesTrend = _ints('practices');
    final usersTrend = _ints('new_users');
    return Column(
      children: [
        Row(
          children: [
            _statCard(
              icon: Icons.people_outline,
              value: '${s['total_users'] ?? 0}',
              label: 'Юзеров',
              spark: usersTrend,
              sparkColor: AppTheme.accent,
            ),
            const SizedBox(width: 10),
            _statCard(
              icon: Icons.workspace_premium_outlined,
              value: '${s['premium_users'] ?? 0}',
              label: 'Премиум',
              spark: _ints('new_premium'),
              sparkColor: AppTheme.accentGreen,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard(
              icon: Icons.self_improvement,
              value: '${s['total_sessions'] ?? 0}',
              label: 'Практик',
              spark: practicesTrend,
              sparkColor: AppTheme.accent,
            ),
            const SizedBox(width: 10),
            _statCard(
              icon: Icons.schedule,
              value: '${s['total_practice_minutes'] ?? 0}',
              label: 'Минут',
              spark: _periodMinutes(practicesTrend),
              sparkColor: AppTheme.accentGreen,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statCard(
              icon: Icons.person_add_alt_1,
              value: '${s['new_users_week'] ?? 0}',
              label: 'Новых/нед.',
              spark: usersTrend,
              sparkColor: AppTheme.accent,
            ),
            const SizedBox(width: 10),
            _statCard(
              icon: Icons.percent,
              value: '${s['conversion_rate'] ?? 0}%',
              label: 'Конверсия',
              spark: [],
              sparkColor: AppTheme.accent,
            ),
          ],
        ),
      ],
    );
  }

  List<double> _periodMinutes(List<double> practices) {
    // Приблизительный тренд минут (практики × среднее время сессии недоступно) — sparks пуст.
    return [];
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required List<double> spark,
    required Color sparkColor,
  }) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.accent, size: 18),
                  const Spacer(),
                  if (spark.isNotEmpty) Sparkline(data: spark, color: sparkColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticesChart() {
    final days = _days ?? [];
    final practices = _ints('practices');
    return ChartCard(
      title: 'Практики по дням',
      child: AreaTrendChart(data: practices, labels: days),
    );
  }

  Widget _buildUsersChart() {
    final days = _days ?? [];
    return ChartCard(
      title: 'Новые пользователи и премиум',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MultiLineChart(
            series: [
              ChartSeries(name: 'Зарегистрировано', color: AppTheme.accent, data: _ints('new_users')),
              ChartSeries(name: 'Премиум', color: AppTheme.accentGreen, data: _ints('new_premium')),
            ],
            labels: days,
          ),
          const SizedBox(height: 10),
          ChartLegend(
            series: [
              const ChartSeries(name: 'Регистрации', color: AppTheme.accent, data: []),
              const ChartSeries(name: 'Премиум', color: AppTheme.accentGreen, data: []),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversion() {
    final s = _stats ?? {};
    final rate = (s['conversion_rate'] as num?)?.toDouble() ?? 0;
    return ChartCard(
      title: 'Конверсия в Premium',
      child: Row(
        children: [
          DonutRate(value: rate, centerLabel: '${rate.round()}%', subLabel: 'премиум/все'),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Всего юзеров', '${s['total_users'] ?? 0}'),
                _kv('Премиум', '${s['premium_users'] ?? 0}'),
                _kv('Новых за месяц', '${s['new_users_month'] ?? 0}'),
                _kv('Практик за месяц', '${s['sessions_month'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(v, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActivity() {
    final list = _activity.take(10).toList();
    return ChartCard(
      title: 'Последняя активность',
      child: list.isEmpty
          ? const Text('Активности нет', style: TextStyle(color: AppTheme.textSecondary))
          : Column(
              children: list.map(_activityRow).toList(),
            ),
    );
  }

  Widget _activityRow(dynamic e) {
    final type = e['type'];
    final isPractice = type == 'practice';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPractice ? Icons.self_improvement : Icons.person_add,
            color: isPractice ? AppTheme.accentGreen : AppTheme.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPractice
                  ? 'Практика: ${e['asanas_count'] ?? 0} асан · ${((e['duration_seconds'] ?? 0) / 60).round()} мин'
                  : 'Новый пользователь: ${e['user_name'] ?? '?'}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Text(
            _shortDate(e['timestamp']),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.length < 16) return '';
    return '${iso.substring(8, 10)}.${iso.substring(5, 7)} ${iso.substring(11, 16)}';
  }
}
