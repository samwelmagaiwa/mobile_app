import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';

class RentalTenantsScreen extends StatefulWidget {
  const RentalTenantsScreen({super.key});

  @override
  State<RentalTenantsScreen> createState() => _RentalTenantsScreenState();
}

class _RentalTenantsScreenState extends State<RentalTenantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final tenants = rentalProvider.tenants;

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Wapangaji",
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add, color: Colors.white),
          onPressed: () =>
              Navigator.pushNamed(context, "/rental/onboard-tenant"),
        ),
      ],
      body: rentalProvider.isLoading && tenants.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : tenants.isEmpty
              ? _buildEmptyState()
              : _buildTenantList(tenants),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.people_outline, size: 64.sp, color: Colors.white38),
          ),
          SizedBox(height: 24.h),
          Text("Hakuna wapangaji",
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          Text("M Registered tenants will appear here",
              style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, "/rental/onboard-tenant"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryOrange,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text("Ongeza Mpagaji",
                style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantList(List tenants) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final tenant = tenants[index] as Map<String, dynamic>;
        return _buildTenantCard(tenant);
      },
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final house = tenant['house'] ?? {};
    final agreement = tenant['agreement'] ?? {};
    final status = agreement['status'] ?? 'active';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
        statusLabel = 'Mstaafu';
      case 'notice':
        statusColor = ThemeConstants.warningAmber;
        statusLabel = 'Notisi';
      case 'defaulter':
        statusColor = ThemeConstants.errorRed;
        statusLabel = 'Mhalifu';
      case 'terminated':
        statusColor = Colors.white38;
        statusLabel = 'Ameondoka';
      default:
        statusColor = Colors.white54;
        statusLabel = status.toString();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTenantDetails(tenant),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeConstants.primaryOrange.withOpacity(0.3),
                        ThemeConstants.primaryOrange.withOpacity(0.1)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    (tenant['name'] ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['name'] ?? '',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12.sp, color: Colors.white54),
                          SizedBox(width: 4.w),
                          Text(tenant['phone_number'] ?? '',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12.sp)),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.home, size: 12.sp, color: Colors.white38),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              "${house['house_number'] ?? ''} - ${house['property_name'] ?? ''}",
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTenantDetails(Map<String, dynamic> tenant) {
    final house = tenant['house'] ?? {};
    final agreement = tenant['agreement'] ?? {};
    final profile = tenant['profile'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeConstants.primaryBlue,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color:
                                ThemeConstants.primaryOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            (tenant['name'] ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                                color: ThemeConstants.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 32.sp),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tenant['name'] ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.h),
                              Text(tenant['phone_number'] ?? '',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14.sp)),
                              if (tenant['email'] != null) ...[
                                SizedBox(height: 2.h),
                                Text(tenant['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12.sp)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionTitle("Taarifa ya Nyumba"),
                    _buildDetailRow("Nyumba", house['house_number'] ?? '-'),
                    _buildDetailRow("Mali", house['property_name'] ?? '-'),
                    _buildDetailRow("Block", house['block_name'] ?? '-'),
                    SizedBox(height: 16.h),
                    _buildSectionTitle("Mkataba"),
                    _buildDetailRow("Kodi",
                        "TSh ${_formatCurrency((agreement['rent_amount'] ?? 0).toDouble())}"),
                    _buildDetailRow("Kipindi",
                        _formatRentCycle(agreement['rent_cycle'] ?? 'monthly')),
                    _buildDetailRow("Kuanzia", agreement['start_date'] ?? '-'),
                    _buildDetailRow(
                        "Muishio", agreement['end_date'] ?? 'Hajawahi'),
                    _buildDetailRow("Status",
                        _formatStatus(agreement['status'] ?? 'active')),
                    if (profile != null) ...[
                      SizedBox(height: 16.h),
                      _buildSectionTitle("Taarifa za Ziada"),
                      if (profile['id_number'] != null)
                        _buildDetailRow("NIDA", profile['id_number']),
                      if (profile['occupation'] != null)
                        _buildDetailRow("Kazi", profile['occupation']),
                      if (profile['emergency_contact_name'] != null)
                        _buildDetailRow(
                            "Mawasiliano", profile['emergency_contact_name']),
                      if (profile['emergency_contact_phone'] != null)
                        _buildDetailRow(
                            "Simu", profile['emergency_contact_phone']),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(title,
          style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}K";
    return value.toStringAsFixed(0);
  }

  String _formatRentCycle(String cycle) {
    switch (cycle) {
      case 'monthly':
        return 'Mwezi';
      case 'quarterly':
        return 'Robo Mwaka';
      case 'semi_annual':
        return 'Miwaka 6';
      case 'annual':
        return 'Mwaka';
      default:
        return cycle;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'active':
        return 'Mstaafu';
      case 'notice':
        return 'Notisi';
      case 'defaulter':
        return 'Mhalifu';
      case 'terminated':
        return 'Ameondoka';
      default:
        return status;
    }
  }
}
