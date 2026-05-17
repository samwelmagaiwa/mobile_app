import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class LeaseAgreementsScreen extends StatefulWidget {
  const LeaseAgreementsScreen({super.key});

  @override
  State<LeaseAgreementsScreen> createState() => _LeaseAgreementsScreenState();
}

class _LeaseAgreementsScreenState extends State<LeaseAgreementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _agreements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<RentalProvider>().fetchTenants();
    // In production, fetch from dedicated agreements endpoint
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Mikataba",
      actions: [
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, "/rental/create-agreement")),
      ],
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                  color: ThemeConstants.primaryOrange,
                  borderRadius: BorderRadius.circular(12.r)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Expiring"),
                Tab(text: "Mikataba")
              ],
            ),
          ),
          Expanded(
              child: TabBarView(controller: _tabController, children: [
            _buildActiveTab(),
            _buildExpiringTab(),
            _buildAllTab(),
          ])),
        ],
      ),
    );
  }

  Widget _buildActiveTab() => _isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: _mockActiveAgreements().length,
          itemBuilder: (_, i) =>
              _buildAgreementCard(_mockActiveAgreements()[i]));

  Widget _buildExpiringTab() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                  color: ThemeConstants.warningAmber.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Icon(Icons.event_note,
                  size: 48.sp, color: ThemeConstants.warningAmber)),
          SizedBox(height: 16.h),
          Text("Hakuna mikataba inayoisha",
              style: TextStyle(color: Colors.white54, fontSize: 16.sp)),
        ]),
      );

  Widget _buildAllTab() => _isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _mockAllAgreements().length + 1,
            itemBuilder: (_, i) => i == 0
                ? _buildStatsHeader()
                : _buildAgreementCard(_mockAllAgreements()[i - 1]),
          ),
        );

  Widget _buildStatsHeader() {
    final active =
        _mockAllAgreements().where((a) => a['status'] == 'active').length;
    final expired =
        _mockAllAgreements().where((a) => a['status'] == 'expired').length;
    final expiring = _mockAllAgreements()
        .where((a) => a['status'] == 'expiring_soon')
        .length;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r)),
      child: Row(children: [
        _miniStat("Active", active.toString(), ThemeConstants.successGreen),
        Container(width: 1, height: 30.h, color: Colors.white12),
        _miniStat("Expiring", expiring.toString(), ThemeConstants.warningAmber),
        Container(width: 1, height: 30.h, color: Colors.white12),
        _miniStat("Expired", expired.toString(), ThemeConstants.errorRed),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
          child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
      ]));

  Widget _buildAgreementCard(Map<String, dynamic> agreement) {
    final status = agreement['status'] ?? 'active';
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
        statusLabel = 'Active';
      case 'expiring_soon':
        statusColor = ThemeConstants.warningAmber;
        statusLabel = 'Expiring';
      case 'expired':
        statusColor = ThemeConstants.errorRed;
        statusLabel = 'Expired';
      default:
        statusColor = Colors.white54;
        statusLabel = status;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, "/rental/agreement-details",
              arguments: agreement),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          statusColor.withOpacity(0.3),
                          statusColor.withOpacity(0.1)
                        ]),
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Icon(Icons.description,
                        color: statusColor, size: 24.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              agreement['tenant_name'] ??
                                  agreement['house_number'] ??
                                  '',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                              "${agreement['house_number'] ?? ''} - ${agreement['property_name'] ?? ''}",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r)),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _infoChip(
                        Icons.calendar_today,
                        "Start: ${agreement['start_date'] ?? '-'}",
                        Colors.white54),
                    SizedBox(width: 8.w),
                    _infoChip(
                        Icons.event,
                        "End: ${agreement['end_date'] ?? '-'}",
                        status == 'expired'
                            ? ThemeConstants.errorRed
                            : status == 'expiring_soon'
                                ? ThemeConstants.warningAmber
                                : Colors.white54),
                    SizedBox(width: 8.w),
                    _infoChip(
                        Icons.monetization_on,
                        "TSh ${_fmt(agreement['rent_amount'] ?? 0)}",
                        ThemeConstants.successGreen),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12.sp, color: color),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(color: color, fontSize: 10.sp)),
      ]),
    );
  }

  String _fmt(num v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}K";
    return v.toString();
  }

  List<Map<String, dynamic>> _mockActiveAgreements() => [
        {
          'tenant_name': 'John Mkomagi',
          'house_number': 'A-101',
          'property_name': 'Mikocheni',
          'rent_amount': 300000,
          'start_date': '01-01-2026',
          'end_date': '31-12-2026',
          'status': 'active',
          'cycle': 'monthly'
        },
        {
          'tenant_name': 'Anna Mwita',
          'house_number': 'B-202',
          'property_name': 'Mikocheni',
          'rent_amount': 250000,
          'start_date': '01-03-2026',
          'end_date': '28-02-2027',
          'status': 'active',
          'cycle': 'monthly'
        },
        {
          'tenant_name': 'Peter Juma',
          'house_number': 'C-303',
          'property_name': 'Posta',
          'rent_amount': 500000,
          'start_date': '15-02-2026',
          'end_date': '14-08-2026',
          'status': 'expiring_soon',
          'cycle': 'monthly'
        },
        {
          'tenant_name': 'Mariam Juma',
          'house_number': 'D-404',
          'property_name': 'Upanga',
          'rent_amount': 350000,
          'start_date': '01-05-2025',
          'end_date': '30-04-2026',
          'status': 'expired',
          'cycle': 'monthly'
        },
      ];

  List<Map<String, dynamic>> _mockAllAgreements() => _mockActiveAgreements();
}
