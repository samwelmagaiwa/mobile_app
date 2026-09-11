import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    );
  }
}
