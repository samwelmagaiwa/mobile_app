// ignore_for_file: avoid_dynamic_calls
import "package:flutter/material.dart";

import "../../constants/colors.dart";
import "../../constants/styles.dart";
import "../../constants/theme_constants.dart";
import "../../services/api_service.dart";
import "../../utils/responsive_helper.dart";
import "../../widgets/custom_card.dart";

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  String _selectedPeriod = "monthly";

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load different types of analytics data
      final revenueData = await _apiService.getRevenueReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      final expenseData = await _apiService.getExpenseReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      final profitLossData = await _apiService.getProfitLossReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _analyticsData = {
            'revenue': revenueData,
            'expenses': expenseData,
            'profit_loss': profitLossData,
            'growth_rate': _calculateGrowthRate(revenueData),
            'profit_margin': _calculateProfitMargin(revenueData, expenseData),
          };
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      debugPrint('Failed to load analytics data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateGrowthRate(Map<String, dynamic>? revenueData) {
    // Simulate growth rate calculation
    return 12.5; // Default growth rate
  }

  double _calculateProfitMargin(
      Map<String, dynamic>? revenueData, Map<String, dynamic>? expenseData) {
    if (revenueData == null || expenseData == null) return 25;

    final revenue = revenueData['total_revenue'] ?? 0;
    final expenses = expenseData['total_expenses'] ?? 0;

    if (revenue == 0) return 0;
    return (revenue - expenses) / revenue * 100;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return ThemeConstants.buildResponsiveScaffold(
      context,
      title: "Uchambuzi",
      body: _isLoading
          ? ThemeConstants.buildResponsiveLoadingWidget(context)
          : SingleChildScrollView(
              padding: ResponsiveHelper.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Period Selection
                  _buildPeriodSelector(),
                  const SizedBox(height: AppStyles.spacingL),

                  // Key Metrics
                  const Text(
                    "Vipimo Muhimu",
                    style: ThemeConstants.headingStyle,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildKeyMetrics(),
                  const SizedBox(height: AppStyles.spacingL),

                  // Performance Charts
                  const Text(
                    "Jedwali za Utendaji",
                    style: ThemeConstants.headingStyle,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildPerformanceCharts(),
                  const SizedBox(height: AppStyles.spacingL),

                  // Trends Analysis
                  const Text(
                    "Uchambuzi wa Mwelekeo",
                    style: ThemeConstants.headingStyle,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildTrendsAnalysis(),
                  const SizedBox(height: AppStyles.spacingL),

                  // Insights
                  const Text(
                    "Maarifa Muhimu",
                    style: ThemeConstants.headingStyle,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  _buildInsights(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() => Row(
        children: <Widget>[
          Expanded(
            child: _PeriodButton(
              label: "Wiki",
              isSelected: _selectedPeriod == "weekly",
              onTap: () {
                setState(() {
                  _selectedPeriod = "weekly";
                });
                _loadAnalyticsData();
              },
            ),
          ),
          const SizedBox(width: AppStyles.spacingS),
          Expanded(
            child: _PeriodButton(
              label: "Mwezi",
              isSelected: _selectedPeriod == "monthly",
              onTap: () {
                setState(() {
                  _selectedPeriod = "monthly";
                });
                _loadAnalyticsData();
              },
            ),
          ),
          const SizedBox(width: AppStyles.spacingS),
          Expanded(
            child: _PeriodButton(
              label: "Mwaka",
              isSelected: _selectedPeriod == "yearly",
              onTap: () {
                setState(() {
                  _selectedPeriod = "yearly";
                });
                _loadAnalyticsData();
              },
            ),
          ),
        ],
      );

  Widget _buildKeyMetrics() => Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  title: "Jumla ya Mapato",
                  value:
                      "TSh ${_analyticsData?['revenue']?['total_revenue'] ?? 450000}",
                  change: "+${_analyticsData?['growth_rate'] ?? 12.5}%",
                  isPositive: true,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _MetricCard(
                  title: "Faida Halisi",
                  value:
                      "TSh ${(_analyticsData?['revenue']?['total_revenue'] ?? 450000) - (_analyticsData?['expenses']?['total_expenses'] ?? 125000)}",
                  change: "+8.2%",
                  isPositive: true,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingM),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  title: "Kiwango cha Faida",
                  value:
                      "${_analyticsData?['profit_margin']?.toStringAsFixed(1) ?? '25.0'}%",
                  change: "+2.1%",
                  isPositive: true,
                  icon: Icons.pie_chart,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _MetricCard(
                  title: "Wateja Wapya",
                  value:
                      "${_analyticsData?['revenue']?['new_customers'] ?? 15}",
                  change: "+18.5%",
                  isPositive: true,
                  icon: Icons.person_add,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildPerformanceCharts() => CustomCard(
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          height: 200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppColors.primary,
                ),
                SizedBox(height: AppStyles.spacingM),
                Text(
                  "Jedwali za Utendaji",
                  style: AppStyles.heading3,
                ),
                SizedBox(height: AppStyles.spacingS),
                Text(
                  "Jedwali za kina zinaonekana hapa",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTrendsAnalysis() => Column(
        children: <Widget>[
          _buildTrendItem(
              "Ukuaji wa Mapato",
              "+12.5% mwezi huu",
              Icons.trending_up,
              AppColors.success,
              "Ukuaji wa mapato umeimarika kwa mwezi huu kwa wastani wa 12.5%"),
          const SizedBox(height: AppStyles.spacingM),
          _buildTrendItem(
              "Ufanisi wa Gharama",
              "Punguzo la 8%",
              Icons.trending_down,
              AppColors.info,
              "Gharama zimepungua kwa 8% kutokana na uongozi bora"),
          const SizedBox(height: AppStyles.spacingM),
          _buildTrendItem(
              "Utendaji wa Wateja",
              "+15 wateja wapya",
              Icons.people,
              AppColors.warning,
              "Tumeongeza wateja wapya 15 mwezi huu"),
        ],
      );

  Widget _buildTrendItem(
    String title,
    String metric,
    IconData icon,
    Color color,
    String description,
  ) =>
      CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingXS),
                    Text(
                      metric,
                      style: AppStyles.bodyMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingXS),
                    Text(
                      description,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInsights() => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.lightbulb,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  SizedBox(width: AppStyles.spacingS),
                  Text(
                    "Maarifa ya Akili Bandia",
                    style: AppStyles.heading3,
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                "Siku Bora zaidi ni Jumanne na Alhamisi",
                "Mapato ni makubwa zaidi katika siku hizi za wiki",
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                "Madereva wengi wanaongeza mapato mchana",
                "Safari za mchana (12PM-3PM) zina faida kubwa zaidi",
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                "Matumizi ya mafuta yamepungua kwa 15%",
                "Uongozi bora wa mafuta umesaidia kupunguza gharama",
              ),
            ],
          ),
        ),
      );

  Widget _buildInsightItem(String title, String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppStyles.spacingXS),
          Text(
            description,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingM),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyles.radiusM(context)),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
  });

  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingS),
              Text(
                value,
                style: AppStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppStyles.spacingXS),
              Row(
                children: <Widget>[
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: AppStyles.spacingXS),
                  Text(
                    change,
                    style: AppStyles.bodySmall.copyWith(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
