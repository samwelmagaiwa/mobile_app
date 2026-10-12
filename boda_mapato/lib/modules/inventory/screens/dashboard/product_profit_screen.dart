import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';
import '../widgets/product_profit_table.dart';

/// "Faida kwa Bidhaa": every product's profit, in the same arrangement as the dashboard
/// card (which only shows the first few). Used as a page of the inventory home menu and,
/// via [route], as a screen pushed from the dashboard's "see all" button.
class ProductProfitScreen extends StatefulWidget {
  const ProductProfitScreen({super.key});

  /// The screen on its own, with a title bar and back button.
  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => DecoratedBox(
          // The same dark-to-teal fade as the rest of the inventory screens.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                ThemeConstants.bgTop,
                ThemeConstants.bgMid,
                ThemeConstants.bgBottom,
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: ThemeConstants.buildAppBar(
              LocalizationService.instance.translate('profit_margins_title'),
            ),
            body: const ProductProfitScreen(),
          ),
        ),
      );

  @override
  State<ProductProfitScreen> createState() => _ProductProfitScreenState();
}

class _ProductProfitScreenState extends State<ProductProfitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always reload: this screen exists to show the complete, current list.
      context.read<InventoryProvider>().fetchAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = context.watch<LocalizationService>();
    final InventoryProvider inv = context.watch<InventoryProvider>();

    return RefreshIndicator(
      onRefresh: inv.fetchAllProducts,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
        children: <Widget>[
          // "Sorted by sales" on the left, how many products on the right.
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    loc.translate('top_products_sorted'),
                    style: ThemeConstants.captionStyle,
                  ),
                ),
                Text(
                  '${inv.allProducts.length}',
                  key: const ValueKey<String>('profit_count'),
                  style: ThemeConstants.captionStyle,
                ),
              ],
            ),
          ),
          Container(
            // Outlined, not filled: the page gradient shows through.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: ThemeConstants.invAccent.withOpacity(0.55),
                width: 1.4,
              ),
            ),
            padding: EdgeInsets.all(12.w),
            child: inv.allProducts.isEmpty
                ? InvEmptyState(
                    icon: Icons.insights_outlined,
                    message: loc.translate('no_data'),
                  )
                : ProductProfitTable(
                    products: inv.allProducts,
                    showTitle: false,
                  ),
          ),
        ],
      ),
    );
  }
}
