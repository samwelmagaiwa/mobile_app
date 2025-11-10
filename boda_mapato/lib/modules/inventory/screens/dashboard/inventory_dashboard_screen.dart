import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../../../widgets/value_listenable_builder_3.dart';
import '../../providers/inventory_provider.dart';

class InventoryDashboardScreen extends StatelessWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();

    // Toggles to match mock: two-series chips above chart, small period selector inside chart
    final ValueNotifier<bool> showOnline = ValueNotifier<bool>(true);
    final ValueNotifier<bool> showPOS = ValueNotifier<bool>(true);
    final ValueNotifier<String> period = ValueNotifier<String>('daily');
    final ValueNotifier<DateTimeRange?> selectedRange =
        ValueNotifier<DateTimeRange?>(null);

    List<LineChartBarData> seriesFor(String p) {
      final List<LineChartBarData> lines = [];
      if (showOnline.value) {
        final spots = p == 'weekly'
            ? inv.onlineTrendWeekly
            : p == 'monthly'
                ? inv.onlineTrendMonthly
                : inv.onlineTrendDaily;
        lines.add(LineChartBarData(
          isCurved: true,
          spots: spots,
          color: const Color(0xFFB388FF), // purple-ish for online
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true, color: const Color(0xFFB388FF).withOpacity(0.12)),
          barWidth: 3,
        ));
      }
      if (showPOS.value) {
        final spots = p == 'weekly'
            ? inv.posTrendWeekly
            : p == 'monthly'
                ? inv.posTrendMonthly
                : inv.posTrendDaily;
        lines.add(LineChartBarData(
          isCurved: true,
          spots: spots,
          color: const Color(0xFF64B5F6), // blue for POS
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true, color: const Color(0xFF64B5F6).withOpacity(0.10)),
          barWidth: 3,
        ));
      }
      return lines;
    }

    Widget chartCard() => SizedBox(
          width: double.infinity,
          child: Container(
            decoration: ThemeConstants.glassCardDecoration,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend-like chips above chart
              Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: showOnline,
                    builder: (_, val, __) => FilterChip(
                      selected: val,
                      label: Text(loc.translate('online_retail_mode')),
                      onSelected: (s) => showOnline.value = s,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  ValueListenableBuilder<bool>(
                    valueListenable: showPOS,
                    builder: (_, val, __) => FilterChip(
                      selected: val,
                      label: Text(loc.translate('pos_total_mode')),
                      onSelected: (s) => showPOS.value = s,
                    ),
                  ),
                ],
              ),
              // Selected range label
              ValueListenableBuilder<DateTimeRange?>(
                valueListenable: selectedRange,
                builder: (_, r, __) {
                  if (r == null) return const SizedBox.shrink();
                  final l = MaterialLocalizations.of(context);
                  String fmt(DateTime d) => l.formatShortDate(d);
                  return Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('${fmt(r.start)}  —  ${fmt(r.end)}',
                        style: ThemeConstants.captionStyle),
                  );
                },
              ),
              SizedBox(height: 6.h),
              Stack(
                children: [
                  SizedBox(
                    height: 200.h,
                    child: ValueListenableBuilder3<bool, bool, String>(
                      a: showOnline,
                      b: showPOS,
                      c: period,
                      builder: (_, __, ___, p) => LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.white24)),
                          lineBarsData: seriesFor(p),
                        ),
                      ),
                    ),
                  ),
                  // Small period selector pinned top-right of chart
                  Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Row(children: [
                          _PeriodMini(
                              value: 'daily',
                              label: 'D',
                              period: period,
                              range: selectedRange),
                          _PeriodMini(
                              value: 'weekly',
                              label: 'W',
                              period: period,
                              range: selectedRange),
                          _PeriodMini(
                              value: 'monthly',
                              label: 'M',
                              period: period,
                              range: selectedRange),
                          const SizedBox(width: 4),
                          _CalendarTrigger(
                              period: period, range: selectedRange),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));

    // Two KPI tiles below chart with a very small inner gap (vertical divider)
    Widget kpisBlock() => SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ThemeConstants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                verticalInside: BorderSide(color: Colors.white24),
              ),
              children: [
                TableRow(children: [
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: _KpiTile(
                        title: loc.translate('pos_total_made'),
                        amount: 'TZS 7,444',
                        change: '+16.24%'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: _KpiTile(
                        title: loc.translate('online_total_made'),
                        amount: 'TZS 7,334',
                        change: '+16.24%'),
                  ),
                ]),
              ],
            ),
          ),
        ));

    String cleanLabel(String keyOrText) {
      final raw = loc.translate(keyOrText);
      final s = (raw == keyOrText || raw.contains('_'))
          ? raw.replaceAll('_', ' ')
          : raw;
      // Title case first letter only to avoid shouting
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    }

    // 2x2 grid block (Inventory, Current Orders, Past Orders, Top Customers)
    Widget gridBlock() => SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ThemeConstants.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside: BorderSide(color: Colors.white24),
                verticalInside: BorderSide(color: Colors.white24),
              ),
              children: [
                // Row 1
                TableRow(children: [
                  _GridCell(
                    icon: Icons.inventory_2_outlined,
                    title: cleanLabel('inventory'),
                    primary:
                        '${inv.products.length} ${loc.translate('products')}',
                    secondary: '+16.24%',
                  ),
                  _GridCell(
                    icon: Icons.shopping_bag_outlined,
                    title: cleanLabel('current_orders'),
                    primary: '05 ${loc.translate('orders')}',
                    secondary:
                        '34 ${loc.translate('orders')} ${loc.translate('today')}',
                    badgeText: '05',
                  ),
                  _GridCell(
                    icon: Icons.history_outlined,
                    title: cleanLabel('past_orders'),
                    primary: '457 ${loc.translate('orders')}',
                    secondary: '+14.24%',
                  ),
                ]),
                // Row 2
                TableRow(children: [
                  _GridCell(
                    icon: Icons.people_alt_outlined,
                    title: cleanLabel('top_customers'),
                    primary: '733 ${loc.translate('customers')}',
                    secondary: '+23 ${loc.translate('this_week')}',
                  ),
                  _GridCell(
                    icon: Icons.attach_money_rounded,
                    title: cleanLabel('total_sales_today'),
                    primary: inv.totalSalesTodayFormatted,
                    secondary: loc.translate('today'),
                  ),
                  _GridCell(
                    icon: Icons.trending_up_rounded,
                    title: cleanLabel('profit'),
                    primary: inv.profitTodayFormatted,
                    secondary:
                        'W: ${inv.profitWeekFormatted} • M: ${inv.profitMonthFormatted}',
                  ),
                ]),
                // Row 3
                TableRow(children: [
                  _GridCell(
                    icon: Icons.star_rate_rounded,
                    title: cleanLabel('top_selling_product'),
                    primary: inv.topSellingProductName,
                    secondary: loc.translate('best_seller'),
                  ),
                  _GridCell(
                    icon: Icons.warning_amber_rounded,
                    title: cleanLabel('low_stock_alerts'),
                    primary: '${inv.lowStockCount}',
                    secondary: loc.translate('items'),
                  ),
                  _GridCell(
                    icon: Icons.notifications_active_outlined,
                    title: cleanLabel('reminders'),
                    primary: '${inv.reminders.length}',
                    secondary: loc.translate('active'),
                  ),
                ]),
              ],
            ),
          ),
        ));

    // Products overview table-like list
    Widget productsOverview() => SizedBox(
          width: double.infinity,
          child: Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: ThemeConstants.glassCardDecoration,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('products_overview'),
                      style: ThemeConstants.headingStyle),
                  Row(children: [
                    const _MiniPill(text: 'Day'),
                    SizedBox(width: 4.w),
                    const _MiniPill(text: 'Week'),
                    SizedBox(width: 4.w),
                    const _MiniPill(text: 'Month'),
                  ]),
                ],
              ),
              SizedBox(height: 6.h),
              // Header row
              Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: Text(loc.translate('product'),
                          style: ThemeConstants.captionStyle)),
                  Expanded(
                      flex: 3,
                      child: Text(loc.translate('orders'),
                          style: ThemeConstants.captionStyle)),
                  Expanded(
                      flex: 4,
                      child: Text(loc.translate('sale'),
                          style: ThemeConstants.captionStyle)),
                  Expanded(
                      flex: 4,
                      child: Text(loc.translate('profit'),
                          style: ThemeConstants.captionStyle)),
                ],
              ),
              SizedBox(height: 4.h),
              ..._topProducts(inv).map((e) => _ProductRow(item: e)),
            ],
          ),
        ));

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chartCard(),
            SizedBox(height: 6.h),
            kpisBlock(),
            SizedBox(height: 6.h),
            gridBlock(),
            productsOverview(),
          ],
        ),
      ),
    );
  }
}


