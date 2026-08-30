import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/services/notifications_center.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _center = NotificationsCenter.instance;

  @override
  void initState() {
    super.initState();
    _center.markAllRead();
    _center.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: ListenableBuilder(
        listenable: _center,
        builder: (context, _) {
          final items = _center.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('Уведомлений пока нет', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final isRead = item is Map ? (item['is_read'] == true) : true;
              final message = item is Map ? (item['message']?.toString() ?? '') : '';
              final createdAt = item is Map ? (item['created_at']?.toString() ?? '') : '';
              return Card(
                color: isRead ? AppTheme.surface : AppTheme.surfaceLight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.campaign_outlined,
                          size: 20,
                          color: isRead ? AppTheme.textSecondary : AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.isEmpty ? 'Сообщение' : message,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (createdAt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                createdAt.length > 16
                                    ? createdAt.substring(0, 16)
                                    : createdAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
