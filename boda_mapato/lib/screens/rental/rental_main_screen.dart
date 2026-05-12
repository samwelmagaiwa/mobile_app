import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/service_switcher_dialog.dart';
import '../../services/navigation_builder.dart';
import 'rental_dashboard_screen.dart';
import 'billing_list_screen.dart';
import 'onboard_tenant_screen.dart';
import '../../config/navigation_config.dart';

class RentalMainScreen extends StatefulWidget {
  const RentalMainScreen({super.key});

  @override
  State<RentalMainScreen> createState() => _RentalMainScreenState();
}

class _RentalMainScreenState extends State<RentalMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const RentalDashboardScreen(isSubView: true),
    const BillingListScreen(isSubView: true),
    // Placeholder for Arrears/Debts
    const Center(child: Text("Arrears Tracking Coming Soon", style: TextStyle(color: Colors.white))),
    // Placeholder for Tenants List
    const Center(child: Text("Tenants List Coming Soon", style: TextStyle(color: Colors.white))),
    // Placeholder for Receipts List
    const Center(child: Text("Rent Receipts Coming Soon", style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = LocalizationService.instance;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildRentalDrawer(context, localizationService),
      body: Stack(
        children: [
          // Background - use shared ThemeConstants gradient
          const DecoratedBox(
            decoration: ThemeConstants.dashboardBackground,
            child: SizedBox.expand(),
          ),
          // Content
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildRentalFooter(context),
          ),
        ],
      ),
    );
  }

  /// Footer styled exactly like Transport module
  Widget _buildRentalFooter(BuildContext context) {
    return ColoredBox(
      color: ThemeConstants.footerBarColor,
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: ThemeConstants.footerBarColor,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Left side: Rent Payments, Arrears
                Row(
                  children: <Widget>[
                    _FooterIcon(
                      icon: Icons.payments_outlined,
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onItemTapped(1),
                    ),
                    SizedBox(width: 14.w),
                    _FooterIcon(
                      icon: Icons.pending_actions,
                      isSelected: _selectedIndex == 2,
                      onTap: () => _onItemTapped(2),
                    ),
                  ],
                ),
                // Center: Menu
                _FooterIcon(
                  icon: Icons.apps,
                  isCenter: true,
                  onTap: () => NavigationBuilder.showGridMenu(context, customItems: [
                    ...NavigationConfig.rentalDrawerItems,
                    ...NavigationConfig.systemItems,
                  ]),
                ),
                // Right side: Tenants, Receipts
                Row(
                  children: <Widget>[
                    _FooterIcon(
                      icon: Icons.people_alt_outlined,
                      isSelected: _selectedIndex == 3,
                      onTap: () => _onItemTapped(3),
                    ),
                    SizedBox(width: 14.w),
                    _FooterIcon(
                      icon: Icons.receipt_long_outlined,
                      isSelected: _selectedIndex == 4,
                      onTap: () => _onItemTapped(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRentalDrawer(BuildContext context, LocalizationService loc) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Drawer(
      backgroundColor: ThemeConstants.bgTop,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: ThemeConstants.cardColor,
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? "L",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? "Landlord",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "landlord@mapato.com",
                    style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
                for (final item in NavigationConfig.rentalDrawerItems)
                  _DrawerItem(
                    icon: item.icon,
                    label: LocalizationService.instance.translate(item.key),
                    onTap: () {
                      if (item.key == 'rental_dashboard') {
                        _onItemTapped(0);
                      } else if (item.key == 'rent_payments') {
                        _onItemTapped(1);
                      } else if (item.key == 'arrears') {
                        _onItemTapped(2);
                      } else if (item.key == 'tenants') {
                        _onItemTapped(3);
                      } else if (item.key == 'properties') {
                        // For now map to dashboard or subview if we had one
                        _onItemTapped(0);
                      } else if (item.key == 'switch_service') {
                        showDialog(
                          context: context,
                          builder: (context) => const ServiceSwitcherDialog(),
                        );
                      } else {
                        Navigator.pushNamed(context, item.route);
                      }
                    },
                  ),
          const Divider(color: Colors.white10),
          _DrawerItem(
            icon: Icons.logout,
            label: "Logout",
            color: ThemeConstants.errorRed,
            onTap: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, "/");
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;

  const _FooterIcon({
    required this.icon,
    this.isSelected = false,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isCenter 
        ? ThemeConstants.primaryOrange 
        : (isSelected ? ThemeConstants.primaryOrange.withOpacity(0.5) : ThemeConstants.primaryBlue.withOpacity(0.22));
    
    return InkResponse(
      onTap: onTap,
      radius: 28.r,
      child: Container(
        width: 46.w,
        height: 46.w,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: Colors.white,
          size: isCenter ? 26.sp : 22.sp,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22.w),
      title: Text(label, style: TextStyle(color: color, fontSize: 14.sp)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
