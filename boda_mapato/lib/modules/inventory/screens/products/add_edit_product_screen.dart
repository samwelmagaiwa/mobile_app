import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../inventory_home.dart';

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key, this.productId});
  final String? productId; // null => add mode, otherwise edit

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  // Basic controllers
  final TextEditingController _name = TextEditingController();
  final TextEditingController _sku = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _minStock = TextEditingController(text: '0');
  final TextEditingController _barcode = TextEditingController();
  final TextEditingController _createdBy = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _groomer = TextEditingController();
  final TextEditingController _deal = TextEditingController();
  final TextEditingController _ingredients = TextEditingController();

  String _unit = 'pcs';
  bool _active = true;

  // Size/variant list
  final List<_Variant> _variants = <_Variant>[
    _Variant(),
  ];

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _category.dispose();
    _cost.dispose();
    _price.dispose();
    _qty.dispose();
    _minStock.dispose();
    _barcode.dispose();
    _createdBy.dispose();
    _description.dispose();
    _groomer.dispose();
    _deal.dispose();
    _ingredients.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ThemeConstants.buildAppBar(
        widget.productId == null
            ? loc.translate('add_product')
            : loc.translate('edit_product'),
        actions: [
          IconButton(
            icon: Icon(Icons.save, size: 20.sp),
            tooltip: loc.translate('save'),
            onPressed: _onSave,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20.sp),
            tooltip: loc.translate('delete'),
            onPressed: _onDelete,
          ),
        ],
      ),
      bottomNavigationBar: _InventoryFooterForForm(),
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: ThemeConstants.dashboardBackground,
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(14.w),
              child: Container(
                decoration: ThemeConstants.invCardDecoration,
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _twoCol(
                      left: _input(loc.translate('name'), _name),
                      right: _input(loc.translate('product_id'), _sku,
                          hint: 'Eg. 343x93W'),
                    ),
                    SizedBox(height: 8.h),

                    // First sizes row mimic (chips + inputs)
                    _variantBlock(loc),

                    SizedBox(height: 10.h),
                    _photosBlock(loc),

                    SizedBox(height: 10.h),
                    _sectionTitle(loc.translate('product_description')),
                    _boxField(_description, hint: 'Product 1'),

                    SizedBox(height: 8.h),
                    _sectionTitle('Groomer Discussion'),
                    _boxField(_groomer, hint: 'Product 1'),

                    SizedBox(height: 8.h),
                    _sectionTitle('Deal String'),
                    _boxField(_deal, hint: 'Product 1'),

                    SizedBox(height: 8.h),
                    _sectionTitle('Ingredients'),
                    _boxField(_ingredients, hint: 'Product 1'),

                    SizedBox(height: 12.h),
                    _sectionTitle('Inventory & Pricing'),
                    SizedBox(height: 6.h),
                    _twoCol(
                      left: _input('Category', _category),
                      right: _dropdown(
                          'Unit', _unit, ['pcs', 'kg', 'litre', 'box'], (v) {
                        setState(() => _unit = v!);
                      }),
                    ),
                    SizedBox(height: 8.h),
                    _twoCol(
                      left: _input('Cost Price', _cost,
                          keyboard: TextInputType.number, hint: 'Eg. 345'),
                      right: _input('Selling Price', _price,
                          keyboard: TextInputType.number, hint: 'Eg. 395'),
                    ),
                    SizedBox(height: 8.h),
                    _twoCol(
                      left: _input('Quantity in Stock', _qty,
                          keyboard: TextInputType.number, hint: 'Eg. 5'),
                      right: _input('Stock Alert Threshold', _minStock,
                          keyboard: TextInputType.number, hint: 'Eg. 3'),
                    ),
                    if (_int(_qty.text) < _int(_minStock.text))
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 18.sp),
                              SizedBox(width: 6.w),
                              Text('Low Stock',
                                  style: ThemeConstants.captionStyle.copyWith(
                                      color: Colors.white, fontSize: 11.sp)),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 8.h),
                    _twoCol(
                      left: _input('Barcode (optional)', _barcode,
                          hint: 'EAN/QR'),
                      right: _switchRow('Status', _active,
                          (v) => setState(() => _active = v)),
                    ),
                    SizedBox(height: 8.h),
                    _twoCol(
                      left: _input('Created By', _createdBy),
                      right: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // UI building blocks
  Widget _variantBlock(LocalizationService loc) {
    // Header labels to mirror the shared design (Size | Quantity | Actual Price | Discounted Price)
    Widget headerLabels() => Padding(
          padding: EdgeInsets.only(bottom: 6.h, left: 4.w, right: 4.w),
          child: Row(
            children: [
              SizedBox(
                  width: 80.w,
                  child: Text('Size', style: ThemeConstants.captionStyle)),
              SizedBox(width: 6.w),
              Expanded(
                  child: Text('Quantity', style: ThemeConstants.captionStyle)),
              SizedBox(width: 6.w),
              Expanded(
                  child:
                      Text('Actual Price', style: ThemeConstants.captionStyle)),
              SizedBox(width: 6.w),
              Expanded(
                  child: Text('Discounted Price',
                      style: ThemeConstants.captionStyle)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerLabels(),
        for (int i = 0; i < _variants.length; i++) ...[
          Row(
            children: [
              SizedBox(width: 80.w, child: _chip('Product ${i + 1}')),
              SizedBox(width: 6.w),
              Expanded(child: _smallInput('Eg. 5x', _variants[i].qty)),
              SizedBox(width: 6.w),
              Expanded(child: _smallInput('Eg. 345', _variants[i].price)),
              SizedBox(width: 6.w),
              Expanded(child: _smallInput('Eg. 305', _variants[i].discount)),
              SizedBox(width: 6.w),
              if (_variants.length > 1)
                _dangerChip('Delete', () {
                  setState(() => _variants.removeAt(i));
                }),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: ThemeConstants.invAccent),
              _neutralChip('Add New Size', () {
                setState(() => _variants.add(_Variant()));
              }),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _photosBlock(LocalizationService loc) {
    Widget box({String? label}) => AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ThemeConstants.invFill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: ThemeConstants.invBorder),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white70, size: 18.sp),
                  if (label != null) ...[
                    SizedBox(height: 4.h),
                    Text(label, style: ThemeConstants.captionStyle),
                  ],
                ],
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Add Photos'),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(child: box(label: 'Primary Photo')),
            SizedBox(width: 8.w),
            Expanded(child: box()),
            SizedBox(width: 8.w),
            Expanded(child: box()),
            SizedBox(width: 8.w),
            Expanded(child: box()),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: AutoSizeText(
          text,
          style: ThemeConstants.headingStyle.copyWith(fontSize: 14.sp),
          maxLines: 1,
          minFontSize: 11,
        ),
      );

  Widget _twoCol({required Widget left, required Widget right}) => Row(
        children: [
          Expanded(child: left),
          SizedBox(width: 8.w),
          Expanded(child: right),
        ],
      );

  Widget _boxField(TextEditingController c, {String? hint}) => TextField(
        controller: c,
        maxLines: 2,
        decoration: _decoration(hint ?? ''),
        style: ThemeConstants.bodyStyle,
      );

  Widget _input(String label, TextEditingController c,
          {String? hint, TextInputType? keyboard}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(label),
          TextField(
            controller: c,
            keyboardType: keyboard,
            decoration: _decoration(hint ?? label),
            style: ThemeConstants.bodyStyle,
          ),
        ],
      );

  Widget _smallInput(String hint, TextEditingController c) => SizedBox(
        height: 36.h,
        child: TextField(
          controller: c,
          decoration: _decoration(hint),
          style: ThemeConstants.bodyStyle,
        ),
      );

  InputDecoration _decoration(String hint) =>
      ThemeConstants.invInputDecoration(hint);

  Widget _dropdown(String label, String value, List<String> items,
          ValueChanged<String?> onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: ThemeConstants.invFill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: ThemeConstants.invBorder),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: ThemeConstants.primaryBlue,
              underline: const SizedBox.shrink(),
              style: ThemeConstants.bodyStyle,
              items: items
                  .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      );

  Widget _switchRow(String label, bool val, ValueChanged<bool> onChanged) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: ThemeConstants.invFill,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: ThemeConstants.invBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ThemeConstants.bodyStyle),
            Switch(value: val, onChanged: onChanged),
          ],
        ),
      );

  Widget _chip(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ThemeConstants.invNeutralChip,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ThemeConstants.invBorder),
        ),
        child: AutoSizeText(text,
            style: ThemeConstants.captionStyle, maxLines: 1, minFontSize: 10),
      );

  // Pill chip builder to guarantee identical height, radius, padding, and icon/text layout
  Widget _pillChip({
    required IconData icon,
    required String text,
    required Color bg,
    Color fg = Colors.white,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(18.r)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg.withOpacity(0.9), size: 18.sp),
              SizedBox(width: 8.w),
              AutoSizeText(
                text,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w600, fontSize: 13.sp),
                maxLines: 1,
                minFontSize: 10,
              ),
            ],
          ),
        ),
      );

  Widget _neutralChip(String text, VoidCallback onTap) => _pillChip(
        icon: Icons.edit_outlined,
        text: text,
        bg: const Color(0xFF1E3A46),
        onTap: onTap,
      );

  Widget _dangerChip(String text, VoidCallback onTap) => _pillChip(
        icon: Icons.delete_outline,
        text: text,
        bg: ThemeConstants.errorRed,
        onTap: onTap,
      );

  // Helpers
  int _int(String? s) => int.tryParse(s ?? '') ?? 0;

  void _onSave() {
    // TODO(dev): integrate with InventoryProvider API
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved (UI only).')));
  }

  void _onDelete() {
    // TODO(dev): hook to provider delete
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted (UI only).')));
  }
}

