enum InvReminderStatus { open, snoozed, done }

class InvReminder {
  InvReminder({
    required this.id,
    required this.type, // payment_due | low_stock
    required this.title,
    required this.description,
    required this.dueAt,
    this.status = InvReminderStatus.open,
    this.snoozeUntil,
    this.relatedId,
  });

  final int id;
  final String type;
  final String title;
  final String description;
  DateTime dueAt;
  InvReminderStatus status;
  DateTime? snoozeUntil;
  int? relatedId; // saleId or productId
}
