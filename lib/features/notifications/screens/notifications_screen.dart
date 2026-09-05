import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/api/api_client.dart';
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
            return Center(
              child: Text('Уведомлений пока нет', style: TextStyle(color: AppTheme.TextSecondary)),
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
              final mediaUrl = item is Map ? (item['media_url']?.toString() ?? '') : '';
              final createdAt = item is Map ? (item['created_at']?.toString() ?? '') : '';
              return Card(
                color: isRead ? AppTheme.Surface : AppTheme.SurfaceLight,
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
                          color: isRead ? AppTheme.TextSecondary : AppTheme.Accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.isEmpty ? 'Сообщение' : message,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.TextPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (mediaUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiClient().resolveUrl(mediaUrl),
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            if (createdAt.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                createdAt.length > 16
                                    ? createdAt.substring(0, 16)
                                    : createdAt,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.TextSecondary,
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
                          decoration: BoxDecoration(
                            color: AppTheme.Accent,
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
