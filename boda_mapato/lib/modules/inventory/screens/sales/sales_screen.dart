import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: ThemeConstants.glassCardDecoration,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('create_sale_pos'), style: ThemeConstants.headingStyle),
                SizedBox(height: 8.h),
                Text(loc.translate('create_sale_hint'), style: ThemeConstants.captionStyle),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add_shopping_cart, size: 18.sp),
                        label: Text(loc.translate('add_products')),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.payments_outlined, size: 18.sp),
                        label: Text(loc.translate('checkout')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(loc.translate('recent_sales'), style: ThemeConstants.headingStyle),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.separated(
              itemCount: 8,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) => Container(
                decoration: ThemeConstants.glassCardDecoration,
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white70, size: 22.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#S00$index • ${loc.translate('cash')}', style: ThemeConstants.bodyStyle),
                          SizedBox(height: 4.h),
                          Text('2 ${loc.translate('items')} • TZS 25,000', style: ThemeConstants.captionStyle),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white54, size: 18.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
