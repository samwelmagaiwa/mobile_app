// ignore_for_file: avoid_dynamic_calls
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/theme_constants.dart";
import "../../services/api_service.dart";
import "../../services/localization_service.dart";

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
      final revenueData = await _apiService.getAdminRevenueReport(
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
      final List<dynamic> series = _revenueSeries(revenueData);
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

  /// Pulls whatever daily/period series the revenue report exposes, in
  /// whichever of the shapes different report endpoints use.
  List<dynamic> _revenueSeries(Map<String, dynamic>? revenueData) {
    if (revenueData == null) return const <dynamic>[];
    final dynamic series = revenueData['daily_data'] ??
        revenueData['series'] ??
        (revenueData['data'] is Map
            ? (revenueData['data']['daily_data'] ??
                revenueData['data']['series'])
            : null);
    return (series as List<dynamic>?) ?? const <dynamic>[];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, loc, child) => Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ThemeConstants.textPrimary),
          title: Text(
            loc.translate('analytics_dashboard'),
            style: ThemeConstants.headingStyle.copyWith(fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalyticsData,
                  backgroundColor: Colors.white,
                  color: ThemeConstants.primaryBlue,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: <Widget>[
                      _PeriodSelector(
                        selected: _selectedPeriod,
                        labels: <String, String>{
                          'weekly': loc.translate('weekly'),
                          'monthly': loc.translate('monthly'),
                          'yearly': loc.translate('yearly'),
                        },
                        onSelected: (String p) {
                          setState(() => _selectedPeriod = p);
                          _loadAnalyticsData();
                        },
                      ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        icon: Icons.speed_rounded,
                        title: loc.translate('performance_metrics'),
                      ),
                      const SizedBox(height: 12),
                      _buildKeyMetrics(loc),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.show_chart_rounded,
                        title: loc.translate('revenue_trends'),
                      ),
                      const SizedBox(height: 12),
                      _buildPerformanceChart(loc),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.insights_rounded,
                        title: loc.translate('revenue_analytics'),
                      ),
                      const SizedBox(height: 12),
                      _buildTrendsAnalysis(loc),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: Icons.lightbulb_outline_rounded,
                        title: loc.translate('analytics'),
                      ),
                      const SizedBox(height: 12),
                      _buildInsights(loc),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(LocalizationService loc) {
    final double growth = (_analyticsData?['growth_rate'] as num? ?? 0).toDouble();
    final double margin = (_analyticsData?['profit_margin'] as num? ?? 0).toDouble();
    final String profitChangeRaw = _computeProfitChange(_analyticsData);
    final double? profitChange = double.tryParse(profitChangeRaw);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: <Widget>[
        _MetricCard(
          title: loc.translate('total_revenue'),
          value: "TSh ${_formatMoney(_extractFirstNumber(_analyticsData?['revenue'], const [
                'total_revenue',
                'revenue_total',
                'total',
              ]))}",
          change: "+${growth.toStringAsFixed(1)}%",
          isPositive: growth >= 0,
          icon: Icons.trending_up_rounded,
          accent: ThemeConstants.primaryCyan,
        ),
        _MetricCard(
          title: loc.translate('net_profit'),
          value: "TSh ${_formatMoney(_computeProfit(_analyticsData))}",
          change: profitChange != null
              ? "${profitChange >= 0 ? '+' : ''}${profitChange.toStringAsFixed(1)}%"
              : '',
          isPositive: (profitChange ?? 0) >= 0,
          icon: Icons.account_balance_wallet_rounded,
          accent: ThemeConstants.successGreen,
        ),
        _MetricCard(
          title: loc.translate('profit_margin'),
          value: "${margin.toStringAsFixed(1)}%",
          change: '',
          isPositive: margin >= 0,
          icon: Icons.pie_chart_rounded,
          accent: ThemeConstants.warningAmber,
        ),
        _MetricCard(
          title: loc.translate('new_customers'),
          value: "${_extractFirstInt(_analyticsData?['revenue'], const [
                'new_customers',
                'customers_new',
                'customers',
              ])}",
          change: '',
          isPositive: true,
          icon: Icons.person_add_alt_1_rounded,
          accent: ThemeConstants.primaryOrange,
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(LocalizationService loc) {
    final List<dynamic> rawSeries = _revenueSeries(_analyticsData?['revenue']);
    final List<double> values =
        rawSeries.map((dynamic e) => _toNumLike(e).toDouble()).toList();

    return Container(
      decoration: ThemeConstants.glassCardDecoration,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      height: 220,
      child: values.length < 2
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.bar_chart_rounded,
                      size: 40, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(height: 10),
                  Text(
                    loc.translate('no_data_for_period'),
                    style: ThemeConstants.captionStyle,
                  ),
                ],
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      (values.reduce((a, b) => a > b ? a : b) / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => ThemeConstants.primaryBlue,
                    getTooltipItems: (List<LineBarSpot> spots) => spots
                        .map((LineBarSpot s) => LineTooltipItem(
                              _formatMoney(s.y),
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: <FlSpot>[
                      for (int i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    color: ThemeConstants.primaryCyan,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          ThemeConstants.primaryCyan.withValues(alpha: 0.28),
                          ThemeConstants.primaryCyan.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static const Map<String, String> _dayKeys = <String, String>{
    'Monday': 'monday',
    'Tuesday': 'tuesday',
    'Wednesday': 'wednesday',
    'Thursday': 'thursday',
    'Friday': 'friday',
    'Saturday': 'saturday',
    'Sunday': 'sunday',
  };

  static const Map<String, String> _timeBucketKeys = <String, String>{
    'morning': 'time_bucket_morning',
    'afternoon': 'time_bucket_afternoon',
    'evening': 'time_bucket_evening',
    'night': 'time_bucket_night',
  };

  Widget _buildTrendsAnalysis(LocalizationService loc) {
    final Map<String, dynamic>? revenue = _analyticsData?['revenue'] as Map<String, dynamic>?;
    final Map<String, dynamic>? expenses = _analyticsData?['expenses'] as Map<String, dynamic>?;

    final double revenueGrowth = (revenue?['revenue_growth'] as num? ?? 0).toDouble();
    final double expenseChange = (expenses?['expense_change'] as num? ?? 0).toDouble();
    final int newCustomers = (revenue?['new_customers'] as num? ?? 0).toInt();

    return Column(
      children: <Widget>[
        _TrendTile(
          title: loc.translate('revenue_growth'),
          metric: "${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth.toStringAsFixed(1)}% ${loc.translate('this_month')}",
          icon: revenueGrowth >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: revenueGrowth >= 0 ? ThemeConstants.successGreen : ThemeConstants.errorRed,
          description: loc.translate(
            revenueGrowth >= 0 ? 'revenue_growth_improved' : 'revenue_growth_declined',
          ),
        ),
        const SizedBox(height: 10),
        _TrendTile(
          title: loc.translate('expense_efficiency'),
          metric:
              "${loc.translate(expenseChange <= 0 ? 'decrease' : 'increase')} ${expenseChange.abs().toStringAsFixed(1)}%",
          icon: expenseChange <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          color: expenseChange <= 0 ? ThemeConstants.primaryCyan : ThemeConstants.warningAmber,
          description: loc.translate(
            expenseChange <= 0 ? 'expenses_reduced_management' : 'expenses_increased_warning',
          ),
        ),
        const SizedBox(height: 10),
        _TrendTile(
          title: loc.translate('customer_performance'),
          metric: "${newCustomers >= 0 ? '+' : ''}$newCustomers ${loc.translate('new_customers')}",
          icon: Icons.people_alt_rounded,
          color: ThemeConstants.warningAmber,
          description: loc.translate('added_customers_this_month'),
        ),
      ],
    );
  }

  Widget _buildInsights(LocalizationService loc) {
    final Map<String, dynamic>? revenue = _analyticsData?['revenue'] as Map<String, dynamic>?;
    final Map<String, dynamic>? expenses = _analyticsData?['expenses'] as Map<String, dynamic>?;

    final String? bestDay = revenue?['best_day'] as String?;
    final String? bestBucket = revenue?['best_time_bucket'] as String?;
    final double fuelChange = (expenses?['fuel_expense_change'] as num? ?? 0).toDouble();
    final bool hasFuelData = (expenses?['fuel_expenses'] as num? ?? 0) > 0;

    final List<Widget> items = <Widget>[];

    if (bestDay != null && _dayKeys.containsKey(bestDay)) {
      items.add(_InsightItem(
        title: loc.translate('best_day_insight_title'),
        description: loc.translate(_dayKeys[bestDay]!),
      ));
    }
    if (bestBucket != null && _timeBucketKeys.containsKey(bestBucket)) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 14));
      items.add(_InsightItem(
        title: loc.translate('best_time_insight_title'),
        description: loc.translate(_timeBucketKeys[bestBucket]!),
      ));
    }
    if (hasFuelData) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 14));
      items.add(_InsightItem(
        title: loc.translate(fuelChange <= 0 ? 'fuel_usage_reduced' : 'fuel_usage_increased'),
        description:
            "${loc.translate(fuelChange <= 0 ? 'decrease' : 'increase')} ${fuelChange.abs().toStringAsFixed(1)}%",
      ));
    }

    return Container(
      decoration: ThemeConstants.glassCardDecoration,
      padding: const EdgeInsets.all(16),
      child: items.isEmpty
          ? Text(loc.translate('no_insights_yet'), style: ThemeConstants.captionStyle)
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: items),
    );
  }
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
  final double rev = _extractFirstNumber(data?['revenue'],
      const <String>['total_revenue', 'revenue_total', 'total']);
  final double exp = _extractFirstNumber(data?['expenses'],
      const <String>['total_expenses', 'expenses_total', 'total']);
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(title, style: ThemeConstants.headingStyle.copyWith(fontSize: 16)),
        ],
      );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final String selected;
  final Map<String, String> labels;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: labels.entries.map((MapEntry<String, String> e) {
            final bool isSelected = e.key == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected ? ThemeConstants.primaryCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white60,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
    required this.accent,
  });

  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: ThemeConstants.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: ThemeConstants.bodyStyle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (change.isNotEmpty)
              Row(
                children: <Widget>[
                  Icon(
                    isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 13,
                    color: isPositive ? ThemeConstants.successGreen : ThemeConstants.errorRed,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? ThemeConstants.successGreen : ThemeConstants.errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 15),
          ],
        ),
      );
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({
    required this.title,
    required this.metric,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String title;
  final String metric;
  final IconData icon;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: ThemeConstants.captionStyle),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ThemeConstants.warningAmber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(description, style: ThemeConstants.captionStyle),
              ],
            ),
          ),
        ],
      );
}
