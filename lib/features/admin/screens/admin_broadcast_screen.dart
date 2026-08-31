import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/features/admin/widgets/date_range_filter.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _api = ApiClient();
  final _messageController = TextEditingController();
  bool _bcAudFree = true;
  bool _bcAudPremium = true;
  bool _bcChanTg = true;
  bool _bcChanApp = true;
  bool _sending = false;

  Map<String, dynamic>? _series;
  bool _seriesLoading = true;

  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final end = DateTime.now();
    _start = end.subtract(const Duration(days: 29));
    _end = end;
    _loadSeries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    setState(() => _seriesLoading = true);
    try {
      final data = await _api.getAdminBroadcastSeries(start: _start, end: _end);
      if (mounted) setState(() { _series = data; _seriesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _seriesLoading = false);
    }
  }

  List<double> _ints(String key) {
    final raw = _series?[key];
    if (raw is List) return raw.map((e) => (e as num).toDouble()).toList();
    return [];
  }

  List<String>? get _days => _series?['days'] is List ? (_series!['days'] as List).cast<String>() : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рассылка'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSeries)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatStrip(),
          const SizedBox(height: 12),
          _buildTrendChart(),
          const SizedBox(height: 4),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildStatStrip() {
    final total = _series?['total_recipients'] ?? 0;
    final campaigns = _series?['campaigns'] is List
        ? (_series?['campaigns'] as List).fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0))
        : 0;
    final recipients = _series?['recipients'] is List
        ? (_series?['recipients'] as List).fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0))
        : 0;
    return Row(
      children: [
        _miniStat('$campaigns', 'Рассылок', AppTheme.accent, menu: true),
        const SizedBox(width: 8),
        _miniStat('$recipients', 'Получателей', AppTheme.accentGreen, menu: false),
        const SizedBox(width: 8),
        _miniStat('$total', 'Всего доставок', AppTheme.accent, menu: false),
      ],
    );
  }

  Widget _miniStat(String value, String label, Color color, {required bool menu}) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return ChartCard(
      title: 'Рассылки по дням',
      subtitle: DateRangeFilter(
        start: _start,
        end: _end,
        onChanged: (sel) {
          setState(() {
            _start = sel.start;
            _end = sel.end;
          });
          _loadSeries();
        },
      ),
      child: _seriesLoading
          ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BarChartSimple(data: _ints('campaigns'), labels: _days ?? [], color: AppTheme.accent),
                const SizedBox(height: 8),
                Text(
                  'Получателей: ${_ints('recipients').isEmpty ? '—' : _ints('recipients').fold<double>(0, (a, b) => a + b).round()}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _buildForm() {
    return ChartCard(
      title: 'Новая рассылка',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Текст сообщения для пользователей',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
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
            const Text('Выберите хотя бы одну аудиторию',
                style: TextStyle(color: AppTheme.danger, fontSize: 12)),
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
            const Text('Выберите хотя бы один канал',
                style: TextStyle(color: AppTheme.danger, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : _sendTest,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Тест админу'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _sending
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : ElevatedButton.icon(
                    onPressed: _send,
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

  bool _validate() {
    if (_messageController.text.trim().isEmpty) {
      _snack('Введите текст сообщения', AppTheme.danger);
      return false;
    }
    if (!_bcAudFree && !_bcAudPremium) {
      _snack('Выберите аудиторию', AppTheme.danger);
      return false;
    }
    if (!_bcChanTg && !_bcChanApp) {
      _snack('Выберите канал', AppTheme.danger);
      return false;
    }
    return true;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _send() async {
    if (!_validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Разослать сообщение?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_messageController.text, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text('Аудитория: ${_audLabel()}'),
            Text('Каналы: ${_chanLabel()}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Отправить')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      final data = await _api.createBroadcast(
        message: _messageController.text.trim(),
        audienceFree: _bcAudFree,
        audiencePremium: _bcAudPremium,
        channelTelegram: _bcChanTg,
        channelApp: _bcChanApp,
      );
      if (mounted) {
        _snack(
          'Рассылка создана. Telegram: ${data['count_telegram'] ?? 0}, Приложение: ${data['count_app'] ?? 0}',
          AppTheme.accentGreen,
        );
        _messageController.clear();
        _loadSeries();
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendTest() async {
    if (_messageController.text.trim().isEmpty) {
      _snack('Введите текст сообщения', AppTheme.danger);
      return;
    }
    setState(() => _sending = true);
    try {
      final data = await _api.testBroadcast(
        message: _messageController.text.trim(),
        audienceFree: _bcAudFree,
        audiencePremium: _bcAudPremium,
        channelTelegram: _bcChanTg,
        channelApp: _bcChanApp,
      );
      if (mounted) {
        _snack('Тест админу: Telegram=${data['telegram'] ?? '?'}, Приложение=${data['app'] ?? '?'}', AppTheme.accent);
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e', AppTheme.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
