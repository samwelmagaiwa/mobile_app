import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class RentalReceiptsScreen extends StatefulWidget {
  const RentalReceiptsScreen({super.key});

  @override
  State<RentalReceiptsScreen> createState() => _RentalReceiptsScreenState();
}

class _RentalReceiptsScreenState extends State<RentalReceiptsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final receipts = rentalProvider.receipts;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Risiti",
      body: rentalProvider.isLoading && receipts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : receipts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.white38),
                      SizedBox(height: 16.h),
                      Text("Hakuna risiti",
                          style: TextStyle(
                              color: Colors.white54, fontSize: 16.sp)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return _buildReceiptCard(context, receipt);
                  },
                ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> receipt) {
    final payment = receipt['payment'] ?? {};
    final tenant = payment['tenant'] ?? {};
    final details = receipt['details'] ?? {};
    final amount =
        (details['amount_paid'] ?? payment['amount_paid'] ?? 0).toDouble();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: ThemeConstants.glassCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReceiptDetails(context, receipt),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.receipt,
                      color: ThemeConstants.primaryOrange, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details['receipt_number'] ??
                            receipt['receipt_number'] ??
                            '',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        tenant['name'] ?? 'Mteja',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12.sp),
                      ),
                      Text(
                        receipt['created_at'] ?? '',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                Text(
                  "TSh ${_formatCurrency(amount)}",
                  style: TextStyle(
                      color: ThemeConstants.primaryOrange,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiptDetails(BuildContext context, Map<String, dynamic> receipt) {
    final details = receipt['details'] ?? {};
    final payment = receipt['payment'] ?? {};
    final tenant = payment['tenant'] ?? {};

    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("RISITI",
                    style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                Text(
                    details['receipt_number'] ??
                        receipt['receipt_number'] ??
                        '',
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20.h),
            _buildDetailRow("Mteja", tenant['name'] ?? '-'),
            _buildDetailRow("Nyumba", details['house_number'] ?? '-'),
            _buildDetailRow("Mali", details['property_name'] ?? '-'),
            _buildDetailRow("Muda", details['period'] ?? '-'),
            Divider(color: Colors.white12),
            _buildDetailRow("Kiasi Alicholipa",
                "TSh ${_formatCurrency((details['amount_paid'] ?? 0).toDouble())}"),
            _buildDetailRow("Baki",
                "TSh ${_formatCurrency((details['balance_remaining'] ?? 0).toDouble())}"),
            _buildDetailRow("Njia ya Malipo", details['payment_method'] ?? '-'),
            _buildDetailRow("Mkusanyaji", details['collector_name'] ?? '-'),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share),
                label: const Text("Shiriki"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
        ],
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
