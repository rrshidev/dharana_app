import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/app/theme_controller.dart';
import 'package:dharana_app/app/language_controller.dart';
import 'package:dharana_app/l10n/app_localizations.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:dharana_app/features/admin/widgets/period_selector.dart';
import 'package:dharana_app/features/profile/widgets/activity_chart.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/shared/widgets/notification_bell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiClient();
  User? _user;
  PracticeStats? _stats;
  List<UserAvatar> _avatars = [];
  bool _isLoading = true;
  bool _isPremium = false;
  List<ActivityDaily> _chartDays = [];
  bool _chartLoading = true;
  int _chartRange = 30;
  String _chartType = 'all';
  static const _chartTypes = <String>['all', 'asana', 'meditation', 'pranayama'];

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'all':
        return l10n.all;
      case 'asana':
        return l10n.asana;
      case 'meditation':
        return l10n.meditation;
      case 'pranayama':
        return l10n.pranayama;
    }
    return type;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _api.getProfile();
      if (mounted) {
        setState(() {
          _user = User.fromJson(userData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final statsData = await _api.getPracticeStats();
      if (mounted) setState(() => _stats = PracticeStats.fromJson(statsData));
    } catch (_) {}

    try {
      final avatarsData = await _api.getAvatars();
      if (mounted) {
        setState(() => _avatars = avatarsData.map((a) => UserAvatar.fromJson(a)).toList());
      }
    } catch (_) {}

    try {
      final sub = await _api.getSubscriptionStatus();
      if (mounted) setState(() => _isPremium = (sub['is_premium'] ?? false) == true);
    } catch (_) {}

    _loadActivityChart();
    _checkNotifications();
  }

  Future<void> _loadActivityChart() async {
    setState(() => _chartLoading = true);
    try {
      final tzOffset = DateTime.now().timeZoneOffset.inMinutes;
      final data = await _api.getPracticeSeries(
        days: _chartRange,
        practiceType: _chartType,
        tzOffsetMinutes: tzOffset,
      );
      final agg = _seriesToDays(data, _chartRange);
      if (mounted) setState(() { _chartDays = List.of(agg); _chartLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _chartDays = []; _chartLoading = false; });
    }
  }

  List<ActivityDaily> _seriesToDays(Map<String, dynamic> data, int rangeDays) {
    final daysRaw = data['days'] as List? ?? <dynamic>[];
    final minutes = data['minutes'] as List? ?? <dynamic>[];
    final sessions = data['sessions'] as List? ?? <dynamic>[];
    final asanas = data['asanas'] as List? ?? <dynamic>[];
    final out = <ActivityDaily>[];
    for (var i = 0; i < daysRaw.length; i++) {
      final dayText = daysRaw[i].toString();
      final date = DateTime.tryParse(dayText);
      if (date == null) continue;
      out.add(ActivityDaily(
        date: date,
        minutes: (minutes.length > i ? minutes[i] : 0).toDouble(),
        sessions: (sessions.length > i ? sessions[i] : 0).toDouble(),
        asanas: (asanas.length > i ? asanas[i] : 0).toDouble(),
      ));
    }
    if (out.length >= rangeDays) return out;
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day).subtract(Duration(days: rangeDays - 1));
    final byDate = {for (final d in out) DateTime(d.date.year, d.date.month, d.date.day): d};
    final filled = <ActivityDaily>[];
    for (var i = 0; i < rangeDays; i++) {
      final day = startDay.add(Duration(days: i));
      filled.add(byDate[day] ?? ActivityDaily(date: day, minutes: 0, sessions: 0, asanas: 0));
    }
    return filled;
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
      await showDialog<void>(
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showEditProfileSheet(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.AccentInk,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 16),
                  _buildUserInfo(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: AppTheme.SurfaceLight,
            backgroundImage: _user?.avatarUrl != null
                ? CachedNetworkImageProvider(
                    ApiClient().resolveUrl(_user!.avatarUrl!))
                : null,
            child: _user?.avatarUrl == null
                ? Text(
                    ((_user?.name ?? '').isNotEmpty ? _user!.name : '?')
                        .toString()[0]
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: AppTheme.AccentInk,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showAvatarPicker(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.AccentInk,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, size: 16, color: AppTheme.Background),
              ),
            ),
          ),
          if (_avatars.length > 1)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.Surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.CardBorder),
                ),
                child: Text(
                  '${_avatars.length}',
                  style: TextStyle(fontSize: 10, color: AppTheme.TextSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          _user?.name ?? l10n.userFallback,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (_user?.username != null) ...[
          const SizedBox(height: 4),
          Text(
            '@${_user!.username}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _user!.bio!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.memberSince(
              _user?.createdAt?.substring(0, 10) ?? l10n.recently),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statistics,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer_outlined,
                  value: '${_stats?.totalMinutes ?? 0}',
                  label: l10n.minutes,
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  value: '${_stats?.totalDays ?? 0}',
                  label: l10n.days,
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department_outlined,
                  value: '${_stats?.currentStreak ?? 0}',
                  label: l10n.streak,
                ),
                _buildStatItem(
                  icon: Icons.self_improvement,
                  value: '${_stats?.totalSessions ?? 0}',
                  label: l10n.sessions,
                ),
              ],
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
        Icon(icon, color: AppTheme.AccentInk, size: 24),
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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.TextSecondary),
        ),
      ],
    );
  }

  String? get _chartThirdLabel {
    final l10n = AppLocalizations.of(context);
    switch (_chartType) {
      case 'all':
        return l10n?.exercises;
      case 'asana':
        return l10n?.asanas;
      case 'pranayama':
        return l10n?.pranayama;
      case 'meditation':
        return null;
    }
    return null;
  }

  String? get _chartThirdUnit {
    final l10n = AppLocalizations.of(context);
    if (_chartThirdLabel == null) return null;
    return _chartType == 'asana' ? l10n?.unitAsanas : l10n?.unitExercises;
  }

  Widget _buildChartSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.activity,
                    style: Theme.of(context).textTheme.titleLarge),
                PeriodSelector(days: _chartRange, onChanged: (d) {
                  setState(() => _chartRange = d);
                  _loadActivityChart();
                }),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _chartTypes)
                  ChoiceChip(
                    label: Text(_typeLabel(l10n, t)),
                    selected: _chartType == t,
                    selectedColor: AppTheme.AccentInk,
                    labelStyle: TextStyle(
                      color: _chartType == t ? Colors.white : AppTheme.TextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppTheme.SurfaceLight,
                    side: BorderSide(color: AppTheme.CardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) {
                      if (_chartType == t) return;
                      setState(() => _chartType = t);
                      _loadActivityChart();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _chartLoading
                ? SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: AppTheme.AccentInk)),
                  )
                : ActivityChart(
                    days: _chartDays,
                    thirdLabel: _chartThirdLabel,
                    thirdUnit: _chartThirdUnit,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_user?.telegramId == null)
          _buildMenuItem(
            context,
            icon: Icons.telegram,
            title: l10n.linkTelegram,
            subtitle: l10n.tgLoginDesc,
            onTap: _linkTelegram,
          ),
        if (_user?.isAdmin == true)
          _buildMenuItem(
            context,
            icon: Icons.admin_panel_settings_outlined,
            title: l10n.adminPanel,
            onTap: () {
              context.push('/admin');
            },
          ),
        _buildMenuItem(
          context,
          icon: Icons.history,
          title: l10n.practiceHistory,
          onTap: () {
            context.push('/practice_history');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.star_outline,
          title: l10n.subscription,
          subtitle: _isPremium ? 'Premium' : l10n.freePlan,
          onTap: () {
            context.push('/subscription');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.language_outlined,
          title: l10n.language,
          subtitle: LanguageController.instance.value.languageCode == 'en'
              ? l10n.english
              : l10n.russian,
          onTap: _showLanguagePicker,
        ),
        _buildMenuItem(
          context,
          icon: Icons.palette_outlined,
          title: l10n.theme,
          subtitle: _themeLabel(l10n),
          onTap: _showThemePicker,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService().logout();
            if (mounted) {
              context.go('/login');
            }
          },
          icon: Icon(Icons.logout, color: AppTheme.Danger),
          label: Text(
            l10n.logout,
            style: TextStyle(color: AppTheme.Danger),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.Danger),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.AccentInk),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: Icon(Icons.chevron_right, color: AppTheme.TextSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _linkTelegram() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        backgroundColor: AppTheme.Surface,
        title: Text(l10n.linkTelegram),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.tgGuide,
              style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.telegramCodeHint,
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://t.me/yogaasana_bot?start=auth');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.telegramNotInstalled)),
                  );
                }
              }
            },
            child: Text(l10n.openBot),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(ctx, controller.text);
            },
            child: Text(l10n.link),
          ),
        ],
        );
      },
    );

    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    try {
      await AuthService().verifyTelegramCode(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.telegramLinked)),
        );
        _loadProfile();
      }
    } catch (e) {
      String msg = l10n.invalidTgCode;
      if (e is DioException) {
        final detail = e.response?.data;
        if (detail is Map && detail['detail'] != null) {
          msg = detail['detail'].toString();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  String _themeLabel(AppLocalizations l10n) {
    switch (ThemeController.instance.value) {
      case ThemeMode.light:
        return l10n.themeModeLight;
      case ThemeMode.dark:
        return l10n.themeModeDark;
      default:
        return l10n.themeModeSystem;
    }
  }

  Future<void> _showThemePicker() async {
    final current = ThemeController.instance.value;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SimpleDialog(
          title: Text(l10n.themeTitle),
          children: [
            _themeOption(ctx, ThemeMode.system, l10n.themeModeSystem, current),
            _themeOption(ctx, ThemeMode.light, l10n.themeModeLight, current),
            _themeOption(ctx, ThemeMode.dark, l10n.themeModeDark, current),
          ],
        );
      },
    );
    if (selected != null) {
      await ThemeController.instance.setTheme(selected);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showLanguagePicker() async {
    final current = LanguageController.instance.value;
    final selected = await showDialog<Locale>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SimpleDialog(
          title: Text(l10n.language),
          children: [
            _languageOption(ctx, const Locale('ru'), l10n.russian, current),
            _languageOption(ctx, const Locale('en'), l10n.english, current),
          ],
        );
      },
    );
    if (selected != null) {
      await LanguageController.instance.setLanguage(selected);
      if (mounted) setState(() {});
    }
  }

  Widget _themeOption(BuildContext ctx, ThemeMode mode, String label,
      ThemeMode current) {
    return _optionRow(ctx, label, current == mode, () => Navigator.of(ctx).pop(mode));
  }

  Widget _languageOption(
      BuildContext ctx, Locale locale, String label, Locale current) {
    return _optionRow(ctx, label, current == locale,
        () => Navigator.of(ctx).pop(locale));
  }

  Widget _optionRow(
      BuildContext ctx, String label, bool selected, VoidCallback onTap) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          if (selected)
            Icon(Icons.check, color: AppTheme.AccentInk)
          else
            const SizedBox(width: 24),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _showEditProfileSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.Surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileSheet(user: _user),
    );
    _loadProfile();
  }

  void _showAvatarPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.Surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AvatarPickerSheet(avatars: _avatars),
    );
    _loadProfile();
  }
}

