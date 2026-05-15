import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';

class TenantSelfServiceScreen extends StatefulWidget {
  const TenantSelfServiceScreen({super.key});

  @override
  State<TenantSelfServiceScreen> createState() =>
      _TenantSelfServiceScreenState();
}

class _TenantSelfServiceScreenState extends State<TenantSelfServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _tenantData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTenantData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTenantData() async {
    // In real app, fetch from API
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _tenantData = _mockTenantData();
      });
    }
  }

  Map<String, dynamic> _mockTenantData() {
    return {
      'name': 'John Mkomagi',
      'phone': '255765123456',
      'house': 'A-101',
      'property': 'Mikocheni Apartments',
      'rent_amount': 300000,
      'balance': 0,
      'bills': [
        {
          'month_year': '05-2026',
          'amount_due': 300000,
          'status': 'paid',
          'paid': 300000,
          'balance': 0
        },
        {
          'month_year': '04-2026',
          'amount_due': 300000,
          'status': 'paid',
          'paid': 300000,
          'balance': 0
        },
        {
          'month_year': '03-2026',
          'amount_due': 300000,
          'status': 'paid',
          'paid': 300000,
          'balance': 0
        },
      ],
      'payments': [
        {
          'date': '2026-05-01',
          'amount': 300000,
          'method': 'M-Pesa',
          'receipt': 'RCP-001'
        },
        {
          'date': '2026-04-01',
          'amount': 300000,
          'method': 'Cash',
          'receipt': 'RCP-002'
        },
        {
          'date': '2026-03-01',
          'amount': 300000,
          'method': 'Bank',
          'receipt': 'RCP-003'
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "My Account",
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildHeader(user?.name ?? "Tenant"),
                _buildTabBar(),
                Expanded(
                    child: TabBarView(controller: _tabController, children: [
                  _buildBillsTab(),
                  _buildPaymentsTab(),
                  _buildReceiptsTab(),
                ])),
              ],
            ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConstants.primaryOrange.withOpacity(0.3),
            ThemeConstants.primaryOrange.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: ThemeConstants.primaryOrange,
            child: Text(
              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold)),
                Text("${_tenantData!['house']} - ${_tenantData!['property']}",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: (_tenantData!['balance'] as int) > 0
                  ? ThemeConstants.errorRed.withOpacity(0.2)
                  : ThemeConstants.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              "Baki: TSh ${_formatCurrency(_tenantData!['balance'])}",
              style: TextStyle(
                  color: (_tenantData!['balance'] as int) > 0
                      ? ThemeConstants.errorRed
                      : ThemeConstants.successGreen,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: ThemeConstants.primaryOrange,
            borderRadius: BorderRadius.circular(12.r)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: "Bima"),
          Tab(text: "Malipo"),
          Tab(text: "Risiti")
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    final bills = _tenantData!['bills'] as List;

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final isPaid = bill['status'] == 'paid';

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: (isPaid
                          ? ThemeConstants.successGreen
                          : ThemeConstants.warningAmber)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(isPaid ? Icons.check_circle : Icons.warning,
                    color: isPaid
                        ? ThemeConstants.successGreen
                        : ThemeConstants.warningAmber,
                    size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill['month_year'],
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600)),
                    Text("TSh ${_formatCurrency(bill['amount_due'])}",
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14.sp)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isPaid ? "Imelipwa" : "Imelipa sehemu",
                      style: TextStyle(
                          color: isPaid
                              ? ThemeConstants.successGreen
                              : ThemeConstants.warningAmber,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                  Text("TSh ${_formatCurrency(bill['paid'])}",
                      style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    final payments = _tenantData!['payments'] as List;

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                    color: ThemeConstants.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.check,
                    color: ThemeConstants.successGreen, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment['date'],
                        style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                    Text(payment['method'],
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("TSh ${_formatCurrency(payment['amount'])}",
                      style: TextStyle(
                          color: ThemeConstants.successGreen,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  Text(payment['receipt'],
                      style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptsTab() {
    final payments = _tenantData!['payments'] as List;

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.receipt,
                    color: ThemeConstants.primaryOrange, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Receipt: ${payment['receipt']}",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)),
                    Text(payment['date'],
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white54, size: 20.sp),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(num value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}K";
    return value.toString();
  }
}
