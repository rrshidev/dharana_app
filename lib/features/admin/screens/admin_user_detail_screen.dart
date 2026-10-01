import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/widgets/admin_charts.dart';
import 'package:dharana_app/features/admin/widgets/period_selector.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.adminUserTitle)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await _loadActivity();
              },
              color: AppTheme.AccentInk,
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
    final l10n = AppLocalizations.of(context)!;
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
            style: TextStyle(fontSize: 24, color: AppTheme.AccentInk, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['name']?.toString() ?? l10n.adminUserNoName, style: Theme.of(context).textTheme.titleLarge),
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
    final l10n = AppLocalizations.of(context)!;
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    return ChartCard(
      title: l10n.adminStatsTitle,
      child: Column(
        children: [
          _row(l10n.adminStatPracticeMinutes, '${user['total_practice_minutes'] ?? 0}'),
          _row(l10n.adminStatPracticeDays, '${user['total_practice_days'] ?? 0}'),
          _row(l10n.adminStatCurrentStreak, '${user['current_streak'] ?? 0}'),
          _row(l10n.adminStatLongestStreak, '${user['longest_streak'] ?? 0}'),
          _row(l10n.adminStatRegisteredAt, _date(user['created_at'])),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final l10n = AppLocalizations.of(context)!;
    final sub = _data?['subscription'] as Map<String, dynamic>? ?? {};
    final isPremium = (sub['is_premium'] ?? false) == true;
    return ChartCard(
      title: l10n.subscription,
      child: Column(
        children: [
          _row(l10n.adminStatusLabel,
              isPremium ? l10n.adminStatusPremium : l10n.adminStatusFree),
          if (sub['subscription_end'] != null)
            _row(l10n.adminUntilLabel, _date(sub['subscription_end'])),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _isUpdating
                ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
                : ElevatedButton.icon(
                    onPressed: _togglePremium,
                    icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: Text(isPremium
                        ? l10n.adminPremiumRemove
                        : l10n.adminPremiumGrant),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPremium ? AppTheme.SurfaceLight : AppTheme.Accent,
                      foregroundColor:
                          isPremium ? AppTheme.TextPrimary : AppTheme.AccentOn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    final l10n = AppLocalizations.of(context)!;
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final isBanned = (user['is_banned'] ?? false) == true;
    final isDeleted = (user['is_deleted'] ?? false) == true;
    return ChartCard(
      title: l10n.adminActionsTitle,
      child: _isActionBusy
          ? Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.AccentInk),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: isDeleted ? null : _sendMessage,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(l10n.adminSendMessage),
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
                        label: Text(isBanned ? l10n.adminUnban : l10n.adminBan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isBanned ? AppTheme.AccentGreen : AppTheme.Danger,
                          foregroundColor:
                              isBanned ? AppTheme.AccentGreenOn : Colors.white,
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
                        label:
                            Text(isDeleted ? l10n.adminRestore : l10n.adminDelete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.Danger,
                          foregroundColor: Colors.white,
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
    final l10n = AppLocalizations.of(context)!;
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
          title: Text(l10n.adminChannelTitle),
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
                title: Text(l10n.adminChannelBoth),
                onTap: hasTelegram ? () => setLocal(() => channel = 'both') : null,
              ),
              ListTile(
                leading: Icon(
                  channel == 'app'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                ),
                title: Text(l10n.adminChannelAppOnly),
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
                title: Text(l10n.adminChannelTelegramOnly),
                onTap: hasTelegram ? () => setLocal(() => channel = 'telegram') : null,
              ),
              if (!hasTelegram)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.adminNoTelegramId,
                    style: TextStyle(color: AppTheme.TextSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, channel),
              child: Text(l10n.adminNext),
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
          title: Text(l10n.adminMessageTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 4,
                maxLength: 2000,
                decoration:
                    InputDecoration(hintText: l10n.adminMessageHint),
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
                      pickedImage == null
                          ? l10n.adminAttachImage
                          : l10n.adminAttachReplace,
                    ),
                  ),
                  if (pickedImage != null)
                    TextButton(
                      onPressed: () => setLocal(() => pickedImage = null),
                      child: Text(l10n.adminRemoveImage),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(
                ctx,
                _MessageInputResult(text: textController.text, image: pickedImage),
              ),
              child: Text(l10n.adminSend),
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
        if (channelResult == 'both' || channelResult == 'app')
          _reportApp(l10n, data['app']),
        if (channelResult == 'both' || channelResult == 'telegram')
          _reportTg(l10n, data['telegram']),
      ];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.where((p) => p.isNotEmpty).join(' · ')),
            backgroundColor: AppTheme.AccentGreenOn,
          ),
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
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  String _reportApp(AppLocalizations l10n, dynamic status) {
    if (status == 'queued') return l10n.adminReportAppQueued;
    if (status == 'failed') return l10n.adminReportAppFailed;
    return l10n.adminReportAppStatus('$status');
  }

  String _reportTg(AppLocalizations l10n, dynamic status) {
    if (status == 'sent') return l10n.adminReportTgSent;
    if (status == 'no_telegram') return l10n.adminReportTgNoId;
    if (status == 'failed') return l10n.adminReportTgFailed;
    if (status == 'no_bot') return l10n.adminReportTgNoBot;
    return l10n.adminReportTgStatus('$status');
  }

  Future<void> _toggleBan(bool current) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final userId = user['id'] ?? widget.userId;
    final ban = !current;
    final ok = await _confirm(
      ban ? l10n.adminConfirmBan : l10n.adminConfirmUnban,
      ban ? l10n.adminBanLosesAccess : null,
    );
    if (!ok) return;

    setState(() => _isActionBusy = true);
    try {
      await _api.setUserBan(userId, ban);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ban ? l10n.adminUserBanned : l10n.adminUserUnbanned),
            backgroundColor: AppTheme.AccentGreenOn,
          ),
        );
      }
      await _load();
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
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<void> _toggleDelete(bool current) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _data?['user'] as Map<String, dynamic>? ?? {};
    final userId = user['id'] ?? widget.userId;
    final del = !current;
    final ok = await _confirm(
      del ? l10n.adminConfirmDelete : l10n.adminConfirmRestore,
      del ? l10n.adminDeleteReversible : null,
    );
    if (!ok) return;

    setState(() => _isActionBusy = true);
    try {
      await _api.setUserDeleted(userId, del);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                del ? l10n.adminUserDeleted : l10n.adminUserRestored),
            backgroundColor: AppTheme.AccentGreenOn,
          ),
        );
      }
      await _load();
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
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Future<bool> _confirm(String title, String? message) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.Surface,
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.adminConfirm)),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildActivityChart() {
    final l10n = AppLocalizations.of(context)!;
    final days = _activity?['days'];
    final minutesSer = _activity?['minutes'];
    final labels = days is List ? days.cast<String>() : <String>[];
    final minutes = minutesSer is List ? minutesSer.map((e) => (e as num).toDouble()).toList() : <double>[];
    return ChartCard(
      title: l10n.adminMinutesChartTitle,
      subtitle: PeriodSelector(days: _rangeDays, onChanged: (d) {
        setState(() => _rangeDays = d);
        _loadActivity();
      }),
      child: _activityLoading
          ? SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppTheme.AccentInk)))
          : AreaTrendChart(data: minutes, labels: labels, color: AppTheme.AccentGreenInk, showBottomLabels: true),
    );
  }

  Widget _buildRecentSessions() {
    final l10n = AppLocalizations.of(context)!;
    final sessions = _data?['recent_sessions'] as List? ?? [];
    return ChartCard(
      title: l10n.adminRecentSessions,
      child: sessions.isEmpty
          ? Text(l10n.adminNoCompletedSessions,
              style: TextStyle(color: AppTheme.TextSecondary))
          : Column(
              children: sessions.take(10).map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            l10n.adminSessionAsanas(
                                (s['asanas_practiced'] as num?)?.toInt() ?? 0),
                            style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      Text(
                        l10n.adminSessionMeta(
                          ((s['total_duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60,
                          _date(s['started_at']),
                        ),
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
    final l10n = AppLocalizations.of(context)!;
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
          title: Text(l10n.adminPremiumGrant),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.adminDaysLabel),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text) ?? 30),
              child: Text(l10n.adminGrant),
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
            content: Text(isPremium
                ? l10n.adminPremiumRemoved
                : l10n.adminPremiumGranted),
            backgroundColor: AppTheme.AccentGreenOn,
          ),
        );
      }
      await _load();
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
