import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/user_permissions.dart';
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
      // Daily Cash — cashier/manager only.
      // Reports — manager/admin only.
      // Alerts — anyone who can view products sees stock alerts.
      // Reminders — anyone with reminders permission.
      tabPermissions: [
        (UserPermissions p) => p.has('inv_view_cash'),
        (UserPermissions p) => p.has('inv_view_reports'),
        (UserPermissions p) => p.has('inv_view_products'),
        (UserPermissions p) => p.has('inv_view_reminders'),
      ],
    );
  }
}
