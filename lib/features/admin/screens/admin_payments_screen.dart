import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _isBusy = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAdminPayments();
      final list = data['payments'];
      if (mounted) {
        setState(() {
          _payments = (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _payments;
    return _payments.where((p) => p['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на Premium'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      _filterChip('all', 'Все'),
                      _filterChip('pending', 'Ожидают'),
                      _filterChip('confirmed', 'Одобрены'),
                      _filterChip('rejected', 'Отклонены'),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Заявок нет'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _buildCard(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.accent,
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? AppTheme.background : AppTheme.textSecondary,
        ),
      ),
    );
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'confirmed':
        return 'Одобрено';
      case 'rejected':
        return 'Отклонено';
      default:
        return 'Ожидает';
    }
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'pending';
    final pending = status == 'pending';
    final receipt = p['receipt_url']?.toString() ?? '';
    final userName = p['user_name']?.toString() ?? '?';
    final bank = p['payment_method']?.toString() ?? '';
    final amount = p['amount'];
    final encoded = Uri.encodeFull(_api.resolveUrl(receipt));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pending ? Icons.hourglass_top : Icons.credit_card,
                  color: pending ? AppTheme.accent : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
                Chip(
                  label: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      color: pending
                          ? AppTheme.textSecondary
                          : status == 'confirmed'
                              ? AppTheme.accentGreen
                              : AppTheme.danger,
                    ),
                  ),
                  backgroundColor: AppTheme.surfaceLight,
                ),
              ],
            ),
            if (bank.isNotEmpty || amount != null) ...[
              const SizedBox(height: 6),
              Text(
                [if (bank.isNotEmpty) bank, if (amount != null) '$amount ₽']
                    .where((s) => s.isNotEmpty)
                    .join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (receipt.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showReceipt(receipt),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(encoded),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.zoom_in,
                          color: AppTheme.textPrimary, size: 18),
                    ),
                  ),
                ),
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _review(p, 'confirmed'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Подтвердить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentGreen,
                        side: const BorderSide(color: AppTheme.accentGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _review(p, 'rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Отклонить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReceipt(String url) {
    final encoded = Uri.encodeFull(_api.resolveUrl(url));
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: Image.network(encoded),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _review(Map<String, dynamic> p, String status) async {
    int days = 30;
    if (status == 'confirmed') {
      final controller = TextEditingController(text: (p['premium_days']?.toString() ?? '30'));
      final result = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Подтвердить оплату'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Кол-во дней Premium'),
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
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      );
      if (result == null) return;
      days = result;
    }

    setState(() => _isBusy = true);
    try {
      final res = await _api.reviewPayment(p['id'] as int, status, days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? 'Оплата подтверждена${res['premium_granted'] == true ? ', Premium выдан' : ''}'
                  : 'Оплата отклонена',
            ),
            backgroundColor: status == 'confirmed' ? AppTheme.accentGreen : AppTheme.danger,
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
      if (mounted) setState(() => _isBusy = false);
    }
  }
}