class _EditProfileSheet extends StatefulWidget {
  final User? user;
  const _EditProfileSheet({this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _bioController = TextEditingController(text: widget.user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editProfile,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.name),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            decoration: InputDecoration(labelText: l10n.about),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ApiClient().updateProfile(
                        name: _nameController.text,
                        username: _usernameController.text,
                        bio: _bioController.text,
                      );
                      if (!mounted) return;
                      navigator.pop();
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.errorMessage('$e'))),
                      );
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

class _AvatarPickerSheet extends StatefulWidget {
  final List<UserAvatar> avatars;
  const _AvatarPickerSheet({required this.avatars});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  bool _isUploading = false;

  Future<void> _pickFromGallery() async {
    setState(() => _isUploading = true);
    try {
      final url = await ApiClient().uploadAvatarFromGallery();
      if (url != null && mounted) {
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.avatarSet),
              backgroundColor: AppTheme.AccentGreenOn),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.errorMessage('$e')),
              backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isUploading = true);
    try {
      final url = await ApiClient().uploadAvatarFromCamera();
      if (url != null && mounted) {
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.avatarSet),
              backgroundColor: AppTheme.AccentGreenOn),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.errorMessage('$e')),
              backgroundColor: AppTheme.Danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.avatar, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (widget.avatars.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.avatars.length,
                itemBuilder: (context, index) {
                  final avatar = widget.avatars[index];
                  return Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: avatar.isPrimary ? AppTheme.AccentInk : AppTheme.CardBorder,
                            width: avatar.isPrimary ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                ApiClient().resolveUrl(avatar.url)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 14,
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            await ApiClient().deleteAvatar(avatar.id);
                            if (!mounted) return;
                            navigator.pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.Danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _isUploading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
                    : OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l10n.gallery),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: AppTheme.CardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isUploading
                    ? const SizedBox()
                    : OutlinedButton.icon(
                        onPressed: _pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l10n.camera),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: AppTheme.CardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
