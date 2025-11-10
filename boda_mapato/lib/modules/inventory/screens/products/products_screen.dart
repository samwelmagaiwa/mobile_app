import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../models/user_permissions.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../providers/inventory_provider.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _page = 0;
  final int _pageSize = 8;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final perms = UserPermissions.fromRole(auth.user?.role ?? 'viewer');
    final canManage = perms.has('inv_manage_products');
    final filtered = inv.products.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q);
    }).toList();
    final start = _page * _pageSize;
    final end = (start + _pageSize) > filtered.length
        ? filtered.length
        : (start + _pageSize);
    final slice =
        start < filtered.length ? filtered.sublist(start, end) : <InvProduct>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _query = v;
                      _page = 0;
                    }),
                    decoration: ThemeConstants.invInputDecoration(
                            loc.translate('search_products'))
                        .copyWith(
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                    ),
                    style: ThemeConstants.bodyStyle,
                  ),
                ),
                SizedBox(width: 12.w),
                if (canManage)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditProductScreen(),
                      ),
                    ),
                    icon: Icon(Icons.add, size: 18.sp),
                    label: Text(loc.translate('add_product')),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.separated(
                      itemCount: slice.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final p = slice[index];
                        final isLow = p.quantity < p.minStock;
                        return Container(
                          decoration: ThemeConstants.glassCardDecoration,
                          padding: EdgeInsets.all(12.w),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.white70, size: 22.sp),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoSizeText(p.name,
                                        style: ThemeConstants.bodyStyle,
                                        maxLines: 1),
                                    SizedBox(height: 4.h),
                                    AutoSizeText(
                                        '${loc.translate('sku')}: ${p.sku} • ${loc.translate('quantity')}: ${p.quantity}',
                                        style: ThemeConstants.captionStyle,
                                        maxLines: 1,
                                        minFontSize: 10),
                                  ],
                                ),
                              ),
                              if (isLow)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius:
                                          BorderRadius.circular(10.r)),
                                  child: Text(loc.translate('low_stock'),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.sp)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${filtered.isEmpty ? 0 : (start + 1)}-$end / ${filtered.length}',
                            style: ThemeConstants.captionStyle),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _page > 0
                                  ? () => setState(() => _page -= 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white70),
                            ),
                            IconButton(
                              onPressed: end < filtered.length
                                  ? () => setState(() => _page += 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
