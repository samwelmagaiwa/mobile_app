import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../models/inv_category.dart';
import '../../providers/inventory_provider.dart';
import 'category_form_screen.dart';

class InventoryCategoriesScreen extends StatefulWidget {
  const InventoryCategoriesScreen({super.key});

  @override
  State<InventoryCategoriesScreen> createState() =>
      _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends State<InventoryCategoriesScreen> {
  String _search = '';
  String _status = 'all'; // all | active | inactive
  final ScrollController _compactHCtrl = ScrollController();

  @override
  void dispose() {
    _compactHCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: ThemeConstants.invInputDecoration(
                        'Search categories...'),
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
                      items: const [
                        DropdownMenuItem(
                            value: 'all',
                            child: Text('All',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: 'active',
                            child: Text('Active',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive',
                                style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'all'),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton.icon(
                  onPressed: () async {
                    final inv = context.read<InventoryProvider>();
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<InventoryProvider>.value(
                          value: inv,
                          child: CategoryFormScreen(providerOverride: inv),
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (saved ?? false) {
                      ThemeConstants.showSuccessSnackBar(
                          context, 'Category added');
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ThemeConstants.buildGlassCardStatic(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: cats.isEmpty
                      ? Center(
                          child: Text('No categories found',
                              style: ThemeConstants.captionStyle))
                      : Builder(builder: (ctx) {
                          final bool compact = 1.sw < 420.w; // phone-friendly per ScreenUtil
                          if (compact) {
                            // Compact: ID | Name | Code | Total | Status
                            return Scrollbar(
                              controller: _compactHCtrl,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _compactHCtrl,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 1.25.sw),
                                  child: DataTable(
                                    columnSpacing: 1.w,
                                    horizontalMargin: 2.w,
                                    headingTextStyle: ThemeConstants.captionStyle.copyWith(fontWeight: FontWeight.bold),
                                    dataTextStyle: ThemeConstants.bodyStyle,
                                    columns: const [
                                      DataColumn(label: Text('Category Name')),
                                      DataColumn(label: Text('Code')),
                                      DataColumn(label: Text('T.products')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: cats.map((c) {
                                      final statusPill = Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: c.status == 'active' ? ThemeConstants.successGreen.withOpacity(0.18) : Colors.white10,
                                          borderRadius: BorderRadius.circular(14.r),
                                          border: Border.all(color: c.status == 'active' ? ThemeConstants.successGreen : Colors.white24),
                                        ),
                                        child: Text(c.status == 'active' ? 'Active' : 'Inactive', style: ThemeConstants.captionStyle),
                                      );
                                      return DataRow(cells: [
                                        DataCell(SizedBox(width: 128.w, child: AutoSizeText(c.name, maxLines: 1))),
                                        DataCell(SizedBox(width: 48.w, child: AutoSizeText(c.code.isEmpty ? '—' : c.code, maxLines: 1))),
                                        DataCell(SizedBox(width: 36.w, child: Text(c.totalProducts.toString()))),
                                        DataCell(statusPill),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          }
                          // Full table on wider screens (scrollable)
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: DataTable(
                              columnSpacing: 2.w,
                              horizontalMargin: 2.w,
                              headingTextStyle: ThemeConstants.captionStyle.copyWith(fontWeight: FontWeight.bold),
                              dataTextStyle: ThemeConstants.bodyStyle,
                              columns: const [
                                DataColumn(label: Text('Category Name')),
                                DataColumn(label: Text('Code')),
                                DataColumn(label: Text('T.products')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: cats.map((c) => _buildRow(context, inv, c, full:true)).toList(),
                            ),
                          );
                        }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context, InventoryProvider inv, InvCategory c, {bool full = false}) {
    final statusChip = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: c.status == 'active'
            ? ThemeConstants.successGreen.withOpacity(0.18)
            : Colors.white10,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: c.status == 'active'
                ? ThemeConstants.successGreen
                : Colors.white24),
      ),
      child: Text(c.status == 'active' ? 'Active' : 'Inactive',
          style: ThemeConstants.captionStyle),
    );

    return DataRow(
      cells: [
        DataCell(SizedBox(width: 150.w, child: AutoSizeText(c.name, maxLines: 1))),
        DataCell(SizedBox(
            width: 64.w,
            child: AutoSizeText(c.code.isEmpty ? '—' : c.code, maxLines: 1))),
        DataCell(SizedBox(width: 60.w, child: Text(c.totalProducts.toString()))),
        DataCell(statusChip),
      ],
    );
  }

}
