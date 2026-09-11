import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    );
  }
}
