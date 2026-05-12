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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.white38),
                      SizedBox(height: 16.h),
                      Text("Hakuna wapangaji",
                          style: TextStyle(
                              color: Colors.white54, fontSize: 16.sp)),
                      SizedBox(height: 8.h),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, "/rental/onboard-tenant"),
                        icon: const Icon(Icons.person_add),
                        label: const Text("Ongeza Mpagaji"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    return _buildTenantCard(context, tenant);
                  },
                ),
    );
  }

  Widget _buildTenantCard(BuildContext context, Map<String, dynamic> tenant) {
    final house = tenant['house'] ?? {};
    final agreement = tenant['agreement'] ?? {};
    final status = agreement['status'] ?? 'active';

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = ThemeConstants.successGreen;
      case 'notice':
        statusColor = ThemeConstants.warningAmber;
      case 'defaulter':
        statusColor = ThemeConstants.errorRed;
      default:
        statusColor = Colors.white54;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: ThemeConstants.glassCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTenantDetails(context, tenant),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor:
                      ThemeConstants.primaryOrange.withOpacity(0.2),
                  child: Text(
                    (tenant['name'] ?? '').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp),
                  ),
                ),
                SizedBox(width: 12.w),
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
                      ),
                      Text(
                        tenant['phone_number'] ?? '',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12.sp),
                      ),
                      Text(
                        "Nyumba: ${house['house_number'] ?? ''}",
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTenantDetails(BuildContext context, Map<String, dynamic> tenant) {
    final house = tenant['house'] ?? {};
    final agreement = tenant['agreement'] ?? {};
    final profile = tenant['profile'];

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
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor:
                      ThemeConstants.primaryOrange.withOpacity(0.2),
                  child: Text(
                    (tenant['name'] ?? '').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant['name'] ?? '',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold)),
                    Text(tenant['phone_number'] ?? '',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14.sp)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildDetailRow("Nyumba", house['house_number'] ?? '-'),
            _buildDetailRow("Mali", house['property_name'] ?? '-'),
            _buildDetailRow("Kodi", "TSh ${agreement['rent_amount'] ?? 0}"),
            _buildDetailRow("Kipindi", agreement['rent_cycle'] ?? 'monthly'),
            _buildDetailRow("Kuanzia", agreement['start_date'] ?? '-'),
            if (profile != null) ...[
              if (profile['id_number'] != null)
                _buildDetailRow("NIDA", profile['id_number']),
              if (profile['occupation'] != null)
                _buildDetailRow("Kazi", profile['occupation']),
            ],
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
}
