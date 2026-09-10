import 'package:flutter/foundation.dart';

import '../../../services/api_service.dart';
import '../models/inv_notification.dart';

/// A logged-in user's own approval-notification inbox: write-offs/returns
/// they can approve just went pending, or a decision landed on something
/// they submitted. Backed by GET/POST inventory/notifications*.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  List<InvNotification> _items = <InvNotification>[];
  int _unreadCount = 0;
  bool _loading = false;

  List<InvNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> fetch({bool unreadOnly = false}) async {
    _loading = true;
    notifyListeners();
    try {
      final Map<String, dynamic>? res = await _api.getOrNull(
        '/inventory/notifications${unreadOnly ? '?unread_only=1' : ''}',
      );
      final dynamic rows = res?['data'];
      _items = rows is List
          ? rows
              .whereType<Map>()
              .map((e) => InvNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <InvNotification>[];
      final dynamic meta = res?['meta'];
      _unreadCount = meta is Map && meta['unread_count'] is num
          ? (meta['unread_count'] as num).toInt()
          : _items.where((InvNotification n) => n.isUnread).length;
    } on Exception {
      // Keep whatever was already loaded rather than blanking the inbox
      // on a transient network error.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cheap poll for just the badge count, e.g. on app-bar build -- avoids
  /// pulling the full list when the user hasn't opened the inbox yet.
  Future<void> refreshUnreadCount() async {
    try {
      final Map<String, dynamic>? res =
          await _api.getOrNull('/inventory/notifications?unread_only=1');
      final dynamic meta = res?['meta'];
      if (meta is Map && meta['unread_count'] is num) {
        _unreadCount = (meta['unread_count'] as num).toInt();
        notifyListeners();
      }
    } on Exception {
      // Badge just stays as-is until the next successful poll.
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.post('/inventory/notifications/$id/read', const <String, dynamic>{});
      final int i = _items.indexWhere((InvNotification n) => n.id == id);
      if (i != -1 && _items[i].isUnread) {
        _items[i] = InvNotification(
          id: _items[i].id,
          type: _items[i].type,
          title: _items[i].title,
          body: _items[i].body,
          data: _items[i].data,
          createdAt: _items[i].createdAt,
          readAt: DateTime.now(),
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } on Exception {
      // Best-effort -- next fetch() reconciles the true state.
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.post('/inventory/notifications/read-all', const <String, dynamic>{});
      await fetch();
    } on Exception {
      // Best-effort -- next fetch() reconciles the true state.
    }
  }
}
