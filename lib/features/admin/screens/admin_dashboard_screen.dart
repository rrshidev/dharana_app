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
        backgroundColor: AppTheme.Surface,
        indicatorColor: AppTheme.Accent.withValues(alpha: 0.25),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.Accent),
            label: 'Обзор',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.people, color: AppTheme.Accent),
            label: 'Юзеры',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_page_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.request_page, color: AppTheme.Accent),
            label: 'Заявки',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.campaign, color: AppTheme.Accent),
            label: 'Рассылка',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.folder, color: AppTheme.Accent),
            label: 'Контент',
          ),
        ],
      ),
    );
  }
}
