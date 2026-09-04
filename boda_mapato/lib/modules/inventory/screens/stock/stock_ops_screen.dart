import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_batch.dart';
import '../../models/inv_product.dart';
import '../../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';

/// "Stock In / Out / Transfer" — quick, everyday stock adjustments.
///
/// This is the fast path for small corrections. Receiving a real delivery
/// from a supplier belongs on the Purchasing screen instead, since that one
/// also keeps the supplier invoice and batch cost together.
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = context.read<InventoryProvider>();
      inv.fetchBatches();
      inv.fetchStockMovements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    return Column(
      children: <Widget>[
        SizedBox(height: 8.h),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: ThemeConstants.primaryOrange,
          tabs: <Widget>[
            Tab(text: loc.translate('stock_in')),
            Tab(text: loc.translate('stock_out')),
            Tab(text: loc.translate('stock_transfer')),
            const Tab(text: 'Historia ya Mzigo (Audit Log)'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const <Widget>[
              _StockInForm(),
              _StockOutForm(),
              _StockTransferForm(),
              _StockHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared bits: product picker and the note explaining what happens.
class _FormShell extends StatelessWidget {
  const _FormShell({required this.noteKey, required this.children});

  final String noteKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.all(12.w),
      child: Container(
        decoration: ThemeConstants.glassCardDecoration,
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline,
                      color: ThemeConstants.primaryCyan, size: 16),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      loc.translate(noteKey),
                      style: ThemeConstants.captionStyle,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _productPicker({
  required BuildContext context,
  required List<InvProduct> products,
  required int? value,
  required ValueChanged<int?> onChanged,
}) {
  final LocalizationService loc = LocalizationService.instance;

  return DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    dropdownColor: ThemeConstants.primaryBlue,
    style: ThemeConstants.bodyStyle,
    decoration: ThemeConstants.invInputDecoration(loc.translate('product')),
    items: products
        .map(
          (InvProduct p) => DropdownMenuItem<int>(
            value: p.id,
            child: Text(
              '${p.name}  ·  ${p.quantity} ${p.unit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ThemeConstants.bodyStyle,
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}

/// Add stock. A batch number and expiry are optional but recommended — they
/// are what lets the app warn about expiring stock and issue the oldest
/// batch first when a sale is made.
class _StockInForm extends StatefulWidget {
  const _StockInForm();

  @override
  State<_StockInForm> createState() => _StockInFormState();
}

class _StockInFormState extends State<_StockInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _ref = TextEditingController();
  final TextEditingController _batchNumber = TextEditingController();
  int? _productId;
  DateTime? _expiry;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qty.addListener(_onQtyChanged);
  }

  void _onQtyChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _qty.removeListener(_onQtyChanged);
    _qty.dispose();
    _ref.dispose();
    _batchNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final LocalizationService loc = LocalizationService.instance;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_productId == null) {
      ThemeConstants.showWarningSnackBar(
          context, loc.translate('select_product'));
      return;
    }

    setState(() => _saving = true);
    final bool ok = await context.read<InventoryProvider>().stockIn(
          _productId!,
          int.parse(_qty.text.trim()),
          reference: _ref.text.trim().isEmpty ? null : _ref.text.trim(),
          batchNumber: _batchNumber.text.trim().isEmpty
              ? null
              : _batchNumber.text.trim(),
          expiryDate: _expiry,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _qty.clear();
      _ref.clear();
      _batchNumber.clear();
      setState(() {
        _expiry = null;
        _productId = null;
      });
      ThemeConstants.showSuccessSnackBar(
          context, loc.translate('stock_updated'));
    } else {
      ThemeConstants.showErrorSnackBar(
          context, loc.translate('operation_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvProduct> products =
        context.watch<InventoryProvider>().products;

    InvProduct? selectedProduct;
    if (_productId != null) {
      final matches = products.where((p) => p.id == _productId);
      if (matches.isNotEmpty) selectedProduct = matches.first;
    }

    final int currentStock = selectedProduct?.quantity ?? 0;
    final int addedQty = int.tryParse(_qty.text.trim()) ?? 0;
    final int newTotalStock = currentStock + addedQty;

    return _FormShell(
      noteKey: 'stock_in_note',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _productPicker(
                context: context,
                products: products,
                value: _productId,
                onChanged: (int? v) => setState(() => _productId = v),
              ),
              if (selectedProduct != null) ...<Widget>[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: ThemeConstants.primaryCyan.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '📦 Mzigo uliopo sasa:',
                            style: ThemeConstants.captionStyle,
                          ),
                          Text(
                            '$currentStock ${selectedProduct.unit}',
                            style: ThemeConstants.bodyStyle
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (addedQty > 0) ...<Widget>[
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              '➕ Mzigo unaoongezwa:',
                              style: ThemeConstants.captionStyle.copyWith(
                                color: ThemeConstants.successGreen,
                              ),
                            ),
                            Text(
                              '+$addedQty ${selectedProduct.unit}',
                              style: ThemeConstants.bodyStyle.copyWith(
                                color: ThemeConstants.successGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          color: Colors.white24,
                          height: 12.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                '📊 Jumla Mpya itakayokuwepo:',
                                style: ThemeConstants.bodyStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '$newTotalStock ${selectedProduct.unit}',
                              style: ThemeConstants.bodyStyle.copyWith(
                                color: ThemeConstants.primaryOrange,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: 10.h),
              InvTextField(
                controller: _qty,
                label: loc.translate('quantity_received'),
                hint: 'e.g. 100',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (String? v) {
                  final int? n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1)
                      ? loc.translate('enter_valid_number')
                      : null;
                },
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _batchNumber,
                label: loc.translate('batch_number'),
                hint: 'e.g. BATCH-2026-09-01',
                isOptional: true,
              ),
              SizedBox(height: 10.h),
              InvDateField(
                label: loc.translate('expiry_date'),
                value: _expiry,
                onChanged: (DateTime? d) => setState(() => _expiry = d),
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _ref,
                label: loc.translate('reference'),
                hint: 'e.g. Delivery note number',
                isOptional: true,
              ),
              SizedBox(height: 16.h),
              InvPrimaryButton(
                busy: _saving,
                label: loc.translate('add_stock'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Remove stock without a sale — for example a sample given away or a count
/// correction. Damaged or expired goods belong on the Write-offs screen
/// instead, since those need a manager's approval.
class _StockOutForm extends StatefulWidget {
  const _StockOutForm();

  @override
  State<_StockOutForm> createState() => _StockOutFormState();
}

class _StockOutFormState extends State<_StockOutForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _ref = TextEditingController();
  int? _productId;
  int? _batchId;
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final LocalizationService loc = LocalizationService.instance;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_productId == null) {
      ThemeConstants.showWarningSnackBar(
          context, loc.translate('select_product'));
      return;
    }

    setState(() => _saving = true);
    final bool ok = await context.read<InventoryProvider>().stockOut(
          _productId!,
          int.parse(_qty.text.trim()),
          reference: _ref.text.trim().isEmpty ? null : _ref.text.trim(),
          batchId: _batchId,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _qty.clear();
      _ref.clear();
      setState(() {
        _batchId = null;
        _productId = null;
      });
      ThemeConstants.showSuccessSnackBar(
          context, loc.translate('stock_updated'));
    } else {
      ThemeConstants.showErrorSnackBar(
          context, loc.translate('cannot_negative_stock'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final InventoryProvider inv = context.watch<InventoryProvider>();
    final List<InvBatch> batches =
        _productId == null ? const <InvBatch>[] : inv.batchesOf(_productId!);

    return _FormShell(
      noteKey: 'stock_out_note',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _productPicker(
                context: context,
                products: inv.products,
                value: _productId,
                onChanged: (int? v) => setState(() {
                  _productId = v;
                  _batchId = null;
                }),
              ),
              if (batches.isNotEmpty) ...<Widget>[
                SizedBox(height: 10.h),
                DropdownButtonFormField<int>(
                  initialValue: _batchId,
                  isExpanded: true,
                  dropdownColor: ThemeConstants.primaryBlue,
                  style: ThemeConstants.bodyStyle,
                  decoration: ThemeConstants.invInputDecoration(
                    '${loc.translate('batch')} '
                    '(${loc.translate('optional')} — ${loc.translate('oldest_first_note')})',
                  ),
                  items: batches
                      .map(
                        (InvBatch b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(
                            '${b.batchNumber} — ${b.quantity} ${loc.translate('left')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ThemeConstants.bodyStyle,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (int? v) => setState(() => _batchId = v),
                ),
              ],
              SizedBox(height: 10.h),
              InvTextField(
                controller: _qty,
                label: loc.translate('quantity'),
                hint: 'e.g. 5',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (String? v) {
                  final int? n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1)
                      ? loc.translate('enter_valid_number')
                      : null;
                },
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _ref,
                label: loc.translate('reason'),
                hint: 'e.g. Sample given to a new customer',
                isOptional: true,
              ),
              SizedBox(height: 16.h),
              InvPrimaryButton(
                busy: _saving,
                label: loc.translate('remove_stock'),
                color: ThemeConstants.errorRed,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Move stock from one batch into a new or existing one for the same
/// product — for example after repacking, relabelling, or splitting a
/// delivery. The total quantity of the product does not change.
class _StockTransferForm extends StatefulWidget {
  const _StockTransferForm();

  @override
  State<_StockTransferForm> createState() => _StockTransferFormState();
}

class _StockTransferFormState extends State<_StockTransferForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _destBatchNumber = TextEditingController();
  int? _productId;
  int? _sourceBatchId;
  DateTime? _destExpiry;
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _destBatchNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final LocalizationService loc = LocalizationService.instance;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_productId == null || _sourceBatchId == null) {
      ThemeConstants.showWarningSnackBar(
          context, loc.translate('select_product_and_batch'));
      return;
    }

    setState(() => _saving = true);
    final InventoryProvider inv = context.read<InventoryProvider>();
    final int qty = int.parse(_qty.text.trim());

    final bool outOk = await inv.stockOut(
      _productId!,
      qty,
      batchId: _sourceBatchId,
      reference: 'Transfer to ${_destBatchNumber.text.trim()}',
    );
    final bool inOk = outOk
        ? await inv.stockIn(
            _productId!,
            qty,
            batchNumber: _destBatchNumber.text.trim(),
            expiryDate: _destExpiry,
            reference: 'Transfer from batch',
          )
        : false;

    if (!mounted) return;
    setState(() => _saving = false);
    if (inOk) {
      _qty.clear();
      _destBatchNumber.clear();
      setState(() {
        _sourceBatchId = null;
        _productId = null;
        _destExpiry = null;
      });
      ThemeConstants.showSuccessSnackBar(
          context, loc.translate('stock_updated'));
    } else {
      ThemeConstants.showErrorSnackBar(
          context, loc.translate('operation_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final InventoryProvider inv = context.watch<InventoryProvider>();
    final List<InvBatch> batches =
        _productId == null ? const <InvBatch>[] : inv.batchesOf(_productId!);

    return _FormShell(
      noteKey: 'stock_transfer_note',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _productPicker(
                context: context,
                products: inv.products,
                value: _productId,
                onChanged: (int? v) => setState(() {
                  _productId = v;
                  _sourceBatchId = null;
                }),
              ),
              SizedBox(height: 10.h),
              DropdownButtonFormField<int>(
                initialValue: _sourceBatchId,
                isExpanded: true,
                dropdownColor: ThemeConstants.primaryBlue,
                style: ThemeConstants.bodyStyle,
                decoration: ThemeConstants.invInputDecoration(
                    loc.translate('from_batch')),
                items: batches
                    .map(
                      (InvBatch b) => DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(
                          '${b.batchNumber} — ${b.quantity} ${loc.translate('left')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ThemeConstants.bodyStyle,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: batches.isEmpty
                    ? null
                    : (int? v) => setState(() => _sourceBatchId = v),
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _qty,
                label: loc.translate('quantity'),
                hint: 'e.g. 20',
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (String? v) {
                  final int? n = int.tryParse((v ?? '').trim());
                  return (n == null || n < 1)
                      ? loc.translate('enter_valid_number')
                      : null;
                },
              ),
              SizedBox(height: 10.h),
              InvTextField(
                controller: _destBatchNumber,
                label: loc.translate('to_batch'),
                hint: 'e.g. BATCH-2026-09-02-B',
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? loc.translate('field_required')
                    : null,
              ),
              SizedBox(height: 10.h),
              InvDateField(
                label: loc.translate('expiry_date'),
                value: _destExpiry,
                onChanged: (DateTime? d) => setState(() => _destExpiry = d),
              ),
              SizedBox(height: 16.h),
              InvPrimaryButton(
                busy: _saving,
                label: loc.translate('move_stock'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockHistoryTab extends StatefulWidget {
  const _StockHistoryTab();

  @override
  State<_StockHistoryTab> createState() => _StockHistoryTabState();
}

class _StockHistoryTabState extends State<_StockHistoryTab> {
  int? _selectedProductId;

  Future<void> _refresh() async {
    await context
        .read<InventoryProvider>()
        .fetchStockMovements(productId: _selectedProductId);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final products = inv.products;
    final movements = inv.stockMovements;

    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedProductId,
                  isExpanded: true,
                  dropdownColor: ThemeConstants.primaryBlue,
                  style: ThemeConstants.bodyStyle,
                  decoration: ThemeConstants.invInputDecoration('Chuja kwa Bidhaa (All Products)'),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Bidhaa Zote (All Products)', style: ThemeConstants.bodyStyle),
                    ),
                    ...products.map(
                      (p) => DropdownMenuItem<int?>(
                        value: p.id,
                        child: Text('${p.name} (${p.sku})', style: ThemeConstants.bodyStyle),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedProductId = v);
                    inv.fetchStockMovements(productId: v);
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _refresh,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              backgroundColor: Colors.white,
              color: ThemeConstants.primaryBlue,
              child: movements.isEmpty
                  ? const InvEmptyState(
                      icon: Icons.history,
                      message: 'Hakuna taarifa za kuingiza au kutoa mzigo bado.',
                    )
                  : ListView.separated(
                      itemCount: movements.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final m = movements[index];
                        final isStockIn = m.isStockIn;
                        final dateStr =
                            '${m.createdAt.year}-${m.createdAt.month.toString().padLeft(2, '0')}-${m.createdAt.day.toString().padLeft(2, '0')} ${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';

                        return Container(
                          decoration: ThemeConstants.glassCardDecoration,
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isStockIn
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                    color: isStockIn
                                        ? ThemeConstants.successGreen
                                        : ThemeConstants.errorRed,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      m.productName.isNotEmpty
                                          ? m.productName
                                          : 'Product #${m.productId}',
                                      style: ThemeConstants.bodyStyle
                                          .copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  InvBadge(
                                    label: isStockIn ? 'Mzigo Umeingia' : 'Mzigo Umetolewa',
                                    color: isStockIn
                                        ? ThemeConstants.successGreen
                                        : ThemeConstants.errorRed,
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📦 Zilizokuwepo: ${m.previousQuantity}',
                                    style: ThemeConstants.captionStyle,
                                  ),
                                  Text(
                                    isStockIn
                                        ? '➕ Ongezeko: +${m.quantity}'
                                        : '➖ Punguzo: -${m.quantity}',
                                    style: ThemeConstants.captionStyle.copyWith(
                                      color: isStockIn
                                          ? ThemeConstants.successGreen
                                          : ThemeConstants.errorRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '📊 Mpya: ${m.newQuantity}',
                                    style: ThemeConstants.captionStyle.copyWith(
                                      color: ThemeConstants.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (m.reference.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  '📝 ${m.reference}',
                                  style: ThemeConstants.captionStyle.copyWith(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              SizedBox(height: 4.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📅 $dateStr',
                                    style: ThemeConstants.captionStyle
                                        .copyWith(fontSize: 10.sp),
                                  ),
                                  if (m.userName.isNotEmpty)
                                    Text(
                                      '👤 ${m.userName}',
                                      style: ThemeConstants.captionStyle
                                          .copyWith(fontSize: 10.sp),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

