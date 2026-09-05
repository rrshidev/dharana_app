import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/features/admin/widgets/period_selector.dart';

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
  bool _isActionBusy = false;
  bool _activityLoading = true;

  int _rangeDays = 30;

  @override
  void initState() {
    super.initState();
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
      final data = await _api.getAdminUserActivity(widget.userId, days: _rangeDays);
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
          ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await _loadActivity();
              },
              color: AppTheme.Accent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatsCard(),
                  const SizedBox(height: 12),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 12),
                  _buildActionsCard(),
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
          backgroundColor: AppTheme.SurfaceLight,
          child: Text(
            user['name']?.toString().isNotEmpty == true
                ? user['name'].toString()[0].toUpperCase()
                : '?',
            style: TextStyle(fontSize: 24, color: AppTheme.Accent, fontWeight: FontWeight.bold),
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
                Text('TG: ${user['telegram_id']}', style: TextStyle(fontSize: 12, color: AppTheme.TextSecondary)),
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
                ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
                : ElevatedButton.icon(
                    onPressed: _togglePremium,
                    icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: Text(isPremium ? 'Снять премиум' : 'Выдать премиум'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? AppTheme.SurfaceLight : AppTheme.Accent,
                      foregroundColor: AppTheme.Background,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final isBanned = (user['is_banned'] ?? false) == true;
    final isDeleted = (user['is_deleted'] ?? false) == true;
    return ChartCard(
      title: 'Действия',
      child: _isActionBusy
          ? Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.Accent),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: isDeleted ? null : _sendMessage,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Написать сообщение'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isDeleted ? null : () => _toggleBan(isBanned),
                        icon: Icon(
                          isBanned ? Icons.check_circle_outline : Icons.block,
                          size: 18,
                        ),
                        label: Text(isBanned ? 'Разбанить' : 'Забанить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isBanned ? AppTheme.AccentGreen : AppTheme.Danger,
                          foregroundColor: AppTheme.Background,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleDelete(isDeleted),
                        icon: Icon(
                          isDeleted ? Icons.restore : Icons.delete,
                          size: 18,
                        ),
                        label: Text(isDeleted ? 'Восстановить' : 'Удалить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.Danger,
                          foregroundColor: AppTheme.Background,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _sendMessage() async {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final userId = user['id'] ?? widget.userId;
    final hasTelegram = user['telegram_id'] != null;
    final textController = TextEditingController();
    String channel = 'both';

    final channelResult = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.Surface,
          title: const Text('Канал доставки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                enabled: hasTelegram,
                leading: Icon(
                  channel == 'both'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                ),
                title: const Text('Telegram + приложение'),
                onTap: hasTelegram ? () => setLocal(() => channel = 'both') : null,
              ),
              ListTile(
                leading: Icon(
                  channel == 'app'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                ),
                title: const Text('Только приложение (in-app)'),
                onTap: () => setLocal(() => channel = 'app'),
              ),
              ListTile(
                enabled: hasTelegram,
                leading: Icon(
                  channel == 'telegram'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                ),
                title: const Text('Только Telegram'),
                onTap: hasTelegram ? () => setLocal(() => channel = 'telegram') : null,
              ),
              if (!hasTelegram)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'У пользователя нет Telegram ID',
                    style: TextStyle(color: AppTheme.TextSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, channel),
              child: const Text('Далее'),
            ),
          ],
        ),
      ),
    );
    if (channelResult == null) return;
    if (!mounted) return;

    File? pickedImage;

    final input = await showDialog<_MessageInputResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.Surface,
          title: const Text('Сообщение пользователю'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(hintText: 'Текст сообщения'),
              ),
              if (pickedImage != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(pickedImage!, height: 120, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final img = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);
                      if (img == null) return;
                      if (!ctx.mounted) return;
                      final file = File(img.path);
                      setLocal(() => pickedImage = file);
                    },
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      pickedImage == null ? '📎 Прикрепить изображение' : '📎 Заменить',
                    ),
                  ),
                  if (pickedImage != null)
                    TextButton(
                      onPressed: () => setLocal(() => pickedImage = null),
                      child: const Text('Убрать'),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                _MessageInputResult(text: textController.text, image: pickedImage),
              ),
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
    if (input == null || input.text.trim().isEmpty) return;

    setState(() => _isActionBusy = true);
    try {
      String? mediaUrl;
      if (input.image != null) {
        final up = await _api.uploadAdminMessageImage(input.image!);
        mediaUrl = up['media_url']?.toString();
      }
      final data = await _api.sendAdminUserMessage(
        userId,
        message: input.text.trim(),
        channel: channelResult,
        mediaUrl: mediaUrl,
      );
      final parts = <String>[
        if (channelResult == 'both' || channelResult == 'app') _reportApp(data['app']),
        if (channelResult == 'both' || channelResult == 'telegram') _reportTg(data['telegram']),
      ];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.where((p) => p.isNotEmpty).join(' · ')),
            backgroundColor: AppTheme.AccentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  String _reportApp(dynamic status) {
    if (status == 'queued') return 'in-app: поставлено';
    if (status == 'failed') return 'in-app: ошибка';
    return 'in-app: $status';
  }

  String _reportTg(dynamic status) {
    if (status == 'sent') return 'TG: отправлено';
    if (status == 'no_telegram') return 'TG: нет ID';
    if (status == 'failed') return 'TG: ошибка';
    if (status == 'no_bot') return 'TG: бот не настроен';
    return 'TG: $status';
  }

  Future<void> _toggleBan(bool current) async {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final userId = user['id'] ?? widget.userId;
    final ban = !current;
    final ok = await _confirm(
      ban ? 'Забанить пользователя?' : 'Разбанить пользователя?',
      ban ? 'Он потеряет доступ к приложению.' : null,
    );
    if (!ok) return;

    setState(() => _isActionBusy = true);
    try {
      await _api.setUserBan(userId, ban);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ban ? 'Пользователь забанен' : 'Бан снят'),
            backgroundColor: AppTheme.AccentGreen,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _toggleDelete(bool current) async {
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final userId = user['id'] ?? widget.userId;
    final del = !current;
    final ok = await _confirm(
      del ? 'Удалить пользователя?' : 'Восстановить пользователя?',
      del ? 'Это обратимо, но юзер будет помечен удалённым.' : null,
    );
    if (!ok) return;

    setState(() => _isActionBusy = true);
    try {
      await _api.setUserDeleted(userId, del);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(del ? 'Пользователь удалён' : 'Пользователь восстановлен'),
            backgroundColor: AppTheme.AccentGreen,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<bool> _confirm(String title, String? message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.Surface,
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Подтвердить')),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildActivityChart() {
    final days = _activity?['days'];
    final minutesSer = _activity?['minutes'];
    final labels = days is List ? days.cast<String>() : <String>[];
    final minutes = minutesSer is List ? minutesSer.map((e) => (e as num).toDouble()).toList() : <double>[];
    return ChartCard(
      title: 'Минут практики',
      subtitle: PeriodSelector(days: _rangeDays, onChanged: (d) {
        setState(() => _rangeDays = d);
        _loadActivity();
      }),
      child: _activityLoading
          ? SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppTheme.Accent)))
          : AreaTrendChart(data: minutes, labels: labels, color: AppTheme.AccentGreen, showBottomLabels: true),
    );
  }

  Widget _buildRecentSessions() {
    final sessions = _data?['recent_sessions'] as List? ?? [];
    return ChartCard(
      title: 'Последние практики',
      child: sessions.isEmpty
          ? Text('Нет завершённых практик', style: TextStyle(color: AppTheme.TextSecondary))
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
          backgroundColor: AppTheme.Surface,
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
            backgroundColor: AppTheme.AccentGreen,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.Danger),
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

class _MessageInputResult {
  final String text;
  final File? image;
  const _MessageInputResult({required this.text, this.image});
}
