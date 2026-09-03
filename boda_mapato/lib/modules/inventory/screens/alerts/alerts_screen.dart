import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../services/localization_service.dart';
import '../../models/inv_depot_models.dart';
import '../../providers/depot_provider.dart';
import '../widgets/inventory_widgets.dart';

/// Area 12 — low stock, near expiry, over credit limit, overdue invoices,
/// large discounts and pending approvals, all in one place.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = false;
  String _filter = 'all';

  static const Map<String, IconData> _icons = <String, IconData>{
    'low_stock': Icons.inventory_2_outlined,
    'near_expiry': Icons.schedule_outlined,
    'expired': Icons.dangerous_outlined,
    'over_credit_limit': Icons.credit_card_off_outlined,
    'overdue_invoice': Icons.event_busy_outlined,
    'pending_approval': Icons.pending_actions_outlined,
  };

  @override
  void initState() {
    super.initState();
    // Draw whatever is already cached; only show a spinner on a cold start.
    _loading = context.read<DepotProvider>().alerts.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<DepotProvider>().fetchAlerts();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final DepotProvider depot = context.watch<DepotProvider>();
    final List<InvAlert> all = depot.alerts;
    final List<InvAlert> rows = _filter == 'all'
        ? all
        : all.where((InvAlert a) => a.severity == _filter).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : RefreshIndicator(
                onRefresh: _load,
                backgroundColor: Colors.white,
                color: ThemeConstants.primaryBlue,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InvStatTile(
                            label: loc.translate('open_alerts'),
                            value: '${depot.openAlertCount}',
                            icon: Icons.notifications_active_outlined,
                            accent: depot.openAlertCount > 0
                                ? ThemeConstants.warningAmber
                                : null,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: InvStatTile(
                            label: loc.translate('critical'),
                            value: '${depot.criticalAlertCount}',
                            icon: Icons.priority_high_rounded,
                            accent: depot.criticalAlertCount > 0
                                ? ThemeConstants.errorRed
                                : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    InvFilterChips<String>(
                      value: _filter,
                      options: <String, String>{
                        'all': loc.translate('all'),
                        'critical': loc.translate('critical'),
                        'warning': loc.translate('warning'),
                        'info': loc.translate('info'),
                      },
                      onSelected: (String v) => setState(() => _filter = v),
                    ),
                    SizedBox(height: 10.h),
                    if (rows.isEmpty)
                      InvEmptyState(
                        icon: Icons.verified_outlined,
                        message: loc.translate('no_alerts'),
                      )
                    else
                      ...rows.map(
                        (InvAlert a) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _AlertCard(
                            alert: a,
                            icon: _icons[a.type] ??
                                Icons.notifications_none_rounded,
                            onAcknowledge: () => _acknowledge(a),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _acknowledge(InvAlert alert) async {
    await context.read<DepotProvider>().acknowledgeAlert(alert.id);
    if (mounted) {
      await _load();
    }
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.icon,
    required this.onAcknowledge,
  });

  final InvAlert alert;
  final IconData icon;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final Color color = switch (alert.severity) {
      'critical' => ThemeConstants.errorRed,
      'warning' => ThemeConstants.warningAmber,
      _ => ThemeConstants.primaryCyan,
    };

    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 17.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText(
                  alert.title,
                  maxLines: 2,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConstants.bodyStyle
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                if (alert.body.isNotEmpty) ...<Widget>[
                  SizedBox(height: 2.h),
                  AutoSizeText(
                    alert.body,
                    maxLines: 2,
                    minFontSize: 9,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConstants.captionStyle,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 6.w),
          IconButton(
            tooltip: loc.translate('acknowledge'),
            onPressed: onAcknowledge,
            icon: Icon(Icons.check_circle_outline,
                color: Colors.white38, size: 20.sp),
          ),
        ],
      ),
    );
  }
}
