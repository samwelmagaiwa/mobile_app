import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import 'orders_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({required this.order, super.key});
  final PurchaseOrder order;

  String _money(num v) => 'TZS ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer/Supplier card
            Container(
              decoration: ThemeConstants.glassCardDecoration.copyWith(
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 18.r,
                          backgroundColor: Colors.white24,
                          child: const Icon(Icons.person, color: Colors.white)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(loc.translate('supplier'),
                                  style: ThemeConstants.captionStyle,
                                  maxLines: 1,
                                  minFontSize: 10),
                              AutoSizeText(order.supplier,
                                  style: ThemeConstants.bodyStyle, maxLines: 1),
                            ]),
                      ),
                      _MiniChip(text: loc.translate('all_orders')),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  AutoSizeText('${loc.translate('order_ref')}: ${order.referenceNo}',
                      style: ThemeConstants.captionStyle,
                      maxLines: 1,
                      minFontSize: 10),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // Items
            ...order.items.map((it) => _ItemCard(item: it, money: _money, loc: loc)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white24)),
      child: AutoSizeText(text,
          style: ThemeConstants.captionStyle, maxLines: 1, minFontSize: 9),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.money, required this.loc});
  final PurchaseOrderItem item;
  final String Function(num) money;
  final LocalizationService loc;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: ThemeConstants.glassCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Colors.white)),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(item.productName,
                          style: ThemeConstants.bodyStyle, maxLines: 1),
                      AutoSizeText(item.category,
                          style: ThemeConstants.captionStyle,
                          maxLines: 1,
                          minFontSize: 10),
                    ]),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Table-ish row
          Row(children: [
            Expanded(flex: 4, child: _kv(loc.translate('product_id'), '#${item.itemId}')),
            Expanded(flex: 3, child: _kv(loc.translate('qty'), '${item.qty}')),
            Expanded(flex: 3, child: _kv(loc.translate('unit_cost'), money(item.unitCost))),
            Expanded(flex: 4, child: _kv(loc.translate('subtotal'), money(item.subtotal))),
          ]),
          SizedBox(height: 6.h),
          Row(children: [
            Expanded(flex: 4, child: _kv(loc.translate('received'), '${item.received}')),
            Expanded(flex: 4, child: _kv(loc.translate('remaining'), '${item.remaining}')),
            Expanded(flex: 4, child: _kv(loc.translate('status'), item.status)),
          ]),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(k,
              style: ThemeConstants.captionStyle, maxLines: 1, minFontSize: 9),
          AutoSizeText(v,
              style: ThemeConstants.bodyStyle, maxLines: 1, minFontSize: 11),
        ],
      );
}