class _KpiTile extends StatelessWidget {
  const _KpiTile(
      {required this.title, required this.amount, required this.change});
  final String title;
  final String amount;
  final String change;
  @override
  Widget build(BuildContext context) {
    return Container(
      // Removed inner glass decoration to avoid the double-layered look.
      // Keep only padding so the outer big container with the vertical divider remains.
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.w),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.payments_outlined,
                color: Colors.white, size: 16),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AutoSizeText(title,
                  style: ThemeConstants.captionStyle,
                  maxLines: 1,
                  minFontSize: 10),
              SizedBox(height: 2.w),
              Row(children: [
                Expanded(
                    child: AutoSizeText(amount,
                        style: ThemeConstants.bodyStyle
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1)),
                Text(change,
                    style: const TextStyle(color: Colors.lightGreenAccent)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell(
      {required this.icon,
      required this.title,
      required this.primary,
      required this.secondary,
      this.badgeText});
  final IconData icon;
  final String title;
  final String primary;
  final String secondary;
  final String? badgeText;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Stack(
        children: [
          // Top-left corner icon inside the grid cell
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white70, size: 14),
            ),
          ),
          // Content with padding to avoid overlapping the top-left icon
          Padding(
            padding: EdgeInsets.only(left: 34, top: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  title,
                  style: ThemeConstants.captionStyle
                      .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  minFontSize: 11,
                ),
                SizedBox(height: 4.h),
                AutoSizeText(
                  primary,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                  maxLines: 1,
                ),
                AutoSizeText(
                  secondary,
                  style: ThemeConstants.captionStyle.copyWith(fontSize: 12.sp),
                  maxLines: 1,
                  minFontSize: 10,
                ),
              ],
            ),
          ),
          // Optional badge
          if (badgeText != null)
            Positioned(
              right: 32,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText!,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          // Eye icon in top-right corner for consistency
          const Positioned(
            right: 6,
            top: 6,
            child: Icon(Icons.remove_red_eye_outlined,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class ProductRowItem {
  ProductRowItem(
      {required this.name,
      required this.category,
      required this.orders,
      required this.sale,
      required this.profit});
  final String name;
  final String category;
  final int orders;
  final double sale;
  final double profit;
}

List<ProductRowItem> _topProducts(InventoryProvider inv) {
  final items = inv.products.take(3).map((p) => ProductRowItem(
        name: p.name,
        category: p.category.isEmpty ? 'Category' : p.category,
        orders: 23,
        sale: 59466,
        profit: 3766,
      ));
  if (items.isNotEmpty) return items.toList();
  // Fallback mocks
  return [
    ProductRowItem(
        name: 'Product 1',
        category: 'Category',
        orders: 23,
        sale: 59466,
        profit: 3766),
    ProductRowItem(
        name: 'Product 2',
        category: 'Category',
        orders: 19,
        sale: 42466,
        profit: 2766),
    ProductRowItem(
        name: 'Product 3',
        category: 'Category',
        orders: 11,
        sale: 29466,
        profit: 1766),
  ];
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item});
  final ProductRowItem item;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.w),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Product cell
          Expanded(
            flex: 5,
            child: Row(children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 16, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(item.name,
                          style: ThemeConstants.bodyStyle, maxLines: 1),
                      AutoSizeText(item.category,
                          style: ThemeConstants.captionStyle,
                          maxLines: 1,
                          minFontSize: 10),
                    ]),
              ),
            ]),
          ),
          Expanded(
              flex: 3,
              child: Text('${item.orders}', style: ThemeConstants.bodyStyle)),
          Expanded(
              flex: 4,
              child: Text('TZS ${item.sale.toStringAsFixed(0)}',
                  style: ThemeConstants.bodyStyle)),
          Expanded(
              flex: 4,
              child: Text('TZS ${item.profit.toStringAsFixed(0)}',
                  style: ThemeConstants.bodyStyle)),
        ],
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog();
  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  final loc = LocalizationService.instance;
  int year = DateTime.now().year;
  // Removed unused 'months' constant to satisfy analyzer.

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: () => setState(() => year -= 1),
          ),
          Text('$year', style: ThemeConstants.headingStyle),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: () => setState(() => year += 1),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final ml = MaterialLocalizations.of(context);
              final label = ml.formatMonthYear(DateTime(year, i + 1));
              return InkWell(
                onTap: () => Navigator.pop(context, DateTime(year, i + 1)),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(label,
                      style: ThemeConstants.bodyStyle,
                      textAlign: TextAlign.center),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}


class _CalendarTrigger extends StatelessWidget {
  const _CalendarTrigger({required this.period, required this.range});
  final ValueNotifier<String> period;
  final ValueNotifier<DateTimeRange?> range;

  Future<void> _handleTap(BuildContext context) async {
    // Temporarily disable popup date pickers to avoid platform/layout issues.
    // You can re-enable by calling _pickForPeriod(context, period.value, range)
    // once tested on the target platform.
    return;
  }

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => _handleTap(context),
      radius: 20,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(Icons.date_range, color: Colors.white, size: 16),
      ),
    );
  }
}

class _PeriodMini extends StatelessWidget {
  const _PeriodMini(
      {required this.value,
      required this.label,
      required this.period,
      required this.range});
  final String value;
  final String label;
  final ValueNotifier<String> period;
  final ValueNotifier<DateTimeRange?> range;
  @override
  Widget build(BuildContext context) {
    final bool selected = period.value == value;
    return GestureDetector(
      onTap: () {
        // Only switch period locally; range picking (dialogs) is disabled for stability
        period.value = value;
        range.value = null;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70, fontSize: 12)),
      ),
    );
  }
}
