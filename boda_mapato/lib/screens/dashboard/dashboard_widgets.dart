import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/styles.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../models/transaction.dart';
import '../../models/device.dart';
import '../../utils/date_utils.dart';

class RevenueCardsSection extends StatelessWidget {
  const RevenueCardsSection({super.key});

  @override
  Widget build(final BuildContext context) => Consumer<TransactionProvider>(
      builder: (final BuildContext context, final TransactionProvider transactionProvider, final Widget? child) {
        var Map<String, double> stats = transactionProvider.getRevenueStats();
        
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _RevenueCard(
                    title: AppStrings.todayRevenue,
                    amount: stats["today"] ?? 0.0,
                    icon: Icons.today,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _RevenueCard(
                    title: AppStrings.weeklyRevenue,
                    amount: stats["week"] ?? 0.0,
                    icon: Icons.date_range,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            Row(
              children: <Widget>[
                Expanded(
                  child: _RevenueCard(
                    title: AppStrings.monthlyRevenue,
                    amount: stats["month"] ?? 0.0,
                    icon: Icons.calendar_month,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingM),
                Expanded(
                  child: _RevenueCard(
                    title: AppStrings.totalRevenue,
                    amount: stats["total"] ?? 0.0,
                    icon: Icons.account_balance_wallet,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
}

class _RevenueCard extends StatelessWidget {

  const _RevenueCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(final BuildContext context) => CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              "TSh ${amount.toStringAsFixed(0)}",
              style: AppStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
}

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  @override
  Widget build(final BuildContext context) => Consumer<TransactionProvider>(
      builder: (final BuildContext context, final TransactionProvider transactionProvider, final Widget? child) {
        var List<Transaction> recentTransactions = transactionProvider.getRecentTransactions(5);
        
        if (recentTransactions.isEmpty) {
          return CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  Text(
                    "Hakuna miamala ya hivi karibuni",
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return CustomCard(
          child: Column(
            children: recentTransactions
                .map((final Transaction transaction) => TransactionTile(
                      transaction: transaction,
                      showDate: true,
                    ),)
                .toList(),
          ),
        );
      },
    );
}

class DeviceStatusSection extends StatelessWidget {
  const DeviceStatusSection({super.key});

  @override
  Widget build(final BuildContext context) => Consumer<DeviceProvider>(
      builder: (final BuildContext context, final DeviceProvider deviceProvider, final Widget? final child) {
        var List<Device> devices = deviceProvider.devices;
        
        if (devices.isEmpty) {
          return CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.directions_car,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppStyles.spacingM),
                  Text(
                    "Hakuna vyombo vilivyosajiliwa",
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return CustomCard(
          child: Column(
            children: devices
                .take(3)
                .map((final Device device) => _DeviceStatusTile(device: device))
                .toList(),
          ),
        );
      },
    );
}

class _DeviceStatusTile extends StatelessWidget {

  const _DeviceStatusTile({required this.device});
  final Device device;

  @override
  Widget build(final BuildContext context) => Consumer<TransactionProvider>(
      builder: (final BuildContext final context, TransactionProvider final transactionProvider, final Widget? child) {
        var todayRevenue = transactionProvider.getDeviceRevenueToday(device.id);
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getDeviceColor(device.type),
            child: Text(
              device.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            device.name,
            style: AppStyles.bodyMedium,
          ),
          subtitle: Text(
            "${device.plateNumber} • ${device.type.name}",
            style: AppStyles.bodySmall,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                "TSh ${todayRevenue.toStringAsFixed(0)}",
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                "Leo",
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );

  Color _getDeviceColor(final DeviceType type) {
    switch (type) {
      case DeviceType.bajaji:
        return AppColors.bajaji;
      case DeviceType.pikipiki:
        return AppColors.pikipiki;
      case DeviceType.gari:
        return AppColors.gari;
    }
  }
}