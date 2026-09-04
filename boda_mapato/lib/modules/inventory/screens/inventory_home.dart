// ignore_for_file: cascade_invocations
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/theme_constants.dart';
import '../../../models/user_permissions.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/localization_service.dart';
import '../../../widgets/service_switcher_dialog.dart';
import 'categories/categories_screen.dart';
import 'dashboard/inventory_dashboard_screen.dart';
import 'orders/orders_screen.dart';
import 'products/products_screen.dart';
import 'reminders/inventory_reminders_screen.dart';
import 'sales/sales_screen.dart';
import 'alerts/alerts_screen.dart';
import 'cash/cash_sessions_screen.dart';
import 'crates/crates_screen.dart';
import 'credit/credit_screen.dart';
import 'dispatch/dispatch_screen.dart';
import 'purchasing/purchasing_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/returns_screen.dart';
import 'settings/depot_settings_screen.dart';
import 'stock/batches_screen.dart';
import 'stock/stock_counts_screen.dart';
import 'stock/stock_levels_screen.dart';
import 'stock/write_offs_screen.dart';
import 'stock/stock_ops_screen.dart';

class InventoryHome extends StatefulWidget {
  const InventoryHome({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome> {
  int _index = 0;

  /// Number of pages the body builds for these permissions. Keeps the quick
  /// menu's indices aligned with the conditional page list.
  int _pageCount(UserPermissions perms) {
    // dashboard, products, stock levels, sales, categories, orders,
    // batches, stock counts, write-offs, purchasing, credit, cash, crates,
    // dispatch, returns, reports, alerts, settings
    int count = 18;
    if (perms.has('inv_manage_stock')) count++;
    if (perms.has('inv_view_reminders')) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }



  Future<void> _openQuickMenu(BuildContext context) async {
    final loc = LocalizationService.instance;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.role ?? 'viewer';
    final perms = UserPermissions.fromRole(role);

    // Build the same navigation items as the drawer, but as a 3-column grid
    final List<_GridNavItem> items = [];
    items.add(_GridNavItem(
      label: loc.translate('dashboard'),
      icon: Icons.dashboard,
      color: ThemeConstants.footerBarColor.withOpacity(0.85),
      onTap: () {
        setState(() => _index = 0);
        Navigator.of(context).pop();
      },
    ));
    items.add(_GridNavItem(
      label: loc.translate('products'),
      icon: Icons.inventory_2_outlined,
      color: ThemeConstants.primaryOrange.withOpacity(0.85),
      onTap: () {
        setState(() => _index = 1);
        Navigator.of(context).pop();
      },
    ));
    items.add(_GridNavItem(
      label: loc.translate('stock_levels'),
      icon: Icons.track_changes_outlined,
      color: ThemeConstants.successGreen.withOpacity(0.85),
      onTap: () {
        setState(() => _index = 2);
        Navigator.of(context).pop();
      },
    ));
    if (perms.has('inv_manage_stock')) {
      items.add(_GridNavItem(
        label: loc.translate('stock_in_out_transfer'),
        icon: Icons.sync_alt_outlined,
        color: ThemeConstants.warningAmber.withOpacity(0.85),
        onTap: () {
          setState(() => _index = 3);
          Navigator.of(context).pop();
        },
      ));
      items.add(_GridNavItem(
        label: loc.translate('sales'),
        icon: Icons.point_of_sale_outlined,
        color: ThemeConstants.primaryGradientEnd.withOpacity(0.85),
        onTap: () {
          setState(() => _index = 4);
          Navigator.of(context).pop();
        },
      ));
      if (perms.has('inv_view_reminders')) {
        items.add(_GridNavItem(
          label: loc.translate('reminders'),
          icon: Icons.notifications_active_outlined,
          color: ThemeConstants.errorRed.withOpacity(0.85),
          onTap: () {
            setState(() => _index = 5);
            Navigator.of(context).pop();
          },
        ));
        items.add(_GridNavItem(
          label: 'Categories',
          icon: Icons.category_outlined,
          color: ThemeConstants.primaryGradientStart.withOpacity(0.85),
          onTap: () {
            setState(() => _index = 6);
            Navigator.of(context).pop();
          },
        ));
      } else {
        items.add(_GridNavItem(
          label: 'Categories',
          icon: Icons.category_outlined,
          color: const Color(0xFF26C6DA).withOpacity(0.35),
          onTap: () {
            setState(() => _index = 5);
            Navigator.of(context).pop();
          },
        ));
      }
    } else {
      items.add(_GridNavItem(
        label: loc.translate('sales'),
        icon: Icons.point_of_sale_outlined,
        color: ThemeConstants.primaryGradientEnd.withOpacity(0.85),
        onTap: () {
          setState(() => _index = 3);
          Navigator.of(context).pop();
        },
      ));
      if (perms.has('inv_view_reminders')) {
        items.add(_GridNavItem(
          label: loc.translate('reminders'),
          icon: Icons.notifications_active_outlined,
          color: ThemeConstants.errorRed.withOpacity(0.85),
          onTap: () {
            setState(() => _index = 4);
            Navigator.of(context).pop();
          },
        ));
        items.add(_GridNavItem(
          label: 'Categories',
          icon: Icons.category_outlined,
          color: ThemeConstants.primaryGradientStart.withOpacity(0.85),
          onTap: () {
            setState(() => _index = 5);
            Navigator.of(context).pop();
          },
        ));
      } else {
        items.add(_GridNavItem(
          label: 'Categories',
          icon: Icons.category_outlined,
          color: ThemeConstants.primaryGradientStart.withOpacity(0.85),
          onTap: () {
            setState(() => _index = 4);
            Navigator.of(context).pop();
          },
        ));
      }
    } // This closes the main perms check or else block

    // Area 3 - stock control entries. Indices are resolved from the same
    // page list the body builds, so they cannot drift out of step.
    final int idxBatches = _pageCount(perms) - 12;
    items.add(_GridNavItem(
      label: loc.translate('batches_and_expiry'),
      icon: Icons.event_available_outlined,
      color: ThemeConstants.primaryCyan.withOpacity(0.85),
      onTap: () {
        setState(() => _index = idxBatches);
        Navigator.of(context).pop();
      },
    ));
    items.add(_GridNavItem(
      label: loc.translate('stock_counts'),
      icon: Icons.fact_check_outlined,
      color: ThemeConstants.successGreen.withOpacity(0.85),
      onTap: () {
        setState(() => _index = idxBatches + 1);
        Navigator.of(context).pop();
      },
    ));
    items.add(_GridNavItem(
      label: loc.translate('write_offs'),
      icon: Icons.report_problem_outlined,
      color: ThemeConstants.errorRed.withOpacity(0.85),
      onTap: () {
        setState(() => _index = idxBatches + 2);
        Navigator.of(context).pop();
      },
    ));

    // Depot areas 4-13. Offsets follow the same page list as above.
    const List<List<Object>> depotEntries = <List<Object>>[
      <Object>['purchasing', Icons.local_shipping_outlined, 3],
      <Object>['customers_and_credit', Icons.credit_card_outlined, 4],
      <Object>['daily_cash', Icons.point_of_sale_outlined, 5],
      <Object>['crates_and_empties', Icons.inbox_outlined, 6],
      <Object>['deliveries', Icons.route_outlined, 7],
      <Object>['returns_and_parked', Icons.assignment_return_outlined, 8],
      <Object>['reports', Icons.bar_chart_outlined, 9],
      <Object>['alerts', Icons.notifications_active_outlined, 10],
      <Object>['depot_settings', Icons.settings_outlined, 11],
    ];
    const List<Color> depotColors = <Color>[
      Color(0xFF667eea),
      Color(0xFF20B8CE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF764ba2),
      Color(0xFFEF4444),
      Color(0xFF00E5FF),
      Color(0xFFF97316),
      Color(0xFF64748B),
    ];
    for (int k = 0; k < depotEntries.length; k++) {
      final int target = idxBatches + (depotEntries[k][2] as int);
      items.add(_GridNavItem(
        label: loc.translate(depotEntries[k][0] as String),
        icon: depotEntries[k][1] as IconData,
        color: depotColors[k].withOpacity(0.85),
        onTap: () {
          setState(() => _index = target);
          Navigator.of(context).pop();
        },
      ));
    }

    // Add Switch Service to quick menu
    items.add(_GridNavItem(
      label: loc.translate('switch_service'),
      icon: Icons.sync_alt,
      color: ThemeConstants.primaryBlue.withOpacity(0.85),
      onTap: () {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => const ServiceSwitcherDialog(),
        );
      },
    ));

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: Container(
            decoration: BoxDecoration(
              color: ThemeConstants.primaryBlue.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white24),
            ),
            padding: EdgeInsets.all(12.w),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.95,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return InkWell(
                    onTap: it.onTap,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: it.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child:
                              Icon(it.icon, color: Colors.white, size: 24.sp),
                        ),
                        SizedBox(height: 4.h),
                        AutoSizeText(
                          it.label,
                          style: ThemeConstants.bodyStyle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 9,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.role ?? 'viewer';
    final perms = UserPermissions.fromRole(role);

    final pages = <Widget>[
      const InventoryDashboardScreen(),
      const ProductsScreen(),
      const StockLevelsScreen(),
      if (perms.has('inv_manage_stock')) const StockOpsScreen(),
      const SalesScreen(),
      if (perms.has('inv_view_reminders')) const InventoryRemindersScreen(),
      const InventoryCategoriesScreen(),
      const InventoryOrdersScreen(),
      const BatchesScreen(),
      const StockCountsScreen(),
      const WriteOffsScreen(),
      const PurchasingScreen(),
      const CreditScreen(),
      const CashSessionsScreen(),
      const CratesScreen(),
      const DispatchScreen(),
      const ReturnsScreen(),
      const ReportsScreen(),
      const AlertsScreen(),
      const DepotSettingsScreen(),
    ];

    final titles = <String>[
      loc.translate('inventory_dashboard'),
      loc.translate('products'),
      loc.translate('stock_levels'),
      if (perms.has('inv_manage_stock')) loc.translate('stock_in_out_transfer'),
      loc.translate('sales'),
      if (perms.has('inv_view_reminders')) loc.translate('reminders'),
      'Categories',
      'Past Orders',
      loc.translate('batches_and_expiry'),
      loc.translate('stock_counts'),
      loc.translate('write_offs'),
      loc.translate('purchasing'),
      loc.translate('customers_and_credit'),
      loc.translate('daily_cash'),
      loc.translate('crates_and_empties'),
      loc.translate('deliveries'),
      loc.translate('returns_and_parked'),
      loc.translate('reports'),
      loc.translate('alerts'),
      loc.translate('depot_settings'),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ThemeConstants.buildAppBar(
        titles[_index],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20.sp),
          tooltip: loc.translate('back'),
          onPressed: () {
            if (_index > 0) {
              setState(() => _index = 0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/select-service');
            }
          },
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, size: 20.sp),
              tooltip: loc.translate('menu'),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.apps, size: 20.sp),
            tooltip: loc.translate('select_service'),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/select-service'),
          ),
        ],
      ),
      drawer: _InventoryDrawer(
        index: _index,
        onSelected: (i) {
          setState(() => _index = i);
          Navigator.pop(context);
        },
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: ThemeConstants.primaryBlue),
        child: SafeArea(child: pages[_index.clamp(0, pages.length - 1)]),
      ),
      bottomNavigationBar: _InventoryFooter(
        index: _index,
        salesIndex: perms.has('inv_manage_stock') ? 4 : 3,
        onTap: (slot) {
          if (slot == 0) {
            setState(() => _index = 0);                    // Dashboard
          } else if (slot == 1) {
            setState(() => _index = 1);                    // Products
          } else if (slot == 2) {
            _openQuickMenu(context);                       // All sections grid
          } else if (slot == 3) {
            // Sales — index shifts by 1 if inv_manage_stock present
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final perms = UserPermissions.fromRole(auth.user?.role ?? '');
            setState(() => _index = perms.has('inv_manage_stock') ? 4 : 3);
          } else if (slot == 4) {
            setState(() => _index = pages.length - 1);    // Settings
          }
        },
      ),
    );
  }
}

