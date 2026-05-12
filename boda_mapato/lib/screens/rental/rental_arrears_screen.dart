import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class RentalArrearsScreen extends StatefulWidget {
  const RentalArrearsScreen({super.key});

  @override
  State<RentalArrearsScreen> createState() => _RentalArrearsScreenState();
}

class _RentalArrearsScreenState extends State<RentalArrearsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchArrears();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final arrears = rentalProvider.arrears;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Deni la Kodi",
      body: rentalProvider.isLoading && arrears.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : arrears.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 64, color: ThemeConstants.successGreen),
                      SizedBox(height: 16.h),
                      Text("Hakuna deni!",
                          style: TextStyle(
                              color: Colors.white54, fontSize: 16.sp)),
                      Text("Wapangaji wote wamelipa",
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14.sp)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCard(context, arrears),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: arrears.length,
                        itemBuilder: (context, index) {
                          final bill = arrears[index];
                          return _buildArrearCard(context, bill);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List arrears) {
    final totalArrears = arrears.fold<double>(
        0, (sum, b) => sum + ((b['balance'] ?? 0).toDouble()));
    final overdueCount = arrears.where((b) => b['status'] == 'overdue').length;
    final partialCount = arrears.where((b) => b['status'] == 'partial').length;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: ThemeConstants.glassCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                    "Jumla",
                    "TSh ${_formatCurrency(totalArrears)}",
                    ThemeConstants.errorRed),
              ),
              Expanded(
                child: _buildSummaryItem("Overdue", overdueCount.toString(),
                    ThemeConstants.errorRed),
              ),
              Expanded(
                child: _buildSummaryItem("Sehemu", partialCount.toString(),
                    ThemeConstants.warningAmber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildArrearCard(BuildContext context, Map<String, dynamic> bill) {
    final agreement = bill['agreement'] ?? {};
    final tenant = agreement['tenant'] ?? {};
    final house = agreement['house'] ?? {};
    final status = bill['status'] ?? 'unpaid';

    Color statusColor;
    switch (status) {
      case 'overdue':
        statusColor = ThemeConstants.errorRed;
      case 'partial':
        statusColor = ThemeConstants.warningAmber;
      default:
        statusColor = Colors.white54;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: ThemeConstants.glassCardDecoration,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.warning, color: statusColor, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant['user']?['name'] ?? tenant['name'] ?? 'Mteja',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Nyumba: ${house['house_number'] ?? ''}",
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                  Text(
                    "Mwezi: ${bill['month_year'] ?? ''}",
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "TSh ${_formatCurrency((bill['balance'] ?? 0).toDouble())}",
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }
}
