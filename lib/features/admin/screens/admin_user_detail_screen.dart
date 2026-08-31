import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/features/admin/widgets/date_range_filter.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _activity;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _activityLoading = true;

  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final end = DateTime.now();
    _start = end.subtract(const Duration(days: 29));
    _end = end;
    _load();
    _loadActivity();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getAdminUserDetail(widget.userId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActivity() async {
    setState(() => _activityLoading = true);
    try {
      final data = await _api.getAdminUserActivity(widget.userId, start: _start, end: _end);
      if (mounted) setState(() { _activity = data; _activityLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователь')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await _loadActivity();
              },
              color: AppTheme.accent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatsCard(),
                  const SizedBox(height: 12),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 12),
                  _buildActivityChart(),
                  const SizedBox(height: 12),
                  _buildRecentSessions(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.surfaceLight,
          child: Text(
            user['name']?.toString().isNotEmpty == true
                ? user['name'].toString()[0].toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 24, color: AppTheme.accent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['name']?.toString() ?? 'Без имени', style: Theme.of(context).textTheme.titleLarge),
              if (user['email'] != null) Text(user['email'].toString(), style: const TextStyle(fontSize: 13)),
              if (user['telegram_id'] != null)
                Text('TG: ${user['telegram_id']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    return ChartCard(
      title: 'Статистика',
      child: Column(
        children: [
          _row('Минут практики', '${user['total_practice_minutes'] ?? 0}'),
          _row('Дней практики', '${user['total_practice_days'] ?? 0}'),
          _row('Текущая серия', '${user['current_streak'] ?? 0}'),
          _row('Лучшая серия', '${user['longest_streak'] ?? 0}'),
          _row('Регистрация', _date(user['created_at'])),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final sub = _data?['subscription'] as Map<String, dynamic>? ?? {};
    final isPremium = (sub['is_premium'] ?? false) == true;
    return ChartCard(
      title: 'Подписка',
      child: Column(
        children: [
          _row('Статус', isPremium ? 'Премиум' : 'Бесплатно'),
          if (sub['subscription_end'] != null)
            _row('До', _date(sub['subscription_end'])),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _isUpdating
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : ElevatedButton.icon(
                    onPressed: _togglePremium,
                    icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: Text(isPremium ? 'Снять премиум' : 'Выдать премиум'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? AppTheme.surfaceLight : AppTheme.accent,
                      foregroundColor: AppTheme.background,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final days = _activity?['days'];
    final minutesSer = _activity?['minutes'];
    final labels = days is List ? days.cast<String>() : <String>[];
    final minutes = minutesSer is List ? minutesSer.map((e) => (e as num).toDouble()).toList() : <double>[];
    return ChartCard(
      title: 'Минут практики',
      subtitle: DateRangeFilter(
        start: _start,
        end: _end,
        showCustom: false,
        onChanged: (sel) {
          setState(() { _start = sel.start; _end = sel.end; });
          _loadActivity();
        },
      ),
      child: _activityLoading
          ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
          : AreaTrendChart(data: minutes, labels: labels, color: AppTheme.accentGreen, showBottomLabels: true),
    );
  }

  Widget _buildRecentSessions() {
    final sessions = _data?['recent_sessions'] as List? ?? [];
    return ChartCard(
      title: 'Последние практики',
      child: sessions.isEmpty
          ? const Text('Нет завершённых практик', style: TextStyle(color: AppTheme.textSecondary))
          : Column(
              children: sessions.take(10).map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${s['asanas_practiced'] ?? 0} асан',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      Text(
                        '${((s['total_duration_seconds'] ?? 0) / 60).round()} мин · ${_date(s['started_at'])}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Future<void> _togglePremium() async {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final sub = _data?['subscription'] as Map<String, dynamic>? ?? {};
    final isPremium = (sub['is_premium'] ?? false) == true;
    final userId = user['id'] ?? widget.userId;

    int? days;
    if (!isPremium) {
      final controller = TextEditingController(text: '30');
      final result = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Выдать премиум'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Кол-во дней'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text) ?? 30),
              child: const Text('Выдать'),
            ),
          ],
        ),
      );
      if (result == null) return;
      days = result;
    }

    setState(() => _isUpdating = true);
    try {
      await _api.setUserPremium(userId, !isPremium, days: days ?? 30);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPremium ? 'Премиум снят' : 'Премиум выдан'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _date(String? iso) {
    if (iso == null || iso.length < 10) return '-';
    return '${iso.substring(8, 10)}.${iso.substring(5, 7)}.${iso.substring(0, 4)}';
  }
}