class _InventoryFooter extends StatelessWidget {
  const _InventoryFooter({required this.index, required this.onTap, this.salesIndex = 4});
  final int index;
  final int salesIndex;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) {
    // Visual pill-like bar with 5 icons as in the mock
    return ColoredBox(
      color: ThemeConstants
          .footerBarColor, // unify background color under the curved bar
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: ThemeConstants
                  .footerBarColor, // same color as outer background
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dashboard
                _FooterIcon(
                  selected: index == 0,
                  icon: Icons.dashboard_rounded,
                  onTap: () => onTap(0),
                ),
                // Products
                _FooterIcon(
                  selected: index == 1,
                  icon: Icons.inventory_2_rounded,
                  onTap: () => onTap(1),
                ),
                // Quick menu (all sections)
                _FooterIcon(
                  selected: false,
                  icon: Icons.grid_view_rounded,
                  onTap: () => onTap(2),
                ),
                // Sales
                _FooterIcon(
                  selected: index == salesIndex,
                  icon: Icons.point_of_sale_rounded,
                  onTap: () => onTap(3),
                ),
                // Settings
                _FooterIcon(
                  selected: false,
                  icon: Icons.settings_rounded,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon(
      {required this.selected, required this.icon, required this.onTap});
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    // Blue-toned background circles for icons (to match requested style)
    final Color bg = selected
        ? ThemeConstants.primaryBlue.withOpacity(0.35)
        : ThemeConstants.primaryBlue.withOpacity(0.22);
    return InkResponse(
      onTap: onTap,
      radius: 28.r,
      child: Container(
        width: 46.w,
        height: 46.w,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22.sp),
      ),
    );
  }
}

