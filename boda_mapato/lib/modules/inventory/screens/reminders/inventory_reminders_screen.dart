import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

class InventoryRemindersScreen extends StatelessWidget {
  const InventoryRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) => Container(
          decoration: ThemeConstants.glassCardDecoration,
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Colors.white70, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(index % 2 == 0 ? loc.translate('payment_due') : loc.translate('low_stock'), style: ThemeConstants.bodyStyle),
                    SizedBox(height: 4.h),
                    Text(index % 2 == 0 ? loc.translate('payment_due_desc') : loc.translate('low_stock_desc'), style: ThemeConstants.captionStyle),
                  ],
                ),
              ),
              TextButton(onPressed: () {}, child: Text(loc.translate('mark_done'))),
              TextButton(onPressed: () {}, child: Text(loc.translate('snooze'))),
            ],
          ),
        ),
      ),
    );
  }
}
