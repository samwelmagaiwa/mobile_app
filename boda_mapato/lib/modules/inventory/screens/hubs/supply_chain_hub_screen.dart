import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/user_permissions.dart';
import '../../../../services/localization_service.dart';
import '../crates/crates_screen.dart';
import '../expenses/expenses_screen.dart';
import '../purchasing/purchasing_screen.dart';
import '../widgets/inventory_widgets.dart';

class SupplyChainHubScreen extends StatelessWidget {
  const SupplyChainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InvTabScaffold(
      title: '',
      tabs: [
        loc.translate('purchasing'),
        loc.translate('crates_and_empties'),
        loc.translate('warehouse_expenses'),
      ],
      views: const [
        PurchasingScreen(),
        CratesScreen(),
        ExpensesScreen(),
      ],
      // Purchasing — only users who can view purchasing orders.
      // Crates & Empties — anyone who tracks crate deposits (sales_officer included).
      // Warehouse Expenses — only users who can view the expense ledger.
      tabPermissions: [
        (UserPermissions p) => p.has('inv_view_purchasing'),
        null,
        (UserPermissions p) =>
            p.has('inv_view_expenses') || p.has('inv_manage_expenses'),
      ],
    );
  }
}
