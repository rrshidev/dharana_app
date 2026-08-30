import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/services/notifications_center.dart';
import 'package:dharana_app/features/notifications/screens/notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final center = NotificationsCenter.instance;
    center.startPolling();
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        return IconButton(
          tooltip: 'Уведомления',
          onPressed: () async {
            await center.refresh();
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: Badge(
            isLabelVisible: center.hasUnread,
            backgroundColor: AppTheme.danger,
            smallSize: 10,
            child: Icon(Icons.notifications_none, color: color),
          ),
        );
      },
    );
  }
}
