import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/user_permissions.dart';
import '../../../../services/localization_service.dart';
import '../stock/batches_screen.dart';
import '../stock/stock_counts_screen.dart';
import '../stock/stock_levels_screen.dart';
import '../stock/stock_ops_screen.dart';
import '../stock/write_offs_screen.dart';
import '../widgets/inventory_widgets.dart';

class StockHubScreen extends StatelessWidget {
  const StockHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InvTabScaffold(
      title: '',
      tabs: [
        loc.translate('stock_levels'),
        loc.translate('stock_in_out_transfer'),
        loc.translate('batches_and_expiry'),
        loc.translate('stock_counts'),
        loc.translate('write_offs'),
      ],
      views: const [
        StockLevelsScreen(),
        StockOpsScreen(),
        BatchesScreen(),
        StockCountsScreen(),
        WriteOffsScreen(),
      ],
      // Stock Levels — anyone who can see this hub (inv_manage_stock or
      //   inv_report_damage) should see current stock to know what's available.
      // Stock In/Out, Batches, Counts — full stock management only.
      // Write-offs — anyone who can report damage (inv_report_damage) or
      //   has full stock management.
      tabPermissions: [
        null,
        (UserPermissions p) => p.has('inv_manage_stock'),
        (UserPermissions p) => p.has('inv_manage_stock'),
        (UserPermissions p) => p.has('inv_manage_stock'),
        (UserPermissions p) =>
            p.has('inv_manage_stock') || p.has('inv_report_damage'),
      ],
    );
  }
}
