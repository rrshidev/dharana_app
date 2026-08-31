import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
import 'package:dharana_app/features/admin/screens/admin_user_detail_screen.dart';

class AdminUser {
  final int id;
  final String? name;
  final String? email;
  final String? username;
  final int? telegramId;
  final bool isPremium;
  final int totalPracticeMinutes;
  final int totalPracticeDays;

  AdminUser({
    required this.id,
    this.name,
    this.email,
    this.username,
    this.telegramId,
    this.isPremium = false,
    this.totalPracticeMinutes = 0,
    this.totalPracticeDays = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      username: json['username'],
      telegramId: json['telegram_id'],
      isPremium: json['is_premium'] ?? false,
      totalPracticeMinutes: json['total_practice_minutes'] ?? 0,
      totalPracticeDays: json['total_practice_days'] ?? 0,
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _api = ApiClient();
  List<AdminUser> _users = [];
  bool _loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String query, {bool searching = false}) async {
    if (searching) setState(() => _searching = true);
    if (query.isEmpty && _users.isEmpty) setState(() => _loading = true);
    try {
      final data = await _api.getAdminUsers(search: query);
      if (mounted) {
        setState(() {
          _users = (data['items'] as List)
              .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
              .toList();
          _searching = false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (q) => _load(q, searching: true),
              decoration: InputDecoration(
                hintText: 'Поиск по имени, email, username',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _load('', searching: true);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _searching
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : _users.isEmpty
                        ? const Center(child: Text('Пользователи не найдены'))
                        : RefreshIndicator(
                            onRefresh: () => _load(_searchController.text),
                            color: AppTheme.accent,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: _users.length,
                              itemBuilder: (context, i) => _buildCard(_users[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AdminUser u) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceLight,
          child: Text(
            (u.name ?? '?').isNotEmpty ? (u.name ?? '?')[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(u.name ?? 'Без имени'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (u.email != null) Text(u.email!, style: const TextStyle(fontSize: 12)),
            if (u.telegramId != null)
              Text('TG: ${u.telegramId}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (u.isPremium)
              const Icon(Icons.workspace_premium, color: AppTheme.accent, size: 18),
            Text(
              '${u.totalPracticeMinutes} мин',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: u.id)),
          );
        },
      ),
    );
  }
}
