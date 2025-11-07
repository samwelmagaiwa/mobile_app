import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: loc.translate('search_products'),
                    hintStyle: ThemeConstants.captionStyle,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  ),
                  style: ThemeConstants.bodyStyle,
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 18.sp),
                label: Text(loc.translate('add_product')),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) => Container(
                decoration: ThemeConstants.glassCardDecoration,
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 22.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product #$index', style: ThemeConstants.bodyStyle),
                          SizedBox(height: 4.h),
                          Text('${loc.translate('sku')}: SKU00$index • ${loc.translate('quantity')}: ${10 - index}', style: ThemeConstants.captionStyle),
                        ],
                      ),
                    ),
                    if (index % 3 == 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(10.r)),
                        child: Text(loc.translate('low_stock'), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
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
