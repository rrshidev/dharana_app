import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/admin/screens/admin_broadcast_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_content_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_overview_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_payments_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: SizedBox.shrink(),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          AdminOverviewScreen(),
          AdminUsersScreen(),
          AdminPaymentsScreen(),
          AdminBroadcastScreen(),
          AdminContentScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.accent),
            label: 'Обзор',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.people, color: AppTheme.accent),
            label: 'Юзеры',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_page_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.request_page, color: AppTheme.accent),
            label: 'Заявки',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.campaign, color: AppTheme.accent),
            label: 'Рассылка',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.folder, color: AppTheme.accent),
            label: 'Контент',
          ),
        ],
      ),
    );
  }
}
