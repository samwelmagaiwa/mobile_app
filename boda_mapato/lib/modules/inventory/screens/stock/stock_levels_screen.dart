import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';

/// A read-only view of what is in stock right now, with a quick way to spot
/// anything running low.
class StockLevelsScreen extends StatefulWidget {
  const StockLevelsScreen({super.key});

  @override
  State<StockLevelsScreen> createState() => _StockLevelsScreenState();
}

class _StockLevelsScreenState extends State<StockLevelsScreen> {
  String _query = '';
  bool _lowStockOnly = false;

  Future<void> _refresh() => context.read<InventoryProvider>().fetchProducts();

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvProduct> all = context.watch<InventoryProvider>().products;
    final String q = _query.trim().toLowerCase();

    final List<InvProduct> products = all.where((InvProduct p) {
      if (_lowStockOnly && p.quantity >= p.minStock) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        backgroundColor: Colors.white,
        color: ThemeConstants.primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.all(12.w),
          children: <Widget>[
            InvSearchField(
              hint: loc.translate('search_products'),
              onChanged: (String v) => setState(() => _query = v),
            ),
            SizedBox(height: 8.h),
            InvFilterChips<bool>(
              value: _lowStockOnly,
              options: <bool, String>{
                false: loc.translate('all'),
                true: loc.translate('low_stock'),
              },
              onSelected: (bool v) => setState(() => _lowStockOnly = v),
            ),
            SizedBox(height: 8.h),
            if (products.isEmpty)
              InvEmptyState(
                icon: Icons.inventory_2_outlined,
                message: loc.translate('no_data'),
              )
            else
              ...products.map(
                (InvProduct p) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _StockLevelCard(product: p),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockLevelCard extends StatelessWidget {
  const _StockLevelCard({required this.product});

  final InvProduct product;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final bool isLow = product.quantity < product.minStock;
    final bool isOut = product.quantity <= 0;

    return Container(
      decoration: ThemeConstants.glassCardDecoration,
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: <Widget>[
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: Colors.white70, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText(
                  product.name,
                  maxLines: 1,
                  minFontSize: 11,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                AutoSizeText(
                  '${loc.translate('sku')}: ${product.sku}  •  '
                  '${loc.translate('quantity')}: ${product.quantity} ${product.unit}  •  '
                  '${loc.translate('min_stock')}: ${product.minStock}',
                  maxLines: 1,
                  minFontSize: 9,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConstants.captionStyle,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          InvBadge(
            label: isOut
                ? loc.translate('out_of_stock')
                : isLow
                    ? loc.translate('low_stock')
                    : loc.translate('in_stock'),
            color: isOut
                ? ThemeConstants.errorRed
                : isLow
                    ? ThemeConstants.warningAmber
                    : ThemeConstants.successGreen,
          ),
        ],
      ),
    );
  }
}
