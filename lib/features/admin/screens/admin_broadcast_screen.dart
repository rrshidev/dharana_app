import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSeries() async {
    try {
      final data = await _api.getAdminBroadcastSeries(days: 30);
      if (mounted) setState(() { _series = data; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminBroadcastTitle),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSeries)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatStrip(),
          const SizedBox(height: 12),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildStatStrip() {
    final l10n = AppLocalizations.of(context)!;
    final total = _series?['total_recipients'] ?? 0;
    final campaigns = _series?['campaigns'] is List
        ? (_series?['campaigns'] as List).fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0))
        : 0;
    final recipients = _series?['recipients'] is List
        ? (_series?['recipients'] as List).fold<int>(0, (a, b) => a + ((b as num?)?.toInt() ?? 0))
        : 0;
    return Row(
      children: [
        _miniStat('$campaigns', l10n.adminBroadcastCampaigns, AppTheme.AccentInk, menu: true),
        const SizedBox(width: 8),
        _miniStat('$recipients', l10n.adminBroadcastRecipients, AppTheme.AccentGreenInk, menu: false),
        const SizedBox(width: 8),
        _miniStat('$total', l10n.adminBroadcastTotalDeliveries, AppTheme.AccentInk, menu: false),
      ],
    );
  }

  Widget _miniStat(String value, String label, Color color, {required bool menu}) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        color: AppTheme.Surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.CardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: AppTheme.TextSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return ChartCard(
      title: l10n.adminBroadcastNew,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.adminBroadcastMessageHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(l10n.adminBroadcastAudience, style: const TextStyle(fontWeight: FontWeight.w600)),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminBroadcastFree),
            value: _bcAudFree,
            activeColor: AppTheme.AccentInk,
            checkColor: Colors.white,
            onChanged: (v) => setState(() => _bcAudFree = v ?? true),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminBroadcastPremium),
            value: _bcAudPremium,
            activeColor: AppTheme.AccentInk,
            checkColor: Colors.white,
            onChanged: (v) => setState(() => _bcAudPremium = v ?? true),
          ),
          if (!_bcAudFree && !_bcAudPremium)
            Text(l10n.adminBroadcastPickAudience,
                style: TextStyle(color: AppTheme.Danger, fontSize: 12)),
          const SizedBox(height: 8),
          Text(l10n.adminBroadcastChannels, style: const TextStyle(fontWeight: FontWeight.w600)),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Telegram'),
            value: _bcChanTg,
            activeColor: AppTheme.AccentInk,
            checkColor: Colors.white,
            onChanged: (v) => setState(() => _bcChanTg = v ?? true),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminBroadcastInApp),
            value: _bcChanApp,
            activeColor: AppTheme.AccentInk,
            checkColor: Colors.white,
            onChanged: (v) => setState(() => _bcChanApp = v ?? true),
          ),
          if (!_bcChanTg && !_bcChanApp)
            Text(l10n.adminBroadcastPickChannel,
                style: TextStyle(color: AppTheme.Danger, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : _sendTest,
              icon: const Icon(Icons.science_outlined),
              label: Text(l10n.adminBroadcastTest),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _sending
                ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
                : ElevatedButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(l10n.adminBroadcastSend),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.Accent,
                      foregroundColor: AppTheme.AccentOn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _audLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_bcAudFree && _bcAudPremium) return l10n.adminBroadcastAll;
    if (_bcAudFree) return l10n.adminBroadcastFree;
    if (_bcAudPremium) return l10n.adminBroadcastPremium;
    return '—';
  }

  String _chanLabel() {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[];
    if (_bcChanTg) parts.add('Telegram');
    if (_bcChanApp) parts.add(l10n.adminBroadcastInApp);
    return parts.isEmpty ? '—' : parts.join(' + ');
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context)!;
    if (_messageController.text.trim().isEmpty) {
      _snack(l10n.adminBroadcastEnterMessage, AppTheme.Danger);
      return false;
    }
    if (!_bcAudFree && !_bcAudPremium) {
      _snack(l10n.adminBroadcastPickAudienceShort, AppTheme.Danger);
      return false;
    }
    if (!_bcChanTg && !_bcChanApp) {
      _snack(l10n.adminBroadcastPickChannelShort, AppTheme.Danger);
      return false;
    }
    return true;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.Surface,
        title: Text(l10n.adminBroadcastConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_messageController.text, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Text(l10n.adminBroadcastAudienceRow(_audLabel())),
            Text(l10n.adminBroadcastChannelsRow(_chanLabel())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.adminSend)),
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
          l10n.adminBroadcastCreated(
              '${data['count_telegram'] ?? 0}', '${data['count_app'] ?? 0}'),
          AppTheme.AccentGreenOn,
        );
        _messageController.clear();
        _loadSeries();
      }
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context)!.errorMessage('$e'), AppTheme.Danger);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendTest() async {
    final l10n = AppLocalizations.of(context)!;
    if (_messageController.text.trim().isEmpty) {
      _snack(l10n.adminBroadcastEnterMessage, AppTheme.Danger);
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
        _snack(
          l10n.adminBroadcastTestResult(
              '${data['telegram'] ?? '?'}', '${data['app'] ?? '?'}'),
          AppTheme.AccentOn,
        );
      }
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context)!.errorMessage('$e'), AppTheme.Danger);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
