import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/core/models/models.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:dharana_app/features/profile/screens/practice_history_screen.dart';
import 'package:dharana_app/features/subscription/screens/subscription_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_dashboard_screen.dart';
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
      await showDialog<void>(
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showEditProfileSheet(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 16),
                  _buildUserInfo(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
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
            backgroundColor: AppTheme.surfaceLight,
            backgroundImage: _user?.avatarUrl != null
                ? NetworkImage(ApiClient().resolveUrl(_user!.avatarUrl!))
                : null,
            child: _user?.avatarUrl == null
                ? Text(
                    (_user?.name ?? 'Й')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      color: AppTheme.accent,
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
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.background),
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
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  '${_avatars.length}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          _user?.name ?? 'Пользователь',
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
          'Участник с ${_user?.createdAt?.substring(0, 10) ?? 'недавно'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer_outlined,
                  value: '${_stats?.totalMinutes ?? 0}',
                  label: 'минут',
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  value: '${_stats?.totalDays ?? 0}',
                  label: 'дней',
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department_outlined,
                  value: '${_stats?.currentStreak ?? 0}',
                  label: 'серия',
                ),
                _buildStatItem(
                  icon: Icons.self_improvement,
                  value: '${_stats?.totalSessions ?? 0}',
                  label: 'сессий',
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
        Icon(icon, color: AppTheme.accent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        if (_user?.telegramId == null)
          _buildMenuItem(
            context,
            icon: Icons.telegram,
            title: 'Привязать Telegram',
            subtitle: 'Вход по коду из бота',
            onTap: _linkTelegram,
          ),
        if (_user?.isAdmin == true)
          _buildMenuItem(
            context,
            icon: Icons.admin_panel_settings_outlined,
            title: 'Админ-панель',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
            },
          ),
        _buildMenuItem(
          context,
          icon: Icons.history,
          title: 'История практик',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PracticeHistoryScreen()),
            );
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.star_outline,
          title: 'Подписка',
          subtitle: _isPremium ? 'Premium' : 'Бесплатный план',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          icon: const Icon(Icons.logout, color: AppTheme.danger),
          label: const Text(
            'Выйти',
            style: TextStyle(color: AppTheme.danger),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.danger),
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
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _linkTelegram() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Привязать Telegram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '1. Нажмите "Открыть бот"\n2. Бот пришлёт вам код\n3. Введите его ниже:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Код из Telegram',
                prefixIcon: Icon(Icons.pin),
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
                    const SnackBar(content: Text('Telegram не установлен')),
                  );
                }
              }
            },
            child: const Text('Открыть бот'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(ctx, controller.text);
            },
            child: const Text('Привязать'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await AuthService().verifyTelegramCode(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram привязан!')),
        );
        _loadProfile();
      }
    } catch (e) {
      String msg = 'Неверный или просроченный код';
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

  void _showEditProfileSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
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
      backgroundColor: AppTheme.surface,
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
    return Padding(
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
          Text('Редактировать профиль', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Имя'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'О себе'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    try {
                      await ApiClient().updateProfile(
                        name: _nameController.text,
                        username: _usernameController.text,
                        bio: _bioController.text,
                      );
                      if (mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Сохранить'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар установлен'), backgroundColor: AppTheme.accentGreen),
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

  Future<void> _pickFromCamera() async {
    setState(() => _isUploading = true);
    try {
      final url = await ApiClient().uploadAvatarFromCamera();
      if (url != null && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар установлен'), backgroundColor: AppTheme.accentGreen),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Аватар', style: Theme.of(context).textTheme.titleLarge),
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
                            color: avatar.isPrimary ? AppTheme.accent : AppTheme.cardBorder,
                            width: avatar.isPrimary ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(ApiClient().resolveUrl(avatar.url)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 14,
                        child: GestureDetector(
                          onTap: () async {
                            await ApiClient().deleteAvatar(avatar.id);
                            if (mounted) Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.danger,
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
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Галерея'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: AppTheme.cardBorder),
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
                        label: const Text('Камера'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: AppTheme.cardBorder),
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
