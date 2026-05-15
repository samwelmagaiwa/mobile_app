import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/theme_constants.dart';

class ReceiptViewScreen extends StatelessWidget {
  final dynamic payment; // Can be a payment record or derived from bill

  const ReceiptViewScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Digital Receipt",
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
             ThemeConstants.showSuccessSnackBar(context, "Receipt shared successfully!");
          },
        ),
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: () {
             ThemeConstants.showSuccessSnackBar(context, "Sending to printer...");
          },
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          
          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500.w : double.infinity,
                ),
                child: Column(
                  children: [
                    _buildReceiptHeader(context),
                    SizedBox(height: 16.h),
                    _buildReceiptBody(context, payment),
                    SizedBox(height: 24.h),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ThemeConstants.successGreen.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: ThemeConstants.successGreen, size: 48.w),
        ),
        SizedBox(height: 16.h),
        Text(
          "Payment Successful",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Receipt #${payment['id'] ?? 'N/A'}",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptBody(BuildContext context, dynamic payment) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        children: [
          _buildReceiptRow("Date", payment['created_at'] ?? 'Today'),
          _buildReceiptRow("Mteja", (payment['bill']?['tenant']?['name'] ?? 'N/A').toString()),
          _buildReceiptRow("Property", (payment['bill']?['house']?['property']?['name'] ?? 'N/A').toString()),
          _buildReceiptRow("House #", (payment['bill']?['house']?['house_number'] ?? 'N/A').toString()),
          const Divider(color: Colors.white10),
          _buildReceiptRow("Payment Method", (payment['payment_method'] ?? 'Cash').toString().toUpperCase()),
          _buildReceiptRow("Amount Paid", "Tsh ${payment['amount']}", isBold: true),
          const Divider(color: Colors.white10),
          _buildReceiptRow("Baki", "Tsh ${payment['bill']?['balance'] ?? '0'}", color: ThemeConstants.errorRed),
          SizedBox(height: 24.h),
          // Barcode or QR placeholder
          Container(
            height: 60.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white38, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color color = Colors.white}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          "Thank you for your payment!",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Mapato Rental Service",
          style: TextStyle(
            color: ThemeConstants.footerBarColor,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
