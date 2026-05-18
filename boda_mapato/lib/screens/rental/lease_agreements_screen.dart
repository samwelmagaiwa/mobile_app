import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/localization_service.dart';
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
    final provider = context.read<RentalProvider>();
    await Future.wait([
      provider.fetchTenants(),
      provider.fetchAgreements(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final agreements = rentalProvider.agreements;
    final loc = LocalizationService.instance;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: loc.translate('lease_agreements'),
      actions: [
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, "/rental/create-agreement")),
      ],
      body: Column(
        children: [
          _buildSummaryStats(agreements),
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
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
              tabs: [
                Tab(text: loc.translate('active_leases')),
                Tab(text: loc.translate('expiring_leases')),
                Tab(text: loc.translate('all_leases'))
              ],
            ),
          ),
          Expanded(
              child: TabBarView(controller: _tabController, children: [
            _buildAgreementList(agreements.where((a) => a['status'] == 'active').toList()),
            _buildAgreementList(agreements.where((a) => a['status'] == 'expiring_soon' || a['status'] == 'notice').toList()),
            _buildAgreementList(agreements),
          ])),
        ],
      ),
    );
  }

  Widget _buildAgreementList(List<dynamic> list) {
    final loc = LocalizationService.instance;
    return _isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : list.isEmpty 
        ? Center(child: Text(loc.translate('no_leases_found'), style: TextStyle(color: Colors.white54, fontSize: 14.sp)))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: list.length,
              itemBuilder: (_, i) => _buildAgreementCard(list[i]),
            ),
          );
  }

  Widget _buildSummaryStats(List<dynamic> agreements) {
    final active = agreements.where((a) => a['status'] == 'active').length;
    final expired = agreements.where((a) => a['status'] == 'expired').length;
    final expiring = agreements
        .where((a) => a['status'] == 'expiring_soon' || a['status'] == 'notice')
        .length;

    final loc = LocalizationService.instance;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(children: [
        _miniStat(loc.translate("active"), active.toString(), ThemeConstants.successGreen),
        Container(width: 1, height: 30.h, color: Colors.white12),
        _miniStat(loc.translate("expiring"), expiring.toString(), ThemeConstants.warningAmber),
        Container(width: 1, height: 30.h, color: Colors.white12),
        _miniStat(loc.translate("expired"), expired.toString(), ThemeConstants.errorRed),
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
    final loc = LocalizationService.instance;
    
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
        statusLabel = loc.translate('active');
        break;
      case 'expiring_soon':
        statusColor = ThemeConstants.warningAmber;
        statusLabel = loc.translate('expiring');
        break;
      case 'expired':
        statusColor = ThemeConstants.errorRed;
        statusLabel = loc.translate('expired');
        break;
      default:
        statusColor = Colors.white54;
        statusLabel = status;
    }

    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '-';
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        return dateStr.split('T')[0];
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ThemeConstants.buildResponsiveGlassCard(
        context,
        onTap: () => Navigator.pushNamed(context, "/rental/lease-details",
            arguments: agreement),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        statusColor.withOpacity(0.3),
                        statusColor.withOpacity(0.1)
                      ]),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
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
                          agreement['tenant']?['name'] ?? 
                          loc.translate('tenant'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "${loc.translate('house')} ${agreement['house_number'] ?? ''}",
                          style: TextStyle(
                              color: Colors.white60, fontSize: 13.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r)),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Divider(color: Colors.white.withOpacity(0.05), height: 1),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _infoChip(
                        Icons.calendar_today,
                        formatDate(agreement['start_date']),
                        Colors.white54),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _infoChip(
                        Icons.event,
                        formatDate(agreement['end_date']),
                        status == 'expired'
                            ? ThemeConstants.errorRed
                            : status == 'expiring_soon'
                                ? ThemeConstants.warningAmber
                                : Colors.white54),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _infoChip(
                        Icons.monetization_on,
                        "TZS ${_fmt(agreement['rent_amount'] ?? 0)}",
                        ThemeConstants.successGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.12))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13.sp, color: color),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 10.sp, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  String _fmt(dynamic val) {
    final num v = num.tryParse(val.toString()) ?? 0;
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}K";
    return v.toString();
  }
}