class _GridNavItem {
  _GridNavItem(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _InventoryDrawer extends StatelessWidget {
  const _InventoryDrawer({required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.role ?? 'viewer';
    final perms = UserPermissions.fromRole(role);

    const idxDashboard = 0;
    const idxProducts = 1;
    const idxStockLevels = 2;
    final hasStockOps = perms.has('inv_manage_stock');
    final idxStockOps = hasStockOps ? 3 : -1;
    final idxSales = hasStockOps ? 4 : 3;
    final hasRem = perms.has('inv_view_reminders');
    final idxRem = hasRem ? (hasStockOps ? 5 : 4) : -1;
    final idxCategory = hasRem ? (hasStockOps ? 6 : 5) : (hasStockOps ? 5 : 4);
    final idxOrders = idxCategory + 1;

    return Drawer(
      backgroundColor: ThemeConstants.primaryBlue,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // 1. Dashboard
                  ListTile(
                    leading:
                        Icon(Icons.dashboard, color: Colors.white, size: 22.sp),
                    title: Text(loc.translate('dashboard'),
                        style: ThemeConstants.bodyStyle),
                    selected: index == idxDashboard,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxDashboard),
                  ),
                  // 2. Categories
                  ListTile(
                    leading: Icon(Icons.category_outlined,
                        color: Colors.white, size: 22.sp),
                    title: Text('Categories', style: ThemeConstants.bodyStyle),
                    selected: index == idxCategory,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxCategory),
                  ),
                  // 3. Products
                  ListTile(
                    leading: Icon(Icons.inventory_2_outlined,
                        color: Colors.white, size: 22.sp),
                    title: Text(loc.translate('products'),
                        style: ThemeConstants.bodyStyle),
                    selected: index == idxProducts,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxProducts),
                  ),
                  // 4. Stock Levels
                  ListTile(
                    leading: Icon(Icons.track_changes_outlined,
                        color: Colors.white, size: 22.sp),
                    title: Text(loc.translate('stock_levels'),
                        style: ThemeConstants.bodyStyle),
                    selected: index == idxStockLevels,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxStockLevels),
                  ),
                  // 5. Stock In / Out / Transfer
                  if (hasStockOps)
                    ListTile(
                      leading: Icon(Icons.sync_alt_outlined,
                          color: Colors.white, size: 22.sp),
                      title: Text(loc.translate('stock_in_out_transfer'),
                          style: ThemeConstants.bodyStyle),
                      selected: index == idxStockOps,
                      selectedTileColor: Colors.white10,
                      onTap: () => onSelected(idxStockOps),
                    ),
                  // 6. Orders (Purchase Orders)
                  ListTile(
                    leading: Icon(Icons.receipt_long_outlined,
                        color: Colors.white, size: 22.sp),
                    title: const Text('Orders',
                        style: TextStyle(color: Colors.white)),
                    selected: index == idxOrders,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxOrders),
                  ),
                  // 7. Sales
                  ListTile(
                    leading: Icon(Icons.point_of_sale_outlined,
                        color: Colors.white, size: 22.sp),
                    title: Text(loc.translate('sales'),
                        style: ThemeConstants.bodyStyle),
                    selected: index == idxSales,
                    selectedTileColor: Colors.white10,
                    onTap: () => onSelected(idxSales),
                  ),
                  // 8. Reminders
                  if (hasRem)
                    ListTile(
                      leading: Icon(Icons.notifications_active_outlined,
                          color: Colors.white, size: 22.sp),
                      title: Text(loc.translate('reminders'),
                          style: ThemeConstants.bodyStyle),
                      selected: index == idxRem,
                      selectedTileColor: Colors.white10,
                      onTap: () => onSelected(idxRem),
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.sync_alt, color: Colors.white, size: 22.sp),
                title: Text(loc.translate('switch_service'),
                    style: ThemeConstants.bodyStyle),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const ServiceSwitcherDialog(),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.white, size: 22.sp),
                title: Text(loc.translate('logout'),
                    style: ThemeConstants.bodyStyle),
                onTap: () async {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();
                  if (context.mounted) {
                    await Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (r) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
