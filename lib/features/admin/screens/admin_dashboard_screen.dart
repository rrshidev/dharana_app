import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/admin/screens/admin_broadcast_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_content_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_overview_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_payments_screen.dart';
import 'package:dharana_app/features/admin/screens/admin_users_screen.dart';
import 'package:dharana_app/l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanelTitle),
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
            label: l10n.adminTabOverview,
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.people, color: AppTheme.Accent),
            label: l10n.adminTabUsers,
          ),
          NavigationDestination(
            icon: Icon(Icons.request_page_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.request_page, color: AppTheme.Accent),
            label: l10n.adminTabPayments,
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.campaign, color: AppTheme.Accent),
            label: l10n.adminTabBroadcast,
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppTheme.TextSecondary),
            selectedIcon: Icon(Icons.folder, color: AppTheme.Accent),
            label: l10n.adminTabContent,
          ),
        ],
      ),
    );
  }
}
