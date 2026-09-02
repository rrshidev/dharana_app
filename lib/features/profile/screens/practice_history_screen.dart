import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/timer/screens/timer_screen.dart';
import 'package:intl/intl.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  final _api = ApiClient();
  final List<PracticeSession> _sessions = [];
  PracticeStats? _stats;
  bool _isLoading = true;
  bool _hasMore = true;
  int _offset = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final historyData = await _api.getPracticeHistory(limit: _limit, offset: _offset);
      final sessionsList = historyData['sessions'] as List<dynamic>;
      final statsData = await _api.getPracticeStats();
      if (mounted) {
        setState(() {
          _sessions.addAll(sessionsList.map((s) => PracticeSession.fromJson(s)).toList());
          _stats = PracticeStats.fromJson(statsData);
          _hasMore = sessionsList.length == _limit;
          _offset += sessionsList.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История практик')),
      body: _isLoading && _sessions.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
          : RefreshIndicator(
              onRefresh: () async {
                _offset = 0;
                _sessions.clear();
                await _loadData();
              },
              color: AppTheme.Accent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsSummary(),
                  const SizedBox(height: 20),
                  if (_sessions.isEmpty)
                    _buildEmptyState()
                  else
                    ..._sessions.map(_buildSessionCard),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoading
                            ? CircularProgressIndicator(color: AppTheme.Accent, strokeWidth: 2)
                            : TextButton(
                                onPressed: _loadData,
                                child: const Text('Загрузить ещё'),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.timer_outlined,
              value: '${_stats?.totalMinutes ?? 0}',
              label: 'минут',
            ),
            _buildStatItem(
              icon: Icons.calendar_today,
              value: '${_stats?.totalDays ?? 0}',
              label: 'дней',
            ),
            _buildStatItem(
              icon: Icons.local_fire_department_outlined,
              value: '${_stats?.currentStreak ?? 0}',
              label: 'серия',
            ),
            _buildStatItem(
              icon: Icons.self_improvement,
              value: '${_stats?.totalSessions ?? 0}',
              label: 'сессий',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.Accent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.TextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.TextSecondary)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.TextSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Нет практик', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Начните практику в таймере', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSessionCard(PracticeSession session) {
    final date = session.completedAt != null
        ? DateFormat('d MMMM yyyy, HH:mm', 'ru').format(DateTime.parse(session.completedAt!))
        : session.startedAt != null
            ? DateFormat('d MMMM yyyy, HH:mm', 'ru').format(DateTime.parse(session.startedAt!))
            : '';
    final duration = session.totalDurationSeconds;
    final m = duration ~/ 60;
    final s = duration % 60;
    final durationStr = m > 0 ? '${m}м ${s > 0 ? '$sс' : ''}' : '${s}с';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  session.status == 'completed'
                      ? Icons.check_circle
                      : Icons.pause_circle,
                  color: session.status == 'completed'
                      ? AppTheme.AccentGreen
                      : AppTheme.TextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  durationStr,
                  style: TextStyle(
                    color: AppTheme.Accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (session.asanasPracticed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: session.asanasPracticed.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.SurfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.CardBorder),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 11, color: AppTheme.TextSecondary),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              if (session.canRepeat)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _repeatSession(session),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Повторить'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppTheme.Accent),
                      foregroundColor: AppTheme.Accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              else
                _buildPremiumUpsell(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.Accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.Accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.Accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Повтор практики доступен по подписке Premium',
              style: TextStyle(fontSize: 13, color: AppTheme.TextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Оформите Premium, чтобы повторять любые практики'),
                  backgroundColor: AppTheme.SurfaceLight,
                ),
              );
            },
            child: Text('Подробнее', style: TextStyle(color: AppTheme.Accent)),
          ),
        ],
      ),
    );
  }

  void _repeatSession(PracticeSession session) {
    final defaultDuration = session.totalDurationSeconds > 0 && session.asanasPracticed.isNotEmpty
        ? session.totalDurationSeconds ~/ session.asanasPracticed.length
        : 60;

    final asanas = session.asanasPracticed.map((name) {
      return {
        'name': name,
        'duration_seconds': session.asanaDurations[name] ?? defaultDuration,
        'rest_seconds': session.restSeconds,
      };
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(asanas: asanas),
      ),
    );
  }
}
