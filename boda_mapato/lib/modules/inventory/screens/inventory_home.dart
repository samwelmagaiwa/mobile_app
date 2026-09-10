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
import 'purchasing/purchasing_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/returns_screen.dart';
import 'settings/depot_settings_screen.dart';
import 'stock/batches_screen.dart';
import 'stock/stock_counts_screen.dart';
import 'stock/stock_levels_screen.dart';
import 'stock/write_offs_screen.dart';
import 'stock/stock_ops_screen.dart';
import 'barcode_scanner_screen.dart';
import 'expenses/expenses_screen.dart';
import 'notifications/approval_notifications_screen.dart';
import '../providers/notifications_provider.dart';

/// One entry in the inventory navigation (bottom-bar pages, quick menu grid,
/// and drawer all read from the same list) so a role's visible sections stay
/// consistent everywhere instead of three independently hand-computed index
/// schemes drifting apart.
class _InvMenuEntry {
  const _InvMenuEntry({
    required this.key,
    required this.icon,
    required this.color,
    required this.pageBuilder,
    this.titleKey,
    this.staticTitle,
    this.visible,
  }) : assert(titleKey != null || staticTitle != null);

  final String key;
  final String? titleKey;
  final String? staticTitle;
  final IconData icon;
  final Color color;
  final Widget Function() pageBuilder;

  /// Null means always visible (used for the four items anchored to fixed
  /// footer slots: dashboard, products, sales, settings).
  final bool Function(UserPermissions perms)? visible;

  String title(LocalizationService loc) =>
      staticTitle ?? loc.translate(titleKey!);

  bool isVisible(UserPermissions perms) => visible?.call(perms) ?? true;
}

