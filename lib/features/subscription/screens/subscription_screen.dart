import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/shared/widgets/notification_bell.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context)!;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isConfirmed
              ? l10n.paymentConfirmedTitle
              : l10n.paymentRejectedTitle),
          content: Text(
            isConfirmed
                ? l10n.paymentConfirmedMsg(
                    end.isEmpty ? '!' : l10n.paymentConfirmedUntil(end))
                : l10n.paymentRejectedMsg,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(e))),
        );
      }
    }
  }

  bool get _isPremium => (_status?['is_premium'] ?? false) == true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription),
        actions: const [NotificationBell()],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.Accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.Accent,
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
                      color: AppTheme.SurfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.subHowToPay,
                      style: TextStyle(fontSize: 13, color: AppTheme.TextSecondary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard() {
    final l10n = AppLocalizations.of(context)!;
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
                  color: _isPremium ? AppTheme.Accent : AppTheme.TextSecondary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPremium ? l10n.subPremiumActive : l10n.freePlan,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isPremium && endStr.isNotEmpty)
              Text(l10n.subActiveUntil(endStr),
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              Text(
                l10n.subPlanDesc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_isPremium)
              const SizedBox(height: 12)
            else ...[
              const SizedBox(height: 12),
              Text(
                l10n.subPricePerMonth,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.Accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequisitesCard() {
    final l10n = AppLocalizations.of(context)!;
    final price = '499 ₽';
    if (_requisites.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(l10n.subRequisitesUnavailable,
              style: TextStyle(color: AppTheme.TextSecondary)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.subRequisitesTitle, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.TextPrimary)),
            const SizedBox(height: 4),
            Text(l10n.subAmount(price),
                style: TextStyle(color: AppTheme.TextSecondary)),
            if (_requisites.first['holder']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                l10n.subRecipient(_requisites.first['holder'].toString()),
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.TextPrimary),
              ),
              const SizedBox(height: 4),
              Text(l10n.subTapToCopy,
                  style: TextStyle(fontSize: 12, color: AppTheme.TextSecondary)),
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
    final l10n = AppLocalizations.of(context)!;
    final bank = r['bank']?.toString() ?? '';
    final number = r['card']?.toString() ?? r['card_number']?.toString() ?? r['number']?.toString() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.credit_card, color: AppTheme.Accent),
      title: Text(bank.isEmpty ? l10n.subCard : bank),
      subtitle: number.isNotEmpty
          ? Text(number, style: TextStyle(fontSize: 13, color: AppTheme.TextSecondary))
          : null,
      onTap: () {
        if (number.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: number));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subCardCopied)),
          );
        }
      },
    );
  }

  Widget _buildPaymentButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: _isUploading
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppTheme.Accent)),
            )
          : ElevatedButton.icon(
              onPressed: _pickAndUploadReceipt,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.subUploadReceipt),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPremium ? AppTheme.SurfaceLight : AppTheme.Accent,
                foregroundColor: AppTheme.Background,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.receiptSentMsg),
            backgroundColor: AppTheme.AccentGreen,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String msg = l10n.subReceiptFailed;
        if (e.response?.data is Map && e.response!.data['detail'] != null) {
          msg = e.response!.data['detail'].toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.Danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorMessage('$e')),
              backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
