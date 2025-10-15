// ignore_for_file: cascade_invocations
import "dart:async";
import "dart:math" as math;
import "dart:ui";

import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../debug_auth_test.dart";
import "../../models/login_response.dart";
import "../../models/user_permissions.dart";
import "../../providers/auth_provider.dart";
import "../../services/api_service.dart";
import "../../services/app_events.dart";
import "../../services/localization_service.dart";
import "../../services/navigation_builder.dart";
import "../../utils/responsive_helper.dart";
import "../receipts/receipts_screen.dart";

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
  
  // Event subscription for automatic refresh
  late StreamSubscription<AppEvent> _eventSubscription;

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
    
    // Listen to app events for automatic refresh
    _eventSubscription = AppEvents.instance.stream.listen((event) {
      switch (event.type) {
        case AppEventType.receiptsUpdated:
        case AppEventType.paymentsUpdated:
        case AppEventType.debtsUpdated:
        case AppEventType.dashboardShouldRefresh:
          // Refresh dashboard when payments, receipts, or debts are updated
          if (mounted) {
            _loadDashboardData();
          }
          break;
      }
    });
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
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _chartAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _animationController.dispose();
    _chartAnimationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Guard: only load if authenticated
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Load real-time data directly from database tables via comprehensive API calls
      await _loadComprehensiveRealTimeData();

      // Load revenue chart data for visualization
      await _loadRevenueChartData();

      // Load additional badge counts (reminders)
      await _loadAdditionalBadgeCounts();

      // Update UI and start animations
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        unawaited(_animationController.forward());
        unawaited(Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _chartAnimationController.forward();
          }
        }));
      }
    } on Exception catch (_) {
      // No mock/fallback data; just surface the error and keep zeros
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar("Backend haipatikani. Tafadhali jaribu tena baadaye.");
      }
    }
  }

  /// Load comprehensive real-time data using existing backend endpoints
  Future<void> _loadComprehensiveRealTimeData() async {
    try {
      // Use main dashboard endpoint which returns complete and accurate data
      final Map<String, dynamic> dashboardResponse = await _apiService.getDashboardData();

      // Extract data from the main dashboard response
      final Map<String, dynamic> mainData = _extractDataFromResponse(dashboardResponse);
      
      // Initialize dashboard data and populate with main response data
      _dashboardData = _getEmptyDashboardData();
      
      // Map the dashboard response to our expected data structure
      _dashboardData.addAll({
        // Revenue data from main endpoint
        'daily_revenue': _toDouble(mainData['payments_today'] ?? 0),
        'weekly_revenue': _toDouble(mainData['payments_this_week'] ?? 0),
        'monthly_revenue': _toDouble(mainData['payments_this_month'] ?? 0),
        
        // Driver and vehicle counts
        'drivers_count': _toInt(mainData['total_drivers'] ?? 0),
        'total_drivers': _toInt(mainData['total_drivers'] ?? 0),
        'active_drivers': _toInt(mainData['active_drivers'] ?? 0),
        'devices_count': _toInt(mainData['total_vehicles'] ?? 0),
        'total_vehicles': _toInt(mainData['total_vehicles'] ?? 0),
        'active_vehicles': _toInt(mainData['active_vehicles'] ?? 0),
        
        // Recent transactions
        'recent_transactions': mainData['recent_transactions'] ?? [],
      });

      // Fetch additional counts (unpaid debts, generated receipts, pending receipts)
      try {
        final List<Map<String, dynamic>> extras = await Future.wait<Map<String, dynamic>>([
          _loadUnpaidDebtsCountFromExisting(),
          _loadPaymentReceiptsCountFromExisting(),
          _loadPendingReceiptsCountFromExisting(),
        ]);
        for (final Map<String, dynamic> m in extras) {
          _dashboardData.addAll(m);
        }
      } on Exception catch (_) {
        // ignore supplemental errors
      }

      // Fetch all-time revenue to display on the balance card
      try {
        final Map<String, dynamic> revResp = await _apiService.getRevenueReport();
        final Map<String, dynamic> revData = _extractDataFromResponse(revResp);
        _dashboardData['total_revenue'] = _toDouble(
          revData['total_revenue'] ?? revData['revenue'] ?? revData['total_amount'] ?? 0,
        );
      } on Exception catch (_) {
        // If unavailable, fall back to monthly revenue already set
        _dashboardData['total_revenue'] = _dashboardData['monthly_revenue'] ?? 0;
      }
      
      // Update badge counts for drawer
      _updateBadgeCounts();
      
    } on Exception catch (e) {
      // Initialize with empty data if all fails
      _dashboardData = _getEmptyDashboardData();
      if (mounted) {
        _showErrorSnackBar("Imeshindikana kupakia data za dashboard: ${e.toString()}");
      }
    }
  }

  /// Load active drivers count from drivers table WHERE is_active = 1
  Future<Map<String, dynamic>> _loadDriversCountFromExisting() async {
    try {
      // Try new endpoint first for active drivers (is_active = 1)
      try {
        final response = await _apiService.getActiveDriversCount();
        final data = _extractDataFromResponse(response);
        return {
          'drivers_count': _toInt(data['count'] ?? data['active_drivers_count'] ?? 0),
          'total_drivers': _toInt(data['count'] ?? data['active_drivers_count'] ?? 0),
        };
      } on Exception {
        // Fallback to existing drivers endpoint and filter active drivers
        final response = await _apiService.getDrivers();
        final data = _extractDataFromResponse(response);
        
        // Try to extract active drivers count from response
        int activeCount = 0;
        if (data['drivers'] is List) {
          final List<dynamic> drivers = data['drivers'] as List<dynamic>;
          activeCount = drivers.where((driver) {
            if (driver is Map<String, dynamic>) {
              return driver['is_active'] == 1 || 
                     driver['is_active'] == true || 
                     driver['status'] == 'active';
            }
            return false;
          }).length;
        } else {
          // If no filtering possible, use total count as fallback
          activeCount = _extractTotalCountFromResponse(response);
        }
        
        return {
          'drivers_count': activeCount,
          'total_drivers': activeCount,
        };
      }
    } on Exception {
      return {'drivers_count': 0, 'total_drivers': 0};
    }
  }

  /// Load active devices count from devices table WHERE is_active = 1
  Future<Map<String, dynamic>> _loadDevicesCountFromExisting() async {
    try {
      // Try new endpoint first for active devices (is_active = 1)
      try {
        final response = await _apiService.getActiveDevicesCount();
        final data = _extractDataFromResponse(response);
        return {
          'devices_count': _toInt(data['count'] ?? data['active_devices_count'] ?? 0),
          'total_vehicles': _toInt(data['count'] ?? data['active_devices_count'] ?? 0),
        };
      } on Exception {
        // Fallback to existing vehicles endpoint and filter active devices
        final response = await _apiService.getVehicles();
        final data = _extractDataFromResponse(response);
        
        // Try to extract active devices count from response
        int activeCount = 0;
        if (data['vehicles'] is List) {
          final List<dynamic> vehicles = data['vehicles'] as List<dynamic>;
          activeCount = vehicles.where((vehicle) {
            if (vehicle is Map<String, dynamic>) {
              return vehicle['is_active'] == 1 || 
                     vehicle['is_active'] == true || 
                     vehicle['status'] == 'active';
            }
            return false;
          }).length;
        } else {
          // If no filtering possible, use total count as fallback
          activeCount = _extractTotalCountFromResponse(response);
        }
        
        return {
          'devices_count': activeCount,
          'total_vehicles': activeCount,
        };
      }
    } on Exception {
      return {'devices_count': 0, 'total_vehicles': 0};
    }
  }

  /// Load unpaid debts count aligned with the DebtsManagementScreen list.
  /// We prefer counting unique drivers who currently have any outstanding debt,
  /// so the value matches the "Ana deni" driver tiles you see in that screen.
  Future<Map<String, dynamic>> _loadUnpaidDebtsCountFromExisting() async {
    try {
      int endpointCount = 0;
      // 1) Try new endpoint first for unpaid debts (is_paid = 0)
      try {
        final response = await _apiService.getUnpaidDebtsCount();
        final data = _extractDataFromResponse(response);
        endpointCount = _toInt(data['count'] ?? data['unpaid_debts_count'] ?? 0);
      } on Exception {
        // 2) Fallback to a generic summary if endpoint not available
        try {
          final response = await _apiService.getPaymentSummary();
          final data = _extractDataFromResponse(response);
          endpointCount = _toInt(
            data['unpaid_debts'] ??
            data['outstanding_debts'] ??
            data['total_debts'] ??
            data['pending_payments'] ?? 0,
          );
        } catch (_) {
          endpointCount = 0;
        }
      }

      // 3) Compute unique debtor drivers via /admin/debts/drivers to match DebtsManagementScreen UI
      int uniqueDebtorDrivers = endpointCount; // default
      try {
        final Map<String, dynamic> resp = await _apiService.getDebtDrivers(limit: 500);
        final Map<String, dynamic>? data = resp['data'] as Map<String, dynamic>?;
        final List<dynamic> list = (data?['drivers'] as List<dynamic>?) ?? <dynamic>[];
        uniqueDebtorDrivers = list.where((e) {
          if (e is Map<String, dynamic>) {
            final m = e;
            final num total = (m['total_debt'] is num)
                ? (m['total_debt'] as num)
                : num.tryParse(m['total_debt']?.toString() ?? '0') ?? 0;
            return total > 0;
          }
          return false;
        }).length;
      } catch (_) {
        // ignore; keep endpointCount
      }

      // Prefer the unique drivers count to match what the user sees in DebtsManagementScreen
      final int finalCount = uniqueDebtorDrivers;
      return {'unpaid_debts_count': finalCount};
    } on Exception {
      return {'unpaid_debts_count': 0};
    }
  }

  /// Load generated receipts count from payment_receipts table WHERE receipt_status = 'generated'
  Future<Map<String, dynamic>> _loadPaymentReceiptsCountFromExisting() async {
    try {
      // Try new endpoint first for generated receipts (receipt_status = 'generated')
      try {
        final response = await _apiService.getGeneratedReceiptsCount();
        final data = _extractDataFromResponse(response);
        final int cnt = _toInt(data['count'] ?? data['generated_receipts_count'] ?? 0);
        return {
          'payment_receipts_count': cnt,
          'receipts_count': cnt,
        };
      } on Exception {
        // Fallback to existing receipts endpoint and filter generated receipts
        final response = await _apiService.getPaymentReceipts();
        final data = _extractDataFromResponse(response);
        
        // Try to extract generated receipts count from response
        int generatedCount = 0;
        if (data['receipts'] is List) {
          final List<dynamic> receipts = data['receipts'] as List<dynamic>;
          generatedCount = receipts.where((receipt) {
            if (receipt is Map<String, dynamic>) {
              return receipt['receipt_status'] == 'generated' || 
                     receipt['status'] == 'generated';
            }
            return false;
          }).length;
        } else {
          // If no filtering possible, use total count as fallback
          generatedCount = _extractTotalCountFromResponse(response);
        }
        
        return {
          'payment_receipts_count': generatedCount,
          'receipts_count': generatedCount,
        };
      }
    } on Exception {
      return {'payment_receipts_count': 0, 'receipts_count': 0};
    }
  }

  /// Load pending receipts count from payments table WHERE receipt_status = 'pending'
  /// To keep consistency with the "Toa Risiti" page, count total pending receipt items
  /// (same as what users see in the receipts screen list).
  Future<Map<String, dynamic>> _loadPendingReceiptsCountFromExisting() async {
    try {
      int endpointCount = 0;
      // 1) Try new endpoint first for pending receipts (receipt_status = 'pending')
      try {
        final response = await _apiService.getPendingReceiptsCount();
        final data = _extractDataFromResponse(response);
        endpointCount = _toInt(data['count'] ?? data['pending_receipts_count'] ?? 0);
      } on Exception {
        // ignore and keep endpointCount = 0
      }

      // 2) Fetch pending receipts list and count TOTAL ITEMS to match ReceiptsScreen UI
      int totalItemsCount = endpointCount; // default to endpoint result
      try {
        final response = await _apiService.getPendingReceipts();
        final data = _extractDataFromResponse(response);

        // Common shapes observed:
        // - { pending_receipts: [ { driver: { id, ... }, ... } ] }
        // - { data: [ ...same as above... ] }
        // - Legacy: { payments: [ { driver_id, receipt_status, ... } ] } -> filter pending
        final List<dynamic> list =
            (data['pending_receipts'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            (data['payments'] as List<dynamic>?) ??
            const <dynamic>[];

        // Count total pending receipt items (same logic as ReceiptsScreen)
        int validItemsCount = 0;
        final Set<String> uniqueDriverIds = <String>{}; // for debug info
        for (final dynamic item in list) {
          if (item is Map<String, dynamic>) {
            // Driver nested - always count as valid pending receipt
            if (item['driver'] is Map) {
              validItemsCount++;
              final Map<String, dynamic> d = (item['driver'] as Map).cast<String, dynamic>();
              final String id = d['id']?.toString() ?? '';
              if (id.isNotEmpty) uniqueDriverIds.add(id);
              continue;
            }
            // Flat driver_id (legacy payments shape), ensure it's pending
            final String driverId = item['driver_id']?.toString() ?? '';
            final String status = item['receipt_status']?.toString() ?? '';
            if (driverId.isNotEmpty && (status.isEmpty || status == 'pending')) {
              validItemsCount++;
              uniqueDriverIds.add(driverId);
            }
          }
        }
        if (validItemsCount > 0) {
          totalItemsCount = validItemsCount;
        } else {
          // As a last resort, fall back to total count extraction
          totalItemsCount = list.length > 0 ? list.length : _extractTotalCountFromResponse(response);
        }
      } catch (_) {
        // ignore; keep endpointCount
      }

      // Return total items count to match ReceiptsScreen (pending filter) UI exactly
      final int finalCount = totalItemsCount;
      return { 'pending_receipts_count': finalCount };
    } on Exception {
      return { 'pending_receipts_count': 0 };
    }
  }

  /// Load revenue data from debt_records (is_paid=1) + payments tables with daily/weekly/monthly filtering
  Future<Map<String, dynamic>> _loadRevenueDataFromExisting() async {
    try {
      final Map<String, dynamic> revenueData = <String, dynamic>{
        'daily_revenue': 0,
        'weekly_revenue': 0,
        'monthly_revenue': 0,
      };

      // Try new specific revenue endpoints first
      try {
        // Load daily revenue from debt_records (is_paid=1) + payments for today
        final dailyResponse = await _apiService.getDailyRevenue();
        final dailyData = _extractDataFromResponse(dailyResponse);
        revenueData['daily_revenue'] = _toDouble(
          dailyData['revenue'] ?? 
          dailyData['daily_revenue'] ?? 
          dailyData['total'] ?? 0
        );
      } on Exception {
        revenueData['daily_revenue'] = 0;
      }

      try {
        // Load weekly revenue from debt_records (is_paid=1) + payments for current week
        final weeklyResponse = await _apiService.getWeeklyRevenue();
        final weeklyData = _extractDataFromResponse(weeklyResponse);
        revenueData['weekly_revenue'] = _toDouble(
          weeklyData['revenue'] ?? 
          weeklyData['weekly_revenue'] ?? 
          weeklyData['total'] ?? 0
        );
      } on Exception {
        revenueData['weekly_revenue'] = 0;
      }

      try {
        // Load monthly revenue from debt_records (is_paid=1) + payments for current month
        final monthlyResponse = await _apiService.getMonthlyRevenue();
        final monthlyData = _extractDataFromResponse(monthlyResponse);
        revenueData['monthly_revenue'] = _toDouble(
          monthlyData['revenue'] ?? 
          monthlyData['monthly_revenue'] ?? 
          monthlyData['total'] ?? 0
        );
      } on Exception {
        // Fallback to existing revenue report endpoint for monthly
        try {
          final DateTime now = DateTime.now();
          final DateTime startOfMonth = DateTime(now.year, now.month, 1);
          
          final response = await _apiService.getRevenueReport(
            startDate: startOfMonth,
            endDate: now,
          );
          final data = _extractDataFromResponse(response);
          
          // Extract monthly revenue (fallback)
          revenueData['monthly_revenue'] = _toDouble(
            data['total_revenue'] ?? 
            data['revenue'] ?? 
            data['total_amount'] ?? 0
          );
          
          // Try to extract daily/weekly if available in response (fallback)
          if (revenueData['daily_revenue'] == 0) {
            revenueData['daily_revenue'] = _toDouble(
              data['daily_revenue'] ?? 
              data['today_revenue'] ?? 0
            );
          }
          
          if (revenueData['weekly_revenue'] == 0) {
            revenueData['weekly_revenue'] = _toDouble(
              data['weekly_revenue'] ?? 
              data['week_revenue'] ?? 0
            );
          }
          
        } on Exception {
          // Keep monthly revenue as 0 if all fails
        }
      }

      return revenueData;
    } on Exception {
      return {
        'daily_revenue': 0,
        'weekly_revenue': 0,
        'monthly_revenue': 0,
      };
    }
  }

  /// Load revenue chart data for visualization
  Future<void> _loadRevenueChartData() async {
    try {
      final List<dynamic> chart = await _apiService.getRevenueChart();
      // Parse entries supporting both 'amount' and 'revenue' keys and capture dates
      final List<double> values = <double>[];
      final List<String> dates = <String>[];
      for (final e in chart) {
        if (e is Map) {
          final dynamic rawVal = e['amount'] ?? e['revenue'] ?? e['value'];
          double val = 0;
          if (rawVal is num) {
            val = rawVal.toDouble();
          } else if (rawVal != null) {
            val = double.tryParse(rawVal.toString()) ?? 0.0;
          }
          values.add(val);
          final String? dateStr = (e['date'] ?? e['created_at'])?.toString();
          dates.add(_formatDateLabel(dateStr));
        } else if (e is num) {
          values.add(e.toDouble());
          dates.add('');
        }
      }
      if (values.isNotEmpty) {
        final int len = values.length;
        final int start = len >= 7 ? len - 7 : 0;
        _dashboardData['weekly_earnings'] = values.sublist(start);
        _dashboardData['weekly_dates'] = dates.length == len
            ? dates.sublist(start)
            : List<String>.generate(len - start, (i) => '');
      } else {
        _dashboardData['weekly_earnings'] = <double>[];
        _dashboardData['weekly_dates'] = <String>[];
      }
    } on Exception {
      // Set empty chart data if loading fails
      _dashboardData['weekly_earnings'] = <double>[];
      _dashboardData['weekly_dates'] = <String>[];
    }
  }

  /// Extract data from API response handling Laravel ResponseHelper format
  Map<String, dynamic> _extractDataFromResponse(Map<String, dynamic> response) {
    // Handle both shapes:
    // - {status: 'success', data: {...}}
    // - {success: true, data: {...}}
    // - Or already a data map with expected keys
    if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>;
    }
    if ((response['success'] == true) || (response['status'] == 'success')) {
      final dynamic data = response['data'];
      if (data is Map<String, dynamic>) return data;
    }
    return response;
  }

  /// Update badge counts for drawer navigation
  void _updateBadgeCounts() {
    _driversCount = _toInt(_dashboardData["drivers_count"] ?? _dashboardData["total_drivers"] ?? 0);
    _vehiclesCount = _toInt(_dashboardData["devices_count"] ?? _dashboardData["total_vehicles"] ?? 0);
    _pendingPaymentsCount = _toInt(_dashboardData["unpaid_debts_count"] ?? _dashboardData["pending_payments"] ?? 0);
  }

  /// Get empty dashboard data structure with defaults
  Map<String, dynamic> _getEmptyDashboardData() {
    return <String, dynamic>{
      // Revenue data
      'daily_revenue': 0,
      'weekly_revenue': 0,
      'monthly_revenue': 0,
      'net_profit': 0,
      'total_saved': 0,
      'saving_rate': 0,
      
      // Database table counts
      'drivers_count': 0,
      'devices_count': 0,
      'unpaid_debts_count': 0,
      'payment_receipts_count': 0,
      'pending_receipts_count': 0,
      
      // Legacy compatibility
      'total_drivers': 0,
      'total_vehicles': 0,
      'active_drivers': 0,
      'active_vehicles': 0,
      'pending_payments': 0,
      'receipts_count': 0,
      
      // Chart data
      'weekly_earnings': <double>[],
      'weekly_dates': <String>[],
      'monthly_data': <dynamic>[],
      'recent_transactions': <dynamic>[],
      
      // Costs
      'fuel_costs': 0,
      'maintenance_costs': 0,
    };
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
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) => Scaffold(
        drawer: _buildDrawer(localizationService), // Add drawer with localization
        body: DecoratedBox(
          decoration: const BoxDecoration(
            color:
                primaryBlue, // Solid blue background matching admin dashboard image
          ),
          child: SafeArea(
            child: _isLoading ? _buildLoadingScreen(localizationService) : _buildMainContent(localizationService),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(LocalizationService localizationService) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              localizationService.translate('loading_dashboard'),
              style: const TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildMainContent(LocalizationService localizationService) => FadeTransition(
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
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeader(localizationService),
                      ResponsiveHelper.verticalSpace(2),
                      _buildBalanceCard(),
                      ResponsiveHelper.verticalSpace(2),
                      _buildStatsCards(),
                      ResponsiveHelper.verticalSpace(2),
                      _buildChartSection(),
                      ResponsiveHelper.verticalSpace(2),
                      _buildQuickActions(localizationService),
                      ResponsiveHelper.verticalSpace(2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader(LocalizationService localizationService) {
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
        Expanded(
          child: Text(
            localizationService.translate('dashboard'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            // Debug button
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugAuthTest(),
                  ),
                );
              },
              icon: const Icon(
                Icons.bug_report,
                color: textPrimary,
                size: 20,
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
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final UserData? user = authProvider.user;

    // Use MediaQuery-driven sizing to avoid overflow on short devices
    final Size size = MediaQuery.of(context).size;
    final bool isShort = size.height < 700;

    // Compute a compact but readable card height
    double cardHeight = size.height * (isShort ? 0.14 : 0.18);
    cardHeight = cardHeight.clamp(110.0, 170.0);

    final double avatarSide = (size.width * 0.10).clamp(36.0, 46.0);
    final double gapLarge = isShort ? 8.0 : 12.0; // replaces verticalSpace(1.2)
    final double gapMid = isShort ? 6.0 : 8.0;   // replaces verticalSpace(0.6)
    final double gapSmall = isShort ? 4.0 : 6.0; // replaces verticalSpace(0.3)

    return SizedBox(
      height: cardHeight,
      child: PageView(
        controller: _cardController,
        children: <Widget>[
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: avatarSide,
                        height: avatarSide,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(avatarSide / 2),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.more_horiz,
                        color: textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: gapLarge),
                  Text(
                    user?.name ?? "Dereva Mkuu",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: ResponsiveHelper.h4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: gapMid),
                  Text(
                    "TSH ${_formatCurrency(_dashboardData["total_revenue"] ?? _dashboardData["monthly_revenue"])}",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: ResponsiveHelper.h2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: gapSmall),
                  Consumer<LocalizationService>(
                    builder: (context, localizationService, child) => Text(
                      localizationService.translate("total_revenue"),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: ResponsiveHelper.bodyM,
                      ),
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

  Widget _buildStatsCards() {
        return Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            // Active vs total for drivers and vehicles (exact backend values)
            final int activeDrivers = _toInt(_dashboardData['active_drivers'] ?? 0);
            final int totalDrivers = _toInt(
              _dashboardData['total_drivers'] ?? _dashboardData['drivers_count'] ?? 0,
            );
            final int activeVehicles = _toInt(_dashboardData['active_vehicles'] ?? 0);
            final int totalVehicles = _toInt(
              _dashboardData['total_vehicles'] ?? _dashboardData['devices_count'] ?? 0,
            );

            return Column(
            children: <Widget>[
              // First row: Revenue cards (Daily, Weekly, Monthly)
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("daily_revenue"),
                      "TSH ${_formatCurrency(_dashboardData["daily_revenue"])}",
                      "",
                      Icons.today,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("weekly_revenue"),
                      "TSH ${_formatCurrency(_dashboardData["weekly_revenue"])}",
                      "",
                      Icons.calendar_view_week,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("monthly_revenue"),
                      "TSH ${_formatCurrency(_dashboardData["monthly_revenue"])}",
                      "",
                      Icons.trending_up,
                      true,
                    ),
                  ),
                ],
              ),
              ResponsiveHelper.verticalSpace(2),
              // Second row: Payment/Receipt cards
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("payments_with_receipts"),
                      "${_dashboardData["payment_receipts_count"] ?? 0}",
                      "",
                      Icons.receipt,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("paid_awaiting_receipts"),
                      "${_dashboardData["pending_receipts_count"] ?? 0}",
                      "",
                      Icons.receipt_long,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("unpaid_payments"),
                      "${_dashboardData["unpaid_debts_count"] ?? 0}",
                      "",
                      Icons.pending_actions,
                      false,
                    ),
                  ),
                ],
              ),
              ResponsiveHelper.verticalSpace(2),
              // Third row: Resources (Drivers, Vehicles)
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("drivers"),
                      "${activeDrivers}",
                      "${localizationService.translate("active")} $activeDrivers/$totalDrivers",
                      Icons.person,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  Expanded(
                    child: _buildStatCard(
                      localizationService.translate("vehicles"),
                      "${activeVehicles}",
                      "${localizationService.translate("active")} $activeVehicles/$totalVehicles",
                      Icons.directions_car,
                      true,
                    ),
                  ),
                  ResponsiveHelper.horizontalSpace(4),
                  // Empty space to maintain 3-column layout
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          );
        },
      );
    }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    IconData icon,
    bool isPositive,
  ) =>
      _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  _buildCardDropdownMenu(title, value, icon),
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
                  color:
                      isPositive ? Colors.green.shade300 : Colors.red.shade300,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildMonthSelector(),
              const SizedBox(height: 24),
              SizedBox(
                height: MediaQuery.of(context).size.height < 700 ? 140 : 170,
                child: AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (BuildContext context, Widget? child) {
                    final List<double> points =
                        (_dashboardData["weekly_earnings"] as List?)
                                ?.map<double>(_toDouble)
                                .toList() ??
                            <double>[];
                    if (points.isEmpty) {
                      return Consumer<LocalizationService>(
                        builder: (context, localizationService, child) => Center(
                          child: Text(
                            localizationService.translate('no_chart_data'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }
                    final double maxY = points.reduce(math.max) * 1.2;
                    return LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withOpacity(0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: maxY / 4,
                              getTitlesWidget: (value, meta) => Text(
                                _formatShort(value),
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final List<String> labels =
                                    (_dashboardData['weekly_dates'] as List?)?.cast<String>() ?? <String>[];
                                final int i = value.toInt();
                                final String text = (i >= 0 && i < labels.length) ? labels[i] : '';
                                return Transform.rotate(
                                  angle: -math.pi / 6, // -30 degrees for readability
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      text,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              final labels =
                                  (_dashboardData['weekly_dates'] as List?)?.cast<String>() ?? <String>[];
                              return touchedSpots.map((barSpot) {
                                final i = barSpot.x.toInt();
                                final label = (i >= 0 && i < labels.length) ? labels[i] : '';
                                final valueText = 'TSH ${_formatCurrency(barSpot.y)}';
                                return LineTooltipItem(
                                  '$label\n$valueText',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points.asMap().entries.map((e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value * _chartAnimation.value,
                                )).toList(),
                            isCurved: true,
                            color: Colors.white,
                            barWidth: 3,
                            dotData: FlDotData(
                              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  Widget _buildQuickActions(LocalizationService localizationService) => _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavigationBuilder.buildQuickActions(
              localization: localizationService,
              permissions: UserPermissions.fromRole('admin'),
              context: context,
            ),
          ),
        ),
      );

  /// Build dropdown menu for each dashboard card
  Widget _buildCardDropdownMenu(String title, String value, IconData icon) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: textSecondary,
        size: ResponsiveHelper.iconSizeS,
      ),
      color: primaryBlue.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      itemBuilder: (BuildContext context) => _getMenuItems(title, icon),
      onSelected: (String action) => _handleMenuAction(action, title, value),
    );
  }

  /// Get menu items based on card type
  List<PopupMenuEntry<String>> _getMenuItems(String title, IconData icon) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final List<PopupMenuEntry<String>> items = [];
    
    // Common actions for all cards
    items.add(_buildMenuItem(
      'view_details', 
      localizationService.translate('view_details'), 
      Icons.visibility,
    ));
    
    // Card-specific actions
    if (_isRevenueCard(title)) {
      items.add(_buildMenuItem(
        'view_revenue_drivers', 
        localizationService.translate('drivers_who_paid'), 
        Icons.people,
      ));
      items.add(_buildMenuItem(
        'revenue_breakdown', 
        localizationService.translate('revenue_breakdown'), 
        Icons.pie_chart,
      ));
    } else if (title == localizationService.translate('drivers')) {
      items.add(_buildMenuItem(
        'view_all_drivers', 
        localizationService.translate('all_drivers'), 
        Icons.people,
      ));
      items.add(_buildMenuItem(
        'active_drivers', 
        localizationService.translate('active_drivers_only'), 
        Icons.check_circle,
      ));
      items.add(_buildMenuItem(
        'add_driver', 
        localizationService.translate('add_driver'), 
        Icons.person_add,
      ));
    } else if (title == localizationService.translate('vehicles')) {
      items.add(_buildMenuItem(
        'view_all_vehicles', 
        localizationService.translate('all_vehicles'), 
        Icons.directions_car,
      ));
      items.add(_buildMenuItem(
        'active_vehicles', 
        localizationService.translate('active_vehicles_only'), 
        Icons.check_circle,
      ));
      items.add(_buildMenuItem(
        'add_vehicle', 
        localizationService.translate('add_vehicle'), 
        Icons.add_circle,
      ));
    } else if (title == localizationService.translate('payments_with_receipts')) {
      items.add(_buildMenuItem(
        'view_receipts', 
        localizationService.translate('all_receipts'), 
        Icons.receipt,
      ));
      items.add(_buildMenuItem(
        'generate_receipt', 
        localizationService.translate('generate_receipt'), 
        Icons.add_circle,
      ));
    } else if (title == localizationService.translate('paid_awaiting_receipts')) {
      items.add(_buildMenuItem(
        'pending_receipts', 
        localizationService.translate('pending_receipts'), 
        Icons.pending,
      ));
      items.add(_buildMenuItem(
        'process_pending', 
        localizationService.translate('process'), 
        Icons.play_arrow,
      ));
    } else if (title == localizationService.translate('unpaid_payments')) {
      items.add(_buildMenuItem(
        'unpaid_debts', 
        localizationService.translate('unpaid_debts'), 
        Icons.warning,
      ));
      items.add(_buildMenuItem(
        'send_reminders', 
        localizationService.translate('send_reminders'), 
        Icons.notifications_active,
      ));
    }
    
    // Add divider and export option for all cards
    items.add(const PopupMenuDivider());
    items.add(_buildMenuItem(
      'export', 
      localizationService.translate('export_data'), 
      Icons.download,
    ));
    
    return items;
  }
  
  bool _isRevenueCard(String title) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return title == localizationService.translate('daily_revenue') ||
           title == localizationService.translate('weekly_revenue') ||
           title == localizationService.translate('monthly_revenue');
  }

  /// Build individual menu item with consistent styling
  PopupMenuItem<String> _buildMenuItem(String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textPrimary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle menu item selection
  void _handleMenuAction(String action, String cardTitle, String value) {
    switch (action) {
      case 'view_details':
        _showCardDetails(cardTitle, value);
        break;
        
      case 'view_revenue_drivers':
        _navigateToRevenueDrivers(cardTitle);
        break;
        
      case 'revenue_breakdown':
        _navigateToRevenueBreakdown(cardTitle);
        break;
        
      case 'view_all_drivers':
        _navigateToDriversList(filter: 'all');
        break;
        
      case 'active_drivers':
        _navigateToDriversList(filter: 'active');
        break;
        
      case 'add_driver':
        _navigateToAddDriver();
        break;
        
      case 'view_all_vehicles':
        _navigateToVehiclesList(filter: 'all');
        break;
        
      case 'active_vehicles':
        _navigateToVehiclesList(filter: 'active');
        break;
        
      case 'add_vehicle':
        _navigateToAddVehicle();
        break;
        
      case 'view_receipts':
        _navigateToReceiptsList(filter: 'generated');
        break;
        
      case 'generate_receipt':
        _navigateToGenerateReceipt();
        break;
        
      case 'pending_receipts':
        _navigateToReceiptsList(filter: 'pending');
        break;
        
      case 'process_pending':
        _processPendingReceipts();
        break;
        
      case 'unpaid_debts':
        _navigateToDebtsList(filter: 'unpaid');
        break;
        
      case 'send_reminders':
        _sendPaymentReminders();
        break;
        
      case 'export':
        _exportCardData(cardTitle);
        break;
    }
  }

  /// Show detailed information about the card
  void _showCardDetails(String title, String value) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Consumer<LocalizationService>(
        builder: (context, localizationService, child) => AlertDialog(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                _getCardIcon(title),
                color: textPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizationService.translate('current_value'),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getCardDescription(title, localizationService),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizationService.translate('close'),
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigation methods for different card actions
  void _navigateToRevenueDrivers(String period) {
    // Navigate to drivers list filtered by revenue period
    Navigator.pushNamed(
      context, 
      '/admin/drivers',
      arguments: {
        'filter': 'revenue',
        'period': period,
      },
    );
  }

  void _navigateToRevenueBreakdown(String period) {
    Navigator.pushNamed(
      context, 
      '/admin/analytics',
      arguments: {
        'view': 'revenue_breakdown',
        'period': period,
      },
    );
  }

  void _navigateToDriversList({required String filter}) {
    Navigator.pushNamed(
      context, 
      '/admin/drivers',
      arguments: {'filter': filter},
    );
  }

  void _navigateToAddDriver() {
    Navigator.pushNamed(context, '/admin/drivers/add');
  }

  void _navigateToVehiclesList({required String filter}) {
    Navigator.pushNamed(
      context, 
      '/admin/vehicles',
      arguments: {'filter': filter},
    );
  }

  void _navigateToAddVehicle() {
    Navigator.pushNamed(context, '/admin/vehicles/add');
  }

  void _navigateToReceiptsList({required String filter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptsScreen(
          initialFilter: filter == 'pending' ? 'pending' : 'all',
        ),
      ),
    );
  }

  void _navigateToGenerateReceipt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiptsScreen(
          initialFilter: 'all',
        ),
      ),
    );
  }

  void _navigateToDebtsList({required String filter}) {
    Navigator.pushNamed(
      context, 
      '/admin/debts',
      arguments: {'filter': filter},
    );
  }

  /// Action methods
  void _processPendingReceipts() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    _showActionDialog(
      title: localizationService.translate('process_pending_receipts'),
      message: localizationService.translate('confirm_process_pending_receipts'),
      confirmText: localizationService.translate('process'),
      onConfirm: () {
        // Implement pending receipts processing
        _showSuccessSnackBar(localizationService.translate('pending_receipts_processed'));
      },
    );
  }

  void _sendPaymentReminders() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    _showActionDialog(
      title: localizationService.translate('send_payment_reminders'),
      message: localizationService.translate('confirm_send_reminders'),
      confirmText: localizationService.translate('send'),
      onConfirm: () {
        // Implement reminder sending
        _showSuccessSnackBar(localizationService.translate('payment_reminders_sent'));
      },
    );
  }

  void _exportCardData(String cardTitle) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    _showActionDialog(
      title: localizationService.translate('export_data'),
      message: '${localizationService.translate('confirm_export_data')} "$cardTitle"?',
      confirmText: localizationService.translate('export'),
      onConfirm: () {
        // Implement data export
        _showSuccessSnackBar(localizationService.translate('data_exported_successfully'));
      },
    );
  }

  /// Helper methods
  IconData _getCardIcon(String title) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    if (title == localizationService.translate('daily_revenue')) {
      return Icons.today;
    } else if (title == localizationService.translate('weekly_revenue')) {
      return Icons.calendar_view_week;
    } else if (title == localizationService.translate('monthly_revenue')) {
      return Icons.trending_up;
    } else if (title == localizationService.translate('drivers')) {
      return Icons.person;
    } else if (title == localizationService.translate('vehicles')) {
      return Icons.directions_car;
    } else if (title == localizationService.translate('payments_with_receipts')) {
      return Icons.receipt;
    } else if (title == localizationService.translate('paid_awaiting_receipts')) {
      return Icons.receipt_long;
    } else if (title == localizationService.translate('unpaid_payments')) {
      return Icons.pending_actions;
    } else {
      return Icons.info;
    }
  }

  String _getCardDescription(String title, LocalizationService localizationService) {
    if (title == localizationService.translate('daily_revenue')) {
      return localizationService.translate('daily_revenue_desc');
    } else if (title == localizationService.translate('weekly_revenue')) {
      return localizationService.translate('weekly_revenue_desc');
    } else if (title == localizationService.translate('monthly_revenue')) {
      return localizationService.translate('monthly_revenue_desc');
    } else if (title == localizationService.translate('drivers')) {
      return localizationService.translate('drivers_desc');
    } else if (title == localizationService.translate('vehicles')) {
      return localizationService.translate('vehicles_desc');
    } else if (title == localizationService.translate('payments_with_receipts')) {
      return localizationService.translate('payments_with_receipts_desc');
    } else if (title == localizationService.translate('paid_awaiting_receipts')) {
      return localizationService.translate('paid_awaiting_receipts_desc');
    } else if (title == localizationService.translate('unpaid_payments')) {
      return localizationService.translate('unpaid_payments_desc');
    } else {
      return localizationService.translate('additional_card_info');
    }
  }

  void _showActionDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Consumer<LocalizationService>(
        builder: (context, localizationService, child) => AlertDialog(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localizationService.translate('cancel'),
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                confirmText,
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: localizationService.translate('close'),
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }


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

  Widget _buildDrawer(LocalizationService localizationService) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final UserData? user = authProvider.user;
    
    // Get user permissions (defaulting to admin for now)
    final UserPermissions permissions = UserPermissions.fromRole('admin');
    
    // Get badge counts from dashboard data
    final badges = NavigationBuilder.getBadgesFromDashboardData(_dashboardData);
    badges['reminders'] = _remindersCount;

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
              children: NavigationBuilder.buildDrawerItems(
                localization: localizationService,
                badges: badges,
                permissions: permissions,
                context: context,
                onLogout: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _formatCurrency(amount) {
    final double value = _toDouble(amount);
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _formatShort(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).round()}K";
    }
    return value.round().toString();
  }

  String _formatDateLabel(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    // Expecting YYYY-MM-DD or ISO8601; take date part and format as DD/MM
    final String datePart = iso.split('T').first;
    final List<String> parts = datePart.split('-');
    if (parts.length >= 3) {
      final String dd = parts[2].padLeft(2, '0');
      final String mm = parts[1].padLeft(2, '0');
      return '$dd/$mm';
    }
    return datePart;
  }

  // Helper method to safely convert dynamic values to double
  double _toDouble(value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0;
  }

  // Helper method to safely convert dynamic values to int
  int _toInt(value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Extract a total count from common API response shapes
  int _extractTotalCountFromResponse(Map<String, dynamic> resp) {
    // Try top-level meta.total
    final dynamic metaTop = resp['meta'];
    if (metaTop is Map && metaTop['total'] is num) {
      return (metaTop['total'] as num).toInt();
    }

    // Try data as List
    final dynamic data = resp['data'];
    if (data is List) return data.length;

    // Try data: { data: [...], meta: { total } }
    if (data is Map<String, dynamic>) {
      final dynamic metaInData = data['meta'];
      if (metaInData is Map && metaInData['total'] is num) {
        return (metaInData['total'] as num).toInt();
      }
      final dynamic inner = data['data'];
      if (inner is List) return inner.length;
    }

    return 0;
  }

  // Load additional counts (reminders, receipts, debts) via API calls
  Future<void> _loadAdditionalBadgeCounts() async {
    try {
      // Ensure user is authenticated before hitting protected endpoints
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) return;

      // Load reminders count for drawer badge
      try {
        final Map<String, dynamic> remindersResponse =
            await _apiService.getReminders(limit: 1);
        final Map<String, dynamic>? remindersMeta =
            remindersResponse["meta"] as Map<String, dynamic>?;
        _remindersCount = remindersMeta?["total"] ?? 0;
      } on Exception {
        _remindersCount = 0;
      }

    } on Exception catch (_) {
      // If API fails, set reminder count to 0
      _remindersCount = 0;
    }
  }
}

