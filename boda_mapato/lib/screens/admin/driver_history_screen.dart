import "dart:ui";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:fl_chart/fl_chart.dart";
import "../../constants/theme_constants.dart";
import "../../utils/responsive_helper.dart";
import "../../models/driver.dart";
import "../../models/payment.dart";
import "../../services/api_service.dart";

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({
    required this.driver,
    super.key,
  });

  final Driver driver;

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _apiEndpointsAvailable = false;
  String _selectedChartType = "debt"; // "debt" or "payment"
  
  // Financial data
  double _totalAmountSubmitted = 0;
  double _totalOutstandingDebt = 0;
  double _totalDebtsRecorded = 0;
  double _totalPaid = 0;
  String _paymentConsistencyRating = "Consistent";
  int _averagePaymentDelay = 0;
  
  // History data
  List<PaymentRecord> _paymentHistory = [];
  List<DebtRecord> _debtHistory = [];
  List<ChartData> _debtChartData = [];
  List<ChartData> _paymentChartData = [];

  @override
  void initState() {
    super.initState();
    _loadDriverHistoryData();
  }

  // Custom glass card decoration for better blue background blending
  Widget _buildBlueBlendGlassCard({required Widget child}) {
    ResponsiveHelper.init(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.cardMinHeight,
        maxWidth: ResponsiveHelper.maxCardWidth,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveHelper.elevation * 3,
            offset: Offset(0, ResponsiveHelper.elevation * 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ResponsiveHelper.isMobile ? 6 : 8,
            sigmaY: ResponsiveHelper.isMobile ? 6 : 8,
          ),
          child: Padding(
            padding: ResponsiveHelper.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _loadDriverHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize API service
      await _apiService.initialize();
      
      // Load financial summary
      await _loadFinancialSummary();
      
      // Load payment history
      await _loadPaymentHistory();
      
      // Load debt history
      await _loadDebtHistory();
      
      // Load chart data (attempt API first, fallback to generated data)
      await _loadChartData();
      
    } catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadChartData() async {
    try {
      // Check if basic driver endpoint exists by testing it first
      bool useApiData = false;
      
      try {
        // First do a quick connectivity test
        bool isConnected = await _apiService.testConnectivity();
        if (!isConnected) {
          useApiData = false;
          setState(() {
            _apiEndpointsAvailable = false;
          });
          print('Quick connectivity test failed - backend unreachable');
        } else {
          // Test if driver endpoint exists by trying a basic driver info call
          final testResponse = await _apiService.get('/admin/drivers/${widget.driver.id}', requireAuth: false);
          useApiData = testResponse['status'] == 'success';
          setState(() {
            _apiEndpointsAvailable = useApiData;
          });
        }
      } catch (e) {
        // If basic driver endpoint doesn't exist, skip API calls entirely
        useApiData = false;
        setState(() {
          _apiEndpointsAvailable = false;
        });
        print('Driver API endpoint test failed: $e');
      }
      
      if (useApiData) {
        // Try to load real chart data from API
        try {
          final debtTrends = await _apiService.getDriverDebtTrends(
            driverId: widget.driver.id,
            period: "monthly",
            months: 12,
          );
          
          final paymentTrends = await _apiService.getDriverPaymentTrends(
            driverId: widget.driver.id,
            period: "monthly",
            months: 12,
          );
          
          // Process API data into chart format
          if (debtTrends['status'] == 'success' && debtTrends['data'] != null) {
            _debtChartData = _processApiChartData(debtTrends['data']['data']);
          } else {
            _debtChartData = _generateDebtData();
          }
          
          if (paymentTrends['status'] == 'success' && paymentTrends['data'] != null) {
            _paymentChartData = _processApiChartData(paymentTrends['data']['data']);
          } else {
            _paymentChartData = _generatePaymentData();
          }
          
          print('Successfully loaded chart data from API');
        } catch (apiError) {
          // API endpoints don't exist or failed, fall back to generated data
          print('Driver trend API endpoints failed, using generated data: $apiError');
          setState(() {
            _apiEndpointsAvailable = false;
          });
          _generateChartData();
        }
      } else {
        // API endpoints not available, use generated data directly
        print('Driver API endpoints not available, using generated data');
        _generateChartData();
      }
      
    } catch (e) {
      // Fallback to generated data if any error occurs
      print('Chart data loading failed, using generated data: $e');
      setState(() {
        _apiEndpointsAvailable = false;
      });
      _generateChartData();
    }
  }
  
  List<ChartData> _processApiChartData(dynamic apiData) {
    if (apiData is List) {
      return apiData.map<ChartData>((item) {
        return ChartData(
          label: item['period'] ?? item['label'] ?? '',
          value: (item['value'] ?? item['amount'] ?? 0).toDouble(),
        );
      }).toList();
    }
    return [];
  }

  Future<void> _loadFinancialSummary() async {
    // Simulate loading financial data
    setState(() {
      _totalAmountSubmitted = 450000.0;
      _totalOutstandingDebt = 85000.0;
      _totalDebtsRecorded = 320000.0;
      _totalPaid = 365000.0;
      _paymentConsistencyRating = "Late";
      _averagePaymentDelay = 3;
    });
  }

  Future<void> _loadPaymentHistory() async {
    // Simulate loading payment history
    final List<PaymentRecord> mockPayments = [
      PaymentRecord(
        paymentDate: DateTime.now().subtract(const Duration(days: 5)),
        amountPaid: 15000,
        previousDebt: 25000,
        associatedPeriod: "Siku 5 - Wiki 1",
        paymentMethod: "Cash",
        receiptStatus: "Issued",
      ),
      PaymentRecord(
        paymentDate: DateTime.now().subtract(const Duration(days: 12)),
        amountPaid: 20000,
        previousDebt: 45000,
        associatedPeriod: "Wiki 2",
        paymentMethod: "M-Pesa",
        receiptStatus: "Issued",
      ),
      PaymentRecord(
        paymentDate: DateTime.now().subtract(const Duration(days: 25)),
        amountPaid: 18000,
        previousDebt: 30000,
        associatedPeriod: "Mwezi 1 - Wiki 1",
        paymentMethod: "Bank Transfer",
        receiptStatus: "Pending",
      ),
    ];
    
    setState(() {
      _paymentHistory = mockPayments;
    });
  }

  Future<void> _loadDebtHistory() async {
    // Simulate loading debt history using imported DebtRecord model
    final List<DebtRecord> mockDebts = [
      DebtRecord(
        driverId: widget.driver.id,
        driverName: widget.driver.name,
        date: DateTime.now().subtract(const Duration(days: 3)).toIso8601String().split('T')[0],
        expectedAmount: 25000,
        isPaid: false,
        promisedToPay: true,
        promiseToPayAt: DateTime.now().add(const Duration(days: 2)),
      ),
      DebtRecord(
        driverId: widget.driver.id,
        driverName: widget.driver.name,
        date: DateTime.now().subtract(const Duration(days: 15)).toIso8601String().split('T')[0],
        expectedAmount: 30000,
        isPaid: true,
        paidAmount: 30000,
        promisedToPay: false,
      ),
      DebtRecord(
        driverId: widget.driver.id,
        driverName: widget.driver.name,
        date: DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        expectedAmount: 45000,
        isPaid: false,
        daysOverdue: 30,
        promisedToPay: true,
        promiseToPayAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
    
    setState(() {
      _debtHistory = mockDebts;
    });
  }

  void _generateChartData() {
    // Generate debt progress chart data - More realistic simulation
    _debtChartData = _generateDebtData();
    
    // Generate payment trends chart data - More realistic simulation
    _paymentChartData = _generatePaymentData();
  }
  
  List<ChartData> _generateDebtData() {
    // Simulate varying amounts of debt data based on driver history
    final now = DateTime.now();
    final List<ChartData> data = [];
    
    // Generate data for the last 12 months (or more depending on driver history)
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthLabel = _getMonthLabel(month);
      
      // Simulate debt amounts with realistic fluctuations
      final baseAmount = 30000 + (i * 2000);
      final variation = (i % 3 == 0) ? 8000 : (i % 2 == 0 ? -3000 : 5000);
      final debtAmount = (baseAmount + variation).clamp(15000, 60000).toDouble();
      
      data.add(ChartData(label: monthLabel, value: debtAmount));
    }
    
    return data;
  }
  
  List<ChartData> _generatePaymentData() {
    // Simulate varying payment data
    final now = DateTime.now();
    final List<ChartData> data = [];
    
    // Generate data for the last 12 months
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthLabel = _getMonthLabel(month);
      
      // Simulate payment amounts with growth trend
      final baseAmount = 15000 + (i * 1500);
      final variation = (i % 4 == 0) ? 3000 : (i % 3 == 0 ? -1000 : 2000);
      final paymentAmount = (baseAmount + variation).clamp(10000, 35000).toDouble();
      
      data.add(ChartData(label: monthLabel, value: paymentAmount));
    }
    
    return data;
  }
  
  String _getMonthLabel(DateTime date) {
    // Ultra-short month abbreviations for better chart readability
    const months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D'
    ];
    
    // Add year suffix if not current year
    final currentYear = DateTime.now().year;
    final monthAbbr = months[date.month - 1];
    
    if (date.year != currentYear) {
      return '$monthAbbr${date.year.toString().substring(2)}';
    }
    
    return monthAbbr;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Historia ya ${widget.driver.name}",
      body: _isLoading 
        ? ThemeConstants.buildResponsiveLoadingWidget(context)
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDriverBasicInfo(),
                ResponsiveHelper.verticalSpace(3),
                _buildFinancialSummary(),
                ResponsiveHelper.verticalSpace(3),
                _buildChartsSection(),
                ResponsiveHelper.verticalSpace(3),
                _buildPaymentHistorySection(),
                ResponsiveHelper.verticalSpace(3),
                _buildDebtHistorySection(),
                ResponsiveHelper.verticalSpace(2),
              ],
            ),
          ),
    );
  }

  Widget _buildDriverBasicInfo() {
    return _buildBlueBlendGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.person,
                color: ThemeConstants.primaryOrange,
                size: 24,
              ),
              ResponsiveHelper.horizontalSpace(2),
              Text(
                "Taarifa za Msingi",
                style: ThemeConstants.responsiveHeadingStyle(context),
              ),
            ],
          ),
          ResponsiveHelper.verticalSpace(2),
          _buildInfoRow("Jina Kamili", widget.driver.name),
          _buildInfoRow("Nambari ya Leseni", widget.driver.licenseNumber ?? "Hakuna"),
          _buildInfoRow("Simu", widget.driver.phone),
          _buildInfoRow("Aina ya Gari", widget.driver.vehicleType ?? "Boda Boda"),
          _buildInfoRow("Nambari ya Gari", widget.driver.vehicleNumber ?? "Hakuna"),
          _buildInfoRow("Tarehe ya Kuanza Kazi", 
            DateFormat("dd/MM/yyyy").format(widget.driver.joinedDate)),
          _buildInfoRow("Hali ya Sasa", 
            widget.driver.status == "active" ? "Hai" : "Haipo"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: ResponsiveHelper.wp(30),
            child: Text(
              "$label:",
              style: ThemeConstants.responsiveSubHeadingStyle(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ThemeConstants.responsiveBodyStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Muhtasari wa Kifedha",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              _buildFinancialSummaryGrid(),
              ResponsiveHelper.verticalSpace(2),
              _buildPaymentConsistencyCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveHelper.isMobile ? 2 : 4,
      childAspectRatio: ResponsiveHelper.isMobile ? 1.5 : 1.2,
      mainAxisSpacing: ResponsiveHelper.spacingM,
      crossAxisSpacing: ResponsiveHelper.spacingM,
      children: <Widget>[
        _buildFinancialCard(
          "Jumla Iliyowasilishwa",
          _totalAmountSubmitted,
          Icons.upload,
          ThemeConstants.primaryOrange,
        ),
        _buildFinancialCard(
          "Deni Linalosalia",
          _totalOutstandingDebt,
          Icons.warning,
          ThemeConstants.errorRed,
        ),
        _buildFinancialCard(
          "Jumla ya Madeni",
          _totalDebtsRecorded,
          Icons.history,
          ThemeConstants.warningAmber,
        ),
        _buildFinancialCard(
          "Jumla Alipolipa",
          _totalPaid,
          Icons.paid,
          ThemeConstants.successGreen,
        ),
      ],
    );
  }

  Widget _buildFinancialCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: ResponsiveHelper.cardPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 28),
          ResponsiveHelper.verticalSpace(1),
          Text(
            title,
            style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ResponsiveHelper.verticalSpace(0.5),
          Text(
            "TSh ${NumberFormat('#,###').format(amount)}",
            style: ThemeConstants.responsiveBodyStyle(context).copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConsistencyCard() {
    final Color ratingColor = _paymentConsistencyRating == "Consistent" 
        ? ThemeConstants.successGreen
        : _paymentConsistencyRating == "Late" 
        ? ThemeConstants.errorRed
        : ThemeConstants.warningAmber;
    
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.cardPadding,
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ratingColor.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Kiwango cha Ulipaji",
                    style: ThemeConstants.responsiveSubHeadingStyle(context).copyWith(
                      color: ratingColor,
                    ),
                  ),
                  Text(
                    _paymentConsistencyRating,
                    style: ThemeConstants.responsiveHeadingStyle(context).copyWith(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "Wastani wa Kuchelewa",
                    style: ThemeConstants.responsiveSubHeadingStyle(context).copyWith(
                      color: ratingColor,
                    ),
                  ),
                  Text(
                    "$_averagePaymentDelay siku",
                    style: ThemeConstants.responsiveHeadingStyle(context).copyWith(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Mchoro wa Takwimu",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              // Chart type selector - Fixed overflow
              ResponsiveHelper.isMobile
                  ? Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedChartType = "debt";
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _selectedChartType == "debt" 
                                  ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedChartType == "debt"
                                    ? ThemeConstants.primaryOrange
                                    : ThemeConstants.textSecondary,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.trending_down,
                                  color: _selectedChartType == "debt"
                                      ? Colors.white
                                      : ThemeConstants.textPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Mwelekeo wa Deni",
                                    style: TextStyle(
                                      color: _selectedChartType == "debt"
                                          ? Colors.white
                                          : ThemeConstants.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedChartType = "payment";
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _selectedChartType == "payment" 
                                  ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedChartType == "payment"
                                    ? ThemeConstants.primaryOrange
                                    : ThemeConstants.textSecondary,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.trending_up,
                                  color: _selectedChartType == "payment"
                                      ? Colors.white
                                      : ThemeConstants.textPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Mwelekeo wa Malipo",
                                    style: TextStyle(
                                      color: _selectedChartType == "payment"
                                          ? Colors.white
                                          : ThemeConstants.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChartType = "debt";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedChartType == "debt" 
                                    ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedChartType == "debt"
                                      ? ThemeConstants.primaryOrange
                                      : ThemeConstants.textSecondary,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.trending_down,
                                    color: _selectedChartType == "debt"
                                        ? Colors.white
                                        : ThemeConstants.textPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Mwelekeo wa Deni",
                                      style: TextStyle(
                                        color: _selectedChartType == "debt"
                                            ? Colors.white
                                            : ThemeConstants.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveHelper.isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChartType = "payment";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedChartType == "payment" 
                                    ? ThemeConstants.primaryOrange.withOpacity(0.8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedChartType == "payment"
                                      ? ThemeConstants.primaryOrange
                                      : ThemeConstants.textSecondary,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.trending_up,
                                    color: _selectedChartType == "payment"
                                        ? Colors.white
                                        : ThemeConstants.textPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Mwelekeo wa Malipo",
                                      style: TextStyle(
                                        color: _selectedChartType == "payment"
                                            ? Colors.white
                                            : ThemeConstants.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveHelper.isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              ResponsiveHelper.verticalSpace(3),
              // Dynamic chart display with refresh option
              Column(
                children: [
                  // Data source indicator
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _apiEndpointsAvailable 
                          ? ThemeConstants.successGreen.withOpacity(0.1)
                          : ThemeConstants.warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _apiEndpointsAvailable 
                            ? ThemeConstants.successGreen.withOpacity(0.3)
                            : ThemeConstants.warningAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _apiEndpointsAvailable ? Icons.cloud_done : Icons.device_unknown,
                          size: 14,
                          color: _apiEndpointsAvailable 
                              ? ThemeConstants.successGreen
                              : ThemeConstants.warningAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _apiEndpointsAvailable 
                              ? "Data kutoka API"
                              : "Data ya mfano (API haipo)",
                          style: TextStyle(
                            fontSize: 11,
                            color: _apiEndpointsAvailable 
                                ? ThemeConstants.successGreen
                                : ThemeConstants.warningAmber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chart refresh indicator
                  if (_isLoading)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryOrange),
                      ),
                    ),
                  // Chart display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedChartType == "debt" 
                        ? _buildDebtChart()
                        : _buildPaymentChart(),
                  ),
                  // Chart actions
                  ResponsiveHelper.verticalSpace(2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isLoading ? null : () async {
                          await _loadChartData();
                        },
                        icon: Icon(
                          Icons.refresh,
                          size: 16,
                          color: _isLoading ? ThemeConstants.textSecondary : ThemeConstants.primaryOrange,
                        ),
                        label: Text(
                          "Onyesha Data",
                          style: TextStyle(
                            color: _isLoading ? ThemeConstants.textSecondary : ThemeConstants.primaryOrange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtChart() {
    if (_debtChartData.isEmpty) {
      return SizedBox(
        height: ResponsiveHelper.hp(30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_down,
                size: 48,
                color: ThemeConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                "Hakuna data ya madeni",
                style: ThemeConstants.responsiveBodyStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate dynamic values for flexible scaling
    final double maxValue = _debtChartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double minValue = _debtChartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue;
    final double padding = range * 0.1; // 10% padding
    
    return SizedBox(
      height: ResponsiveHelper.hp(30),
      key: const ValueKey("debt_chart"),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          // Dynamic scaling based on data
          minX: 0,
          maxX: (_debtChartData.length - 1).toDouble(),
          minY: (minValue - padding).clamp(0, double.infinity),
          maxY: maxValue + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 5 : 1000, // Dynamic grid intervals
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: ThemeConstants.textSecondary.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _debtChartData.length > 8 ? 4 : _debtChartData.length > 6 ? 3 : 2, // Dynamic intervals based on data count
                reservedSize: ResponsiveHelper.isMobile ? 50 : 40, // More space for rotated labels on mobile
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _debtChartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: ResponsiveHelper.isMobile ? -0.5 : 0, // Slight rotation on mobile
                        child: Text(
                          _debtChartData[value.toInt()].label,
                          style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
                            fontSize: ResponsiveHelper.isMobile ? 9 : 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: range > 0 ? range / 4 : 1000, // Dynamic intervals
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) {
                    return Text(
                      "${(value / 1000000).toStringAsFixed(1)}M",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else if (value >= 1000) {
                    return Text(
                      "${(value / 1000).toStringAsFixed(0)}K",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else {
                    return Text(
                      value.toStringAsFixed(0),
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  }
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _debtChartData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              color: ThemeConstants.errorRed,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: ThemeConstants.errorRed.withOpacity(0.3),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: ResponsiveHelper.isMobile ? 3 : 4,
                    color: ThemeConstants.errorRed,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChart() {
    if (_paymentChartData.isEmpty) {
      return SizedBox(
        height: ResponsiveHelper.hp(30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: ThemeConstants.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                "Hakuna data ya malipo",
                style: ThemeConstants.responsiveBodyStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate dynamic values for flexible scaling
    final double maxValue = _paymentChartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double minValue = _paymentChartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double range = maxValue - minValue;
    final double padding = range * 0.1; // 10% padding
    
    // Dynamic bar width based on data count
    final double barWidth = _paymentChartData.length > 12 
        ? (ResponsiveHelper.isMobile ? 12 : 16) 
        : (ResponsiveHelper.isMobile ? 20 : 30);
    
    return SizedBox(
      height: ResponsiveHelper.hp(30),
      key: const ValueKey("payment_chart"),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          alignment: BarChartAlignment.spaceAround,
          // Dynamic scaling based on data
          minY: 0,
          maxY: maxValue + padding,
          barGroups: _paymentChartData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: ThemeConstants.successGreen,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(4),
                  // Add gradient effect for better visualization
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.successGreen,
                      ThemeConstants.successGreen.withOpacity(0.7),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 5 : 1000, // Dynamic grid intervals
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: ThemeConstants.textSecondary.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _paymentChartData.length > 8 ? 4 : _paymentChartData.length > 6 ? 3 : 2, // Dynamic intervals based on data count
                reservedSize: ResponsiveHelper.isMobile ? 50 : 40, // More space for rotated labels on mobile
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _paymentChartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: ResponsiveHelper.isMobile ? -0.5 : 0, // Slight rotation on mobile
                        child: Text(
                          _paymentChartData[value.toInt()].label,
                          style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
                            fontSize: ResponsiveHelper.isMobile ? 9 : 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: range > 0 ? range / 4 : 1000, // Dynamic intervals
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) {
                    return Text(
                      "${(value / 1000000).toStringAsFixed(1)}M",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else if (value >= 1000) {
                    return Text(
                      "${(value / 1000).toStringAsFixed(0)}K",
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  } else {
                    return Text(
                      value.toStringAsFixed(0),
                      style: ThemeConstants.responsiveCaptionStyle(context),
                    );
                  }
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Historia ya Malipo",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              // Table header - Made scrollable on mobile
              ResponsiveHelper.isMobile
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: 800, // Fixed width to prevent cramping
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeConstants.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(width: 80, child: Text("Tarehe", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 100, child: Text("Kiasi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 120, child: Text("Deni la Awali", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 150, child: Text("Kipindi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 100, child: Text("Njia", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 80, child: Text("Risiti", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: Text("Tarehe", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Kiasi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Deni la Awali", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 3, child: Text("Kipindi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Njia", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 1, child: Text("Risiti", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                        ],
                      ),
                    ),
              ResponsiveHelper.verticalSpace(1),
              // Payment records - Made scrollable on mobile
              ResponsiveHelper.isMobile
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 800, // Fixed width to match header
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _paymentHistory.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: ThemeConstants.textSecondary,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final payment = _paymentHistory[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      DateFormat("dd/MM/yy").format(payment.paymentDate),
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      "${NumberFormat('#,###').format(payment.amountPaid)}",
                                      style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                                        color: ThemeConstants.successGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      "${NumberFormat('#,###').format(payment.previousDebt)}",
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      payment.associatedPeriod,
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      payment.paymentMethod,
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: IconButton(
                                      icon: Icon(
                                        payment.receiptStatus == "Issued" 
                                            ? Icons.receipt
                                            : Icons.receipt_long_outlined,
                                        color: payment.receiptStatus == "Issued"
                                            ? ThemeConstants.successGreen
                                            : ThemeConstants.warningAmber,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _showReceiptDialog(payment);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paymentHistory.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: ThemeConstants.textSecondary,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final payment = _paymentHistory[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat("dd/MM/yy").format(payment.paymentDate),
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${NumberFormat('#,###').format(payment.amountPaid)}",
                                  style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                                    color: ThemeConstants.successGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${NumberFormat('#,###').format(payment.previousDebt)}",
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  payment.associatedPeriod,
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  payment.paymentMethod,
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: Icon(
                                    payment.receiptStatus == "Issued" 
                                        ? Icons.receipt
                                        : Icons.receipt_long_outlined,
                                    color: payment.receiptStatus == "Issued"
                                        ? ThemeConstants.successGreen
                                        : ThemeConstants.warningAmber,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _showReceiptDialog(payment);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Historia ya Madeni",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              // Table header - Made scrollable on mobile
              ResponsiveHelper.isMobile
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: 750, // Fixed width to prevent cramping
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeConstants.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(width: 80, child: Text("Tarehe", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 180, child: Text("Maelezo", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 120, child: Text("Kiasi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 100, child: Text("Ahadi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                            SizedBox(width: 100, child: Text("Hali", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeConstants.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: Text("Tarehe", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 3, child: Text("Maelezo", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Kiasi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Ahadi", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                          Expanded(flex: 2, child: Text("Hali", style: ThemeConstants.responsiveSubHeadingStyle(context))),
                        ],
                      ),
                    ),
              ResponsiveHelper.verticalSpace(1),
              // Debt records - Made scrollable on mobile
              ResponsiveHelper.isMobile
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 750, // Fixed width to match header
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _debtHistory.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: ThemeConstants.textSecondary,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final debt = _debtHistory[index];
                            Color statusColor = _getDebtStatusColor(debt);
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      debt.formattedDate,
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      "Deni la ${debt.formattedDate}",
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      "${NumberFormat('#,###').format(debt.expectedAmount)}",
                                      style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                                        color: ThemeConstants.errorRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      debt.promiseToPayAt != null 
                                          ? DateFormat("dd/MM/yy").format(debt.promiseToPayAt!)
                                          : "Hakuna",
                                      style: ThemeConstants.responsiveBodyStyle(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        _getDebtStatusText(debt),
                                        style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _debtHistory.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: ThemeConstants.textSecondary,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final debt = _debtHistory[index];
                        Color statusColor = _getDebtStatusColor(debt);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  debt.formattedDate,
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Deni la ${debt.formattedDate}",
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${NumberFormat('#,###').format(debt.expectedAmount)}",
                                  style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                                    color: ThemeConstants.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  debt.promiseToPayAt != null 
                                      ? DateFormat("dd/MM/yy").format(debt.promiseToPayAt!)
                                      : "Hakuna",
                                  style: ThemeConstants.responsiveBodyStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    _getDebtStatusText(debt),
                                    style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return ThemeConstants.successGreen;
      case 'ongoing':
        return ThemeConstants.warningAmber;
      case 'late':
        return ThemeConstants.errorRed;
      case 'canceled':
        return ThemeConstants.textSecondary;
      default:
        return ThemeConstants.textPrimary;
    }
  }

  Color _getDebtStatusColor(DebtRecord debt) {
    if (debt.isPaid) {
      return ThemeConstants.successGreen;
    } else if (debt.isOverdue) {
      return ThemeConstants.errorRed;
    } else {
      return ThemeConstants.warningAmber;
    }
  }

  String _getDebtStatusText(DebtRecord debt) {
    if (debt.isPaid) {
      return "Imeshalipwa";
    } else if (debt.isOverdue) {
      return "Imechelewa";
    } else {
      return "Haijalipwa";
    }
  }

  void _showReceiptDialog(PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
          title: Text(
            "Risiti ya Malipo",
            style: ThemeConstants.responsiveHeadingStyle(context),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Tarehe: ${DateFormat("dd/MM/yyyy").format(payment.paymentDate)}", 
                style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Kiasi: TSh ${NumberFormat('#,###').format(payment.amountPaid)}", 
                style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Njia ya Malipo: ${payment.paymentMethod}", 
                style: ThemeConstants.responsiveBodyStyle(context)),
              Text("Hali ya Risiti: ${payment.receiptStatus}", 
                style: ThemeConstants.responsiveBodyStyle(context)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Funga",
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: ThemeConstants.primaryOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Data models
class PaymentRecord {
  final DateTime paymentDate;
  final double amountPaid;
  final double previousDebt;
  final String associatedPeriod;
  final String paymentMethod;
  final String receiptStatus;

  PaymentRecord({
    required this.paymentDate,
    required this.amountPaid,
    required this.previousDebt,
    required this.associatedPeriod,
    required this.paymentMethod,
    required this.receiptStatus,
  });
}

// DebtRecord is imported from payment.dart
// Using a simple alias class for driver history
class DriverHistoryDebtRecord {
  final DateTime debtDate;
  final String description;
  final double amountOwed;
  final DateTime? promiseToPayDate;
  final String status;

  DriverHistoryDebtRecord({
    required this.debtDate,
    required this.description,
    required this.amountOwed,
    this.promiseToPayDate,
    required this.status,
  });
}

class ChartData {
  final String label;
  final double value;

  ChartData({
    required this.label,
    required this.value,
  });
}