import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../providers/inventory_provider.dart';

class StockLevelsScreen extends StatelessWidget {
  const StockLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final products = inv.products;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: products.isEmpty
            ? Center(
                child: Text(loc.translate('no_data'),
                    style: ThemeConstants.captionStyle))
            : ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final p = products[index];
                  final isLow = p.quantity < p.minStock;
                  return Container(
                    decoration: ThemeConstants.glassCardDecoration,
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_outlined,
                            color: Colors.white70, size: 22.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(p.name,
                                  style: ThemeConstants.bodyStyle, maxLines: 1),
                              SizedBox(height: 4.h),
                              AutoSizeText(
                                  '${loc.translate('sku')}: ${p.sku} • ${loc.translate('quantity')}: ${p.quantity} • ${loc.translate('min_stock')}: ${p.minStock}',
                                  style: ThemeConstants.captionStyle,
                                  maxLines: 1,
                                  minFontSize: 10),
                            ],
                          ),
                        ),
                        if (isLow)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(10.r)),
                            child: Text(loc.translate('low_stock'),
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11.sp)),
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
