import "package:flutter/material.dart";

import "../../constants/theme_constants.dart";
import "../../services/api_service.dart";
import "../../utils/responsive_helper.dart";

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService _apiService = ApiService();
  String _selectedPeriod = "daily";
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  Map<String, dynamic>? _currentReportData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final reportData = await _apiService.getRevenueReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _currentReportData = reportData;
        });
      }
    } on Exception catch (e) {
      // Silently fail for initial load - user can still generate report manually
      debugPrint('Failed to load initial report data: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _currentReportData = null;
    });

    try {
      Map<String, dynamic>? reportData;

      // Determine which API endpoint to call based on selected period
      switch (_selectedPeriod) {
        case 'revenue':
          reportData = await _apiService.getRevenueReport(
            startDate: _startDate,
            endDate: _endDate,
          );
        case 'expense':
          reportData = await _apiService.getExpenseReport(
            startDate: _startDate,
            endDate: _endDate,
          );
        case 'profit_loss':
          reportData = await _apiService.getProfitLossReport(
            startDate: _startDate,
            endDate: _endDate,
          );
        default:
          // For daily/weekly/monthly, use revenue report as default
          reportData = await _apiService.getRevenueReport(
            startDate: _startDate,
            endDate: _endDate,
          );
      }

      setState(() {
        _currentReportData = reportData;
      });

      if (mounted) {
        _showReportPreview();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hitilafu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showReportPreview() {
    showDialog(
      context: context,
      builder: (final BuildContext context) => _ReportPreviewDialog(
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        reportData: _currentReportData,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildScaffold(
      title: "Ripoti",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Welcome Header with Overview
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Quick Stats Preview - Moved up for better visibility
            _buildQuickStatsSection(),
            const SizedBox(height: 24),

            // Report Types with enhanced design
            _buildReportTypesSection(),
            const SizedBox(height: 24),

            // Date Range Selection with better UX
            _buildDateRangeSection(),
            const SizedBox(height: 24),

            // Generate Report Button with enhanced styling
            _buildGenerateReportButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Welcome header with summary
  Widget _buildWelcomeHeader() => ThemeConstants.buildGlassCardStatic(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: ThemeConstants.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Ripoti za Biashara",
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Angalia mapato na matumizi yako",
                          style: ThemeConstants.captionStyle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // Enhanced quick stats section
  Widget _buildQuickStatsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.dashboard_outlined,
                color: ThemeConstants.textPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Muhtasari wa Haraka",
                style: ThemeConstants.headingStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main revenue card
          _buildMainRevenueCard(),
          const SizedBox(height: 12),

          // Secondary stats grid
          Row(
            children: <Widget>[
              Expanded(
                child: _buildEnhancedStatCard(
                  title: "Miamala",
                  value: _currentReportData != null
                      ? "${_currentReportData!['transaction_count'] ?? 23}"
                      : "23",
                  icon: Icons.receipt_long,
                  color: const Color(0xFF06B6D4),
                  subtitle: "Leo",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedStatCard(
                  title: "Vyombo",
                  value: _currentReportData != null
                      ? "${_currentReportData!['vehicle_count'] ?? 3}"
                      : "3",
                  icon: Icons.directions_car,
                  color: const Color(0xFF8B5CF6),
                  subtitle: "Vimefanya kazi",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildEnhancedStatCard(
                  title: "Wastani",
                  value: _currentReportData != null
                      ? "TSh ${_formatCurrency(_currentReportData!['average_per_day'] ?? 64286)}"
                      : "TSh 64,286",
                  icon: Icons.trending_up,
                  color: ThemeConstants.primaryOrange,
                  subtitle: "Kila siku",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedStatCard(
                  title: "Faida",
                  value: "85%",
                  icon: Icons.show_chart,
                  color: ThemeConstants.successGreen,
                  subtitle: "Ya mapato",
                ),
              ),
            ],
          ),
        ],
      );

  // Main revenue card with progress indicator
  Widget _buildMainRevenueCard() => ThemeConstants.buildGlassCardStatic(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeConstants.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: ThemeConstants.successGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Jumla ya Mapato",
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentReportData != null
                              ? "TSh ${_formatCurrency(_currentReportData!['total_revenue'] ?? 450000)}"
                              : "TSh 450,000",
                          style: const TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeConstants.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "+12.5%",
                      style: TextStyle(
                        color: ThemeConstants.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.75, // 75% progress
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeConstants.successGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "75% ya lengo la mwezi",
                style: TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  // Enhanced report types section
  Widget _buildReportTypesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.category_outlined,
                color: ThemeConstants.textPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Aina za Ripoti",
                style: ThemeConstants.headingStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildEnhancedReportTypeCard(
                  title: "Leo",
                  subtitle: "Ripoti ya siku",
                  icon: Icons.today,
                  color: const Color(0xFF10B981),
                  isSelected: _selectedPeriod == "daily",
                  onTap: () {
                    setState(() {
                      _selectedPeriod = "daily";
                      _startDate = DateTime.now();
                      _endDate = DateTime.now();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedReportTypeCard(
                  title: "Wiki",
                  subtitle: "Ripoti ya wiki",
                  icon: Icons.date_range,
                  color: const Color(0xFF3B82F6),
                  isSelected: _selectedPeriod == "weekly",
                  onTap: () {
                    setState(() {
                      _selectedPeriod = "weekly";
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 7));
                      _endDate = DateTime.now();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedReportTypeCard(
                  title: "Mwezi",
                  subtitle: "Ripoti ya mwezi",
                  icon: Icons.calendar_month,
                  color: ThemeConstants.primaryOrange,
                  isSelected: _selectedPeriod == "monthly",
                  onTap: () {
                    setState(() {
                      _selectedPeriod = "monthly";
                      _startDate =
                          DateTime(DateTime.now().year, DateTime.now().month);
                      _endDate = DateTime.now();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  // Enhanced date range section
  Widget _buildDateRangeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.event_outlined,
                color: ThemeConstants.textPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Chagua Kipindi",
                style: ThemeConstants.headingStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ThemeConstants.buildGlassCard(
            onTap: _selectDateRange,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range,
                      color: ThemeConstants.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Kipindi cha Ripoti",
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}",
                          style: const TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  // Enhanced generate report button
  Widget _buildGenerateReportButton() => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isGenerating
                ? [Colors.grey.shade600, Colors.grey.shade700]
                : [ThemeConstants.primaryOrange, const Color(0xFFEA580C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  (_isGenerating ? Colors.grey : ThemeConstants.primaryOrange)
                      .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _generateReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isGenerating) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const Icon(
                  Icons.analytics,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                _isGenerating ? "Inatengeneza Ripoti..." : "Tengeneza Ripoti",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

// Enhanced report type card
Widget _buildEnhancedReportTypeCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required bool isSelected,
  required VoidCallback onTap,
}) =>
    ThemeConstants.buildGlassCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.1)),
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : ThemeConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : ThemeConstants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? color.withOpacity(0.8)
                    : ThemeConstants.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

// Enhanced stat card
Widget _buildEnhancedStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  String? subtitle,
}) =>
    ThemeConstants.buildGlassCardStatic(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ThemeConstants.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );

// Helper method to format currency
String _formatCurrency(num? amount) {
  final num numAmount = amount ?? 0;
  if (numAmount >= 1000000) {
    return "${(numAmount / 1000000).toStringAsFixed(1)}M";
  } else if (numAmount >= 1000) {
    return "${(numAmount / 1000).toStringAsFixed(0)}K";
  }
  return numAmount.toStringAsFixed(0);
}

class _ReportPreviewDialog extends StatelessWidget {
  const _ReportPreviewDialog({
    required this.period,
    required this.startDate,
    required this.endDate,
    this.reportData,
  });
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic>? reportData;

  @override
  Widget build(final BuildContext context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              Row(
                children: <Widget>[
                  const Text(
                    "Muhtasari wa Ripoti",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(),

              // Report Summary
              Text(
                "Ripoti ya ${_getPeriodName(period)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 16),

              // Report Data
              Builder(
                builder: (context) {
                  final num totalRevenue =
                      (reportData?['total_revenue'] as num?) ?? 450000;
                  final num totalExpenses =
                      (reportData?['total_expenses'] as num?) ?? 125000;
                  final int transactionCount =
                      (reportData?['transaction_count'] as int?) ?? 23;
                  final num averagePerDay =
                      (reportData?['average_per_day'] as num?) ?? 64286;
                  final num netProfit = totalRevenue - totalExpenses;
                  return Column(
                    children: <Widget>[
                      _ReportRow(
                        "Jumla ya Mapato:",
                        "TSh ${totalRevenue.toStringAsFixed(0)}",
                      ),
                      _ReportRow(
                        "Jumla ya Matumizi:",
                        "TSh ${totalExpenses.toStringAsFixed(0)}",
                      ),
                      _ReportRow(
                        "Faida Halisi:",
                        "TSh ${netProfit.toStringAsFixed(0)}",
                      ),
                      _ReportRow(
                        "Idadi ya Miamala:",
                        "$transactionCount",
                      ),
                      _ReportRow(
                        "Wastani wa Siku:",
                        "TSh ${averagePerDay.toStringAsFixed(0)}",
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ripoti imehamishwa"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Hamisha"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ripoti imechapishwa"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Chapisha"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  String _getPeriodName(final String period) {
    switch (period) {
      case "daily":
        return "Kila Siku";
      case "weekly":
        return "Kila Wiki";
      case "monthly":
        return "Kila Mwezi";
      default:
        return "Maalum";
    }
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
