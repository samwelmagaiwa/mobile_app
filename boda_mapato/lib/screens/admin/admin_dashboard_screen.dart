import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../../config/app_config.dart";
import "../../models/login_response.dart";
import "../../providers/auth_provider.dart";
import "../../services/api_service.dart";
import "../../services/mock_api_service.dart";

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> _dashboardData = <String, dynamic>{};
  bool _isLoading = true;
  final PageController _cardController = PageController();

  // Modern theme colors
  static const Color primaryGradientStart = Color(0xFF667eea);
  static const Color primaryGradientEnd = Color(0xFF764ba2);
  static const Color cardColor = Color(0x1AFFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentColor = Color(0xFFFF6B9D);
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

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

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _chartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.elasticOut),
    );
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
      final ApiService apiService = ApiService();
      await apiService.initialize();
      final Map<String, dynamic> response = await apiService.getDashboardData();
      
      if (mounted) {
        // Handle different response structures (API vs Mock)
        Map<String, dynamic> data;
        if (response.containsKey('data') && response['data'] != null) {
          data = response['data'] as Map<String, dynamic>;
        } else {
          data = response;
        }
        
        _dashboardData = data;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Load mock data as fallback
        _loadMockData();
        _showErrorSnackBar("Using demo data - Backend unavailable");
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
    // Set system UI overlay for immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryBlue,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: primaryBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(),
      backgroundColor: primaryBlue,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: primaryBlue,
        ),
        child: SafeArea(
          bottom: false, // Allow content to extend to bottom
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          backgroundColor: Colors.white,
          color: primaryGradientStart,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth > 400 ? 20 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeader(),
                        SizedBox(height: constraints.maxWidth > 400 ? 24 : 16),
                        _buildBalanceCard(),
                        SizedBox(height: constraints.maxWidth > 400 ? 24 : 16),
                        _buildStatsCards(),
                        SizedBox(height: constraints.maxWidth > 400 ? 24 : 16),
                        _buildRecentTransactions(),
                        SizedBox(height: constraints.maxWidth > 400 ? 24 : 16),
                        _buildQuickActions(),
                        // Add padding for bottom navigation area
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, color: textPrimary, size: 24),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Admin Dashboard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (AppConfig.shouldShowMockIndicator)
                const Text(
                  "🚧 Demo Mode - Mock Data",
                  style: TextStyle(
                    color: Color(0xFFFFCC80),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 20,
          backgroundColor: cardColor,
          child: Icon(Icons.admin_panel_settings, color: textPrimary, size: 20),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final UserData? user = Provider.of<AuthProvider>(context).user;
    
    return Container(
      height: 160,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: textPrimary, size: 20),
                  ),
                  const Icon(Icons.more_horiz, color: textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Karibu, ${user?.name ?? "Admin"}!",
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "TSH ${_formatCurrency(_dashboardData["monthly_revenue"] ?? 0)}",
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Mapato ya Mwezi +${_toDouble(_dashboardData["revenue_growth"] ?? 0).toStringAsFixed(1)}%",
                      style: const TextStyle(color: textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: _buildStatCard(
            "Madereva",
            _getFormattedStatValue("drivers"),
            "+${_toDouble(_dashboardData["driver_growth"] ?? 0).toStringAsFixed(1)}%",
            Icons.people,
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            "Magari",
            _getFormattedStatValue("vehicles"),
            "${_toDouble(_dashboardData["vehicle_utilization"] ?? 0).toStringAsFixed(1)}%",
            Icons.directions_car,
            true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            "Malipo",
            "${_dashboardData["pending_payments"] ?? 0}",
            "Yanahitaji",
            Icons.pending_actions,
            false,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatCard(String title, String value, String change, IconData icon, bool isPositive) =>
    _buildGlassCard(
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(icon, color: textSecondary, size: 16),
                const Icon(Icons.more_vert, color: textSecondary, size: 12),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? Colors.green.shade300 : Colors.amber.shade300,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

  Widget _buildRecentTransactions() {
    final List transactions = _dashboardData["recent_transactions"] as List? ?? [];
    
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              "Miamala ya Hivi Karibuni",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...transactions.take(3).map((transaction) => _buildTransactionItem(transaction as Map<String, dynamic>)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final String status = transaction["status"] as String;
    final double amount = _toDouble(transaction["amount"]);
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case "paid":
        statusColor = successGreen;
        statusIcon = Icons.check_circle;
      case "pending":
        statusColor = warningAmber;
        statusIcon = Icons.pending;
      default:
        statusColor = errorRed;
        statusIcon = Icons.error;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  transaction["driver_name"],
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  transaction["vehicle_number"],
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "TSH ${_formatCurrency(amount)}",
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() => _buildGlassCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildActionButton(Icons.bar_chart, "Ripoti", () {
            _navigateToPage("reports");
          }),
          _buildActionButton(Icons.people, "Madereva", () {
            _navigateToPage("drivers");
          }),
          _buildActionButton(Icons.directions_car, "Magari", () {
            _navigateToPage("vehicles");
          }),
          _buildActionButton(Icons.payment, "Malipo", () {
            _navigateToPage("payments");
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: textPrimary, size: 24),
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
      border: Border.all(color: Colors.white.withOpacity(0.2)),
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

  Widget _buildNavigationDrawer() => Drawer(
    backgroundColor: primaryBlue,
    child: Column(
      children: <Widget>[
        UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: primaryBlue),
          accountName: Text(
            Provider.of<AuthProvider>(context).user?.name ?? "Admin",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(
            Provider.of<AuthProvider>(context).user?.email ?? "admin@bodamapato.com",
            style: const TextStyle(color: Colors.white70),
          ),
          currentAccountPicture: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.admin_panel_settings, color: primaryBlue, size: 30),
          ),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              _buildNavItem(icon: Icons.dashboard, title: "Dashboard", page: "dashboard"),
              _buildNavItem(icon: Icons.auto_graph, title: "Modern Da...", page: "modern_dashboard"),
              const Divider(color: Colors.white24, height: 16),
              _buildNavItem(icon: Icons.people, title: "Madereva", page: "drivers", badge: "${_dashboardData["total_drivers"] ?? 0}"),
              _buildNavItem(icon: Icons.directions_car, title: "Magari", page: "vehicles", badge: "${_dashboardData["total_vehicles"] ?? 0}"),
              const Divider(color: Colors.white24, height: 16),
              _buildNavItem(icon: Icons.payment, title: "Malipo", page: "payments", badge: "${_dashboardData["pending_payments"] ?? 0}"),
              _buildNavItem(icon: Icons.assignment_turned_in, title: "Rekodi Madeni", page: "debts"),
              _buildNavItem(icon: Icons.receipt, title: "Risiti", page: "receipts"),
              _buildNavItem(icon: Icons.swap_horiz, title: "Miamala", page: "transactions"),
              const Divider(color: Colors.white24, height: 16),
              _buildNavItem(icon: Icons.analytics, title: "Ripoti", page: "reports"),
              _buildNavItem(icon: Icons.trending_up, title: "Uchambuzi", page: "analytics"),
              const Divider(color: Colors.white24, height: 16),
              _buildNavItem(icon: Icons.notifications, title: "Mikumbuzi", page: "reminders"),
              _buildNavItem(icon: Icons.settings, title: "Mipangilio", page: "settings"),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Toka"),
          ),
        ),
      ],
    ),
  );

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String page,
    String? badge,
  }) => ListTile(
    leading: Icon(icon, color: Colors.white70, size: 24),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.normal),
    ),
    trailing: badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : null,
    onTap: () {
      Navigator.pop(context);
      _navigateToPage(page);
    },
  );

  void _navigateToPage(String page) {
    switch (page) {
      case "modern_dashboard":
        Navigator.pushNamed(context, "/modern-dashboard");
      case "drivers":
        Navigator.pushNamed(context, "/admin/drivers");
      case "vehicles":
        Navigator.pushNamed(context, "/admin/vehicles");
      case "payments":
        Navigator.pushNamed(context, "/admin/payments");
      case "debts":
        Navigator.pushNamed(context, "/admin/debts");
      case "reports":
        Navigator.pushNamed(context, "/admin/reports");
      case "analytics":
        Navigator.pushNamed(context, "/admin/analytics");
      case "reminders":
        Navigator.pushNamed(context, "/admin/reminders");
      default:
        _showComingSoonDialog(page);
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Inakuja Hivi Karibuni"),
        content: Text("Kipengele cha $feature kinatengenezwa. Subiri kidogo!"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sawa"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Toka"),
        content: const Text("Je, una uhakika unataka kutoka?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hapana"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
            },
            child: const Text("Ndio", style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final double value = _toDouble(amount);
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    } else {
      return value.toStringAsFixed(0);
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _getFormattedStatValue(String type) {
    switch (type) {
      case "drivers":
        final int active = _dashboardData["active_drivers"] as int? ?? 0;
        final int total = _dashboardData["total_drivers"] as int? ?? 0;
        return total == 0 ? "0" : "$active/$total";
      case "vehicles":
        final int active = _dashboardData["active_vehicles"] as int? ?? 0;
        final int total = _dashboardData["total_vehicles"] as int? ?? 0;
        return total == 0 ? "0" : "$active/$total";
      default:
        return "0";
    }
  }

  Future<void> _loadMockData() async {
    try {
      final Map<String, dynamic> mockResponse = await MockApiService.getDashboardData();
      
      if (mounted) {
        Map<String, dynamic> data;
        if (mockResponse.containsKey('data') && mockResponse['data'] != null) {
          data = mockResponse['data'] as Map<String, dynamic>;
        } else {
          data = mockResponse;
        }
        
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
        
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _chartAnimationController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
