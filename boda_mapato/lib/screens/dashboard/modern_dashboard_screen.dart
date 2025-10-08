import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../models/login_response.dart";
import "../../providers/auth_provider.dart";
import "../../services/api_service.dart";
import "../../utils/responsive_helper.dart";

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  final ApiService _apiService = ApiService();
  Map<String, dynamic> _dashboardData = <String, dynamic>{};
  bool _isLoading = true;
  final PageController _cardController = PageController();
  int _selectedMonth = DateTime.now().month;

  // Badge counters for drawer notifications
  int _driversCount = 0;
  int _vehiclesCount = 0;
  int _pendingPaymentsCount = 0;
  int _remindersCount = 0;

  // Colors for the modern theme - matching admin dashboard image
  static const Color primaryBlue = Color(0xFF1E40AF); // Deep blue from image
  static const Color cardColor = Color(0x1AFFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentColor = Color(0xFFFF6B9D);

  final List<String> months = <String>[
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ),);

    _chartAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.elasticOut,
    ),);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      await _apiService.initialize();

      // Try to load real dashboard data from API
      final Map<String, dynamic> dashboardResponse = await _apiService.getDashboardData();
      
      // Extract data from response - Laravel ResponseHelper format
      Map<String, dynamic> data;
      if (dashboardResponse.containsKey('success') && dashboardResponse['success'] == true) {
        data = dashboardResponse['data'] as Map<String, dynamic>;
      } else {
        data = dashboardResponse;
      }

      // Use real data from Laravel backend
      _dashboardData = <String, dynamic>{
        // Financial data
        "monthly_income": _toDouble(data["monthly_revenue"] ?? 0),
        "weekly_revenue": _toDouble(data["weekly_revenue"] ?? 0),
        "daily_revenue": _toDouble(data["daily_revenue"] ?? 0),
        "net_profit": _toDouble(data["net_profit"] ?? 0),
        "total_saved": _toDouble(data["monthly_revenue"] ?? 0) * 0.2, // 20% savings
        "saving_rate": 20.0, // Fixed savings rate
        
        // Operational data
        "active_drivers": _toInt(data["active_drivers"] ?? 0),
        "total_drivers": _toInt(data["total_drivers"] ?? 0), 
        "total_vehicles": _toInt(data["total_vehicles"] ?? 0),
        "active_vehicles": _toInt(data["active_vehicles"] ?? 0),
        "pending_payments": _toInt(data["pending_payments"] ?? 0),
        
        // Calculated metrics
        "fuel_costs": _toDouble(data["monthly_revenue"] ?? 0) * 0.3, // 30% estimate
        "maintenance_costs": _toDouble(data["monthly_revenue"] ?? 0) * 0.1, // 10% estimate
        
        // Chart data - use real or generated from monthly data
        "weekly_earnings": _generateWeeklyEarnings(_toDouble(data["weekly_revenue"] ?? 0)),
        "monthly_data": <dynamic>[],
        "recent_transactions": data["recent_transactions"] ?? <dynamic>[],
      };

      // Update badge counts immediately from dashboard data
      _driversCount = _toInt(data["total_drivers"] ?? 0);
      _vehiclesCount = _toInt(data["total_vehicles"] ?? 0);
      _pendingPaymentsCount = _toInt(data["pending_payments"] ?? 0);
      _remindersCount = 5; // Default for now, will be loaded separately

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _chartAnimationController.forward();
          }
        });
      }

      // Load additional badge counts
      await _loadAdditionalBadgeCounts();
      
    } catch (e) {
      // Fallback to default values if API fails
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dashboardData = _getDefaultDashboardData();
          _driversCount = 12;
          _vehiclesCount = 8;
          _pendingPaymentsCount = 3;
          _remindersCount = 5;
        });
        _showErrorSnackBar("Using fallback data - Backend unavailable");
      }
    }
  }



  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      drawer: _buildDrawer(), // Add drawer
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: primaryBlue, // Solid blue background matching admin dashboard image
        ),
        child: SafeArea(
          child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 24),
          Text(
            "Inapakia Dashboard...",
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildMainContent() => FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (BuildContext context, Widget? child) => Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              backgroundColor: Colors.white,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),),
                child: Padding(
                  padding: ResponsiveHelper.defaultPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeader(),
                      ResponsiveHelper.verticalSpace(4),
                      _buildBalanceCard(),
                      ResponsiveHelper.verticalSpace(4),
                      _buildStatsCards(),
                      ResponsiveHelper.verticalSpace(4),
                      _buildChartSection(),
                      ResponsiveHelper.verticalSpace(4),
                      _buildQuickActions(),
                      ResponsiveHelper.verticalSpace(2),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ),
    );

  Widget _buildHeader() {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final UserData? user = authProvider.user;

    return Row(
      children: <Widget>[
        Builder(
          builder: (BuildContext context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu,
              color: textPrimary,
              size: 24,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            "Dashboard",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: cardColor,
          child: user?.name != null
              ? Text(
                  user!.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: textPrimary,
                  size: 20,
                ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final UserData? user = authProvider.user;

    return SizedBox(
      height: ResponsiveHelper.flexibleHeight(
        minHeight: 180,
        maxHeight: 250,
        percentage: 0.25,
      ),
      child: PageView(
        controller: _cardController,
        children: <Widget>[
          _buildGlassCard(
            child: Padding(
              padding: ResponsiveHelper.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: ResponsiveHelper.wp(12),
                        height: ResponsiveHelper.wp(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.wp(6)),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: textPrimary,
                          size: ResponsiveHelper.iconSizeM,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.more_horiz,
                        color: textSecondary,
                        size: ResponsiveHelper.iconSizeM,
                      ),
                    ],
                  ),
                  ResponsiveHelper.verticalSpace(2),
                  Text(
                    user?.name ?? "Dereva Mkuu",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: ResponsiveHelper.h4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(0.8),
                  Text(
                    "TSH ${_formatCurrency(_dashboardData["net_profit"])}",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: ResponsiveHelper.h2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(0.5),
                  Text(
                    "Faida Halisi ya Mwezi",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: ResponsiveHelper.bodyM,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() => Column(
      children: <Widget>[
        // First row of stats
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                "Jumla ya Akiba",
                "TSH ${_formatCurrency(_dashboardData["total_saved"])}",
                "+12.5%",
                Icons.savings,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                "Mapato ya Mwezi",
                "TSH ${_formatCurrency(_dashboardData["monthly_income"])}",
                "+8.2%",
                Icons.trending_up,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                "Kiwango cha Akiba",
                "${_toDouble(_dashboardData["saving_rate"]).toStringAsFixed(1)}%",
                "+2.1%",
                Icons.percent,
                true,
              ),
            ),
          ],
        ),
        ResponsiveHelper.verticalSpace(2),
        // Second row of stats
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                "Madereva Hai",
                "${_dashboardData["active_drivers"] ?? 0}",
                "+3",
                Icons.person,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                "Magari",
                "${_dashboardData["total_vehicles"] ?? 0}",
                "+1",
                Icons.directions_car,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                "Malipo Yasiyolipwa",
                "${_dashboardData["pending_payments"] ?? 0}",
                "-2",
                Icons.pending_actions,
                false,
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    IconData icon,
    bool isPositive,
  ) => _buildGlassCard(
      child: Padding(
        padding: ResponsiveHelper.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: textSecondary,
                  size: ResponsiveHelper.iconSizeM,
                ),
                const Spacer(),
                Icon(
                  Icons.more_vert,
                  color: textSecondary,
                  size: ResponsiveHelper.iconSizeS,
                ),
              ],
            ),
            ResponsiveHelper.verticalSpace(1.5),
            Text(
              title,
              style: TextStyle(
                color: textSecondary,
                fontSize: ResponsiveHelper.bodyS,
                fontWeight: FontWeight.w500,
              ),
            ),
            ResponsiveHelper.verticalSpace(0.5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: ResponsiveHelper.bodyL,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ResponsiveHelper.verticalSpace(0.5),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                fontSize: ResponsiveHelper.bodyS,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildChartSection() => _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildMonthSelector(),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _chartAnimation,
                builder: (BuildContext context, Widget? child) => CustomPaint(
                    painter: ChartPainter(
                      data: _dashboardData["weekly_earnings"] ??
                          <double>[0, 0, 0, 0, 0, 0, 0],
                      animationValue: _chartAnimation.value,
                    ),
                    child: Container(),
                  ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildMonthSelector() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: months.asMap().entries.map((MapEntry<int, String> entry) {
          final int index = entry.key;
          final String month = entry.value;
          final bool isSelected = index + 1 == _selectedMonth;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = index + 1;
              });
              _chartAnimationController.reset();
              _chartAnimationController.forward();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                month,
                style: TextStyle(
                  color: isSelected ? textPrimary : textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

  Widget _buildQuickActions() => _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildActionButton(Icons.bar_chart, "Takwimu", () {
              Navigator.pushNamed(context, "/admin/analytics");
            }),
            _buildActionButton(Icons.add, "Ongeza", () {
              Navigator.pushNamed(context, "/admin/record-payment");
            }),
            Builder(
              builder: (BuildContext context) => _buildActionButton(Icons.apps, "Menyu", () {
                Scaffold.of(context).openDrawer();
              }),
            ),
            _buildActionButton(Icons.receipt, "Ripoti", () {
              Navigator.pushNamed(context, "/admin/reports");
            }),
            _buildActionButton(Icons.settings, "Mipangilio", () {
              Navigator.pushNamed(context, "/settings");
            }),
          ],
        ),
      ),
    );

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: icon == Icons.apps
                  ? accentColor
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  Widget _buildGlassCard({required Widget child}) => DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );

  Widget _buildDrawer() {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final UserData? user = authProvider.user;

    return Drawer(
      backgroundColor: primaryBlue,
      child: Column(
        children: <Widget>[
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: cardColor,
                    child: user?.name != null
                        ? Text(
                            user!.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: textPrimary,
                            size: 30,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? "Admin User",
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? "admin@bodamapato.com",
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: "Dashboard",
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: "Madereva",
                  badgeCount: _driversCount,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/drivers");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.directions_car,
                  title: "Magari",
                  badgeCount: _vehiclesCount,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/vehicles");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  title: "Malipo",
                  badgeCount: _pendingPaymentsCount,
                  badgeColor: Colors.red.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/payments");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle,
                  title: "Rekodi Malipo",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/record-payment");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: "Takwimu",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/analytics");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: "Ripoti",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/reports");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications,
                  title: "Mikumbuzo",
                  badgeCount: _remindersCount,
                  badgeColor: Colors.orange.shade400,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/admin/reminders");
                  },
                ),
                const Divider(color: textSecondary),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: "Mipangilio",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/settings");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: "Toka",
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
    Color? badgeColor,
  }) => ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Icon(
            icon,
            color: textPrimary,
            size: 24,
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor ?? accentColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? accentColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (badgeColor ?? accentColor).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  color: badgeColor ?? accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );

  String _formatCurrency(dynamic amount) {
    final double value = _toDouble(amount);
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return value.toStringAsFixed(0);
    }
  }

  // Helper method to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely convert dynamic values to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Generate weekly earnings data from weekly revenue
  List<double> _generateWeeklyEarnings(double weeklyRevenue) {
    if (weeklyRevenue <= 0) {
      return <double>[45000, 67000, 89000, 79000, 65000, 72000, 58000];
    }
    
    // Distribute weekly revenue across 7 days with some variation
    final double dailyAverage = weeklyRevenue / 7;
    final List<double> earnings = <double>[];
    
    for (int i = 0; i < 7; i++) {
      // Add some realistic daily variation (±30%)
      final double variation = (math.Random().nextDouble() - 0.5) * 0.6; // -30% to +30%
      final double dailyEarning = dailyAverage * (1 + variation);
      earnings.add(math.max(0, dailyEarning)); // Ensure non-negative
    }
    
    return earnings;
  }

  // Get default dashboard data for fallback
  Map<String, dynamic> _getDefaultDashboardData() {
    return <String, dynamic>{
      "monthly_income": 1200000.0,
      "weekly_revenue": 280000.0,
      "daily_revenue": 40000.0,
      "net_profit": 480000.0,
      "total_saved": 240000.0,
      "saving_rate": 20.0,
      "active_drivers": 12,
      "total_drivers": 15,
      "total_vehicles": 8,
      "active_vehicles": 7,
      "pending_payments": 3,
      "fuel_costs": 360000.0,
      "maintenance_costs": 120000.0,
      "weekly_earnings": <double>[45000, 67000, 89000, 79000, 65000, 72000, 58000],
      "monthly_data": <dynamic>[],
      "recent_transactions": <dynamic>[],
    };
  }

  // Load additional badge counts (reminders) that need separate API calls
  Future<void> _loadAdditionalBadgeCounts() async {
    try {
      // Load reminders count
      final Map<String, dynamic> remindersResponse = await _apiService.getReminders(limit: 1);
      final Map<String, dynamic>? remindersMeta = remindersResponse["meta"] as Map<String, dynamic>?;
      _remindersCount = remindersMeta?["total"] ?? 5;
      
      if (mounted) {
        setState(() {
          // Update UI with reminder count
        });
      }
    } catch (e) {
      // Keep default reminder count if API fails
      _remindersCount = 5;
    }
  }
}

// Custom Chart Painter
class ChartPainter extends CustomPainter {

  ChartPainter({required this.data, required this.animationValue});
  final List<dynamic> data;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final Path fillPath = Path();

    final double maxValue =
        data.map((dynamic e) => _toDoubleStatic(e)).reduce(math.max);
    final double minValue =
        data.map((dynamic e) => _toDoubleStatic(e)).reduce(math.min);
    final double range = maxValue - minValue;

    if (range == 0) return;

    final double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double value = _toDoubleStatic(data[i]);
      final double normalizedValue = (value - minValue) / range;
      final double x = i * stepX;
      final double y = size.height -
          (normalizedValue * size.height * 0.8 + size.height * 0.1);

      final double animatedX = x * animationValue;
      final double animatedY = y + (size.height - y) * (1 - animationValue);

      if (i == 0) {
        path.moveTo(animatedX, animatedY);
        fillPath.moveTo(animatedX, size.height);
        fillPath.lineTo(animatedX, animatedY);
      } else {
        path.lineTo(animatedX, animatedY);
        fillPath.lineTo(animatedX, animatedY);
      }

      // Draw data points
      if (animationValue > 0.8 && i % 2 == 0) {
        canvas.drawCircle(
          Offset(animatedX, animatedY),
          4,
          Paint()..color = Colors.white,
        );

        // Draw value labels
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: "TSH ${value.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(animatedX - textPainter.width / 2, animatedY - 25),
        );
      }
    }

    // Complete the fill path
    fillPath.lineTo(size.width * animationValue, size.height);
    fillPath.close();

    // Draw fill first, then stroke
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Static helper method for type conversion in chart painter
  static double _toDoubleStatic(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
