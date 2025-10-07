import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/reminder.dart';
import '../utils/date_utils.dart';

class ReminderTile extends StatelessWidget {

  const ReminderTile({
    required this.reminder, super.key,
    this.isOverdue = false,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
  });
  final Reminder reminder;
  final bool isOverdue;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(final BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Reminder Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getReminderColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusM),
                  ),
                  child: Icon(
                    _getReminderIcon(),
                    color: _getReminderColor(),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: AppStyles.spacingM),
                
                // Reminder Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        reminder.title,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Text(
                        reminder.message,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppStyles.spacingXS),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: AppStyles.spacingXS),
                          Text(
                            _getTimeText(),
                            style: AppStyles.bodySmall.copyWith(
                              color: isOverdue ? AppColors.error : AppColors.textSecondary,
                              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppStyles.spacingS,
                              vertical: AppStyles.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusS),
                            ),
                            child: Text(
                              reminder.type.name,
                              style: AppStyles.bodySmall.copyWith(
                                color: _getTypeColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status and Actions
                Column(
                  children: <Widget>[
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingS,
                          vertical: AppStyles.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppStyles.radiusS),
                        ),
                        child: Text(
                          "Imechelewa",
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppStyles.spacingS),
                    PopupMenuButton<String>(
                      onSelected: (final String value) {
                        switch (value) {
                          case "complete":
                            onComplete?.call();
                          case "edit":
                            onEdit?.call();
                          case "delete":
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (final BuildContext context) => <PopupMenuEntry<String>>[
                        if (reminder.status == ReminderStatus.active)
                          const PopupMenuItem(
                            value: "complete",
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 8),
                                Text("Kamilisha"),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: "edit",
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text("Hariri"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "delete",
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete, size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text("Futa", style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Quick Actions (for active reminders)
            if (reminder.status == ReminderStatus.active && !isOverdue) ...<Widget>[
              const SizedBox(height: AppStyles.spacingM),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Kamilisha"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Snooze reminder (add 1 hour)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Kikumbusho kimesongwa kwa saa 1"),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                      icon: const Icon(Icons.snooze, size: 16),
                      label: const Text("Songeza"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

  Color _getReminderColor() {
    if (isOverdue) return AppColors.error;
    
    switch (reminder.status) {
      case ReminderStatus.active:
        return AppColors.primary;
      case ReminderStatus.completed:
        return AppColors.success;
      case ReminderStatus.cancelled:
        return AppColors.textHint;
    }
  }

  IconData _getReminderIcon() {
    if (isOverdue) return Icons.warning;
    
    switch (reminder.status) {
      case ReminderStatus.active:
        return Icons.notifications_active;
      case ReminderStatus.completed:
        return Icons.check_circle;
      case ReminderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getTypeColor() {
    switch (reminder.type) {
      case ReminderType.daily:
        return AppColors.success;
      case ReminderType.weekly:
        return AppColors.info;
      case ReminderType.monthly:
        return AppColors.warning;
      case ReminderType.oneTime:
        return AppColors.primary;
    }
  }

  String _getTimeText() {
    final now = DateTime.now();
    final reminderTime = reminder.reminderTime;
    
    if (isOverdue) {
      final difference = now.difference(reminderTime);
      if (difference.inDays > 0) {
        return 'Imechelewa kwa siku ${difference.inDays}';
      } else if (difference.inHours > 0) {
        return 'Imechelewa kwa saa ${difference.inHours}';
      } else {
        return 'Imechelewa kwa dakika ${difference.inMinutes}';
      }
    }
    
    if (reminderTime.day == now.day && 
        reminderTime.month == now.month && 
        reminderTime.year == now.year) {
      return 'Leo ${AppDateUtils.formatTime(reminderTime)}';
    }
    
    final tomorrow = now.add(const Duration(days: 1));
    if (reminderTime.day == tomorrow.day && 
        reminderTime.month == tomorrow.month && 
        reminderTime.year == tomorrow.year) {
      return 'Kesho ${AppDateUtils.formatTime(reminderTime)}';
    }
    
    return '${AppDateUtils.formatDate(reminderTime)} ${AppDateUtils.formatTime(reminderTime)}';
  }
}

class ReminderSummaryCard extends StatelessWidget {

  const ReminderSummaryCard({
    required this.title, required this.count, required this.icon, required this.color, super.key,
    this.onTap,
  });
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.radiusL),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            Text(
              count.toString(),
              style: AppStyles.heading2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.spacingXS),
            Text(
              count == 1 ? "kikumbusho" : "vikumbusho",
              style: AppStyles.bodySmall.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
}