import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class RecordPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? preSelectedTenant;
  const RecordPaymentScreen({super.key, this.preSelectedTenant});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  Map<String, dynamic>? _selectedTenant;
  Map<String, dynamic>? _selectedBill;
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  final _referenceController = TextEditingController();
  bool _isProcessing = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'icon': '💵'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': '🏦'},
    {'value': 'mpesa', 'label': 'M-Pesa', 'icon': '📱'},
    {'value': 'airtel_money', 'label': 'Airtel Money', 'icon': '📱'},
    {'value': 'tigo_pesa', 'label': 'Tigo Pesa', 'icon': '📱'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RentalProvider>();
      provider.fetchTenants();
      provider.fetchBills();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Rekodi Malipo",
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(),
            SizedBox(height: 24.h),
            _buildTenantSection(),
            if (_selectedTenant != null) ...[
              SizedBox(height: 16.h),
              _buildBillSection(),
            ],
            if (_selectedBill != null) ...[
              SizedBox(height: 16.h),
              _buildAmountSection(),
              SizedBox(height: 16.h),
              _buildPaymentMethodSection(),
              SizedBox(height: 24.h),
              _buildSubmitButton(),
            ],
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    int step = 1;
    if (_selectedTenant != null) step = 2;
    if (_selectedBill != null) step = 3;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _buildStepDot(1, step >= 1, "Mteja"),
          _buildStepLine(step >= 2),
          _buildStepDot(2, step >= 2, "Bima"),
          _buildStepLine(step >= 3),
          _buildStepDot(3, step >= 3, "Malipo"),
        ],
      ),
    );
  }

  Widget _buildStepDot(int num, bool active, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: active ? ThemeConstants.primaryOrange : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                active ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white38,
                  fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40.w,
      height: 2.h,
      decoration: BoxDecoration(
        color: active ? ThemeConstants.primaryOrange : Colors.white12,
      ),
    );
  }

  Widget _buildTenantSection() {
    final provider = context.watch<RentalProvider>();
    final tenants = provider.tenants;

    return _buildSectionCard(
      "Chagua Mteja",
      Icons.person,
      Column(
        children: [
          if (provider.isLoading && tenants.isEmpty)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (tenants.isEmpty)
            Text("Hakuna wapangaji", style: TextStyle(color: Colors.white54))
          else
            ...tenants.map((tenant) => _buildTenantItem(tenant)),
        ],
      ),
    );
  }

  Widget _buildTenantItem(Map<String, dynamic> tenant) {
    final isSelected = _selectedTenant?['id'] == tenant['id'];
    final house = tenant['house'] ?? {};

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTenant = tenant;
          _selectedBill = null;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color:
                  isSelected ? ThemeConstants.primaryOrange : Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
              child: Text(
                (tenant['name'] ?? '?')[0].toString().toUpperCase(),
                style: TextStyle(
                    color: ThemeConstants.primaryOrange,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant['name'] ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600)),
                  Text("Nyumba: ${house['house_number'] ?? ''}",
                      style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: ThemeConstants.primaryOrange, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSection() {
    final provider = context.watch<RentalProvider>();
    final bills = provider.bills.where((b) {
      final tenantId = b['agreement']?['tenant_id'];
      return tenantId == _selectedTenant?['id'] &&
          (b['status'] == 'unpaid' ||
              b['status'] == 'partial' ||
              b['status'] == 'overdue');
    }).toList();

    return _buildSectionCard(
      "Chagua Kipindi cha Kodi",
      Icons.receipt_long,
      Column(
        children: [
          if (bills.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Text("Hakuna bima zilizo kugawanyika",
                  style: TextStyle(color: Colors.white54)),
            )
          else
            ...bills.map((bill) => _buildBillItem(bill)),
        ],
      ),
    );
  }

  Widget _buildBillItem(Map<String, dynamic> bill) {
    final isSelected = _selectedBill?['id'] == bill['id'];
    final amountDue = (bill['amount_due'] ?? 0).toDouble();
    final balance = (bill['balance'] ?? 0).toDouble();
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

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBill = bill;
          _amountController.text = balance.toStringAsFixed(0);
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color:
                  isSelected ? ThemeConstants.primaryOrange : Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.receipt, color: statusColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill['month_year'] ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600)),
                  Text("Kodi: TSh ${_formatCurrency(amountDue)}",
                      style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  Text("Baki: TSh ${_formatCurrency(balance)}",
                      style: TextStyle(color: statusColor, fontSize: 12.sp)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r)),
              child: Text(_formatStatus(status),
                  style: TextStyle(color: statusColor, fontSize: 10.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return _buildSectionCard(
      "Kiasi cha Malipo",
      Icons.attach_money,
      Column(
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "0",
              hintStyle: TextStyle(color: Colors.white24, fontSize: 24.sp),
              prefixText: "TSh ",
              prefixStyle: TextStyle(color: Colors.white54, fontSize: 18.sp),
              border: InputBorder.none,
            ),
          ),
          if (_selectedBill != null) ...[
            SizedBox(height: 8.h),
            Text(
              "Kiwango cha Kodi: TSh ${_formatCurrency((_selectedBill!['amount_due'] ?? 0).toDouble())}",
              style: TextStyle(color: Colors.white38, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return _buildSectionCard(
      "Njia ya Malipo",
      Icons.payment,
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod == method['value'];
          return InkWell(
            onTap: () =>
                setState(() => _selectedPaymentMethod = method['value']!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? ThemeConstants.primaryOrange
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: isSelected
                        ? ThemeConstants.primaryOrange
                        : Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(method['icon'] ?? '',
                      style: const TextStyle(fontSize: 16)),
                  SizedBox(width: 6.w),
                  Text(method['label'] ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final canSubmit =
        _selectedTenant != null && _selectedBill != null && amount > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !_isProcessing ? _submitPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSubmit ? ThemeConstants.primaryOrange : Colors.white24,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                "Hifadhi Malipo",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ThemeConstants.primaryOrange, size: 20.sp),
              SizedBox(width: 8.w),
              Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12.h),
          content,
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}K";
    return value.toStringAsFixed(0);
  }

  String _formatStatus(String status) {
    return switch (status) {
      'overdue' => 'Overdue',
      'partial' => 'Sehemu',
      'paid' => 'Imelipwa',
      _ => 'Bado'
    };
  }

  Future<void> _submitPayment() async {
    setState(() => _isProcessing = true);

    try {
      final provider = context.read<RentalProvider>();
      final success = await provider.recordPayment({
        'bill_id': _selectedBill!['id'],
        'amount_paid': double.parse(_amountController.text),
        'payment_method': _selectedPaymentMethod,
        'transaction_reference': _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
      });

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog("Malipo hayafaulu. Jaribu tena.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Hitilafu: $e");
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ThemeConstants.successGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  color: ThemeConstants.successGreen, size: 48.sp),
            ),
            SizedBox(height: 16.h),
            Text("Malipo Yamehifadhiwa!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text("Risiti itatumwa kwenye simu",
                style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Sawa",
                style: TextStyle(color: ThemeConstants.primaryOrange)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    ThemeConstants.showErrorSnackBar(context, message);
  }
}
