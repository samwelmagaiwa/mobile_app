import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/styles.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/custom_card.dart';
import '../transactions/transactions_screen.dart';
import '../device_selection/device_selection_screen.dart';
import '../receipts/receipt_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/report_screen.dart';
import 'dashboard_widgets.dart';

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
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    await Future.wait(<Future<void>>[
      transactionProvider.loadTransactions(),
      deviceProvider.loadDevices(),
    ]);
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.dashboard,
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
                  builder: (final BuildContext final context) => const RemindersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Revenue Summary Cards
              const RevenueCardsSection(),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Quick Actions
              const Text(
                "Vitendo vya Haraka",
                style: AppStyles.heading3,
              ),
              const SizedBox(height: AppStyles.spacingM),
              const QuickActionsSection(),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    AppStrings.recentTransactions,
                    style: AppStyles.heading3,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (final BuildContext context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: const Text("Ona Zote"),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),
              const RecentTransactionsSection(),
              
              const SizedBox(height: AppStyles.spacingL),
              
              // Device Status
              const Text(
                "Hali ya Vyombo",
                style: AppStyles.heading3,
              ),
              const SizedBox(height: AppStyles.spacingM),
              const DeviceStatusSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashibodi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Miamala",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Risiti",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: "Ripoti",
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
                  builder: (final BuildContext context) => const TransactionsScreen(),
                ),
              );
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final BuildContext final context) => const ReceiptScreen(),
                ),
              );
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final BuildContext context) => const ReportScreen(),
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
              builder: (final BuildContext context) => const DeviceSelectionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(final BuildContext context) => Row(
      children: <Widget>[
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle,
            title: "Muamala Mpya",
            color: AppColors.success,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final BuildContext context) => const TransactionsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppStyles.spacingM),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.receipt_long,
            title: "Tengeneza Risiti",
            color: AppColors.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final BuildContext context) => const ReceiptScreen(),
                ),
              );
            },
          ),
        ),
      ],
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
          children: <Widget>[
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              title,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}