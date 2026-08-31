import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/screens/admin_payments_screen.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';

class AdminUser {
  final int id;
  final String? name;
  final String? email;
  final String? username;
  final int? telegramId;
  final bool isPremium;
  final int totalPracticeMinutes;
  final int totalPracticeDays;
  final String? createdAt;

  AdminUser({
    required this.id,
    this.name,
    this.email,
    this.username,
    this.telegramId,
    this.isPremium = false,
    this.totalPracticeMinutes = 0,
    this.totalPracticeDays = 0,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      username: json['username'],
      telegramId: json['telegram_id'],
      isPremium: json['is_premium'] ?? false,
      totalPracticeMinutes: json['total_practice_minutes'] ?? 0,
      totalPracticeDays: json['total_practice_days'] ?? 0,
      createdAt: json['created_at'],
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _series;
  int _seriesDays = 30;
  List<AdminUser> _users = [];
  List<dynamic> _activity = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final _bcMessageController = TextEditingController();
  bool _bcAudFree = true;
  bool _bcAudPremium = true;
  bool _bcChanTg = true;
  bool _bcChanApp = true;
  bool _bcSending = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bcMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _api.getAdminStats();
      final users = await _api.getAdminUsers();
      final activity = await _api.getAdminActivity();
      final series = await _api.getAdminStatsSeries(days: _seriesDays);
      if (mounted) {
        setState(() {
          _stats = stats;
          _users = (users['items'] as List)
              .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
              .toList();
          _activity = activity;
          _series = series;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _loadSeries(int days) async {
    setState(() => _seriesDays = days);
    try {
      final series = await _api.getAdminStatsSeries(days: days);
      if (mounted) {
        setState(() => _series = series);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки графиков: $e')),
        );
      }
    }
  }

  Future<void> _search(String query) async {
    try {
      final users = await _api.getAdminUsers(search: query);
      if (mounted) {
        setState(() {
          _users = (users['items'] as List)
              .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : DefaultTabController(
              length: 6,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: AppTheme.accent,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicatorColor: AppTheme.accent,
                    tabs: [
                      Tab(text: 'Статистика'),
                      Tab(text: 'Пользователи'),
                      Tab(text: 'Активность'),
                      Tab(text: 'Заявки'),
                      Tab(text: 'Рассылка'),
                      Tab(text: 'Графики'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStatsTab(),
                        _buildUsersTab(),
                        _buildActivityTab(),
                        const AdminPaymentsScreen(),
                        _buildBroadcastTab(),
                        _buildChartsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsTab() {
    final s = _stats ?? {};
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _statCard(
                icon: Icons.people_outline,
                value: '${s['total_users'] ?? 0}',
                label: 'Всего юзеров',
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.workspace_premium_outlined,
                value: '${s['premium_users'] ?? 0}',
                label: 'Премиум',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.self_improvement,
                value: '${s['total_sessions'] ?? 0}',
                label: 'Практик',
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.schedule,
                value: '${s['total_practice_minutes'] ?? 0}',
                label: 'Минут',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.person_add_alt_1,
                value: '${s['new_users_week'] ?? 0}',
                label: 'Новых за нед.',
              ),
              const SizedBox(width: 12),
              _statCard(
                icon: Icons.person_add_alt,
                value: '${s['new_users_month'] ?? 0}',
                label: 'Новых за мес.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Конверсия в премиум',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${s['conversion_rate'] ?? 0}%',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.accent, size: 22),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return AdminCharts(
      series: _series,
      days: _seriesDays,
      loading: _series == null,
      onDaysChanged: _loadSeries,
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchController,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Поиск по имени, email, username',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _search('');
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('Пользователи не найдены'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceLight,
                          child: Text(
                            (u.name ?? '?').isNotEmpty
                                ? (u.name ?? '?')[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(u.name ?? 'Без имени'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (u.email != null) Text(u.email!),
                            if (u.telegramId != null)
                              Text('TG: ${u.telegramId}',
                                  style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (u.isPremium)
                              const Icon(Icons.workspace_premium,
                                  color: AppTheme.accent, size: 18),
                            Text(
                              '${u.totalPracticeMinutes} мин',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(userId: u.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    if (_activity.isEmpty) {
      return const Center(child: Text('Активности нет'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activity.length,
      itemBuilder: (context, i) {
        final e = _activity[i];
        final type = e['type'];
        final isPractice = type == 'practice';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isPractice ? Icons.self_improvement : Icons.person_add,
              color: isPractice ? AppTheme.accentGreen : AppTheme.accent,
            ),
            title: Text(isPractice
                ? 'Практика: ${e['asanas_count'] ?? 0} асан'
                : 'Новый пользователь: ${e['user_name'] ?? '?'}'),
            subtitle: Text(
              isPractice
                  ? '${((e['duration_seconds'] ?? 0) / 60).round()} мин'
                  : (_formatTime(e['timestamp'])),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.length < 10) return '';
    final d = iso.substring(0, 10);
    final t = iso.length > 16 ? iso.substring(11, 16) : '';
    return '$d $t';
  }
  Widget _buildBroadcastTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Новая рассылка', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _bcMessageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Текст сообщения для пользователей',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Аудитория', style: TextStyle(fontWeight: FontWeight.w600)),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Бесплатные'),
                  value: _bcAudFree,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setState(() => _bcAudFree = v ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Премиум'),
                  value: _bcAudPremium,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setState(() => _bcAudPremium = v ?? true),
                ),
                if (!_bcAudFree && !_bcAudPremium)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Выберите хотя бы одну аудиторию',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text('Каналы', style: TextStyle(fontWeight: FontWeight.w600)),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                   title: const Text('Telegram'),
                  value: _bcChanTg,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setState(() => _bcChanTg = v ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('В приложении'),
                  value: _bcChanApp,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => setState(() => _bcChanApp = v ?? true),
                ),
                if (!_bcChanTg && !_bcChanApp)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Выберите хотя бы один канал',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _bcSending ? null : _sendTestBroadcast,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Тест админу'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _bcSending
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.accent))
                      : ElevatedButton.icon(
                          onPressed: _sendBroadcast,
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('Разослать'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.background,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _audLabel() {
    if (_bcAudFree && _bcAudPremium) return 'Все';
    if (_bcAudFree) return 'Бесплатные';
    if (_bcAudPremium) return 'Премиум';
    return '—';
  }

  String _chanLabel() {
    final parts = <String>[];
    if (_bcChanTg) parts.add('Telegram');
    if (_bcChanApp) parts.add('Приложение');
    return parts.isEmpty ? '—' : parts.join(' + ');
  }

  Future<void> _sendBroadcast() async {
    final msg = _bcMessageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст сообщения'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    if (!_bcAudFree && !_bcAudPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите аудиторию'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    if (!_bcChanTg && !_bcChanApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите канал'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Разослать сообщение?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text('Аудитория: ${_audLabel()}'),
            Text('Каналы: ${_chanLabel()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _bcSending = true);
    try {
      final data = await _api.createBroadcast(
        message: msg,
        audienceFree: _bcAudFree,
        audiencePremium: _bcAudPremium,
        channelTelegram: _bcChanTg,
        channelApp: _bcChanApp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Рассылка создана. Telegram: ${data['count_telegram'] ?? 0}, '
              'Приложение: ${data['count_app'] ?? 0}',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _bcMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _bcSending = false);
    }
  }

  Future<void> _sendTestBroadcast() async {
    final msg = _bcMessageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст сообщения'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _bcSending = true);
    try {
      final data = await _api.testBroadcast(
        message: msg,
        audienceFree: _bcAudFree,
        audiencePremium: _bcAudPremium,
        channelTelegram: _bcChanTg,
        channelApp: _bcChanApp,
      );
      if (mounted) {
        final tg = data['telegram'] ?? '?';
        final app = data['app'] ?? '?';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тест админу: Telegram=$tg, Приложение=$app'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _bcSending = false);
    }
  }
}

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getAdminUserDetail(widget.userId);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователь')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final sub = _data?['subscription'] as Map<String, dynamic>? ?? {};
    final sessions = _data?['recent_sessions'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.surfaceLight,
              child: Text(
                (user['name'] ?? '?').toString()[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name']?.toString() ?? 'Без имени',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (user['email'] != null) Text(user['email'].toString()),
                  if (user['telegram_id'] != null)
                    Text('TG: ${user['telegram_id']}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Статистика', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _row('Минут практики', '${user['total_practice_minutes'] ?? 0}'),
                _row('Дней практики', '${user['total_practice_days'] ?? 0}'),
                _row('Текущая серия', '${user['current_streak'] ?? 0}'),
                _row('Лучшая серия', '${user['longest_streak'] ?? 0}'),
                _row('Дата регистрации', _date(user['created_at'])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Подписка', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _row('Статус',
                    (sub['is_premium'] ?? false) == true ? 'Премиум' : 'Бесплатно'),
                if (sub['subscription_end'] != null)
                  _row('До', _date(sub['subscription_end'])),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _isUpdating
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.accent))
                      : ElevatedButton.icon(
                          onPressed: _togglePremium,
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: Text((sub['is_premium'] ?? false) == true
                              ? 'Снять премиум'
                              : 'Выдать премиум'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (sub['is_premium'] ?? false) == true
                                ? AppTheme.surfaceLight
                                : AppTheme.accent,
                            foregroundColor: AppTheme.background,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Последние практики',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  const Text('Нет завершённых практик')
                else
                  for (final s in sessions.take(10))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${s['asanas_practiced'] ?? 0} асан',
                              style: Theme.of(context).textTheme.bodyLarge),
                          const Spacer(),
                          Text(
                            '${((s['total_duration_seconds'] ?? 0) / 60).round()} мин',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final n = int.tryParse(controller.text);
                Navigator.pop(ctx, n ?? 30);
              },
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
    return iso.substring(0, 10);
  }
}
