import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../providers/inventory_provider.dart';

class InventoryDashboardScreen extends StatelessWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _StatCard(title: loc.translate('total_sales_today'), value: inv.totalSalesTodayFormatted)),
              SizedBox(width: 12.w),
              Expanded(child: _StatCard(title: loc.translate('profit_today'), value: inv.profitTodayFormatted)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _StatCard(title: loc.translate('profit_week'), value: inv.profitWeekFormatted)),
              SizedBox(width: 12.w),
              Expanded(child: _StatCard(title: loc.translate('profit_month'), value: inv.profitMonthFormatted)),
            ],
          ),
          SizedBox(height: 16.h),

          // Sales line chart
          Container(
            decoration: ThemeConstants.glassCardDecoration,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('sales_trend'), style: ThemeConstants.headingStyle),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 160.h,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          spots: inv.salesTrend,
                          color: Colors.lightBlueAccent,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
          // Low stock section
          Text(loc.translate('low_stock'), style: ThemeConstants.headingStyle),
          SizedBox(height: 8.h),
          ...inv.lowStockTop5.map((p) => ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                leading: Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 20.sp),
                title: Text(p.name, style: ThemeConstants.bodyStyle),
                subtitle: Text('${loc.translate('quantity')}: ${p.quantity} • ${loc.translate('min_stock')}: ${p.minStock}', style: ThemeConstants.captionStyle),
                onTap: () {},
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemeConstants.glassCardDecoration,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ThemeConstants.captionStyle),
          SizedBox(height: 6.h),
          Text(value, style: ThemeConstants.headingStyle.copyWith(fontSize: 20.sp)),
        ],
      ),
    );
  }
}
