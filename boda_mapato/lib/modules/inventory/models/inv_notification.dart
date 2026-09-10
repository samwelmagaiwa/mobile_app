import 'package:flutter/foundation.dart';

/// One row of a user's approval-notification inbox: a write-off/return
/// they can approve just arrived as pending, or a decision landed on a
/// request they submitted.
@immutable
class InvNotification {
  const InvNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  factory InvNotification.fromJson(Map<String, dynamic> j) => InvNotification(
        id: _toInt(j['id']),
        type: _toStr(j['type']),
        title: _toStr(j['title']),
        body: _toStr(j['body']),
        data: j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : const <String, dynamic>{},
        createdAt: DateTime.tryParse(_toStr(j['created_at'])) ?? DateTime.now(),
        readAt: j['read_at'] == null ? null : DateTime.tryParse(_toStr(j['read_at'])),
      );

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _toStr(dynamic v) => v?.toString() ?? '';
}
