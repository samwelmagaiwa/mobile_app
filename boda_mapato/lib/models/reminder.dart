enum ReminderType {
  daily,
  weekly,
  monthly,
  oneTime,
}

enum ReminderStatus {
  active,
  completed,
  cancelled,
}

extension ReminderTypeExtension on ReminderType {
  String get name {
    switch (this) {
      case ReminderType.daily:
        return 'Kila Siku';
      case ReminderType.weekly:
        return 'Kila Wiki';
      case ReminderType.monthly:
        return 'Kila Mwezi';
      case ReminderType.oneTime:
        return 'Mara Moja';
    }
  }
}

extension ReminderStatusExtension on ReminderStatus {
  String get name {
    switch (this) {
      case ReminderStatus.active:
        return 'Inatumika';
      case ReminderStatus.completed:
        return 'Imekamilika';
      case ReminderStatus.cancelled:
        return 'Imeghairiwa';
    }
  }
}

class Reminder {

  Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.reminderTime,
    required this.type,
    required this.status,
    required this.driverId,
    required this.createdAt,
    required this.updatedAt,
    this.isNotificationSent = false,
    this.deviceId,
  });

  factory Reminder.fromJson(final Map<String, dynamic> json) => Reminder(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      reminderTime: DateTime.parse(json['reminder_time'] ?? DateTime.now().toIso8601String()),
      type: _parseReminderType(json['type']),
      status: _parseReminderStatus(json['status']),
      driverId: json['driver_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isNotificationSent: json['is_notification_sent'] ?? false,
      deviceId: json['device_id'],
    );
  final String id;
  final String title;
  final String message;
  final DateTime reminderTime;
  final ReminderType type;
  final ReminderStatus status;
  final String driverId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNotificationSent;
  final String? deviceId;

  static ReminderType _parseReminderType(final String? type) {
    switch (type?.toLowerCase()) {
      case 'daily':
        return ReminderType.daily;
      case 'weekly':
        return ReminderType.weekly;
      case 'monthly':
        return ReminderType.monthly;
      case 'one_time':
        return ReminderType.oneTime;
      default:
        return ReminderType.oneTime;
    }
  }

  static ReminderStatus _parseReminderStatus(final String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ReminderStatus.active;
      case 'completed':
        return ReminderStatus.completed;
      case 'cancelled':
        return ReminderStatus.cancelled;
      default:
        return ReminderStatus.active;
    }
  }

  Map<String, dynamic> toJson() => <String, >{
      "id": id,
      "title": title,
      "message": message,
      "reminder_time": reminderTime.toIso8601String(),
      "type": type.name.toLowerCase(),
      "status": status.name.toLowerCase(),
      "driver_id": driverId,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "is_notification_sent": isNotificationSent,
      "device_id": deviceId,
    };

  Reminder copyWith({
    final String? id,
    final String? title,
    final String? message,
    final DateTime? reminderTime,
    final ReminderType? type,
    final ReminderStatus? status,
    final String? driverId,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final bool? isNotificationSent,
    final String? deviceId,
  }) => Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      reminderTime: reminderTime ?? this.reminderTime,
      type: type ?? this.type,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isNotificationSent: isNotificationSent ?? this.isNotificationSent,
      deviceId: deviceId ?? this.deviceId,
    );

  bool get isActive => status == ReminderStatus.active;
  bool get isOverdue => reminderTime.isBefore(DateTime.now()) && isActive;
  bool get isUpcoming => reminderTime.isAfter(DateTime.now()) && isActive;

  @override
  String toString() => "Reminder(id: $id, title: $title, reminderTime: $reminderTime, type: ${type.name}, status: ${status.name})";

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}