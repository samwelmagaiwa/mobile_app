// ignore_for_file: directives_ordering
import 'dart:async';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../../../utils/responsive_helper.dart';
import '../../models/inv_sale.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';

/// Inventory dashboard styled to match the Transport (Modern) dashboard:
/// hero balance card, glass stat cards, month strip + line chart.
class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen>
    with TickerProviderStateMixin {
  static const Color primaryBlue = ThemeConstants.primaryBlue;
  static const Color cardColor = ThemeConstants.cardColor;
  static const Color textPrimary = ThemeConstants.textPrimary;
  static const Color textSecondary = ThemeConstants.textSecondary;

  late final AnimationController _chartAnimationController;
  late final Animation<double> _chartAnimation;

  int _selectedMonth = DateTime.now().month;

  static const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _chartAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final InventoryProvider inv =
        Provider.of<InventoryProvider>(context, listen: false);
    await inv.bootstrap();
    if (!mounted) {
      return;
    }
    _chartAnimationController.reset();
    unawaited(_chartAnimationController.forward());
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final LocalizationService loc = LocalizationService.instance;
    final InventoryProvider inv = context.watch<InventoryProvider>();

    return RefreshIndicator(
      onRefresh: _refresh,
      backgroundColor: Colors.white,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildBalanceCard(loc, inv),
              ResponsiveHelper.verticalSpace(2),
              _buildStatsCards(loc, inv),
              ResponsiveHelper.verticalSpace(2),
              _buildChartSection(loc, inv),
              ResponsiveHelper.verticalSpace(2),
              _buildInventoryValuation(loc, inv),
              ResponsiveHelper.verticalSpace(2),
              _buildProductsOverview(loc, inv),
            ],
          ),
        ),
      ),
    );
  }

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
          child: child,
        ),
      );

  Widget _buildBalanceCard(LocalizationService loc, InventoryProvider inv) {
    final Size size = MediaQuery.of(context).size;
    final bool isShort = size.height < 700;

    double cardHeight = size.height * (isShort ? 0.11 : 0.14);
    cardHeight = cardHeight.clamp(100.0, 130.0);

    final double avatarSide = (size.width * 0.10).clamp(32.0, 42.0);
    final double gapLarge = isShort ? 6.0 : 8.0;
    final double gapMid = isShort ? 4.0 : 6.0;
    final double gapSmall = isShort ? 3.0 : 4.0;

    return SizedBox(
      height: cardHeight,
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 4),
                  const Icon(Icons.more_horiz, color: textSecondary),
                ],
              ),
              SizedBox(height: gapLarge),
              SizedBox(height: gapMid),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TSH ${_formatCurrency(_monthSalesTotal(inv))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: isShort
                          ? (ResponsiveHelper.h2 * 0.9)
                          : ResponsiveHelper.h2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: gapSmall),
                    child: Text(
                      loc.translate('total_sales'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: isShort
                            ? (ResponsiveHelper.bodyL * 0.95)
                            : ResponsiveHelper.bodyL,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(LocalizationService loc, InventoryProvider inv) {
    final int totalProducts = inv.products.length;
    final int lowStock = inv.lowStockCount;
    final int inStock = math.max(0, totalProducts - lowStock);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                loc.translate('total_sales_today'),
                'TSH ${_formatCurrency(inv.totalSalesToday)}',
                '',
                Icons.today,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                loc.translate('profit'),
                'TSH ${_formatCurrency(inv.profitToday)}',
                '',
                Icons.trending_up_rounded,
                true,
              ),
            ),
          ],
        ),
        ResponsiveHelper.verticalSpace(2),
        _buildStatCard(
          loc.translate('sales'),
          'TSH ${_formatCurrency(_monthSalesTotal(inv))}',
          '',
          Icons.calendar_month,
          false,
        ),
        ResponsiveHelper.verticalSpace(2),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                loc.translate('products'),
                '$totalProducts',
                '${loc.translate('active')} $inStock/$totalProducts',
                Icons.inventory_2_outlined,
                true,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            Expanded(
              child: _buildStatCard(
                loc.translate('low_stock_alerts'),
                '$lowStock',
                loc.translate('items'),
                Icons.warning_amber_rounded,
                lowStock == 0,
              ),
            ),
            ResponsiveHelper.horizontalSpace(4),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: ResponsiveHelper.bodyS,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveHelper.verticalSpace(0.5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildChartSection(LocalizationService loc, InventoryProvider inv) =>
      _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildMonthSelector(),
              const SizedBox(height: 24),
              SizedBox(
                height: MediaQuery.of(context).size.height < 700 ? 200 : 240,
                child: AnimatedBuilder(
                  animation: _chartAnimation,
                  builder: (BuildContext context, Widget? child) {
                    final List<double> points = _monthDailyTotals(inv);
                    if (points.isEmpty) {
                      return Center(
                        child: Text(
                          loc.translate('no_chart_data'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    final List<String> labels = _monthDayLabels();
                    final double dataMax = points.reduce(math.max);
                    final double displayMax =
                        _niceCeilValue((dataMax <= 0 ? 1 : dataMax) * 1.1);
                    final double interval =
                        math.max(1, _niceStep(displayMax / 5));
                    final String maxLabel = _formatShort(displayMax);
                    final double reserved =
                        (maxLabel.length * 8 + 12).clamp(44, 72).toDouble();

                    return LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: 0,
                        maxY: displayMax,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (double value) => FlLine(
                            color: Colors.white.withOpacity(0.15),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: reserved,
                              interval: interval,
                              getTitlesWidget: (double value, meta) => Text(
                                _formatShort(value),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 40,
                              getTitlesWidget: (double value, meta) {
                                final int i = value.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                final double width =
                                    MediaQuery.of(context).size.width - 40;
                                const double approxLabelWidth = 22;
                                final int step = labels.isEmpty
                                    ? 1
                                    : (labels.length * approxLabelWidth / width)
                                        .ceil()
                                        .clamp(1, 6);
                                if (i % step != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Transform.rotate(
                                  angle: -math.pi / 6,
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[i],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
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
                          handleBuiltInTouches: false,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (List<LineBarSpot> touchedSpots) =>
                                touchedSpots.map((LineBarSpot barSpot) {
                              final int i = barSpot.x.toInt();
                              final String label = (i >= 0 && i < labels.length)
                                  ? labels[i]
                                  : '';
                              return LineTooltipItem(
                                '$label\nTSH ${_formatCurrency(barSpot.y)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            spots: points
                                .asMap()
                                .entries
                                .map(
                                  (MapEntry<int, double> e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value * _chartAnimation.value,
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: Colors.white,
                            barWidth: 3,
                            dotData: FlDotData(
                              getDotPainter: (FlSpot spot, double percent,
                                      LineChartBarData bar, int index) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: <Color>[
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
                setState(() => _selectedMonth = index + 1);
                _chartAnimationController
                  ..reset()
                  ..forward();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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

  Widget _buildInventoryValuation(
    LocalizationService loc,
    InventoryProvider inv,
  ) {
    final double totalCost = inv.totalInventoryCost;
    final double totalRevenue = inv.totalInventoryRevenue;
    final double totalProfit = inv.totalInventoryExpectedProfit;
    final int totalProducts = inv.products.length;
    final int totalUnits = inv.products.fold<int>(0, (s, p) => s + p.quantity);

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.assessment_outlined,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Muhtasari wa Mzigo - Imported Products Valuation',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: ResponsiveHelper.bodyL,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalProducts Products · $totalUnits Units',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveHelper.bodyS,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Aggregate stat tiles
            Row(
              children: <Widget>[
                Expanded(
                  child: _valuationTile(
                    'Total Cost (Gharama)',
                    'TZS ${formatAmount(totalCost)}',
                    Colors.amber.shade300,
                    Icons.shopping_cart_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _valuationTile(
                    'Total Revenue (Kuuza)',
                    'TZS ${formatAmount(totalRevenue)}',
                    Colors.lightBlueAccent.shade200,
                    Icons.storefront_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Profit banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.green.shade800.withOpacity(0.5),
                    Colors.green.shade600.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.greenAccent.shade400.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.trending_up,
                            color: Colors.greenAccent.shade400, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Faida Tarajiwa (Expected Profit):',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.bodyS,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TZS ${formatAmount(totalProfit)}',
                    style: TextStyle(
                      color: Colors.greenAccent.shade400,
                      fontSize: ResponsiveHelper.bodyL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Per-product breakdown table
            Text(
              'Product Profit Margins',
              style: TextStyle(
                color: textPrimary,
                fontSize: ResponsiveHelper.bodyM,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Text('Product',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: ResponsiveHelper.bodyS,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: ResponsiveHelper.bodyS,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Cost',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: ResponsiveHelper.bodyS,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Profit',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: ResponsiveHelper.bodyS,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ),
            // Product rows
            ...inv.products.map((p) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              p.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: ResponsiveHelper.bodyS,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.unit.toUpperCase(),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${p.quantity}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: ResponsiveHelper.bodyS,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          formatAmount(p.totalCostPrice),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: ResponsiveHelper.bodyS,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          formatAmount(p.totalExpectedProfit),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.greenAccent.shade400,
                            fontSize: ResponsiveHelper.bodyS,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _valuationTile(
      String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: ResponsiveHelper.bodyS,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: ResponsiveHelper.bodyL,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildProductsOverview(
    LocalizationService loc,
    InventoryProvider inv,
  ) =>
      _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                loc.translate('products_overview'),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: ResponsiveHelper.bodyL,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ResponsiveHelper.verticalSpace(1.5),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 6,
                    child: Text(
                      loc.translate('product'),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: ResponsiveHelper.bodyS,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      loc.translate('stock'),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: ResponsiveHelper.bodyS,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      loc.translate('sale'),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: ResponsiveHelper.bodyS,
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveHelper.verticalSpace(1),
              if (inv.products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    loc.translate('no_data'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              else
                ...inv.products.take(5).map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 28.w,
                                    height: 28.w,
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: AutoSizeText(
                                      p.name,
                                      maxLines: 1,
                                      minFontSize: 10,
                                      style: const TextStyle(
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${p.quantity}',
                                style: const TextStyle(color: textPrimary),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: AutoSizeText(
                                'TSH ${_formatCurrency(p.sellingPrice)}',
                                maxLines: 1,
                                minFontSize: 10,
                                style: const TextStyle(color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );

  // ---- data helpers -------------------------------------------------------

  List<InvSale> _salesForSelectedMonth(InventoryProvider inv) {
    final int year = DateTime.now().year;
    return inv.sales
        .where((InvSale s) =>
            s.createdAt.year == year && s.createdAt.month == _selectedMonth)
        .toList();
  }

  double _monthSalesTotal(InventoryProvider inv) => _salesForSelectedMonth(inv)
      .fold<double>(0, (double sum, InvSale s) => sum + s.total);

  int get _daysInSelectedMonth =>
      DateTime(DateTime.now().year, _selectedMonth + 1, 0).day;

  List<double> _monthDailyTotals(InventoryProvider inv) {
    final List<double> totals = List<double>.filled(_daysInSelectedMonth, 0);
    for (final InvSale s in _salesForSelectedMonth(inv)) {
      final int i = s.createdAt.day - 1;
      if (i >= 0 && i < totals.length) {
        totals[i] += s.total;
      }
    }
    return totals;
  }

  List<String> _monthDayLabels() =>
      List<String>.generate(_daysInSelectedMonth, (int i) => '${i + 1}');

  String _formatCurrency(num amount) {
    final double value = amount.toDouble();
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatShort(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).round()}K';
    }
    return value.round().toString();
  }

  double _niceStep(double raw) {
    if (raw <= 0) {
      return 1;
    }
    final double magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final double residual = raw / magnitude;
    if (residual <= 1) {
      return magnitude;
    }
    if (residual <= 2) {
      return 2 * magnitude;
    }
    if (residual <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  double _niceCeilValue(double raw) {
    final double step = _niceStep(raw / 5);
    return (raw / step).ceil() * step;
  }
}
