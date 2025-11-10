import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_product.dart';
import '../../providers/inventory_provider.dart';

class StockOpsScreen extends StatefulWidget {
  const StockOpsScreen({super.key});

  @override
  State<StockOpsScreen> createState() => _StockOpsScreenState();
}

class _StockOpsScreenState extends State<StockOpsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Column(
      children: [
        SizedBox(height: 8.h),
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.translate('stock_in')),
            Tab(text: loc.translate('stock_out')),
            Tab(text: loc.translate('stock_transfer')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _StockForm(type: 'in'),
              _StockForm(type: 'out'),
              _StockForm(type: 'transfer'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockForm extends StatefulWidget {
  const _StockForm({required this.type});
  final String type;

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final TextEditingController _ref = TextEditingController();
  final TextEditingController _qty = TextEditingController(text: '1');
  InvProduct? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final inv = context.watch<InventoryProvider>();
    final isTransfer = widget.type == 'transfer';

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate('reference'),
                style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            TextField(controller: _ref, decoration: _input()),
            SizedBox(height: 12.h),
            Text(loc.translate('product'), style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            DropdownButton<InvProduct>(
              value: _selectedProduct,
              dropdownColor: ThemeConstants.primaryBlue,
              hint: Text(loc.translate('product'),
                  style: ThemeConstants.bodyStyle),
              items: inv.products
                  .map((p) => DropdownMenuItem<InvProduct>(
                        value: p,
                        child: Text('${p.name} (SKU: ${p.sku})',
                            style: ThemeConstants.bodyStyle),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedProduct = v),
            ),
            SizedBox(height: 12.h),
            Text(loc.translate('quantity'), style: ThemeConstants.captionStyle),
            SizedBox(height: 6.h),
            TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: _input()),
            if (isTransfer) ...[
              SizedBox(height: 12.h),
              Text(loc.translate('from_warehouse'),
                  style: ThemeConstants.captionStyle),
              SizedBox(height: 6.h),
              TextField(decoration: _input()),
              SizedBox(height: 12.h),
              Text(loc.translate('to_warehouse'),
                  style: ThemeConstants.captionStyle),
              SizedBox(height: 6.h),
              TextField(decoration: _input()),
            ],
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(_qty.text) ?? 0;
                  if (_selectedProduct == null || qty <= 0) {
                    ThemeConstants.showErrorSnackBar(
                        context, loc.translate('error'));
                    return;
                  }
                  bool ok = true;
                  if (widget.type == 'in') {
                    ok = await inv.stockIn(_selectedProduct!.id, qty);
                  } else if (widget.type == 'out') {
                    ok = await inv.stockOut(_selectedProduct!.id, qty);
                  } else {
                    // transfer: simple out then in on same product (single warehouse MVP)
                    ok = await inv.stockOut(_selectedProduct!.id, qty);
                    if (ok) ok = await inv.stockIn(_selectedProduct!.id, qty);
                  }
                  if (ok) {
                    if (!context.mounted) return;
                    ThemeConstants.showSuccessSnackBar(
                        context, loc.translate('saved'));
                  } else {
                    if (!context.mounted) return;
                    ThemeConstants.showErrorSnackBar(
                        context, loc.translate('cannot_negative_stock'));
                  }
                },
                child: Text(loc.translate('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input() => InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        hintStyle: ThemeConstants.captionStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      );
}
