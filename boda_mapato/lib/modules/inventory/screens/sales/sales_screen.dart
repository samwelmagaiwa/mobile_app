import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../models/user_permissions.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../models/inv_sale.dart';
import '../../providers/inventory_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Temp controllers for Add Customer dialog
  final TextEditingController _custName = TextEditingController();
  final TextEditingController _custPhone = TextEditingController();
  final TextEditingController _custAddress = TextEditingController();
  String _status = 'all'; // all | paid | debt | partial
  DateTime? _from;
  DateTime? _to;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final perms = UserPermissions.fromRole(auth.user?.role ?? 'viewer');
    final canCreateSales = perms.has('inv_create_sales');
    final role = (auth.user?.role ?? '').toLowerCase();
    final canManageCustomers = role == 'admin' || role == 'manager';

    final filtered = inv.sales.where((s) {
      if (_status != 'all' && s.paymentStatus != _status) return false;
      if (_from != null && s.createdAt.isBefore(_from!)) return false;
      if (_to != null && s.createdAt.isAfter(_to!)) return false;
      return true;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // POS composer (gated)
            if (canCreateSales)
              Container(
                decoration: ThemeConstants.glassCardDecoration,
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate('create_sale_pos'),
                        style: ThemeConstants.headingStyle),
                    SizedBox(height: 8.h),
                    Text(loc.translate('create_sale_hint'),
                        style: ThemeConstants.captionStyle),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openProductPicker(context),
                            icon: Icon(Icons.add_shopping_cart, size: 18.sp),
                            label: Text(loc.translate('add_products')),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
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
                            icon: Icon(Icons.payments_outlined, size: 18.sp),
                            label: Text(loc.translate('checkout')),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Payment mode and customer
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(loc.translate('payment_mode'),
                            style: ThemeConstants.captionStyle),
                        ChoiceChip(
                          label: Text(loc.translate('cash')),
                          selected: inv.paymentMode == 'cash',
                          onSelected: (_) => inv.setPaymentMode('cash'),
                        ),
                        ChoiceChip(
                          label: Text(loc.translate('debt')),
                          selected: inv.paymentMode == 'debt',
                          onSelected: (_) => inv.setPaymentMode('debt'),
                        ),
                        ChoiceChip(
                          label: Text(loc.translate('partial')),
                          selected: inv.paymentMode == 'partial',
                          onSelected: (_) => inv.setPaymentMode('partial'),
                        ),
                        if (inv.paymentMode != 'cash')
                          DropdownButton<int?>(
                            value: inv.selectedCustomerId,
                            dropdownColor: ThemeConstants.primaryBlue,
                            items: [
                              DropdownMenuItem<int?>(
                                child: Text(loc.translate('select_customer'),
                                    style: ThemeConstants.bodyStyle),
                              ),
                              ...inv.customers
                                  .map((c) => DropdownMenuItem<int?>(
                                        value: c.id,
                                        child: Text(c.name,
                                            style: ThemeConstants.bodyStyle),
                                      )),
                            ],
                            onChanged: inv.setCustomer,
                          ),
                        if (inv.paymentMode != 'cash' && canManageCustomers)
                          OutlinedButton.icon(
                            onPressed: () => _openCreateCustomerDialog(context),
                            icon: const Icon(Icons.person_add,
                                color: Colors.white70),
                            label: Text(loc.translate('add_customer')),
                          ),
                        if (inv.paymentMode == 'partial')
                          SizedBox(
                            width: 140.w,
                            child: TextField(
                              onChanged: (v) =>
                                  inv.setPaidAmount(double.tryParse(v) ?? 0),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: loc.translate('paid_amount'),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                  borderSide:
                                      const BorderSide(color: Colors.white24),
                                ),
                              ),
                              style: ThemeConstants.bodyStyle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Cart table (constrained height to avoid page overflow)
                    if (inv.cart.isNotEmpty) ...[
                      const Divider(color: Colors.white24),
                      Builder(builder: (_) {
                        final int n = inv.cart.length;
                        // each row ~56.h; cap the list to ~35% of screen height when long
                        final double listHeight = n <= 3 ? (n * 56.h) : 0.35.sh;
                        return SizedBox(
                          height: listHeight,
                          child: ListView.separated(
                            itemCount: inv.cart.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                            itemBuilder: (_, i) => _CartRow(item: inv.cart[i]),
                          ),
                        );
                      }),
                      const Divider(color: Colors.white24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '${loc.translate('subtotal')}: ${inv.cartSubtotal.toStringAsFixed(0)}',
                                style: ThemeConstants.bodyStyle),
                            Text(
                                '${loc.translate('total')}: ${inv.cartTotal.toStringAsFixed(0)}',
                                style: ThemeConstants.bodyStyle
                                    .copyWith(fontWeight: FontWeight.w600)),
                            Text(
                                '${loc.translate('profit')}: ${inv.cartProfit.toStringAsFixed(0)}',
                                style: ThemeConstants.captionStyle),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Filters for sales list
            SizedBox(height: 16.h),
            Row(
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
                const Spacer(),
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
                      '${loc.translate('from_date')}: ${_from != null ? _from!.toLocal().toString().split(' ').first : '-'}'),
                ),
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
                      '${loc.translate('to_date')}: ${_to != null ? _to!.toLocal().toString().split(' ').first : '-'}'),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: SingleChildScrollView(
                child: ListView.separated(
                  itemCount: filtered.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return Container(
                      decoration: ThemeConstants.glassCardDecoration,
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long,
                              color: Colors.white70, size: 22.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: Sale No • Status • Date
                                Text(
                                    '#${s.number} • ${s.paymentStatus.toUpperCase()} • ${s.createdAt.toLocal().toString().split(' ').first}',
                                    style: ThemeConstants.bodyStyle),
                                SizedBox(height: 4.h),
                                // Row 2: Customer • Totals
                                Builder(builder: (context) {
                                  final customers = context
                                      .read<InventoryProvider>()
                                      .customers;
                                  final matches = customers
                                      .where((c) =>
                                          s.customerId != null &&
                                          c.id == s.customerId!)
                                      .toList();
                                  final custName = matches.isNotEmpty
                                      ? matches.first.name
                                      : '-';
                                  final paid = s.paidTotal;
                                  final balance =
                                      (s.total - s.paidTotal).clamp(0, s.total);
                                  return Text(
                                    '${loc.translate('customer')}: $custName • ${loc.translate('total')}: ${s.total.toStringAsFixed(0)} • ${loc.translate('paid')}: ${paid.toStringAsFixed(0)} • ${loc.translate('balance')}: ${balance.toStringAsFixed(0)}',
                                    style: ThemeConstants.captionStyle,
                                  );
                                }),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.white54, size: 18.sp),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            height: 0.7.sh, // constrain height to avoid overflow
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
                  decoration: InputDecoration(
                      labelText: loc.translate('customer_name'),
                      filled: true,
                      fillColor: Colors.white10),
                  style: ThemeConstants.bodyStyle),
              SizedBox(height: 8.h),
              TextField(
                  controller: _custPhone,
                  decoration: InputDecoration(
                      labelText: loc.translate('phone_number'),
                      filled: true,
                      fillColor: Colors.white10),
                  style: ThemeConstants.bodyStyle),
              SizedBox(height: 8.h),
              TextField(
                  controller: _custAddress,
                  decoration: InputDecoration(
                      labelText: loc.translate('address'),
                      filled: true,
                      fillColor: Colors.white10),
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
      leading: const Icon(Icons.inventory_2_outlined, color: Colors.white70),
      title: Text(product.name, style: ThemeConstants.bodyStyle),
      subtitle: Text(
          'SKU: ${product.sku} • TZS ${product.sellingPrice.toStringAsFixed(0)} • ${product.quantity} in stock',
          style: ThemeConstants.captionStyle),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
        onPressed: () {
          inv.addProductToCart(product);
          ThemeConstants.showSuccessSnackBar(context, 'Added');
        },
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});
  final InvSaleItem item;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.read<InventoryProvider>();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(child: Text(item.name, style: ThemeConstants.bodyStyle)),
          SizedBox(
            width: 90.w,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => inv.setCartQty(item.productId, item.qty - 1),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 28.w,
                    height: 28.w,
                  ),
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  iconSize: 18.sp,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text('${item.qty}', style: ThemeConstants.bodyStyle),
                ),
                IconButton(
                  onPressed: () => inv.setCartQty(item.productId, item.qty + 1),
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 28.w,
                    height: 28.w,
                  ),
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  iconSize: 18.sp,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 90.w,
            child: TextField(
              onChanged: (v) => inv.setCartUnitPrice(
                  item.productId, double.tryParse(v) ?? item.unitPrice),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.translate('unit_price'),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
              style: ThemeConstants.bodyStyle,
            ),
          ),
          SizedBox(width: 12.w),
          Text('TZS ${item.total.toStringAsFixed(0)}',
              style: ThemeConstants.bodyStyle),
          IconButton(
            onPressed: () => inv.removeFromCart(item.productId),
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
