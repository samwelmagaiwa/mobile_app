import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/theme_constants.dart';
import 'order_details_screen.dart';

class PurchaseOrder {
  PurchaseOrder({
    required this.id,
    required this.referenceNo,
    required this.supplier,
    required this.warehouse,
    required this.createdAt,
    required this.status,
    required this.totalCost,
    required this.createdBy,
    required this.updatedAt,
    required this.items,
    this.expectedDate,
    this.paidAmount,
    this.paymentStatus,
    this.notes,
  });
  final int id;
  final String referenceNo;
  final String supplier;
  final String warehouse;
  final DateTime createdAt;
  final DateTime? expectedDate;
  final String status; // Pending / Received / Canceled
  final double totalCost;
  final double? paidAmount;
  final String? paymentStatus; // Paid / Partial / Unpaid
  final String createdBy;
  final DateTime updatedAt;
  final String? notes;
  final List<PurchaseOrderItem> items;
}

class PurchaseOrderItem {
  PurchaseOrderItem({
    required this.itemId,
    required this.productName,
    required this.sku,
    required this.category,
    required this.qty,
    required this.unitCost,
    required this.received,
    required this.warehouse,
    required this.status, // Pending / Received / Partial
    required this.createdBy,
    this.receivedDate,
  });
  final int itemId;
  final String productName;
  final String sku;
  final String category;
  final int qty;
  final double unitCost;
  final int received;
  final DateTime? receivedDate;
  final String warehouse;
  final String status;
  final String createdBy;
  double get subtotal => qty * unitCost;
  int get remaining => qty - received;
}

class InventoryOrdersScreen extends StatefulWidget {
  const InventoryOrdersScreen({super.key});
  @override
  State<InventoryOrdersScreen> createState() => _InventoryOrdersScreenState();
}

class _InventoryOrdersScreenState extends State<InventoryOrdersScreen> {
  String _statusFilter = 'All';

  List<PurchaseOrder> _mock() {
    final items = [
      PurchaseOrderItem(
        itemId: 45,
        productName: 'Paracetamol 500mg',
        sku: 'PRC-500',
        category: 'Medicine',
        qty: 100,
        unitCost: 300,
        received: 80,
        receivedDate: DateTime.now().subtract(const Duration(days: 2)),
        warehouse: 'Main Warehouse',
        status: 'Partial',
        createdBy: 'Sales Officer',
      ),
      PurchaseOrderItem(
        itemId: 46,
        productName: 'Glucose Saline 1L',
        sku: 'GLC-1L',
        category: 'Medicine',
        qty: 40,
        unitCost: 2500,
        received: 40,
        receivedDate: DateTime.now().subtract(const Duration(days: 1)),
        warehouse: 'Main Warehouse',
        status: 'Received',
        createdBy: 'Sales Officer',
      ),
    ];
    return [
      PurchaseOrder(
        id: 12,
        referenceNo: 'PO-2025-0004',
        supplier: 'Jumla Hardware Ltd',
        warehouse: 'Main Warehouse',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expectedDate: DateTime.now().add(const Duration(days: 3)),
        status: 'Received',
        totalCost: 450000,
        paidAmount: 300000,
        paymentStatus: 'Partial',
        createdBy: 'Manager',
        updatedAt: DateTime.now(),
        notes: 'Received 3 out of 5 items',
        items: items,
      ),
      PurchaseOrder(
        id: 13,
        referenceNo: 'PO-2025-0005',
        supplier: 'MedSupply Co.',
        warehouse: 'Main Warehouse',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expectedDate: DateTime.now().add(const Duration(days: 5)),
        status: 'Pending',
        totalCost: 220000,
        paidAmount: 0,
        paymentStatus: 'Unpaid',
        createdBy: 'Manager',
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        notes: 'Urgent delivery',
        items: items.take(1).toList(),
      ),
    ];
  }

  String _formatMoney(num v) => 'TZS ${v.toStringAsFixed(0)}';


  @override
  Widget build(BuildContext context) {
    final orders = _mock();
    final filtered = _statusFilter == 'All'
        ? orders
        : orders
            .where((o) => o.status.toLowerCase() == _statusFilter.toLowerCase())
            .toList();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(left: 6.w, right: 6.w, top: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search + filters bar (UI only)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: ThemeConstants.captionStyle,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                    ),
                    style: ThemeConstants.bodyStyle,
                  ),
                ),
                SizedBox(width: 8.w),
                const _SmallFilterPill(icon: Icons.sort_by_alpha, label: 'A-Z'),
                SizedBox(width: 8.w),
                const _SmallFilterPill(
                    icon: Icons.view_list, label: 'All Orders'),
              ],
            ),
            SizedBox(height: 10.h),
            // Status chips row (All / Pending / Received)
            Row(
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _statusFilter == 'All',
                  onTap: () => setState(() => _statusFilter = 'All'),
                ),
                SizedBox(width: 6.w),
                _StatusChip(
                  label: 'Pending',
                  selected: _statusFilter == 'Pending',
                  onTap: () => setState(() => _statusFilter = 'Pending'),
                ),
                SizedBox(width: 6.w),
                _StatusChip(
                  label: 'Received',
                  selected: _statusFilter == 'Received',
                  onTap: () => setState(() => _statusFilter = 'Received'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Outer section container holding all customer orders
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeConstants.bgMid,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    topRight: Radius.circular(18.r),
                  ),
                  border: Border.all(color: Colors.white24),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.separated(
                  itemCount: filtered.length,
                  padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (ctx, i) => _OrderListCard(
                    order: filtered[i],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(order: orders[i]),
                        ),
                      );
                    },
                    money: _formatMoney,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.25) : Colors.white12,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white24),
        ),
        child: AutoSizeText(label,
            style: ThemeConstants.captionStyle, maxLines: 1, minFontSize: 9),
      ),
    );
  }
}

