import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/theme_constants.dart';
import '../../../services/localization_service.dart';
import '../providers/inventory_provider.dart';
import 'dashboard/inventory_dashboard_screen.dart';
import 'products/products_screen.dart';
import 'stock/stock_levels_screen.dart';
import 'stock/stock_ops_screen.dart';
import 'sales/sales_screen.dart';
import 'reminders/inventory_reminders_screen.dart';

class InventoryHome extends StatefulWidget {
  const InventoryHome({super.key});

  @override
  State<InventoryHome> createState() => _InventoryHomeState();
}

class _InventoryHomeState extends State<InventoryHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;

    final pages = <Widget>[
      const InventoryDashboardScreen(),
      const ProductsScreen(),
      const StockLevelsScreen(),
      const StockOpsScreen(),
      const SalesScreen(),
      const InventoryRemindersScreen(),
    ];

    final titles = <String>[
      loc.translate('inventory_dashboard'),
      loc.translate('products'),
      loc.translate('stock_levels'),
      loc.translate('stock_in_out_transfer'),
      loc.translate('sales'),
      loc.translate('reminders'),
    ];

    return ChangeNotifierProvider(
      create: (_) => InventoryProvider()..bootstrap(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: ThemeConstants.primaryBlue,
          appBar: ThemeConstants.buildAppBar(titles[_index], actions: [
            IconButton(
              icon: Icon(Icons.search, size: 20.sp),
              onPressed: () {},
            ),
          ]),
          drawer: _InventoryDrawer(
            index: _index,
            onSelected: (i) {
              setState(() => _index = i);
              Navigator.pop(context);
            },
          ),
          body: SafeArea(child: pages[_index]),
        ),
      ),
    );
  }
}

class _InventoryDrawer extends StatelessWidget {
  const _InventoryDrawer({required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return Drawer(
      backgroundColor: ThemeConstants.primaryBlue,
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('dashboard'), style: ThemeConstants.bodyStyle),
              selected: index == 0,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(0),
            ),
            ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('products'), style: ThemeConstants.bodyStyle),
              selected: index == 1,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(1),
            ),
            ListTile(
              leading: Icon(Icons.track_changes_outlined, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('stock_levels'), style: ThemeConstants.bodyStyle),
              selected: index == 2,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(2),
            ),
            ListTile(
              leading: Icon(Icons.sync_alt_outlined, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('stock_in_out_transfer'), style: ThemeConstants.bodyStyle),
              selected: index == 3,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(3),
            ),
            ListTile(
              leading: Icon(Icons.point_of_sale_outlined, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('sales'), style: ThemeConstants.bodyStyle),
              selected: index == 4,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(4),
            ),
            ListTile(
              leading: Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22.sp),
              title: Text(loc.translate('reminders'), style: ThemeConstants.bodyStyle),
              selected: index == 5,
              selectedTileColor: Colors.white10,
              onTap: () => onSelected(5),
            ),
          ],
        ),
      ),
    );
  }
}
