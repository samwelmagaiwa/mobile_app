import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_category.dart';
import '../../providers/inventory_provider.dart';
import '../../../../models/user_permissions.dart';
import 'category_form_screen.dart';

class InventoryCategoriesScreen extends StatefulWidget {
  const InventoryCategoriesScreen({super.key});

  @override
  State<InventoryCategoriesScreen> createState() =>
      _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends State<InventoryCategoriesScreen> {
  String _search = '';
  String _status = 'all';
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _openForm(InvCategory? existing) async {
    final inv = context.read<InventoryProvider>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<InventoryProvider>.value(
          value: inv,
          child: CategoryFormScreen(providerOverride: inv, existing: existing),
        ),
      ),
    );
    if (!mounted) return;
    if (saved ?? false) {
      ThemeConstants.showSuccessSnackBar(
          context, LocalizationService.instance.translate('saved'));
    }
  }

  Future<void> _confirmDelete(
      BuildContext ctx, InventoryProvider inv, InvCategory c) async {
    final loc = LocalizationService.instance;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        title: Text(loc.translate('confirm_delete'),
            style: ThemeConstants.bodyStyle
                .copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          '${loc.translate('delete')} "${c.name}"?\n${c.totalProducts > 0 ? loc.translate('category_has_products_warning') : ""}',
          style: ThemeConstants.captionStyle,
        ),
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
    final ok = await inv.deleteCategory(c.id);
    if (!mounted) return;
    if (ok) {
      ThemeConstants.showSuccessSnackBar(ctx, loc.translate('deleted'));
    } else {
      ThemeConstants.showErrorSnackBar(ctx, loc.translate('failed_to_delete'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final inv = context.watch<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    // Categories are gated by inv_manage_products (same as elsewhere in the
    // inventory module -- there is no separate inv_manage_categories
    // permission on the backend). fromUser (not fromRole) also honours a
    // per-user explicit grant, not just the role default.
    final canManage = UserPermissions.fromUser(
      userRole: auth.user?.role ?? 'viewer',
      explicitGrants: auth.user?.permissions,
    ).has('inv_manage_products');

    final List<InvCategory> cats = inv.categories
        .where((c) =>
            (_status == 'all' || c.status == _status) &&
            (c.name.toLowerCase().contains(_search.toLowerCase()) ||
                c.code.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    onPressed: () => _openForm(null),
                    icon: const Icon(Icons.add),
                    label: Text(loc.translate('add_category')),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            // ── Table ────────────────────────────────────────────────
            Expanded(
              child: ThemeConstants.buildGlassCardStatic(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: cats.isEmpty
                      ? Center(
                          child: Text(loc.translate('no_categories_found'),
                              style: ThemeConstants.captionStyle))
                      : Scrollbar(
                          controller: _hCtrl,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _hCtrl,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minWidth: MediaQuery.of(context).size.width - 60),
                              child: DataTable(
                                columnSpacing: 12.w,
                                horizontalMargin: 8.w,
                                headingTextStyle: ThemeConstants.captionStyle
                                    .copyWith(fontWeight: FontWeight.bold),
                                dataTextStyle: ThemeConstants.bodyStyle,
                                columns: [
                                  DataColumn(
                                      label: Text(loc.translate('category_name'))),
                                  DataColumn(
                                      label: Text(loc.translate('code'))),
                                  DataColumn(
                                      label: Text(
                                          loc.translate('total_products_abbr'))),
                                  DataColumn(
                                      label: Text(loc.translate('status'))),
                                  if (canManage)
                                    DataColumn(
                                        label:
                                            Text(loc.translate('actions'))),
                                ],
                                rows: cats
                                    .map((c) => _buildRow(
                                        context, loc, inv, c,
                                        canManage: canManage))
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

  Widget _statusPill(LocalizationService loc, InvCategory c) => Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: c.status == 'active'
              ? ThemeConstants.successGreen.withOpacity(0.18)
              : Colors.white10,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: c.status == 'active'
                  ? ThemeConstants.successGreen
                  : Colors.white24),
        ),
        child: Text(
            c.status == 'active'
                ? loc.translate('active')
                : loc.translate('inactive'),
            style: ThemeConstants.captionStyle),
      );

  DataRow _buildRow(
    BuildContext context,
    LocalizationService loc,
    InventoryProvider inv,
    InvCategory c, {
    required bool canManage,
  }) {
    return DataRow(cells: [
      DataCell(SizedBox(
          width: 150.w, child: AutoSizeText(c.name, maxLines: 1))),
      DataCell(SizedBox(
          width: 64.w,
          child:
              AutoSizeText(c.code.isEmpty ? '—' : c.code, maxLines: 1))),
      DataCell(
          SizedBox(width: 60.w, child: Text(c.totalProducts.toString()))),
      DataCell(_statusPill(loc, c)),
      if (canManage)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: loc.translate('edit'),
                onPressed: () => _openForm(c),
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white70, size: 18),
              ),
              IconButton(
                tooltip: loc.translate('delete'),
                onPressed: () => _confirmDelete(context, inv, c),
                icon: Icon(Icons.delete_outline,
                    color: ThemeConstants.errorRed, size: 18),
              ),
            ],
          ),
        ),
    ]);
  }
}
