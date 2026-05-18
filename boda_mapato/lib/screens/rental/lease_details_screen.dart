import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../constants/theme_constants.dart';
import '../../services/localization_service.dart';

class LeaseDetailsScreen extends StatefulWidget {
  const LeaseDetailsScreen({super.key, this.agreement});
  final Map<String, dynamic>? agreement;

  @override
  State<LeaseDetailsScreen> createState() => _LeaseDetailsScreenState();
}

class _LeaseDetailsScreenState extends State<LeaseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _agreement;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _agreement = widget.agreement ?? {};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: loc.translate("lease_details"),
      body: Column(children: [
        _buildHeader(),
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
            tabs: [
              Tab(text: loc.translate("details")),
              Tab(text: loc.translate("documents")),
              Tab(text: loc.translate("payments"))
            ],
          ),
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          _buildDetailsTab(),
          _buildDocumentsTab(),
          _buildPaymentsTab(),
        ])),
      ]),
    );
  }

  Widget _buildHeader() {
    final loc = LocalizationService.instance;
    final status = _agreement['status'] ?? 'active';
    Color c;
    String l;
    switch (status) {
      case 'active':
        c = ThemeConstants.successGreen;
        l = loc.translate('active');
        break;
      case 'expiring_soon':
        c = ThemeConstants.warningAmber;
        l = loc.translate('expiring_soon');
        break;
      case 'expired':
        c = ThemeConstants.errorRed;
        l = loc.translate('expired');
        break;
      default:
        c = Colors.white54;
        l = status;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          ThemeConstants.primaryOrange.withOpacity(0.2),
          ThemeConstants.primaryOrange.withOpacity(0.05)
        ]),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
              color: ThemeConstants.primaryOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r)),
          child: Icon(Icons.description,
              color: ThemeConstants.primaryOrange, size: 32.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_agreement['tenant_name'] ?? loc.translate('not_available'),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold)),
          Text(_agreement['house_number'] ?? '',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
        ])),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r)),
          child: Text(l,
              style: TextStyle(
                  color: c, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildDetailsTab() {
    final loc = LocalizationService.instance;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(children: [
        _card(loc.translate("lease_agreement"), [
          _rw(loc.translate("house"), _agreement['house_number'] ?? '-'),
          _rw(loc.translate("property"), _agreement['property_name'] ?? '-'),
          _rw(loc.translate("rent"), "TSh ${_fmt(_agreement['rent_amount'] ?? 0)}"),
          _rw(loc.translate('deposit'), "TSh ${_fmt(_agreement['deposit_amount'] ?? 0)}"),
          _rw(
              loc.translate("billing_cycle"),
              loc.translate(_agreement['cycle'] ?? 'monthly')),
          _rw(loc.translate("status"), loc.translate(_agreement['status'] ?? 'active').toUpperCase()),
        ]),
        SizedBox(height: 16.h),
        _card(loc.translate("lease_terms"), [
          _rw(loc.translate("notice_period"), "${_agreement['notice_period_days'] ?? 30} ${loc.translate('days')}"),
          _rw(loc.translate("penalty_per_day"), "TSh ${_fmt(_agreement['penalty_per_day'] ?? 0)}"),
          _rw(loc.translate("auto_renew"), (_agreement['auto_renew'] == 1 || _agreement['auto_renew'] == true) ? loc.translate("yes") : loc.translate("no")),
          if (_agreement['renewal_date'] != null)
            _rw(loc.translate("renewal_date"), _formatDate(_agreement['renewal_date'].toString())),
          if (_agreement['notes'] != null && (_agreement['notes'] ?? '').isNotEmpty)
            _rw(loc.translate("notes"), _agreement['notes'].toString()),
        ]),
        SizedBox(height: 16.h),
        _card(loc.translate("dates"), [
          _rw(loc.translate("start_date"), _formatDate(_agreement['start_date'])),
          _rw(loc.translate("end_date"), _formatDate(_agreement['end_date'])),
        ]),
        SizedBox(height: 24.h),
        if (_agreement['status'] == 'expiring_soon')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(loc.translate("renew_lease")),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r))),
            ),
          ),
        if (_agreement['status'] == 'active')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.warning, color: ThemeConstants.warningAmber),
              label: Text(loc.translate("terminate_early"),
                  style: const TextStyle(color: ThemeConstants.warningAmber)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ThemeConstants.warningAmber),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r))),
            ),
          ),
      ]),
    );
  }

  Widget _buildDocumentsTab() {
    final loc = LocalizationService.instance;
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _docTile(Icons.picture_as_pdf, loc.translate("contract_signed"), "2.3 MB",
            "${loc.translate('uploaded')} 12-05-2026"),
        _docTile(
            Icons.image, loc.translate("tenant_id_card"), "0.5 MB", "${loc.translate('uploaded')} 12-05-2026"),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file, color: Colors.white70),
            label: Text(loc.translate("upload_document")),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r))),
          ),
        ),
      ],
    );
  }

  Widget _docTile(IconData ic, String title, String size, String date) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Row(children: [
        Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
                color: ThemeConstants.errorRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.picture_as_pdf,
                color: ThemeConstants.errorRed, size: 24.sp)),
        SizedBox(width: 14.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600)),
          Text("$size • $date",
              style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
        ])),
        IconButton(
            icon: const Icon(Icons.download, color: Colors.white54),
            onPressed: () {}),
      ]),
    );
  }

  Widget _buildPaymentsTab() {
    final loc = LocalizationService.instance;
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.payment, size: 48.sp, color: Colors.white24),
      SizedBox(height: 16.h),
      Text(loc.translate("payments_will_appear_here"),
          style: TextStyle(color: Colors.white54, fontSize: 16.sp)),
    ]));
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 12.h),
        ...children,
      ]),
    );
  }

  Widget _rw(String l, String v) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          Text(v,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  String _fmt(dynamic val) {
    final num v = num.tryParse(val.toString()) ?? 0;
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(0)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}K";
    return v.toInt().toString();
  }
}