List<_InvMenuEntry> _invEntries(LocalizationService loc) => <_InvMenuEntry>[
      _InvMenuEntry(
        key: 'dashboard',
        titleKey: 'inventory_dashboard',
        icon: Icons.dashboard,
        color: ThemeConstants.footerBarColor,
        pageBuilder: () => const InventoryDashboardScreen(),
      ),
      _InvMenuEntry(
        key: 'products',
        titleKey: 'products',
        icon: Icons.inventory_2_outlined,
        color: ThemeConstants.primaryOrange,
        pageBuilder: () => const ProductsScreen(),
        visible: (UserPermissions p) => p.has('inv_view_products'),
      ),
      _InvMenuEntry(
        key: 'stock_levels',
        titleKey: 'stock_levels',
        icon: Icons.track_changes_outlined,
        color: ThemeConstants.successGreen,
        pageBuilder: () => const StockLevelsScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_stock'),
      ),
      _InvMenuEntry(
        key: 'stock_ops',
        titleKey: 'stock_in_out_transfer',
        icon: Icons.sync_alt_outlined,
        color: ThemeConstants.warningAmber,
        pageBuilder: () => const StockOpsScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_stock'),
      ),
      _InvMenuEntry(
        key: 'sales',
        titleKey: 'sales',
        icon: Icons.point_of_sale_outlined,
        color: ThemeConstants.primaryGradientEnd,
        pageBuilder: () => const SalesScreen(),
        visible: (UserPermissions p) => p.has('inv_create_sales'),
      ),
      _InvMenuEntry(
        key: 'reminders',
        titleKey: 'reminders',
        icon: Icons.notifications_active_outlined,
        color: ThemeConstants.errorRed,
        pageBuilder: () => const InventoryRemindersScreen(),
        visible: (UserPermissions p) => p.has('inv_view_reminders'),
      ),
      _InvMenuEntry(
        key: 'categories',
        staticTitle: 'Categories',
        icon: Icons.category_outlined,
        color: ThemeConstants.primaryGradientStart,
        pageBuilder: () => const InventoryCategoriesScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_products'),
      ),
      _InvMenuEntry(
        key: 'orders',
        staticTitle: 'Past Orders',
        icon: Icons.receipt_long_outlined,
        color: ThemeConstants.primaryGradientStart,
        pageBuilder: () => const InventoryOrdersScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_products'),
      ),
      _InvMenuEntry(
        key: 'batches',
        titleKey: 'batches_and_expiry',
        icon: Icons.event_available_outlined,
        color: ThemeConstants.primaryCyan,
        pageBuilder: () => const BatchesScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_stock'),
      ),
      _InvMenuEntry(
        key: 'stock_counts',
        titleKey: 'stock_counts',
        icon: Icons.fact_check_outlined,
        color: ThemeConstants.successGreen,
        pageBuilder: () => const StockCountsScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_stock'),
      ),
      _InvMenuEntry(
        key: 'write_offs',
        titleKey: 'write_offs',
        icon: Icons.report_problem_outlined,
        color: ThemeConstants.errorRed,
        pageBuilder: () => const WriteOffsScreen(),
        // inv_report_damage lets a sales_officer flag damage/breakage at the
        // counter without granting them full stock-management rights;
        // approving a report still requires inv_manage_stock inside the
        // screen itself.
        visible: (UserPermissions p) =>
            p.has('inv_manage_stock') || p.has('inv_report_damage'),
      ),
      _InvMenuEntry(
        key: 'purchasing',
        titleKey: 'purchasing',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF667eea),
        pageBuilder: () => const PurchasingScreen(),
        visible: (UserPermissions p) => p.has('inv_view_purchasing'),
      ),
      _InvMenuEntry(
        key: 'credit',
        titleKey: 'customers_and_credit',
        icon: Icons.credit_card_outlined,
        color: const Color(0xFF20B8CE),
        pageBuilder: () => const CreditScreen(),
        visible: (UserPermissions p) => p.has('inv_view_credit'),
      ),
      _InvMenuEntry(
        key: 'cash',
        titleKey: 'daily_cash',
        icon: Icons.point_of_sale_outlined,
        color: const Color(0xFF10B981),
        pageBuilder: () => const CashSessionsScreen(),
        visible: (UserPermissions p) => p.has('inv_view_cash'),
      ),
      _InvMenuEntry(
        key: 'crates',
        titleKey: 'crates_and_empties',
        icon: Icons.inbox_outlined,
        color: const Color(0xFFF59E0B),
        pageBuilder: () => const CratesScreen(),
        visible: (UserPermissions p) => p.has('inv_view_crates'),
      ),
      _InvMenuEntry(
        key: 'returns',
        titleKey: 'returns_and_parked',
        icon: Icons.assignment_return_outlined,
        color: const Color(0xFFEF4444),
        pageBuilder: () => const ReturnsScreen(),
        // The API only needs inv_create_sales to view/submit a return or
        // park a sale (routes/api.php); inv_manage_sales is only required
        // to approve one, which the screen itself gates separately. Gating
        // the whole screen on inv_manage_sales blocked a sales_officer from
        // even opening it, though they could already call the endpoints.
        visible: (UserPermissions p) => p.has('inv_create_sales'),
      ),
      _InvMenuEntry(
        key: 'reports',
        titleKey: 'reports',
        icon: Icons.bar_chart_outlined,
        color: const Color(0xFF00E5FF),
        pageBuilder: () => const ReportsScreen(),
        visible: (UserPermissions p) => p.has('inv_view_reports'),
      ),
      _InvMenuEntry(
        key: 'alerts',
        titleKey: 'alerts',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFFF97316),
        pageBuilder: () => const AlertsScreen(),
        visible: (UserPermissions p) => p.has('inv_view_products'),
      ),
      _InvMenuEntry(
        key: 'expenses',
        staticTitle: 'Matumizi ya Ghala',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFEC4899),
        pageBuilder: () => const ExpensesScreen(),
        visible: (UserPermissions p) => p.has('inv_view_expenses'),
      ),
      _InvMenuEntry(
        key: 'settings',
        titleKey: 'depot_settings',
        icon: Icons.settings_outlined,
        color: const Color(0xFF64748B),
        pageBuilder: () => const DepotSettingsScreen(),
        visible: (UserPermissions p) => p.has('inv_manage_settings'),
      ),
    ];

