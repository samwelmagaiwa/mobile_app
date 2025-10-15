// ignore_for_file: avoid_dynamic_calls
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/colors.dart";
import "../../constants/styles.dart";
import "../../constants/theme_constants.dart";
import "../../services/api_service.dart";
import "../../services/localization_service.dart";
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
    if (revenueData == null) return 0;

    // Try common growth keys provided by backend reports
    final dynamic direct = revenueData['growth_rate'] ??
        revenueData['revenue_growth'] ??
        (revenueData['data'] is Map
            ? (revenueData['data']['growth_rate'] ??
                revenueData['data']['revenue_growth'])
            : null);
    if (direct is num) return direct.toDouble();
    if (direct is String) return double.tryParse(direct) ?? 0;

    // If there is daily/monthly series, estimate simple MoM/period change when possible
    try {
      final List<dynamic> series = (revenueData['daily_data'] ??
              revenueData['series'] ??
              (revenueData['data'] is Map
                  ? (revenueData['data']['daily_data'] ??
                      revenueData['data']['series'])
                  : null))
          ?.cast<dynamic>() ??
          <dynamic>[];
      if (series.length >= 2) {
        final double last = _toNumLike(series.last).toDouble();
        final double prev = _toNumLike(series[series.length - 2]).toDouble();
        if (prev == 0) return last > 0 ? 100 : 0;
        return ((last - prev) / prev) * 100;
      }
    } on Exception {
      // ignore, fall through
    }
    return 0;
  }

  double _calculateProfitMargin(
      Map<String, dynamic>? revenueData, Map<String, dynamic>? expenseData) {
    if (revenueData == null || expenseData == null) return 0;

    final double revenue = _extractFirstNumber(
      revenueData,
      const ['total_revenue', 'revenue_total', 'total'],
    );
    final double expenses = _extractFirstNumber(
      expenseData,
      const ['total_expenses', 'expenses_total', 'total'],
    );

    if (revenue <= 0) return 0;
    return ((revenue - expenses) / revenue) * 100;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) => ThemeConstants.buildResponsiveScaffold(
        context,
        title: localizationService.translate('analytics_dashboard'),
        body: _isLoading
            ? ThemeConstants.buildResponsiveLoadingWidget(context)
            : SingleChildScrollView(
                padding: ResponsiveHelper.defaultPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Period Selection
                    _buildPeriodSelector(localizationService),
                    const SizedBox(height: AppStyles.spacingL),

                    // Key Metrics
                    Text(
                      localizationService.translate('performance_metrics'),
                      style: ThemeConstants.headingStyle,
                    ),
                    const SizedBox(height: AppStyles.spacingM),
                    _buildKeyMetrics(localizationService),
                    const SizedBox(height: AppStyles.spacingL),

                    // Performance Charts
                    Text(
                      localizationService.translate('revenue_trends'),
                      style: ThemeConstants.headingStyle,
                    ),
                    const SizedBox(height: AppStyles.spacingM),
                    _buildPerformanceCharts(localizationService),
                    const SizedBox(height: AppStyles.spacingL),

                    // Trends Analysis
                    Text(
                      localizationService.translate('revenue_analytics'),
                      style: ThemeConstants.headingStyle,
                    ),
                    const SizedBox(height: AppStyles.spacingM),
                    _buildTrendsAnalysis(localizationService),
                    const SizedBox(height: AppStyles.spacingL),

                    // Insights
                    Text(
                      localizationService.translate('analytics'),
                      style: ThemeConstants.headingStyle,
                    ),
                    const SizedBox(height: AppStyles.spacingM),
                    _buildInsights(localizationService),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPeriodSelector(LocalizationService localizationService) => Row(
        children: <Widget>[
          Expanded(
            child: _PeriodButton(
              label: localizationService.translate('weekly'),
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
              label: localizationService.translate('monthly'),
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
              label: localizationService.translate('yearly'),
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

  Widget _buildKeyMetrics(LocalizationService localizationService) => Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  title: localizationService.translate('total_revenue'),
                  value:
                      "TSh ${_formatMoney(_extractFirstNumber(_analyticsData?['revenue'], const ['total_revenue','revenue_total','total']))}",
                  change: "+${(_analyticsData?['growth_rate'] as num? ?? 0).toStringAsFixed(1)}%",
                  isPositive: true,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _MetricCard(
                  title: localizationService.translate('net_profit'),
                  value:
                      "TSh ${_formatMoney(_computeProfit(_analyticsData))}",
                  change: "+${_computeProfitChange(_analyticsData)}%",
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
                  title: localizationService.translate('profit_margin'),
                  value:
                      "${(_analyticsData?['profit_margin'] as num? ?? 0).toStringAsFixed(1)}%",
                  change: "",
                  isPositive: true,
                  icon: Icons.pie_chart,
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _MetricCard(
                  title: localizationService.translate('new_customers'),
                  value:
                      "${_extractFirstInt(_analyticsData?['revenue'], const ['new_customers','customers_new','customers'])}",
                  change: "",
                  isPositive: true,
                  icon: Icons.person_add,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildPerformanceCharts(LocalizationService localizationService) => CustomCard(
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppStyles.spacingM),
                Text(
                  localizationService.translate('performance_charts'),
                  style: AppStyles.heading3,
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  localizationService.translate('detailed_charts_shown_here'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTrendsAnalysis(LocalizationService localizationService) => Column(
        children: <Widget>[
          _buildTrendItem(
              localizationService.translate('revenue_growth'),
              "+12.5% ${localizationService.translate('this_month')}",
              Icons.trending_up,
              AppColors.success,
              localizationService.translate('revenue_growth_improved')),
          const SizedBox(height: AppStyles.spacingM),
          _buildTrendItem(
              localizationService.translate('expense_efficiency'),
              "${localizationService.translate('decrease')} 8%",
              Icons.trending_down,
              AppColors.info,
              localizationService.translate('expenses_reduced_management')),
          const SizedBox(height: AppStyles.spacingM),
          _buildTrendItem(
              localizationService.translate('customer_performance'),
              "+15 ${localizationService.translate('new_customers')}",
              Icons.people,
              AppColors.warning,
              localizationService.translate('added_customers_this_month')),
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

  Widget _buildInsights(LocalizationService localizationService) => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.lightbulb,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Text(
                    localizationService.translate('ai_insights'),
                    style: AppStyles.heading3,
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                localizationService.translate('best_days_insights'),
                localizationService.translate('best_days_description'),
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                localizationService.translate('afternoon_earnings_insights'),
                localizationService.translate('afternoon_trips_profitable'),
              ),
              const SizedBox(height: AppStyles.spacingM),
              _buildInsightItem(
                localizationService.translate('fuel_usage_reduced'),
                localizationService.translate('fuel_management_helped'),
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

// Helper functions (top-level) for analytics number extraction and formatting
num _toNumLike(Object? v) {
  if (v is num) return v;
  if (v is Map && (v['amount'] != null || v['value'] != null)) {
    final dynamic raw = v['amount'] ?? v['value'];
    if (raw is num) return raw;
    return double.tryParse(raw.toString()) ?? 0;
  }
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double _extractFirstNumber(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return 0;
  // try at top level
  for (final String k in keys) {
    final dynamic v = map[k];
    if (v is num) return v.toDouble();
    if (v is String) {
      final double? d = double.tryParse(v);
      if (d != null) return d;
    }
  }
  // try nested under 'data'
  final dynamic data = map['data'];
  if (data is Map<String, dynamic>) {
    return _extractFirstNumber(data, keys);
  }
  return 0;
}

int _extractFirstInt(Map<String, dynamic>? map, List<String> keys) =>
    _extractFirstNumber(map, keys).round();

String _formatMoney(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

double _computeProfit(Map<String, dynamic>? data) {
  final double rev =
      _extractFirstNumber(data?['revenue'], const <String>['total_revenue', 'revenue_total', 'total']);
  final double exp =
      _extractFirstNumber(data?['expenses'], const <String>['total_expenses', 'expenses_total', 'total']);
  return (rev - exp).clamp(0, double.infinity);
}

String _computeProfitChange(Map<String, dynamic>? data) {
  // If backend supplies a profit_growth or similar, use it; otherwise empty
  final dynamic v = data?['profit_loss']?['profit_growth'] ??
      data?['revenue']?['profit_growth'] ??
      data?['data']?['profit_growth'];
  if (v is num) return v.toStringAsFixed(1);
  if (v is String) {
    final double? d = double.tryParse(v);
    if (d != null) return d.toStringAsFixed(1);
  }
  return '';
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
