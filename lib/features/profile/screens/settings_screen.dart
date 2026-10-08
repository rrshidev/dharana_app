import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/app/theme_controller.dart';
import 'package:dharana_app/app/language_controller.dart';
import 'package:dharana_app/l10n/app_localizations.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/profile/screens/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiClient();
  User? _user;
  bool _isLoading = true;

  static final _timezones = <String>[
    for (var i = -12; i <= 14; i++)
      if (i == 0)
        'UTC'
      else
        'UTC${i > 0 ? '+' : ''}$i',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getProfile();
      if (mounted) {
        setState(() {
          _user = User.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _patch(Map<String, dynamic> data) async {
    await _api.dio.patch('/profile', data: data);
    final updated = await _api.getProfile();
    if (mounted) setState(() => _user = User.fromJson(updated));
  }

  Future<void> _runSave(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.dailyAsanaSaved),
          backgroundColor: AppTheme.AccentGreenOn,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.dailyAsanaSaveFailed),
          backgroundColor: AppTheme.Danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.AccentInk))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle(l10n.profile),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, color: AppTheme.AccentInk),
                    title: Text(l10n.editProfile),
                    trailing: Icon(Icons.chevron_right,
                        color: AppTheme.TextSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: _showEditProfileSheet,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(l10n.themeTitle),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading:
                        Icon(Icons.palette_outlined, color: AppTheme.AccentInk),
                    title: Text(l10n.theme),
                    subtitle: Text(_themeLabel(l10n)),
                    trailing: Icon(Icons.chevron_right,
                        color: AppTheme.TextSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: _showThemePicker,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(l10n.language),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.language_outlined,
                        color: AppTheme.AccentInk),
                    title: Text(l10n.language),
                    subtitle: Text(
                        LanguageController.instance.value.languageCode == 'en'
                            ? l10n.english
                            : l10n.russian),
                    trailing: Icon(Icons.chevron_right,
                        color: AppTheme.TextSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: _showLanguagePicker,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(l10n.dailyAsana),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    l10n.dailyAsanaHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(Icons.mark_email_read_outlined,
                            color: AppTheme.AccentInk),
                        title: Text(l10n.dailyAsanaEnable),
                        value: _user?.dailyAsanaEnabled ?? false,
                        activeThumbColor: AppTheme.AccentInk,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onChanged: (v) => _runSave(
                            () => _patch({'daily_asana_enabled': v})),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.access_time,
                            color: AppTheme.AccentInk),
                        title: Text(l10n.dailyAsanaTime),
                        trailing: Text(
                          _user?.dailyAsanaTime ?? '09:00',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.AccentInk,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: _showTimePicker,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.public,
                            color: AppTheme.AccentInk),
                        title: Text(l10n.dailyAsanaTimezone),
                        trailing: Text(
                          _user?.timezone ?? 'UTC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.AccentInk,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: _showTimezonePicker,
                      ),
                    ],
                  ),
                ),
                if (_user?.telegramId == null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n.dailyAsanaNotLinked,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.TextSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
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
            _optionRow(ctx, l10n.themeModeSystem, current == ThemeMode.system,
                () => Navigator.of(ctx).pop(ThemeMode.system)),
            _optionRow(ctx, l10n.themeModeLight, current == ThemeMode.light,
                () => Navigator.of(ctx).pop(ThemeMode.light)),
            _optionRow(ctx, l10n.themeModeDark, current == ThemeMode.dark,
                () => Navigator.of(ctx).pop(ThemeMode.dark)),
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
            _optionRow(ctx, l10n.russian, current == const Locale('ru'),
                () => Navigator.of(ctx).pop(const Locale('ru'))),
            _optionRow(ctx, l10n.english, current == const Locale('en'),
                () => Navigator.of(ctx).pop(const Locale('en'))),
          ],
        );
      },
    );
    if (selected != null) {
      await LanguageController.instance.setLanguage(selected);
      if (mounted) setState(() {});
      _runSave(() => _patch({'language': selected.languageCode}));
    }
  }

  Future<void> _showTimePicker() async {
    final raw = _user?.dailyAsanaTime ?? '09:00';
    final parts = raw.split(':');
    final current = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _runSave(() => _patch({'daily_asana_time': value}));
  }

  Future<void> _showTimezonePicker() async {
    final current = _user?.timezone ?? 'UTC';
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(ctx)!.dailyAsanaTimezone),
          children: [
            SizedBox(
              height: 360,
              width: 260,
              child: ListView.builder(
                itemCount: _timezones.length,
                itemBuilder: (context, index) {
                  final tz = _timezones[index];
                  return SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(tz),
                    child: Row(
                      children: [
                        if (current == tz)
                          Icon(Icons.check, color: AppTheme.AccentInk)
                        else
                          const SizedBox(width: 24),
                        const SizedBox(width: 12),
                        Text(tz),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    if (selected != null && selected != current) {
      _runSave(() => _patch({'timezone': selected}));
    }
  }

  void _showEditProfileSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.Surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditProfileSheet(user: _user),
    );
    _loadProfile();
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
}