class InventoryHome extends StatefulWidget {
  const InventoryHome({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationsProvider>().refreshUnreadCount(),
    );
  }

  /// Returns effective permissions for this user.
  /// When the server returned effective_permissions (role defaults ∪ explicit
  /// grants already merged), use those directly via fromUser so the role is
  /// still tracked for admin-bypass logic. Local role defaults fill the gap
  /// when the server omits the resolved list (older API, cached login).
  UserPermissions _perms(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return UserPermissions.empty();
    return UserPermissions.fromUser(
      userRole: user.role,
      // user.permissions now holds effective_permissions from the server
      // (role defaults ∪ explicit grants), or null if the server hasn't
      // sent it yet — fromUser handles both cases correctly.
      explicitGrants: user.permissions,
    );
  }

  Future<void> _openQuickMenu(BuildContext context) async {
    final loc = LocalizationService.instance;
    final perms = _perms(context);
    final List<_InvMenuEntry> visible =
        _invEntries(loc).where((e) => e.isVisible(perms)).toList();

    // Build the same navigation items as the drawer, but as a 3-column grid.
    final List<_GridNavItem> items = <_GridNavItem>[
      for (int i = 0; i < visible.length; i++)
        _GridNavItem(
          label: visible[i].title(loc),
          icon: visible[i].icon,
          color: visible[i].color.withOpacity(0.85),
          onTap: () {
            setState(() => _index = i);
            Navigator.of(context).pop();
          },
        ),
    ];

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

    final perms = _perms(context);
    final List<_InvMenuEntry> visible =
        _invEntries(loc).where((e) => e.isVisible(perms)).toList();

    final pages = visible.map((e) => e.pageBuilder()).toList(growable: false);
    final titles = visible.map((e) => e.title(loc)).toList(growable: false);
    final int salesIndex = visible.indexWhere((e) => e.key == 'sales');
    final int settingsIndex = visible.indexWhere((e) => e.key == 'settings');

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
          Consumer<NotificationsProvider>(
            builder: (BuildContext context, NotificationsProvider n, __) => Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.notifications_outlined, size: 22.sp),
                  tooltip: loc.translate('notifications'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ApprovalNotificationsScreen(),
                    ),
                  ),
                ),
                if (n.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: ThemeConstants.errorRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        n.unreadCount > 9 ? '9+' : '${n.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, size: 22.sp),
            tooltip: loc.isSwahili ? 'Scan Barcode / QR' : 'Scan Barcode / QR',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
            ),
          ),
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
        child: SafeArea(
          child: IndexedStack(
            index: _index.clamp(0, pages.length - 1),
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: _InventoryFooter(
        index: _index,
        salesIndex: salesIndex,
        onTap: (slot) {
          if (slot == 0) {
            setState(() => _index = 0); // Dashboard
          } else if (slot == 1) {
            setState(() => _index = 1); // Products
          } else if (slot == 2) {
            _openQuickMenu(context); // All sections grid
          } else if (slot == 3) {
            setState(() => _index = salesIndex); // Sales
          } else if (slot == 4) {
            setState(() => _index = settingsIndex >= 0
                ? settingsIndex
                : pages.length - 1); // Settings
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
                  icon: Icons.bar_chart_rounded,
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
    final perms = UserPermissions.fromRole(auth.user?.role ?? 'viewer');
    final List<_InvMenuEntry> visible =
        _invEntries(loc).where((e) => e.isVisible(perms)).toList();

    return Drawer(
      backgroundColor: ThemeConstants.primaryBlue,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (int i = 0; i < visible.length; i++)
                    ListTile(
                      leading: Icon(visible[i].icon,
                          color: Colors.white, size: 22.sp),
                      title: Text(visible[i].title(loc),
                          style: ThemeConstants.bodyStyle),
                      selected: index == i,
                      selectedTileColor: Colors.white10,
                      onTap: () => onSelected(i),
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
