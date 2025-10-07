import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../constants/currency.dart';
import "../../models/login_response.dart";
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_utils.dart';
// import 'package:fl_chart/fl_chart.dart'; // Commented out until package is installed

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = <String, dynamic>{};
  String _selectedPage = 'dashboard';
  
  // Enhanced color scheme
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color grayBackground = Color(0xFFF8FAFC);
  static const Color darkGray = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // TODO: Replace with actual API call to Laravel backend
      // final apiService = ApiService();
      // final data = await apiService.getDashboardData();
      
      // Simulate API call with enhanced mock data
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _dashboardData = <String, dynamic>{
          'total_drivers': 24,
          'active_drivers': 18,
          'total_vehicles': 18,
          'active_vehicles': 15,
          'monthly_revenue': 2400000.0,
          'weekly_revenue': 580000.0,
          'daily_revenue': 85000.0,
          'pending_payments': 6,
          'completed_trips': 156,
          'revenue_growth': 15.2,
          'driver_growth': 12.5,
          'vehicle_utilization': 83.3,
          'recent_transactions': <Map<String, Object>>[
            <String, Object>{
              'id': '1',
              'driver_name': 'John Mukasa',
              'vehicle_number': 'UBE 123A',
              'amount': 50000.0,
              'date': DateTime.now().subtract(const Duration(hours: 2)),
              'status': 'paid',
              'type': 'daily_payment',
            },
            <String, Object>{
              'id': '2',
              'driver_name': 'Peter Ssali',
              'vehicle_number': 'UBF 456B',
              'amount': 45000.0,
              'date': DateTime.now().subtract(const Duration(hours: 6)),
              'status': 'pending',
              'type': 'daily_payment',
            },
            <String, Object>{
              'id': '3',
              'driver_name': 'Mary Nakato',
              'vehicle_number': 'UBG 789C',
              'amount': 55000.0,
              'date': DateTime.now().subtract(const Duration(days: 1)),
              'status': 'paid',
              'type': 'weekly_payment',
            },
          ],
          'revenue_chart_data': <Map<String, Object>>[
            <String, Object>{'day': 'Mon', 'amount': 75000},
            <String, Object>{'day': 'Tue', 'amount': 82000},
            <String, Object>{'day': 'Wed', 'amount': 68000},
            <String, Object>{'day': 'Thu', 'amount': 91000},
            <String, Object>{'day': 'Fri', 'amount': 85000},
            <String, Object>{'day': 'Sat', 'amount': 95000},
            <String, Object>{'day': 'Sun', 'amount': 78000},
          ],
        };
        
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Hitilafu katika kupakia data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(final String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(message),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(final BuildContext context) => ResponsiveScaffold(
      backgroundColor: grayBackground,
      padding: EdgeInsets.zero,
      body: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: _buildNavigationDrawer(),
        body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      ),
    );

  Widget _buildLoadingScreen() => DecoratedBox(
      decoration: const BoxDecoration(
        color: primaryBlue,
      ),
      child: Center(
        child: ResponsiveColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 24),
          children: <Widget>[
            SizedBox(
              width: ResponsiveUtils.getResponsiveIconSize(context, 40),
              height: ResponsiveUtils.getResponsiveIconSize(context, 40),
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.w,
              ),
            ),
            Text(
              "Inapakia Dashboard...",
              style: AppStyles.bodyLarge(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildNavigationDrawer() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final logoSize = ResponsiveUtils.getResponsiveIconSize(context, 80);
    
    return Drawer(
      width: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 280.w,
        tablet: 320.w,
        desktop: 360.w,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: primaryBlue,
        ),
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.getResponsiveSpacing(context, 16),
                ResponsiveUtils.getResponsiveSpacing(context, 60),
                ResponsiveUtils.getResponsiveSpacing(context, 16),
                ResponsiveUtils.getResponsiveSpacing(context, 20),
              ),
              child: ResponsiveColumn(
                spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
                children: <Widget>[
                  // Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(logoSize / 2),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.3),
                          blurRadius: ResponsiveUtils.getResponsiveSpacing(context, 20),
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.motorcycle,
                      color: Colors.white,
                      size: ResponsiveUtils.getResponsiveIconSize(context, 40),
                    ),
                  ),
                  Text(
                    'Boda Mapato',
                    style: AppStyles.heading2(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                      ),
                    ),
                    child: Text(
                      user?.name ?? 'Admin User',
                      style: AppStyles.bodyMedium(context).copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                ),
                children: <Widget>[
                  _buildNavItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    page: 'dashboard',
                    isSelected: _selectedPage == 'dashboard',
                  ),
                  _buildNavItem(
                    icon: Icons.people,
                    title: 'Madereva',
                    page: 'drivers',
                    badge: '${_dashboardData['total_drivers'] ?? 0}',
                  ),
                  _buildNavItem(
                    icon: Icons.directions_car,
                    title: 'Magari',
                    page: 'vehicles',
                    badge: '${_dashboardData['total_vehicles'] ?? 0}',
                  ),
                  _buildNavItem(
                    icon: Icons.devices,
                    title: 'Vifaa',
                    page: 'devices',
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildNavItem(
                    icon: Icons.payment,
                    title: 'Malipo',
                    page: 'payments',
                    badge: '${_dashboardData['pending_payments'] ?? 0}',
                  ),
                  _buildNavItem(
                    icon: Icons.receipt_long,
                    title: 'Risiti',
                    page: 'receipts',
                  ),
                  _buildNavItem(
                    icon: Icons.swap_horiz,
                    title: 'Miamala',
                    page: 'transactions',
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildNavItem(
                    icon: Icons.analytics,
                    title: 'Ripoti',
                    page: 'reports',
                  ),
                  _buildNavItem(
                    icon: Icons.trending_up,
                    title: 'Uchambuzi',
                    page: 'analytics',
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildNavItem(
                    icon: Icons.notifications,
                    title: 'Mikumbuzi',
                    page: 'reminders',
                  ),
                  _buildNavItem(
                    icon: Icons.settings,
                    title: 'Mipangilio',
                    page: 'settings',
                  ),
                ],
              ),
            ),
            
            // Logout Button
            Container(
              padding: ResponsiveUtils.getResponsiveCardPadding(context),
              child: CustomButton(
                text: 'Toka',
                icon: Icons.logout,
                backgroundColor: errorRed,
                onPressed: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required final IconData icon,
    required final String title,
    required final String page,
    final String? badge,
    final bool isSelected = false,
  }) => Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getResponsiveSpacing(context, 2),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryOrange : Colors.white70,
          size: ResponsiveUtils.getResponsiveIconSize(context, 24),
        ),
        title: Text(
          title,
          style: AppStyles.bodyMedium(context).copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: badge != null
            ? Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                  vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
                ),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                  ),
                ),
                child: Text(
                  badge,
                  style: AppStyles.bodySmall(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: primaryOrange.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 12),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedPage = page;
          });
          Navigator.pop(context);
          _navigateToPage(page);
        },
      ),
    );

  Widget _buildMainContent() => FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: <Widget>[
          _buildTopAppBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: primaryBlue,
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: ResponsiveColumn(
                  spacing: ResponsiveUtils.getResponsiveSpacing(context, 24),
                  children: <Widget>[
                    _buildWelcomeCard(),
                    _buildStatsGrid(),
                    _buildRevenueChart(),
                    _buildQuickActions(),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildTopAppBar() => Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.getResponsiveSpacing(context, 16),
        ResponsiveUtils.getResponsiveSpacing(context, 60),
        ResponsiveUtils.getResponsiveSpacing(context, 16),
        ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 24),
          ),
          bottomRight: Radius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 24),
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: ResponsiveUtils.getResponsiveSpacing(context, 20),
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ResponsiveRow(
        spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
        children: <Widget>[
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 28),
            ),
          ),
          Expanded(
            child: Text(
              "Admin Dashboard",
              style: AppStyles.heading2(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
          ),
          IconButton(
            onPressed: _showNotifications,
            icon: Stack(
              children: <Widget>[
                Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                ),
                if ((_dashboardData["pending_payments"] ?? 0) > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSpacing(context, 12),
                      height: ResponsiveUtils.getResponsiveSpacing(context, 12),
                      decoration: const BoxDecoration(
                        color: errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildWelcomeCard() {
    final user = Provider.of<AuthProvider>(context).user;
    final iconSize = ResponsiveUtils.getResponsiveIconSize(context, 60);
    
    return CustomCard(
      child: ResponsiveContainer(
        decoration: BoxDecoration(
          color: successGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 16),
          ),
        ),
        child: ResponsiveRow(
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 20),
          children: <Widget>[
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: ResponsiveUtils.getResponsiveIconSize(context, 30),
              ),
            ),
            Expanded(
              child: ResponsiveColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
                children: <Widget>[
                  Text(
                    'Karibu, ${user?.name ?? 'Admin'}!',
                    style: AppStyles.heading3(context).copyWith(
                      color: darkGray,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'Simamia biashara yako ya boda boda kwa urahisi',
                    style: AppStyles.bodyMedium(context).copyWith(
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveBorderRadius(context, 20),
                      ),
                    ),
                    child: Text(
                      'Mapato: +${_dashboardData['revenue_growth']?.toStringAsFixed(1) ?? '0'}%',
                      style: AppStyles.bodySmall(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() => ResponsiveGridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 2,
        tablet: 3,
        desktop: 4,
      ),
      childAspectRatio: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 1.2,
        tablet: 1.1,
        desktop: 1.0,
      ),
      spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: <Widget>[
        _buildStatCard(
          title: "Madereva",
          value: '${_dashboardData['active_drivers']}/${_dashboardData['total_drivers']}',
          icon: Icons.people,
          color: primaryBlue,
          subtitle: '+${_dashboardData['driver_growth']?.toStringAsFixed(1) ?? '0'}%',
        ),
        _buildStatCard(
          title: "Magari",
          value: '${_dashboardData['active_vehicles']}/${_dashboardData['total_vehicles']}',
          icon: Icons.directions_car,
          color: primaryOrange,
          subtitle: '${_dashboardData['vehicle_utilization']?.toStringAsFixed(1) ?? '0'}% matumizi',
        ),
        _buildStatCard(
          title: "Mapato ya Mwezi",
          value: 'TSH ${_formatCurrency(_dashboardData['monthly_revenue'] ?? 0)}',
          icon: Icons.trending_up,
          color: successGreen,
          subtitle: '+${_dashboardData['revenue_growth']?.toStringAsFixed(1) ?? '0'}%',
        ),
        _buildStatCard(
          title: "Malipo Yanayosubiri",
          value: '${_dashboardData['pending_payments'] ?? 0}',
          icon: Icons.pending_actions,
          color: warningAmber,
          subtitle: "Yanahitaji uangalizi",
        ),
      ],
    );

  Widget _buildStatCard({
    required final String title,
    required final String value,
    required final IconData icon,
    required final Color color,
    final String? subtitle,
  }) {
    final iconSize = ResponsiveUtils.getResponsiveIconSize(context, 40);
    
    return CustomCard(
      child: ResponsiveContainer(
        child: ResponsiveColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
          children: <Widget>[
            ResponsiveRow(
              children: <Widget>[
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_vert,
                  color: Colors.grey[400],
                  size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                ),
              ],
            ),
            Text(
              title,
              style: AppStyles.bodySmall(context).copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppStyles.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: AppStyles.caption(context).copyWith(
                  color: Colors.black45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final chartData = _dashboardData['revenue_chart_data'] as List? ?? <dynamic>[];
    
    return CustomCard(
      child: ResponsiveContainer(
        child: ResponsiveColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 20),
          children: <Widget>[
            ResponsiveRow(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Mapato ya Wiki',
                    style: AppStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
                    vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveBorderRadius(context, 20),
                    ),
                  ),
                  child: Text(
                    'TSH ${_formatCurrency(_dashboardData['weekly_revenue'] ?? 0)}',
                    style: AppStyles.bodySmall(context).copyWith(
                      color: successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveContainerHeight(context, 200),
              child: chartData.isNotEmpty
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                        ),
                      ),
                      child: Center(
                        child: ResponsiveColumn(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
                          children: <Widget>[
                            Icon(
                              Icons.show_chart,
                              size: ResponsiveUtils.getResponsiveIconSize(context, 48),
                              color: Colors.black54,
                            ),
                            Text(
                              'Chati ya Mapato',
                              style: AppStyles.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'Itaongezwa baadaye',
                              style: AppStyles.bodySmall(context).copyWith(
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'Hakuna data ya kuchora',
                        style: AppStyles.bodyMedium(context).copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() => ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: <Widget>[
        Text(
          "Vitendo vya Haraka",
          style: AppStyles.heading4(context).copyWith(
            fontWeight: FontWeight.bold,
            color: darkGray,
          ),
        ),
        ResponsiveGridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 2,
            tablet: 3,
            desktop: 4,
          ),
          childAspectRatio: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 1.5,
            tablet: 1.3,
            desktop: 1.2,
          ),
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
          children: <Widget>[
            _buildQuickActionCard(
              title: "Rekodi Malipo",
              icon: Icons.payment,
              color: successGreen,
              onTap: () => _navigateToPage("record_payment"),
            ),
            _buildQuickActionCard(
              title: "Ongeza Dereva",
              icon: Icons.person_add,
              color: primaryBlue,
              onTap: () => _navigateToPage("add_driver"),
            ),
            _buildQuickActionCard(
              title: "Sajili Gari",
              icon: Icons.add_road,
              color: primaryOrange,
              onTap: () => _navigateToPage("add_vehicle"),
            ),
            _buildQuickActionCard(
              title: "Tengeneza Ripoti",
              icon: Icons.analytics,
              color: purpleAccent,
              onTap: () => _navigateToPage("generate_report"),
            ),
          ],
        ),
      ],
    );

  Widget _buildQuickActionCard({
    required final String title,
    required final IconData icon,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    final iconContainerSize = ResponsiveUtils.getResponsiveIconSize(context, 48);
    
    return CustomCard(
      onTap: onTap,
      child: ResponsiveContainer(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 16),
          ),
        ),
        child: ResponsiveColumn(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: ResponsiveUtils.getResponsiveSpacing(context, 12),
          children: <Widget>[
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(iconContainerSize / 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: ResponsiveUtils.getResponsiveSpacing(context, 12),
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: AppStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = _dashboardData['recent_transactions'] as List? ?? <dynamic>[];
    
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
      children: <Widget>[
        ResponsiveRow(
          children: <Widget>[
            Expanded(
              child: Text(
                'Miamala ya Hivi Karibuni',
                style: AppStyles.heading4(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToPage('transactions'),
              child: Text(
                'Ona Zote',
                style: AppStyles.bodyMedium(context).copyWith(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        CustomCard(
          child: Column(
            children: transactions.map<Widget>((final transaction) => _buildTransactionItem(transaction as Map<String, dynamic>)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(final Map<String, dynamic> transaction) {
    final status = transaction['status'] as String;
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as DateTime;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'paid':
        statusColor = successGreen;
        statusIcon = Icons.check_circle;
      case 'pending':
        statusColor = warningAmber;
        statusIcon = Icons.pending;
      default:
        statusColor = errorRed;
        statusIcon = Icons.error;
    }
    
    final iconSize = ResponsiveUtils.getResponsiveIconSize(context, 48);
    
    return Container(
      padding: ResponsiveUtils.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5.w),
        ),
      ),
      child: ResponsiveRow(
        spacing: ResponsiveUtils.getResponsiveSpacing(context, 16),
        children: <Widget>[
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(iconSize / 2),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
          ),
          Expanded(
            child: ResponsiveColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ResponsiveUtils.getResponsiveSpacing(context, 4),
              children: <Widget>[
                Text(
                  transaction['driver_name'],
                  style: AppStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  transaction['vehicle_number'],
                  style: AppStyles.bodyMedium(context).copyWith(
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  _formatDateTime(date),
                  style: AppStyles.bodySmall(context).copyWith(
                    color: Colors.black45,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          ResponsiveColumn(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: ResponsiveUtils.getResponsiveSpacing(context, 4),
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'TSH ${_formatCurrency(amount)}',
                  style: AppStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
                  vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppStyles.caption(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(final double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDateTime(final DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} siku zilizopita';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saa zilizopita';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika zilizopita';
    } else {
      return 'Sasa hivi';
    }
  }

  void _navigateToPage(final String page) {
    // TODO: Implement navigation to different pages
    switch (page) {
      case 'drivers':
        Navigator.pushNamed(context, '/admin/drivers');
      case 'vehicles':
        Navigator.pushNamed(context, '/admin/vehicles');
      case 'payments':
        Navigator.pushNamed(context, '/admin/payments');
      case 'reports':
        Navigator.pushNamed(context, '/admin/reports');
      case 'record_payment':
        Navigator.pushNamed(context, '/admin/record-payment');
      case 'add_driver':
        Navigator.pushNamed(context, '/admin/drivers');
      case 'add_vehicle':
        Navigator.pushNamed(context, '/admin/vehicles');
      default:
        _showComingSoonDialog(page);
    }
  }

  void _showComingSoonDialog(final String feature) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Inakuja Hivi Karibuni'),
        content: SelectableText('Kipengele cha $feature kinatengenezwa. Subiri kidogo!'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    // TODO: Implement notifications
    _showComingSoonDialog('Arifa');
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Toka'),
        content: const Text('Je, una uhakika unataka kutoka?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
            },
            child: const Text(
              'Ndio',
              style: TextStyle(color: errorRed),
            ),
          ),
        ],
      ),
    );
  }
}