import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

class StockLevelsScreen extends StatelessWidget {
  const StockLevelsScreen({super.key});

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
              Icon(Icons.inventory_outlined, color: Colors.white70, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product #$index', style: ThemeConstants.bodyStyle),
                    SizedBox(height: 4.h),
                    Text('${loc.translate('warehouse')}: Main • ${loc.translate('quantity')}: ${20 - index}', style: ThemeConstants.captionStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
