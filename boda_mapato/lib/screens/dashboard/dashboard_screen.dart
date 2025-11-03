import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/colors.dart";
import "../../constants/styles.dart";
import "../../providers/device_provider.dart";
import "../../providers/transaction_provider.dart";
import "../../services/localization_service.dart";
import "../../widgets/custom_card.dart";
import "../device_selection/device_selection_screen.dart";
import "../receipts/receipt_screen.dart";
import "../reminders/reminders_screen.dart";
import "../reports/report_screen.dart";
import "../transactions/transactions_screen.dart";
import "dashboard_widgets.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final TransactionProvider transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final DeviceProvider deviceProvider =
        Provider.of<DeviceProvider>(context, listen: false);

    await Future.wait(<Future<void>>[
      transactionProvider.loadTransactions(),
      deviceProvider.loadDevices(),
    ]);
  }

  @override
  Widget build(final BuildContext context) => Consumer<LocalizationService>(
    builder: (context, localizationService, child) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            localizationService.translate("dashboard"),
            style: AppStyles.heading2,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final BuildContext context) =>
                        const RemindersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  SingleChildScrollView(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppStyles.spacingM * 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Revenue Summary Cards
                      const RevenueCardsSection(),

                      const SizedBox(height: AppStyles.spacingL),

                      // Quick Actions
                      Text(
                        localizationService.translate("quick_actions"),
                        style: AppStyles.heading3,
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      QuickActionsSection(localizationService: localizationService),

                      const SizedBox(height: AppStyles.spacingL),

                      // Recent Transactions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              localizationService.translate("recent_transactions"),
                              style: AppStyles.heading3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (final BuildContext context) =>
                                      const TransactionsScreen(),
                                ),
                              );
                            },
                            child: Text(localizationService.translate("view_all")),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      const RecentTransactionsSection(),

                      const SizedBox(height: AppStyles.spacingL),

                      // Device Status
                      Text(
                        localizationService.translate("device_status"),
                        style: AppStyles.heading3,
                      ),
                      const SizedBox(height: AppStyles.spacingM),
                      const DeviceStatusSection(),

                      // Add bottom padding to ensure FAB doesn't overlap content
                      const SizedBox(height: AppStyles.spacingXL),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: localizationService.translate("dashboard"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet),
              label: localizationService.translate("transactions"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt),
              label: localizationService.translate("generate_receipt"),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assessment),
              label: localizationService.translate("reports"),
            ),
          ],
          onTap: (final int index) {
            switch (index) {
              case 0:
                // Already on dashboard
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final BuildContext context) =>
                        const TransactionsScreen(),
                  ),
                );
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final BuildContext context) =>
                        const ReceiptScreen(),
                  ),
                );
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final BuildContext context) =>
                        const ReportScreen(),
                  ),
                );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final BuildContext context) =>
                    const DeviceSelectionScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    },
  );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.localizationService, super.key});
  
  final LocalizationService localizationService;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Use column layout for very small screens
          if (constraints.maxWidth < 300) {
            return Column(
              children: <Widget>[
                _QuickActionCard(
                  icon: Icons.add_circle,
                  title: localizationService.translate("new_transaction"),
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final BuildContext context) =>
                            const TransactionsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),
                _QuickActionCard(
                  icon: Icons.receipt_long,
                  title: localizationService.translate("generate_receipt"),
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final BuildContext context) =>
                            const ReceiptScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          }

          // Use row layout for normal screens
          return Row(
            children: <Widget>[
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle,
                  title: localizationService.translate("new_transaction"),
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final BuildContext context) =>
                            const TransactionsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.receipt_long,
                  title: localizationService.translate("generate_receipt"),
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (final BuildContext context) =>
                            const ReceiptScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => CustomCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: AppStyles.spacingS),
              Flexible(
                child: Text(
                  title,
                  style: AppStyles.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}
