import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import 'receipt_view_screen.dart';

class BillingListScreen extends StatefulWidget {
  final bool isSubView;
  const BillingListScreen({super.key, this.isSubView = false});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  String _filter = 'all'; // all, unpaid, paid, overdue

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final bills = rentalProvider.bills.where((b) {
      if (_filter == 'all') return true;
      if (_filter == 'unpaid') return (b['status'] == 'unpaid' || b['status'] == 'partial');
      if (_filter == 'paid') return b['status'] == 'paid';
      if (_filter == 'overdue') return b['is_overdue'] == 1 || b['is_overdue'] == true;
      return true;
    }).toList();

    final content = LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              _buildFilters(context),
              SizedBox(height: 16.h),
              Expanded(
                child: rentalProvider.isLoading && bills.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : bills.isEmpty
                    ? Center(child: Text("No bills found", style: TextStyle(color: Colors.white54, fontSize: 14.sp)))
                    : RefreshIndicator(
                        onRefresh: () => rentalProvider.fetchBills(),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: bills.length,
                          itemBuilder: (context, index) {
                            final bill = bills[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildBillCard(context, bill),
                            );
                          },
                        ),
                      ),
              ),
              SizedBox(height: 100.h),
            ],
          ),
        );
      },
    );

    if (widget.isSubView) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          title: Text(
            "Rent Billing",
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Rent Billing",
      body: content,
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("All", 'all'),
          SizedBox(width: 8.w),
          _buildFilterChip("Unpaid", 'unpaid'),
          SizedBox(width: 8.w),
          _buildFilterChip("Overdue", 'overdue'),
          SizedBox(width: 8.w),
          _buildFilterChip("Paid", 'paid'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = value);
      },
      selectedColor: ThemeConstants.primaryOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: ThemeConstants.cardColor,
    );
  }

  Widget _buildBillCard(BuildContext context, dynamic bill) {
    final status = bill['status'] as String;
    final isOverdue = bill['is_overdue'] == 1 || bill['is_overdue'] == true;
    
    Color statusColor = ThemeConstants.successGreen;
    if (isOverdue) {
      statusColor = ThemeConstants.errorRed;
    } else if (status == 'unpaid') {
      statusColor = ThemeConstants.warningAmber;
    } else if (status == 'partial') {
      statusColor = Colors.lightBlueAccent;
    }

    return ThemeConstants.buildResponsiveGlassCard(
      context,
      onTap: () {
        if (status != 'paid') {
          _showPaymentModal(context, bill);
        }
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill['tenant']['name'] ?? 'Tenant',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "House ${bill['house']['house_number']}",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  isOverdue ? "OVERDUE" : status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Divider(color: Colors.white10, height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountItem("Total", bill['amount_due']),
              _buildAmountItem("Paid", bill['amount_paid']),
              _buildAmountItem("Balance", bill['balance'], isBold: true),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white54, size: 14.w),
              SizedBox(width: 4.w),
              Text(
                "Due: ${bill['due_date']}",
                style: TextStyle(color: Colors.white54, fontSize: 11.sp),
              ),
              const Spacer(),
              if (status != 'paid')
                Text(
                  "Tap to Pay",
                  style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, dynamic value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
        Text(
          "Tsh ${value.toString()}",
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showPaymentModal(BuildContext context, dynamic bill) {
    final amountController = TextEditingController(text: bill['balance'].toString());
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: ThemeConstants.bgMid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Record Payment",
                  style: ThemeConstants.responsiveHeadingStyle(context),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Recording payment for ${bill['tenant']['name']} - House ${bill['house']['house_number']}",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                SizedBox(height: 24.h),
                ThemeConstants.buildResponsiveGlassCardStatic(
                  context,
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: ThemeConstants.invInputDecoration("Amount Paid (Tsh)").copyWith(
                      prefixIcon: const Icon(Icons.payments, color: Colors.white70),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setModalState(() => isSaving = true);
                      final success = await context.read<RentalProvider>().recordPayment({
                        "rental_bill_id": bill['id'].toString(),
                        "amount": amountController.text,
                        "payment_method": "cash", // Default for MVP
                      });
                      if (mounted) {
                        setModalState(() => isSaving = false);
                        if (success) {
                          ThemeConstants.showSuccessSnackBar(context, "Payment recorded successfully!");
                          final lastPayment = context.read<RentalProvider>().lastPayment;
                          Navigator.pop(context); // Close modal
                          if (lastPayment != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReceiptViewScreen(payment: lastPayment),
                              ),
                            );
                          }
                        } else {
                          ThemeConstants.showErrorSnackBar(context, "Failed to record payment.");
                        }
                      }
                    },
                    style: ThemeConstants.responsiveElevatedButtonStyle(context),
                    child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm Payment"),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
