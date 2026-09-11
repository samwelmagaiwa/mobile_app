import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../models/user_permissions.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_brand.dart';
import '../../providers/inventory_provider.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  String _search = '';
  String _status = 'all';
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm({InvBrand? brand}) async {
    final inv = context.read<InventoryProvider>();
    final loc = LocalizationService.instance;
    final nameCtrl = TextEditingController(text: brand?.name ?? '');
    final descCtrl = TextEditingController(text: brand?.description ?? '');
    bool active = brand?.status != 'inactive';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (sCtx, setSt) => AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue,
          title: Text(
            brand == null ? loc.translate('add_brand') : loc.translate('edit_brand'),
            style: ThemeConstants.bodyStyle
                .copyWith(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 320.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: ThemeConstants.bodyStyle,
                  decoration: ThemeConstants.invInputDecoration(
                      loc.translate('brand_name')),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: descCtrl,
                  style: ThemeConstants.bodyStyle,
                  maxLines: 2,
                  decoration: ThemeConstants.invInputDecoration(
                      loc.translate('description')),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(loc.translate('active'),
                        style: ThemeConstants.captionStyle),
                    const Spacer(),
                    Switch(
                      value: active,
                      activeColor: ThemeConstants.successGreen,
                      onChanged: (v) => setSt(() => active = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text(loc.translate('cancel'),
                  style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                bool ok;
                if (brand == null) {
                  final id = await inv.createBrand(
                    name: name,
                    description: descCtrl.text.trim(),
                    status: active ? 'active' : 'inactive',
                  );
                  ok = id != null;
                } else {
                  ok = await inv.updateBrand(
                    brand.id,
                    name: name,
                    description: descCtrl.text.trim(),
                    status: active ? 'active' : 'inactive',
                  );
                }
                if (sCtx.mounted) Navigator.pop(dCtx, ok);
              },
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      ThemeConstants.showSuccessSnackBar(context, loc.translate('saved'));
    } else if (saved == false && brand != null) {
      ThemeConstants.showErrorSnackBar(
          context, loc.translate('failed_to_save'));
    }
  }

  Future<void> _confirmDelete(InventoryProvider inv, InvBrand b) async {
    final loc = LocalizationService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        title: Text(loc.translate('confirm_delete'),
            style:
                ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
        content: Text('${loc.translate('delete')} "${b.name}"?',
            style: ThemeConstants.captionStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(loc.translate('cancel'),
                style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.errorRed),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await inv.deleteBrand(b.id);
    if (!mounted) return;
    if (ok) {
      ThemeConstants.showSuccessSnackBar(context, loc.translate('deleted'));
    } else {
      ThemeConstants.showErrorSnackBar(
          context, loc.translate('failed_to_delete'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final inv = context.watch<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final canManage =
        UserPermissions.fromRole(auth.user?.role ?? 'viewer').has('inv_manage_products');

    final brands = inv.brands
        .where((b) =>
            (_status == 'all' || b.status == _status) &&
            b.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
        child: Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: ThemeConstants.invInputDecoration(
                        '${loc.translate('search')}...'),
                  ),
                ),
                SizedBox(width: 8.w),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: ThemeConstants.invFill,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: ThemeConstants.invBorder),
                    ),
                    child: DropdownButton<String>(
                      value: _status,
                      dropdownColor: ThemeConstants.primaryBlue,
                      items: [
                        DropdownMenuItem(
                            value: 'all',
                            child: Text(loc.translate('all'),
                                style: const TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: 'active',
                            child: Text(loc.translate('active'),
                                style: const TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: 'inactive',
                            child: Text(loc.translate('inactive'),
                                style: const TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'all'),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (canManage)
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: Text(loc.translate('add_brand')),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            // ── Table ────────────────────────────────────────────────
            Expanded(
              child: ThemeConstants.buildGlassCardStatic(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: brands.isEmpty
                      ? Center(
                          child: Text(loc.translate('no_brands_found'),
                              style: ThemeConstants.captionStyle))
                      : Scrollbar(
                          controller: _hCtrl,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _hCtrl,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width - 60),
                              child: DataTable(
                                columnSpacing: 12.w,
                                horizontalMargin: 8.w,
                                headingTextStyle: ThemeConstants.captionStyle
                                    .copyWith(fontWeight: FontWeight.bold),
                                dataTextStyle: ThemeConstants.bodyStyle,
                                columns: [
                                  DataColumn(
                                      label: Text(loc.translate('brand_name'))),
                                  DataColumn(
                                      label:
                                          Text(loc.translate('total_products_abbr'))),
                                  DataColumn(
                                      label: Text(loc.translate('status'))),
                                  if (canManage)
                                    DataColumn(
                                        label: Text(loc.translate('actions'))),
                                ],
                                rows: brands
                                    .map((b) =>
                                        _buildRow(loc, inv, b, canManage))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(LocalizationService loc, InvBrand b) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: b.isActive
              ? ThemeConstants.successGreen.withOpacity(0.18)
              : Colors.white10,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: b.isActive ? ThemeConstants.successGreen : Colors.white24),
        ),
        child: Text(
            b.isActive ? loc.translate('active') : loc.translate('inactive'),
            style: ThemeConstants.captionStyle),
      );

  DataRow _buildRow(
      LocalizationService loc, InventoryProvider inv, InvBrand b, bool canManage) {
    return DataRow(cells: [
      DataCell(SizedBox(
          width: 180.w, child: AutoSizeText(b.name, maxLines: 1))),
      DataCell(SizedBox(
          width: 60.w, child: Text(b.totalProducts.toString()))),
      DataCell(_statusPill(loc, b)),
      if (canManage)
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: loc.translate('edit'),
              onPressed: () => _openForm(brand: b),
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white70, size: 18),
            ),
            IconButton(
              tooltip: loc.translate('delete'),
              onPressed: () => _confirmDelete(inv, b),
              icon: Icon(Icons.delete_outline,
                  color: ThemeConstants.errorRed, size: 18),
            ),
          ],
        )),
    ]);
  }
}
