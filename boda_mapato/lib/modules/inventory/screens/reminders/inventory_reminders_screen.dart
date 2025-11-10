import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_reminder.dart';
import '../../providers/inventory_provider.dart';

class InventoryRemindersScreen extends StatelessWidget {
  const InventoryRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final reminders = inv.reminders;
    if (reminders.isEmpty) {
      // Try fetch on first build if list empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<InventoryProvider>().fetchReminders();
      });
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView.separated(
          itemCount: reminders.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final r = reminders[index];
            final isLow = r.type == 'low_stock';
            final icon =
                isLow ? Icons.inventory_2_outlined : Icons.payments_outlined;
            final statusText = r.status == InvReminderStatus.done
                ? loc.translate('done')
                : r.status == InvReminderStatus.snoozed
                    ? loc.translate('snoozed')
                    : loc.translate('open');
            return Container(
              decoration: ThemeConstants.glassCardDecoration,
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 22.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(r.title,
                            style: ThemeConstants.bodyStyle, maxLines: 1),
                        SizedBox(height: 4.h),
                        AutoSizeText(r.description,
                            style: ThemeConstants.captionStyle,
                            maxLines: 2,
                            minFontSize: 10),
                        SizedBox(height: 4.h),
                        AutoSizeText(statusText,
                            style: ThemeConstants.captionStyle,
                            maxLines: 1,
                            minFontSize: 10),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: r.status == InvReminderStatus.done
                        ? null
                        : () async {
                            await inv.markReminderDone(r.id);
                            if (!context.mounted) return;
                            ThemeConstants.showSuccessSnackBar(
                                context, loc.translate('success'));
                          },
                    child: Text(loc.translate('mark_done')),
                  ),
                  TextButton(
                    onPressed: () async {
                      await inv.snoozeReminder(r.id, minutes: 60 * 24);
                      if (!context.mounted) return;
                      ThemeConstants.showSuccessSnackBar(
                          context, loc.translate('success'));
                    },
                    child: Text(loc.translate('snooze')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
