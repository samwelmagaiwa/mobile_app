import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../models/user_permissions.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../models/inv_sale.dart';
import '../../providers/depot_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/inventory_export_service.dart';
import '../scanning/barcode_scanner_screen.dart';
import '../widgets/inventory_widgets.dart';
import 'sale_receipt_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _custName = TextEditingController();
  final TextEditingController _custPhone = TextEditingController();
  final TextEditingController _custAddress = TextEditingController();
  String _status = 'all'; // all | paid | debt | partial
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _custName.dispose();
    _custPhone.dispose();
    _custAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final perms = UserPermissions.fromRole(auth.user?.role ?? 'viewer');
    final canCreateSales = perms.has('inv_create_sales');

    return SafeArea(
      child: Column(
        children: [
          // Top Segment / Tab Switcher (POS vs History)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: ThemeConstants.invFill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: ThemeConstants.invBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: ThemeConstants.invAccent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale, size: 18.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          loc.translate('create_sale_pos'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 18.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          loc.translate('sales_history'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: POS Creation
                if (canCreateSales)
                  _buildPosTab(context, inv, loc)
                else
                  Center(
                    child: Text(
                      loc.translate('no_permission'),
                      style: ThemeConstants.bodyStyle,
                    ),
                  ),

                // TAB 2: Sales History & Ledger
                _buildHistoryTab(context, inv, loc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: POS CREATION TAB
  // ==========================================
  Widget _buildPosTab(
      BuildContext context, InventoryProvider inv, LocalizationService loc) {
    final auth = context.read<AuthProvider>();
    final role = (auth.user?.role ?? '').toLowerCase();
    final canManageCustomers = role == 'admin' || role == 'manager';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Toolbar: Add Products + Scan + Clear Cart
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: ThemeConstants.invCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.invAccent,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () => _openProductPicker(context),
                        icon: Icon(Icons.add_shopping_cart, size: 20.sp),
                        label: Text(
                          inv.cart.isEmpty
                              ? loc.translate('add_products')
                              : '${loc.translate('add_products')} (${inv.cart.length})',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: ThemeConstants.invBorder),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () => _scanToCart(context),
                        icon: Icon(Icons.qr_code_scanner,
                            size: 18.sp, color: Colors.white),
                        label: Text(
                          loc.translate('scan'),
                          style: ThemeConstants.bodyStyle,
                        ),
                      ),
                    ),
                    if (inv.cart.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      IconButton(
                        tooltip: 'Clear Cart',
                        icon: const Icon(Icons.delete_outline,
                            color: ThemeConstants.errorRed),
                        onPressed: () => inv.clearCart(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Cart Items List / Empty Placeholder
          if (inv.cart.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: ThemeConstants.invCardDecoration,
              child: Column(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 44.sp, color: Colors.white38),
                  SizedBox(height: 8.h),
                  Text(
                    loc.translate('create_sale_hint'),
                    style: ThemeConstants.bodyStyle
                        .copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: ThemeConstants.invCardDecoration,
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cart Items (${inv.cart.length})',
                        style: ThemeConstants.headingStyle,
                      ),
                      Text(
                        'Total: TZS ${inv.cartTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: ThemeConstants.invAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inv.cart.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 12),
                    itemBuilder: (_, i) => _CartRow(item: inv.cart[i]),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12.h),

          // Payment & Customer Configuration
          Container(
            decoration: ThemeConstants.invCardDecoration,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment & Customer',
                  style: ThemeConstants.headingStyle,
                ),
                SizedBox(height: 10.h),

                // Payment Mode Segment Pills
                Row(
                  children: [
                    Text(
                      '${loc.translate('payment_mode')}:',
                      style: ThemeConstants.captionStyle,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Row(
                        children: [
                          _buildModeChip(inv, 'cash', loc.translate('cash')),
                          SizedBox(width: 6.w),
                          _buildModeChip(inv, 'debt', loc.translate('debt')),
                          SizedBox(width: 6.w),
                          _buildModeChip(
                              inv, 'partial', loc.translate('partial')),
                        ],
                      ),
                    ),
                  ],
                ),

                // Customer Selector (if Debt or Partial)
                if (inv.paymentMode != 'cash') ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          key: ValueKey<String>('customer_${inv.selectedCustomerId}'),
                          initialValue: inv.selectedCustomerId,
                          dropdownColor: ThemeConstants.primaryBlue,
                          decoration: ThemeConstants.invInputDecoration(
                              loc.translate('select_customer')),
                          style: ThemeConstants.bodyStyle,
                          items: [
                            DropdownMenuItem<int?>(
                              child: Text(
                                loc.translate('select_customer'),
                                style: ThemeConstants.bodyStyle,
                              ),
                            ),
                            ...inv.customers.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name,
                                    style: ThemeConstants.bodyStyle),
                              ),
                            ),
                          ],
                          onChanged: inv.setCustomer,
                        ),
                      ),
                      if (canManageCustomers) ...[
                        SizedBox(width: 8.w),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: ThemeConstants.invFill,
                            side:
                                const BorderSide(color: ThemeConstants.invBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          tooltip: loc.translate('add_customer'),
                          icon: const Icon(Icons.person_add,
                              color: Colors.white),
                          onPressed: () => _openCreateCustomerDialog(context),
                        ),
                      ],
                    ],
                  ),
                ],

                // Paid Amount (if Partial)
                if (inv.paymentMode == 'partial') ...[
                  SizedBox(height: 10.h),
                  TextField(
                    onChanged: (v) =>
                        inv.setPaidAmount(parseAmount(v)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    decoration: ThemeConstants.invInputDecoration(
                        loc.translate('paid_amount')),
                    style: ThemeConstants.bodyStyle,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Grand Total Breakdown & Checkout Button
          Container(
            decoration: ThemeConstants.invCardDecoration.copyWith(
              border: Border.all(color: ThemeConstants.invAccent, width: 1.2),
            ),
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate('subtotal'),
                      style: ThemeConstants.bodyStyle,
                    ),
                    Text(
                      'TZS ${inv.cartSubtotal.toStringAsFixed(0)}',
                      style: ThemeConstants.bodyStyle,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate('total'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'TZS ${inv.cartTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: ThemeConstants.invAccent,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.invAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: inv.cart.isEmpty
                        ? null
                        : () async {
                            final result = await inv.checkout(createdBy: 1);
                            if (!context.mounted) return;
                            final ok = result.$1;
                            final msgKey = result.$2;
                            if (!ok) {
                              ThemeConstants.showErrorSnackBar(
                                  context, loc.translate(msgKey));
                            } else {
                              ThemeConstants.showSuccessSnackBar(
                                  context, loc.translate('success'));
                            }
                          },
                    icon: Icon(Icons.payments_outlined, size: 22.sp),
                    label: Text(
                      '${loc.translate('checkout')} • TZS ${inv.cartTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildModeChip(InventoryProvider inv, String mode, String label) {
    final bool selected = inv.paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => inv.setPaymentMode(mode),
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ThemeConstants.invAccent : ThemeConstants.invFill,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? ThemeConstants.invAccent
                  : ThemeConstants.invBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: SALES HISTORY & LEDGER TAB
  // ==========================================
  Widget _buildHistoryTab(
      BuildContext context, InventoryProvider inv, LocalizationService loc) {
    final filtered = inv.sales.where((s) {
      if (_status != 'all' && s.paymentStatus != _status) return false;
      if (_from != null && s.createdAt.isBefore(_from!)) return false;
      if (_to != null && s.createdAt.isAfter(_to!)) return false;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _status,
                  dropdownColor: ThemeConstants.primaryBlue,
                  items: [
                    DropdownMenuItem(
                        value: 'all',
                        child: Text(loc.translate('all'),
                            style: ThemeConstants.bodyStyle)),
                    DropdownMenuItem(
                        value: 'paid',
                        child: Text(loc.translate('paid'),
                            style: ThemeConstants.bodyStyle)),
                    DropdownMenuItem(
                        value: 'debt',
                        child: Text(loc.translate('debt'),
                            style: ThemeConstants.bodyStyle)),
                    DropdownMenuItem(
                        value: 'partial',
                        child: Text(loc.translate('partial'),
                            style: ThemeConstants.bodyStyle)),
                  ],
                  onChanged: (v) async {
                    setState(() => _status = v ?? 'all');
                    await context.read<InventoryProvider>().fetchSales(
                          status: _status,
                          from: _from,
                          to: _to,
                        );
                  },
                ),
                SizedBox(width: 12.w),
                TextButton.icon(
                  onPressed: () async {
                    final inv = context.read<InventoryProvider>();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _from ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (!context.mounted) return;
                    if (d != null) {
                      setState(() => _from = d);
                      await inv.fetchSales(
                          status: _status, from: _from, to: _to);
                    }
                  },
                  icon: const Icon(Icons.date_range, color: Colors.white70),
                  label: Text(
                    '${loc.translate('from_date')}: ${_from != null ? _from!.toLocal().toString().split(' ').first : '-'}',
                    style: ThemeConstants.captionStyle,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () async {
                    final inv = context.read<InventoryProvider>();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _to ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (!context.mounted) return;
                    if (d != null) {
                      setState(() => _to = d);
                      await inv.fetchSales(
                          status: _status, from: _from, to: _to);
                    }
                  },
                  icon: const Icon(Icons.date_range, color: Colors.white70),
                  label: Text(
                    '${loc.translate('to_date')}: ${_to != null ? _to!.toLocal().toString().split(' ').first : '-'}',
                    style: ThemeConstants.captionStyle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Sales List
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: ThemeConstants.invCardDecoration,
              child: Center(
                child: Text(
                  loc.translate('no_sales_found'),
                  style: ThemeConstants.bodyStyle,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: filtered.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final s = filtered[index];
                final customers = context.read<InventoryProvider>().customers;
                final matches = customers
                    .where((c) => s.customerId != null && c.id == s.customerId!)
                    .toList();
                final custName = matches.isNotEmpty ? matches.first.name : '-';
                final paid = s.paidTotal;
                final balance = (s.total - s.paidTotal).clamp(0.0, s.total);

                Color statusColor;
                if (s.paymentStatus == 'paid') {
                  statusColor = ThemeConstants.successGreen;
                } else if (s.paymentStatus == 'debt') {
                  statusColor = ThemeConstants.errorRed;
                } else {
                  statusColor = ThemeConstants.warningAmber;
                }

                return Container(
                  decoration: ThemeConstants.invCardDecoration,
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long,
                            color: statusColor, size: 20.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${s.number}',
                                  style: ThemeConstants.bodyStyle
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    s.paymentStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Cust: $custName • ${s.createdAt.toLocal().toString().split(' ').first}',
                              style: ThemeConstants.captionStyle,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Total: TZS ${s.total.toStringAsFixed(0)} • Paid: ${paid.toStringAsFixed(0)} • Bal: ${balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Angalia Risiti',
                        onPressed: () => Navigator.of(context).push(
                          SaleReceiptScreen.route(s),
                        ),
                        icon: Icon(Icons.receipt_long_outlined,
                            color: Colors.white70, size: 20.sp),
                      ),
                      IconButton(
                        tooltip: loc.translate('receipt'),
                        onPressed: () => _shareReceipt(context, s),
                        icon: Icon(Icons.print_outlined,
                            color: Colors.white70, size: 20.sp),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static const InventoryExportService _exportService =
      InventoryExportService();

  Future<void> _shareReceipt(BuildContext context, InvSale sale) async {
    final loc = LocalizationService.instance;
    final inv = context.read<InventoryProvider>();
    final matches = inv.customers
        .where((c) => sale.customerId != null && c.id == sale.customerId)
        .toList();

    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print_outlined, color: Colors.white70),
              title: Text(loc.translate('print_receipt'),
                  style: ThemeConstants.bodyStyle),
              onTap: () => Navigator.pop(ctx, 'print'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white70),
              title: Text(loc.translate('share_receipt'),
                  style: ThemeConstants.bodyStyle),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    try {
      final File file = await _exportService.saleReceiptToPdf(
        sale,
        customer: matches.isEmpty ? null : matches.first,
      );
      if (!context.mounted) return;
      if (action == 'print') {
        await _exportService.printPdf(file);
      } else {
        await _exportService.shareFile(file,
            subject: '${loc.translate('receipt')} ${sale.number}');
      }
    } on Exception {
      if (context.mounted) {
        ThemeConstants.showErrorSnackBar(
            context, loc.translate('export_failed'));
      }
    }
  }

  Future<void> _scanToCart(BuildContext context) async {
    final loc = LocalizationService.instance;
    final String? code =
        await scanBarcode(context, title: loc.translate('scan_to_add'));
    if (code == null || code.isEmpty || !context.mounted) return;

    final depot = context.read<DepotProvider>();
    final inv = context.read<InventoryProvider>();
    final result = await depot.resolveBarcode(code);

    if (result == null || result.productId == null) {
      if (context.mounted) {
        ThemeConstants.showErrorSnackBar(
            context, loc.translate('barcode_not_found'));
      }
      return;
    }

    final matches =
        inv.products.where((p) => p.id == result.productId).toList();
    if (matches.isEmpty) {
      if (context.mounted) {
        ThemeConstants.showErrorSnackBar(
            context, loc.translate('barcode_not_found'));
      }
      return;
    }

    inv.addProductToCart(matches.first);
    if (context.mounted) {
      ThemeConstants.showSuccessSnackBar(
        context,
        '${matches.first.name} ${loc.translate('added_to_cart')}',
      );
    }
  }

  Future<void> _openProductPicker(BuildContext context) async {
    final loc = LocalizationService.instance;
    final inv = context.read<InventoryProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeConstants.primaryBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.w,
            right: 12.w,
            top: 12.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12.h,
          ),
          child: SizedBox(
            height: 0.7.sh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.translate('add_to_cart'),
                        style: ThemeConstants.headingStyle,
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: Colors.white70, size: 18.sp),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: inv.products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (_, i) =>
                        _ProductPickTile(product: inv.products[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateCustomerDialog(BuildContext context) async {
    final loc = LocalizationService.instance;
    final inv = context.read<InventoryProvider>();
    _custName.clear();
    _custPhone.clear();
    _custAddress.clear();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(loc.translate('add_customer'),
            style: ThemeConstants.bodyStyle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _custName,
                  decoration: ThemeConstants.invInputDecoration(
                      loc.translate('customer_name')),
                  style: ThemeConstants.bodyStyle),
              SizedBox(height: 8.h),
              TextField(
                  controller: _custPhone,
                  decoration: ThemeConstants.invInputDecoration(
                      loc.translate('phone_number')),
                  style: ThemeConstants.bodyStyle),
              SizedBox(height: 8.h),
              TextField(
                  controller: _custAddress,
                  decoration: ThemeConstants.invInputDecoration(
                      loc.translate('address')),
                  style: ThemeConstants.bodyStyle),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final id = await inv.createCustomer(
                name: _custName.text.trim(),
                phone: _custPhone.text.trim(),
                address: _custAddress.text.trim(),
              );
              if (id != null) {
                inv.setCustomer(id);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(loc.translate('save')),
          ),
        ],
      ),
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  const _ProductPickTile({required this.product});
  final InvProduct product;

  @override
  Widget build(BuildContext context) {
    final inv = context.read<InventoryProvider>();
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: ThemeConstants.invFill,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.inventory_2_outlined,
            color: ThemeConstants.invAccent, size: 20.sp),
      ),
      title: Text(product.name, style: ThemeConstants.bodyStyle),
      subtitle: Text(
        'SKU: ${product.sku} • TZS ${product.sellingPrice.toStringAsFixed(0)} • ${product.quantity} in stock',
        style: ThemeConstants.captionStyle,
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.invAccent,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onPressed: () {
          inv.addProductToCart(product);
          ThemeConstants.showSuccessSnackBar(context, 'Added to cart');
        },
        child: Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});
  final InvSaleItem item;

  @override
  Widget build(BuildContext context) {
    final inv = context.read<InventoryProvider>();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'TZS ${item.total.toStringAsFixed(0)}',
                style: TextStyle(
                  color: ThemeConstants.invAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => inv.removeFromCart(item.productId),
                icon: const Icon(Icons.delete_outline,
                    color: ThemeConstants.errorRed, size: 20),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Controls
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ThemeConstants.invFill,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: ThemeConstants.invBorder),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          inv.setCartQty(item.productId, item.qty - 1),
                      icon: const Icon(Icons.remove, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 28.w,
                        height: 28.w,
                      ),
                      iconSize: 16.sp,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(
                        '${item.qty}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          inv.setCartQty(item.productId, item.qty + 1),
                      icon: const Icon(Icons.add, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 28.w,
                        height: 28.w,
                      ),
                      iconSize: 16.sp,
                    ),
                  ],
                ),
              ),

              // Automatic Selling Price Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: ThemeConstants.invFill,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: ThemeConstants.invBorder),
                ),
                child: Text(
                  '@ TZS ${item.unitPrice.toStringAsFixed(0)} / unit',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
