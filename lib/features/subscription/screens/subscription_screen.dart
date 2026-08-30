import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/shared/widgets/notification_bell.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _api = ApiClient();
  final _picker = ImagePicker();

  bool _isLoading = true;
  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _requisites = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    try {
      final notifications = await _api.getPaymentNotifications();
      if (mounted && notifications.isNotEmpty) {
        await _api.markPaymentNotificationsRead();
      final first = notifications.first is Map
          ? Map<String, dynamic>.from(notifications.first as Map)
          : <String, dynamic>{};
      final status = first['status']?.toString() ?? '';
      final end = first['subscription_end']?.toString() ?? '';
      if (!mounted) return;
      final isConfirmed = status == 'confirmed';
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isConfirmed ? '🎉 Оплата подтверждена!' : '❌ Заявка отклонена'),
          content: Text(
            isConfirmed
                ? 'Ваш платеж подтвержден. Премиум-подписка активна'
                    '${end.isEmpty ? '!' : ' до $end'}'
                : 'К сожалению, мы не смогли подтвердить ваш платёж.\n'
                    'Свяжитесь с администратором, если вы уверены в оплате, '
                    'или попробуйте ещё раз.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Хорошо'),
            ),
          ],
        ),
      );
      }
    } catch (_) {}
  }


  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final status = await _api.getSubscriptionStatus();
      List<Map<String, dynamic>> requisites = [];
      try {
        final req = await _api.getPaymentRequisites();
        final list = req['requisites'];
        if (list is List) {
          requisites = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _status = status;
          _requisites = requisites;
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

  bool get _isPremium => (_status?['is_premium'] ?? false) == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка'),
        actions: const [NotificationBell()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPlanCard(),
                  const SizedBox(height: 20),
                  _buildRequisitesCard(),
                  const SizedBox(height: 20),
                  _buildPaymentButton(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Как оплатить: переведите сумму на карту, затем нажмите '
                      '"Я оплатил(а) и прикрепить чек" и загрузите фото/скрин чека. '
                      'После проверки Premium будет активирован автоматически.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard() {
    final end = _status?['subscription_end'] ?? '';
    final endStr = end is String && end.length >= 10 ? end.substring(0, 10) : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                  color: _isPremium ? AppTheme.accent : AppTheme.textSecondary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPremium ? 'Premium активен' : 'Бесплатный план',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isPremium && endStr.isNotEmpty)
              Text('Действует до $endStr',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              Text(
                'Откройте все видео из каталога, безлимитные последовательности и повтор практик',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_isPremium)
              const SizedBox(height: 12)
            else ...[
              const SizedBox(height: 12),
              const Text(
                '499 ₽ / месяц',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequisitesCard() {
    final price = '499 ₽';
    if (_requisites.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Реквизиты недоступны',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Реквизиты для оплаты', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Сумма: $price',
                style: const TextStyle(color: AppTheme.textSecondary)),
            if (_requisites.first['holder']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                'Получатель: ${_requisites.first['holder']}',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('Нажмите на карту, чтобы скопировать номер',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 16),
            for (final r in _requisites)
              _buildRequisiteTile(r),
          ],
        ),
      ),
    );
  }

  Widget _buildRequisiteTile(Map<String, dynamic> r) {
    final bank = r['bank']?.toString() ?? '';
    final number = r['card']?.toString() ?? r['card_number']?.toString() ?? r['number']?.toString() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.credit_card, color: AppTheme.accent),
      title: Text(bank.isEmpty ? 'Карта' : bank),
      subtitle: number.isNotEmpty
          ? Text(number, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))
          : null,
      onTap: () {
        if (number.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: number));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Номер карты скопирован')),
          );
        }
      },
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: _isUploading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          : ElevatedButton.icon(
              onPressed: _pickAndUploadReceipt,
              icon: const Icon(Icons.upload_file),
              label: const Text('Я оплатил(а), прикрепить чек'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPremium ? AppTheme.surfaceLight : AppTheme.accent,
                foregroundColor: AppTheme.background,
              ),
            ),
    );
  }

  Future<void> _pickAndUploadReceipt() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isUploading = true);
    try {
      await _api.uploadReceipt(
        File(picked.path),
        paymentMethod: _requisites.isNotEmpty
            ? (_requisites.first['bank']?.toString() ?? '')
            : '',
        amount: '499',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Чек получен! Premium будет активирован после проверки.'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } on DioException catch (e) {
      String msg = 'Не удалось отправить чек';
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        msg = e.response!.data['detail'].toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