// Custom Chart Painter
class ChartPainter extends CustomPainter {
  ChartPainter(
      {required this.data, required this.animationValue, this.yAxisMax});
  final List<dynamic> data;
  final double animationValue;
  // Optional Y-axis maximum. If null, a nice rounded ceiling above data max is used.
  final double? yAxisMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Layout paddings to make space for Y-axis labels
    const double leftPad = 44;
    const double rightPad = 12;
    const double topPad = 8;
    const double bottomPad = 28;

    final double chartWidth =
        (size.width - leftPad - rightPad).clamp(1.0, double.infinity);
    final double chartHeight =
        (size.height - topPad - bottomPad).clamp(1.0, double.infinity);
    const double chartLeft = leftPad;
    final double chartRight = leftPad + chartWidth;
    final double chartBottom = size.height - bottomPad;

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
      ).createShader(Rect.fromLTWH(chartLeft, topPad, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final Path fillPath = Path();

    final double dataMax = data.map(_toDoubleStatic).reduce(math.max);

    // Determine the display max: at least yAxisMax (e.g., 6M), or a rounded-up nice number above data
    double displayMax = yAxisMax ?? dataMax;
    // Add 10% headroom above data if our desired max equals the data max
    if ((yAxisMax == null) || (displayMax <= dataMax)) {
      displayMax = _niceCeil((dataMax <= 0 ? 1 : dataMax) * 1.1);
    }
    // Ensure the displayMax is at least the provided yAxisMax (for 6M cap)
    if (yAxisMax != null && displayMax < yAxisMax!) {
      displayMax = yAxisMax!;
    }

    if (displayMax <= 0) return;

    // Draw horizontal gridlines and Y-axis labels (6 ticks including 0)
    const int tickCount = 6;
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;

    for (int i = 0; i < tickCount; i++) {
      final double t = i / (tickCount - 1);
      final double value = displayMax * (1 - t); // top to bottom labels
      final double y = topPad + chartHeight * t;

      // grid line
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      // label
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: _formatShort(value),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 6);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final double stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double value = _toDoubleStatic(data[i]);
      // Normalize from 0 to displayMax so the baseline is zero and scale is flexible
      final double normalizedValue = (value / displayMax).clamp(0.0, 1.0);
      final double x = chartLeft + i * stepX;
      final double y = chartBottom - (normalizedValue * chartHeight);

      final double animatedX = chartLeft + (x - chartLeft) * animationValue;
      final double animatedY = y + (chartBottom - y) * (1 - animationValue);

      if (i == 0) {
        path.moveTo(animatedX, animatedY);
        fillPath.moveTo(animatedX, chartBottom);
        fillPath.lineTo(animatedX, animatedY);
      } else {
        path.lineTo(animatedX, animatedY);
        fillPath.lineTo(animatedX, animatedY);
      }

      // Draw data point marker (kept as-is)
      canvas.drawCircle(
        Offset(animatedX, animatedY),
        4,
        Paint()..color = Colors.white,
      );

      // Always-visible, rotated green amount label above each point/bar
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(
            color: Color(0xFF00FF00), // bright green
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position label directly above the bar/point and rotate 90° clockwise
      canvas.save();
      // Translate to a point above the data point
      const double labelYOffset = 20;
      canvas.translate(animatedX, animatedY - labelYOffset);
      // Rotate clockwise 90 degrees so text reads left-to-right when head tilted right
      canvas.rotate(math.pi / 2);
      // Draw centered, with text positioned above the anchor point
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Complete the fill path
    fillPath.lineTo(chartLeft + chartWidth * animationValue, chartBottom);
    fillPath.close();

    // Draw fill first, then stroke
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // Static helper method for type conversion in chart painter
  static double _toDoubleStatic(value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0;
  }

  static String _formatShort(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    }
    if (value >= 1000) {
      return "${(value / 1000).round()}K";
    }
    return value.round().toString();
  }

  // Compute a "nice" rounded-up ceiling for axis max (1, 2, or 5 times a power of 10)
  static double _niceCeil(double value) {
    if (value <= 0) return 1;
    final double exponent = (math.log(value) / math.ln10).floorToDouble();
    final double fraction = value / math.pow(10, exponent);
    double niceFraction;
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * math.pow(10, exponent);
  }
}
