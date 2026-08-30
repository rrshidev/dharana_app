import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dharana_app/core/api/api_client.dart';

class NotificationsCenter extends ChangeNotifier {
  NotificationsCenter._();
  static final NotificationsCenter instance = NotificationsCenter._();

  final ApiClient _api = ApiClient();
  Timer? _timer;

  List<dynamic> _items = [];
  int _unread = 0;

  List<dynamic> get items => List.unmodifiable(_items);
  int get unread => _unread;
  bool get hasUnread => _unread > 0;

  Future<void> refresh() async {
    try {
      final data = await _api.getBroadcastNotifications();
      final itemsRaw = data['items'];
      if (itemsRaw is List) {
        _items = itemsRaw;
      }
      _unread = (data['unread'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {
      // ignore network/auth errors; keep last known state
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markBroadcastNotificationsRead();
      for (int i = 0; i < _items.length; i++) {
        final m = _items[i];
        if (m is Map) {
          m['is_read'] = true;
        }
      }
      _unread = 0;
      notifyListeners();
    } catch (_) {}
  }

  void startPolling() {
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