class _StatusDropdown extends StatefulWidget {
  const _StatusDropdown({required this.value});
  final String value;
  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late String _value;
  final _items = const ['Pending', 'Received', 'Canceled'];
  @override
  void initState() {
    super.initState();
    _value = _items.contains(widget.value) ? widget.value : 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 40.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white30),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _value,
            isDense: true,
            dropdownColor: ThemeConstants.primaryBlue,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            style: ThemeConstants.bodyStyle,
            items: _items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _value = v ?? _value),
          ),
        ),
      ),
    );
  }
}

class _SmallFilterPill extends StatelessWidget {
  const _SmallFilterPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white12,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        Icon(icon, size: 14.sp, color: Colors.white70),
        SizedBox(width: 6.w),
        AutoSizeText(label,
            style: ThemeConstants.captionStyle, maxLines: 1, minFontSize: 9),
      ]),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard(
      {required this.order, required this.onTap, required this.money});
  final PurchaseOrder order;
  final VoidCallback onTap;
  final String Function(num) money;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (no container) — keep only the data
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                      radius: 18.r,
                      backgroundColor: Colors.pinkAccent,
                      child: const Icon(Icons.person, color: Colors.white)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText('Customer Name',
                              style: ThemeConstants.bodyStyle
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1),
                          AutoSizeText(order.supplier,
                              style: ThemeConstants.captionStyle,
                              maxLines: 1,
                              minFontSize: 10),
                        ]),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AutoSizeText('Status',
                          style: ThemeConstants.captionStyle,
                          maxLines: 1,
                          minFontSize: 9),
                      SizedBox(height: 4.h),
                      _StatusDropdown(value: order.status),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // Mini header row labels
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: AutoSizeText('Type',
                          style: ThemeConstants.captionStyle
                              .copyWith(color: const Color(0xFF7CD6E4)),
                          maxLines: 1,
                          minFontSize: 9)),
                  Expanded(
                      flex: 5,
                      child: AutoSizeText('Order ID',
                          style: ThemeConstants.captionStyle
                              .copyWith(color: const Color(0xFF7CD6E4)),
                          maxLines: 1,
                          minFontSize: 9)),
                  Expanded(
                      flex: 5,
                      child: AutoSizeText('Date',
                          style: ThemeConstants.captionStyle
                              .copyWith(color: const Color(0xFF7CD6E4)),
                          maxLines: 1,
                          minFontSize: 9)),
                  Expanded(
                      flex: 5,
                      child: AutoSizeText('Time',
                          style: ThemeConstants.captionStyle
                              .copyWith(color: const Color(0xFF7CD6E4)),
                          maxLines: 1,
                          minFontSize: 9)),
                  Expanded(
                      flex: 6,
                      child: AutoSizeText('Product',
                          style: ThemeConstants.captionStyle
                              .copyWith(color: const Color(0xFF7CD6E4)),
                          maxLines: 1,
                          minFontSize: 9)),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            // Value strip (footer-like cyan background) with clearly separated columns
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ThemeConstants.footerBarColor,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 10.r,
                      offset: const Offset(0, 4)),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(children: [
                      Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: const BoxDecoration(
                              color: Colors.white24, shape: BoxShape.circle),
                          child: Icon(Icons.receipt_long,
                              size: 16.sp, color: Colors.white)),
                    ]),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: AutoSizeText(
                          '#${order.id.toString().padLeft(5, '0')}',
                          style: ThemeConstants.bodyStyle,
                          maxLines: 1,
                          minFontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: AutoSizeText(
                          '${order.createdAt.day}-${order.createdAt.month}-${order.createdAt.year}',
                          style: ThemeConstants.bodyStyle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: AutoSizeText(
                          TimeOfDay.fromDateTime(order.createdAt)
                              .format(context),
                          style: ThemeConstants.bodyStyle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: AutoSizeText('Product Name',
                          style: ThemeConstants.bodyStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          minFontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                children: [
                  Expanded(
                      child: AutoSizeText(order.referenceNo,
                          style: ThemeConstants.captionStyle,
                          maxLines: 1,
                          minFontSize: 9)),
                  AutoSizeText(money(order.totalCost),
                      style: ThemeConstants.bodyStyle
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
