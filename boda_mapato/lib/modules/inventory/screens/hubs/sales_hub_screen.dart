import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/localization_service.dart';
import '../orders/orders_screen.dart';
import '../sales/returns_screen.dart';
import '../sales/sales_screen.dart';
import '../widgets/inventory_widgets.dart';

class SalesHubScreen extends StatelessWidget {
  const SalesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InvTabScaffold(
      title: '',
      tabs: [
        loc.translate('sales'),
        loc.translate('returns_and_parked'),
        loc.translate('past_orders'),
      ],
      views: const [
        SalesScreen(),
        ReturnsScreen(),
        InventoryOrdersScreen(),
      ],
    );
  }
}
