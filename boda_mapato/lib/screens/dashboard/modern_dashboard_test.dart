import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../models/login_response.dart";
import "../../providers/auth_provider.dart";

class ModernDashboardTest extends StatefulWidget {
  const ModernDashboardTest({super.key});

  @override
  State<ModernDashboardTest> createState() => _ModernDashboardTestState();
}

class _ModernDashboardTestState extends State<ModernDashboardTest>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  Map<String, dynamic> _dashboardData = <String, dynamic>{};
  bool _isLoading = true;
  final PageController _cardController = PageController();
  int _selectedMonth = DateTime.now().month;

  // Colors for the modern theme
  static const Color primaryGradientStart = Color(0xFF667eea);
  static const Color primaryGradientEnd = Color(0xFF764ba2);
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
    _loadMockData();
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
    ));

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _chartAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadMockData() async {
    try {
      // Simulate loading
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Mock dashboard data with explicit double typing
      _dashboardData = <String, dynamic>{
        "total_saved": 85750.0,
        "monthly_income": 125840.0,
        "saving_rate": 68.2,
        "weekly_earnings": <double>[45.5, 67.2, 89.1, 79.5, 65.3, 72.8, 58.4],
        "monthly_data": <dynamic>[],
        "recent_trips": 142,
        "fuel_costs": 28500.0,
        "maintenance_costs": 12000.0,
        "net_profit": 85340.0,
        "active_drivers": 18,
        "total_vehicles": 15,
        "pending_payments": 3,
        "daily_revenue": 25000.0,
      };

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar("Hitilafu katika kupakia data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[primaryGradientStart, primaryGradientEnd],
          ),
        ),
        child: SafeArea(
          child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
        ),
      ),
    );

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
              onRefresh: _loadMockData,
              backgroundColor: Colors.white,
              color: primaryGradientStart,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildBalanceCard(),
                      const SizedBox(height: 30),
                      _buildStatsCards(),
                      const SizedBox(height: 30),
                      _buildChartSection(),
                      const SizedBox(height: 30),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ),
    );

  Widget _buildHeader() {
    final AuthProvider? authProvider = Provider.of<AuthProvider>(context, listen: false);
    final UserData? user = authProvider?.user;

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: textPrimary,
            size: 24,
          ),
        ),
        const Expanded(
          child: Text(
            "Modern Dashboard",
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
    final AuthProvider? authProvider = Provider.of<AuthProvider>(context, listen: false);
    final UserData? user = authProvider?.user;

    return SizedBox(
      height: 200,
      child: PageView(
        controller: _cardController,
        children: <Widget>[
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: textPrimary,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.more_horiz,
                        color: textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?.name ?? "Dereva Mkuu",
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "TSH ${_formatCurrency(_dashboardData["net_profit"])}",
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Faida Halisi ya Mwezi",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Mapato ya Mwezi",
                "TSH ${_formatCurrency(_dashboardData["monthly_income"])}",
                "+8.2%",
                Icons.trending_up,
                true,
              ),
            ),
            const SizedBox(width: 16),
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
        const SizedBox(height: 16),
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Magari",
                "${_dashboardData["total_vehicles"] ?? 0}",
                "+1",
                Icons.directions_car,
                true,
              ),
            ),
            const SizedBox(width: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: textSecondary,
                  size: 20,
                ),
                const Spacer(),
                const Icon(
                  Icons.more_vert,
                  color: textSecondary,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
                fontSize: 12,
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
              Navigator.pop(context);
            }),
            _buildActionButton(Icons.add, "Ongeza", () {
              _showSnackBar("Ongeza kipengele");
            }),
            _buildActionButton(Icons.apps, "Menyu", () {
              Navigator.pop(context);
            }),
            _buildActionButton(Icons.receipt, "Ripoti", () {
              _showSnackBar("Ripoti za biashara");
            }),
            _buildActionButton(Icons.settings, "Mipangilio", () {
              _showSnackBar("Mipangilio ya mfumo");
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
      if (animationValue > 0.8 && i.isEven) {
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
