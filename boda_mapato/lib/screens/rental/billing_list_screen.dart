import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'receipt_view_screen.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key, this.isSubView = false});
  final bool isSubView;

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
      if (_filter == 'unpaid') return b['status'] == 'unpaid' || b['status'] == 'partial';
      if (_filter == 'paid') return b['status'] == 'paid';
      if (_filter == 'overdue') return b['is_overdue'] == 1 || b['is_overdue'] == true;
      return true;
    }).toList();

    return ThemeConstants.buildScaffold(
      title: LocalizationService.instance.translate("rent_billing"),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(context),
            Expanded(
              child: rentalProvider.isLoading && bills.isEmpty
                ? ThemeConstants.buildLoadingWidget()
                : bills.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56.sp, color: Colors.white24),
                          SizedBox(height: 16.h),
                          Text(LocalizationService.instance.translate("no_bills_found"), style: ThemeConstants.captionStyle),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: rentalProvider.fetchBills,
                      color: ThemeConstants.primaryOrange,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 100.h),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final loc = LocalizationService.instance;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 16.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(loc.translate("all"), 'all'),
            SizedBox(width: 8.w),
            _buildFilterChip(loc.translate("unpaid"), 'unpaid'),
            SizedBox(width: 8.w),
            _buildFilterChip(loc.translate("overdue"), 'overdue'),
            SizedBox(width: 8.w),
            _buildFilterChip(loc.translate("paid"), 'paid'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isSelected ? [
            BoxShadow(color: ThemeConstants.primaryOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, bill) {
    final status = bill['status'] as String;
    final isOverdue = bill['is_overdue'] == 1 || bill['is_overdue'] == true;
    
    final loc = LocalizationService.instance;
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
                    (bill['tenant'] != null ? bill['tenant']['name'] : null) ?? 'Mteja',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Nyumba ${(bill['house'] != null ? bill['house']['house_number'] : null) ?? '-'}",
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
                  isOverdue ? loc.translate("overdue").toUpperCase() : (loc.translate(status).toUpperCase()),
                  style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Divider(color: Colors.white10, height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountItem(loc.translate("total"), bill['amount_due']),
              _buildAmountItem(loc.translate("paid"), bill['amount_paid']),
              _buildAmountItem(loc.translate("balance"), bill['balance'], isBold: true),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white54, size: 14.w),
              SizedBox(width: 4.w),
              Text(
                "${loc.translate('due')}: ${bill['due_date']}",
                style: TextStyle(color: Colors.white54, fontSize: 11.sp),
              ),
              const Spacer(),
              if (status != 'paid')
                Text(
                  loc.translate("tap_to_pay"),
                  style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
        Text(
          "Tsh $value",
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showPaymentModal(BuildContext context, bill) {
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
                  LocalizationService.instance.translate("record_payment"),
                  style: ThemeConstants.responsiveHeadingStyle(context),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Kurekodi malipo ya ${(bill['tenant'] != null ? bill['tenant']['name'] : null) ?? ''} - Nyumba ${(bill['house'] != null ? bill['house']['house_number'] : null) ?? ''}",
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                ),
                SizedBox(height: 24.h),
                ThemeConstants.buildResponsiveGlassCardStatic(
                  context,
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: ThemeConstants.invInputDecoration(LocalizationService.instance.translate("amount_paid_tsh")).copyWith(
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
                          ThemeConstants.showSuccessSnackBar(context, LocalizationService.instance.translate("payment_success"));
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
                          ThemeConstants.showErrorSnackBar(context, LocalizationService.instance.translate("payment_failed"));
                        }
                      }
                    },
                    style: ThemeConstants.responsiveElevatedButtonStyle(context),
                    child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(LocalizationService.instance.translate("confirm_payment")),
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
