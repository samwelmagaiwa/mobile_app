import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/localization_service.dart';
import '../alerts/alerts_screen.dart';
import '../cash/cash_sessions_screen.dart';
import '../reminders/inventory_reminders_screen.dart';
import '../reports/reports_screen.dart';
import '../widgets/inventory_widgets.dart';

class FinanceReportsHubScreen extends StatelessWidget {
  const FinanceReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InvTabScaffold(
      title: '',
      tabs: [
        loc.translate('daily_cash'),
        loc.translate('reports'),
        loc.translate('alerts'),
        loc.translate('reminders'),
      ],
      views: const [
        CashSessionsScreen(),
        ReportsScreen(),
        AlertsScreen(),
        InventoryRemindersScreen(),
      ],
    );
  }
}
