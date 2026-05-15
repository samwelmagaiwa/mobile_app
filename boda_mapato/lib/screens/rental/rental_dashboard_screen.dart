import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/service_switcher_dialog.dart';

class RentalDashboardScreen extends StatefulWidget {
  final bool isSubView;
  const RentalDashboardScreen({super.key, this.isSubView = false});

  @override
  State<RentalDashboardScreen> createState() => _RentalDashboardScreenState();
}

class _RentalDashboardScreenState extends State<RentalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                _buildWelcomeSection(context),
                SizedBox(height: 24.h),
                _buildStatsGrid(context, constraints),
                SizedBox(height: 30.h),
                _buildQuickActions(context),
                SizedBox(height: 30.h),
                _buildRecentProperties(context),
                SizedBox(height: 120.h), // Bottom padding
              ],
            ),
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
            LocalizationService.instance.translate("rental_dashboard"),
            style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: LocalizationService.instance.translate("rental_dashboard"),
      body: content,
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final loc = LocalizationService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${loc.translate('welcome')}, ${user?.name ?? loc.translate('welcome_landlord')}",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        Text(
          loc.translate("select_service_subtitle"),
          style: ThemeConstants.responsiveCaptionStyle(context),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, BoxConstraints constraints) {
    final rentalProvider = context.watch<RentalProvider>();
    final properties = rentalProvider.properties;
    final totalProperties = properties.length;

    double totalArrears = 0;
    int totalHouses = 0;
    int occupiedHouses = 0;

    for (var prop in properties) {
      final houses = prop['houses'] as List? ?? [];
      totalHouses += houses.length;
      for (var house in houses) {
        if (house['is_occupied'] == 1 || house['is_occupied'] == true) {
          occupiedHouses++;
        }
        totalArrears += (house['current_balance'] ?? 0).toDouble();
      }
    }

    final loc = LocalizationService.instance;
    final isTablet = constraints.maxWidth >= 600;
    final user = context.watch<AuthProvider>().user;
    final bool canViewProperties = user?.hasPermission('manage_properties_rental') ?? false;
    final bool canViewArrears = user?.hasPermission('manage_debts_transport') ?? false;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      mainAxisSpacing: 12.w,
      crossAxisSpacing: 12.w,
      childAspectRatio: isTablet ? 1.5 : 1.45,
      children: [
        if (canViewProperties)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/rental/properties"),
            child: _buildStatCard(
              context,
              loc.translate("properties"),
              totalProperties.toString(),
              Icons.business_outlined,
              ThemeConstants.footerBarColor,
            ),
          ),
        if (canViewProperties)
          _buildStatCard(
            context,
            loc.translate("houses"),
            totalHouses.toString(),
            Icons.home_outlined,
            ThemeConstants.successGreen,
          ),
        if (canViewProperties)
          _buildStatCard(
            context,
            loc.translate("occupancy"),
            "${totalHouses > 0 ? ((occupiedHouses / totalHouses) * 100).toStringAsFixed(0) : 0}%",
            Icons.people_outline,
            ThemeConstants.primaryOrange,
          ),
        if (canViewArrears)
          _buildStatCard(
            context,
            loc.translate("arrears"),
            "Tsh ${_formatArrears(totalArrears)}",
            Icons.money_off_csred_outlined,
            ThemeConstants.errorRed,
          ),
      ],
    );
  }

  String _formatArrears(double value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}K";
    return value.toStringAsFixed(0);
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final loc = LocalizationService.instance;
    final user = context.watch<AuthProvider>().user;
    final bool canAddProperty = user?.hasPermission('manage_properties_rental') ?? false;
    final bool canViewBills = user?.hasPermission('manage_billing_rental') ?? false;
    final bool canOnboardTenant = user?.hasPermission('onboard_tenants_rental') ?? false;

    if (!canAddProperty && !canViewBills && !canOnboardTenant) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate("quick_actions"),
          style: ThemeConstants.responsiveSubHeadingStyle(context),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            if (canAddProperty)
              Expanded(
                child: _buildActionButton(
                  context,
                  loc.translate("add_property"),
                  Icons.add_business,
                  () => Navigator.pushNamed(context, "/rental/add-property"),
                ),
              ),
            if (canAddProperty && canViewBills) SizedBox(width: 12.w),
            if (canViewBills)
              Expanded(
                child: _buildActionButton(
                  context,
                  loc.translate("view_bills"),
                  Icons.receipt_long,
                  () => Navigator.pushNamed(context, "/rental/billing"),
                ),
              ),
          ],
        ),
        if (canOnboardTenant) SizedBox(height: 12.h),
        if (canOnboardTenant)
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              context,
              loc.translate("onboard_tenant"),
              Icons.person_add,
              () => Navigator.pushNamed(context, "/rental/onboard-tenant"),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ThemeConstants.buildResponsiveGlassCard(
      context,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: ThemeConstants.primaryOrange, size: 24.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProperties(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final properties = rentalProvider.properties;

    final loc = LocalizationService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.translate("my_properties"),
              style: ThemeConstants.responsiveSubHeadingStyle(context),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/rental/properties"),
              child: Text(loc.translate("see_all"),
                  style: const TextStyle(color: ThemeConstants.footerBarColor)),
            ),
          ],
        ),
        if (rentalProvider.isLoading && properties.isEmpty)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (properties.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Text(loc.translate("no_properties_found"),
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final prop = properties[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ThemeConstants.buildResponsiveGlassCard(
                  context,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      "/rental/property-details",
                      arguments: prop['id'].toString(), // Simplified arguments consistency
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: ThemeConstants.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.business_outlined, color: ThemeConstants.primaryOrange, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prop['name'] ?? 'Unnamed Property',
                              style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 15.sp),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12.sp, color: Colors.white54),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    prop['full_address'] ?? prop['location'] ?? 'No location',
                                    style: ThemeConstants.captionStyle.copyWith(fontSize: 11.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${(prop['houses'] as List? ?? []).length} ${loc.translate('houses')}",
                            style: TextStyle(
                              color: ThemeConstants.primaryOrange,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12.sp),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
