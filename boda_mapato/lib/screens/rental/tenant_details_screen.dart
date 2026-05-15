import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import 'record_payment_screen.dart';
import 'house_details_screen.dart';
import 'property_details_screen.dart';

class TenantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tenant;
  const TenantDetailsScreen({super.key, required this.tenant});

  @override
  State<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  bool _isTerminating = false;

  Future<void> _handleTerminate() async {
    final loc = LocalizationService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.bgMid,
        title: Text(loc.translate("confirm_termination"),
            style: const TextStyle(color: Colors.white)),
        content: Text(loc.translate("termination_message"),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.translate("cancel"))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.translate("terminate"),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isTerminating = true);
      final success = await context
          .read<RentalProvider>()
          .terminateTenantAgreement(widget.tenant['id'].toString());
      if (mounted) {
        setState(() => _isTerminating = false);
        if (success) {
          ThemeConstants.showSuccessSnackBar(
              context, loc.translate("termination_success"));
          Navigator.pop(context);
        } else {
          ThemeConstants.showErrorSnackBar(
              context, loc.translate("termination_failed"));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenant;
    final loc = LocalizationService.instance;
    final house = t['house'] ?? {};
    final agreement = t['agreement'] ?? {};
    final profile = t['profile'] ?? {};

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: loc.translate("tenant_details"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildProfileHeader(t),
            SizedBox(height: 16.h),
            _buildAgreementCard(agreement, house),
            SizedBox(height: 16.h),
            _buildPersonalInfo(profile, t),
            SizedBox(height: 24.h),
            if (agreement['status'] != 'terminated')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTerminating ? null : _handleTerminate,
                  icon: const Icon(Icons.person_remove, color: Colors.white),
                  label: Text(loc.translate("terminate_agreement")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.8),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> t) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Row(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: ThemeConstants.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              image: t['photo_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(t['photo_url']), fit: BoxFit.cover)
                  : null,
            ),
            child: t['photo_url'] == null
                ? Center(
                    child: Text(t['name']?[0] ?? '?',
                        style: TextStyle(
                            color: ThemeConstants.primaryOrange,
                            fontSize: 30.sp,
                            fontWeight: FontWeight.bold)))
                : null,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['name'] ?? 'N/A',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                Text(t['phone_number'] ?? 'N/A',
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                if (t['email'] != null)
                  Text(t['email'],
                      style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
              ],
            ),
          ),
          _buildStatusBadge(t['agreement']?['status'] ?? 'active'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final loc = LocalizationService.instance;
    Color color = ThemeConstants.successGreen;
    if (status == 'notice') color = ThemeConstants.warningAmber;
    if (status == 'defaulter') color = ThemeConstants.errorRed;
    if (status == 'terminated') color = Colors.white24;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(loc.translate(status).toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAgreementCard(
      Map<String, dynamic> agreement, Map<String, dynamic> house) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description,
                  color: ThemeConstants.primaryOrange, size: 16.sp),
              SizedBox(width: 8.w),
              Text(loc.translate("rental_agreement"),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordPaymentScreen(preSelectedTenant: widget.tenant),
                  ),
                ).then((_) {
                  // Refresh tenant data if needed, or rely on global provider state
                  context.read<RentalProvider>().fetchTenants();
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(loc.translate("record_payment"),
                    style: TextStyle(color: ThemeConstants.primaryOrange, fontSize: 10.sp)),
              ),
            ],
          ),
          Divider(color: Colors.white10, height: 24.h),
          _buildClickableInfoRow(
            loc.translate("house"),
            house['house_number'] ?? '-',
            () => Navigator.pushNamed(context, '/rental/house-details',
                arguments: house).then((_) => context.read<RentalProvider>().fetchTenants()),
          ),
          _buildClickableInfoRow(
            loc.translate("property"),
            house['property_name'] ?? '-',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(
                    propertyId: house['property_id']?.toString() ?? ''),
              ),
            ).then((_) => context.read<RentalProvider>().fetchTenants()),
          ),
          _buildInfoRow(loc.translate("rent_amount"),
              "Tsh ${agreement['rent_amount'] ?? 0}"),
          _buildInfoRow(
              loc.translate("start_date"), agreement['start_date'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildClickableInfoRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
            Row(
              children: [
                Text(value,
                    style: TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 4.w),
                Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 10.sp),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(
      Map<String, dynamic> profile, Map<String, dynamic> t) {
    final loc = LocalizationService.instance;
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: ThemeConstants.primaryOrange, size: 16.sp),
              SizedBox(width: 8.w),
              Text(loc.translate("personal_info"),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Divider(color: Colors.white10, height: 24.h),
          _buildInfoRow(loc.translate("nida_id"), profile['nida'] ?? '-'),
          _buildInfoRow(loc.translate("gender"), profile['gender'] ?? '-'),
          _buildInfoRow(
              loc.translate("occupation"),
              profile['occupation'] ??
                  profile['employment']?['title'] ??
                  '-'),
          _buildInfoRow(loc.translate("emergency_contact"),
              profile['emergency_contact']?['name'] ?? '-'),
          _buildInfoRow(loc.translate("emergency_phone"),
              profile['emergency_contact']?['phone'] ?? '-'),
          if (profile['notes'] != null &&
              (profile['notes'] ?? '').toString().isNotEmpty)
            _buildInfoRow("Maelezo", profile['notes'].toString()),
          if (profile['photo_url'] != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Text("Picha:",
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  SizedBox(width: 8.w),
                  Icon(Icons.check_circle,
                      color: ThemeConstants.successGreen, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text("Imepakiwa",
                      style: TextStyle(
                          color: ThemeConstants.successGreen,
                          fontSize: 12.sp)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
          Flexible(
              child: Text(value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