class _InventoryFooterForForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ThemeConstants.footerBarColor,
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: ThemeConstants.footerBarColor,
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
                _footerIcon(context, Icons.calendar_today_outlined,
                    () => _goto(context, 0)),
                Stack(children: [
                  _footerIcon(
                      context, Icons.person_outline, () => _goto(context, 1)),
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                            color: Colors.amber, shape: BoxShape.circle)),
                  ),
                ]),
                _footerIcon(context, Icons.menu, () => _openMenu(context)),
                _footerIcon(
                    context, Icons.pets_outlined, () => _goto(context, 2)),
                _footerIcon(context, Icons.settings_outlined,
                    () => Navigator.pushNamed(context, '/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerIcon(BuildContext context, IconData icon, VoidCallback onTap) =>
      InkResponse(
        onTap: onTap,
        radius: 28.r,
        child: Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
              color: ThemeConstants.primaryBlue.withOpacity(0.22),
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 22.sp),
        ),
      );

  void _goto(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => InventoryHome(initialIndex: index)),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final loc = LocalizationService.instance;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Container(
          decoration: BoxDecoration(
            color: ThemeConstants.primaryBlue.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white24),
          ),
          padding: EdgeInsets.all(12.w),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            shrinkWrap: true,
            children: [
              _gridItem(context, Icons.dashboard, loc.translate('dashboard'),
                  () => _goto(context, 0)),
              _gridItem(context, Icons.inventory_2_outlined,
                  loc.translate('products'), () => _goto(context, 1)),
              _gridItem(context, Icons.track_changes_outlined,
                  loc.translate('stock_levels'), () => _goto(context, 2)),
              _gridItem(
                  context,
                  Icons.sync_alt_outlined,
                  loc.translate('stock_in_out_transfer'),
                  () => _goto(context, 3)),
              _gridItem(context, Icons.point_of_sale_outlined,
                  loc.translate('sales'), () => _goto(context, 4)),
              _gridItem(context, Icons.category_outlined, 'Categories',
                  () => _goto(context, 5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridItem(BuildContext context, IconData icon, String label,
          VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
              color: ThemeConstants.invNeutralChip,
              borderRadius: BorderRadius.circular(16.r)),
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24.sp),
              SizedBox(height: 8.h),
              AutoSizeText(label,
                  style: ThemeConstants.bodyStyle,
                  maxLines: 2,
                  minFontSize: 10,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _Variant {
  _Variant();
  final TextEditingController qty = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController discount = TextEditingController();
}
