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
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildWelcomeSection(context),
                SizedBox(height: 24.h),
                _buildStatsGrid(context, constraints),
                SizedBox(height: 24.h),
                _buildQuickActions(context),
                SizedBox(height: 24.h),
                _buildRecentProperties(context),
                SizedBox(height: 100.h), // Bottom padding
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

    // Calculate total arrears and occupancy
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      mainAxisSpacing: 16.w,
      crossAxisSpacing: 16.w,
      childAspectRatio: isTablet ? 1.5 : 1.3,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, "/rental/properties"),
          child: _buildStatCard(
            context,
            loc.translate("properties"),
            totalProperties.toString(),
            Icons.business,
            ThemeConstants.footerBarColor,
          ),
        ),
        _buildStatCard(
          context,
          loc.translate("houses"),
          totalHouses.toString(),
          Icons.home,
          ThemeConstants.successGreen,
        ),
        _buildStatCard(
          context,
          loc.translate("occupancy"),
          "${totalHouses > 0 ? ((occupiedHouses / totalHouses) * 100).toStringAsFixed(0) : 0}%",
          Icons.people,
          ThemeConstants.primaryOrange,
        ),
        _buildStatCard(
          context,
          loc.translate("arrears"),
          "Tsh ${totalArrears.toStringAsFixed(0)}",
          Icons.money_off,
          ThemeConstants.errorRed,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return ThemeConstants.buildResponsiveGlassCardStatic(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final loc = LocalizationService.instance;
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
            Expanded(
              child: _buildActionButton(
                context,
                loc.translate("add_property"),
                Icons.add_business,
                () => Navigator.pushNamed(context, "/rental/add-property"),
              ),
            ),
            SizedBox(width: 12.w),
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
        SizedBox(height: 12.h),
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
          Icon(icon, color: ThemeConstants.primaryOrange, size: 28.w),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
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
                      arguments: {'id': prop['id'].toString()},
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: ThemeConstants.footerBarColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.location_city,
                            color: ThemeConstants.footerBarColor),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prop['name'] ?? 'Unnamed Property',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              prop['location'] ?? 'No location',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
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
                          Icon(Icons.chevron_right,
                              color: Colors.white54, size: 20.w),
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
