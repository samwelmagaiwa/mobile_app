class DashboardReport {
  DashboardReport({
    required this.monthlyRevenue,
    required this.weeklyRevenue,
    required this.dailyRevenue,
    required this.netProfit,
    required this.activeDrivers,
    required this.totalDrivers,
    required this.activeVehicles,
    required this.totalVehicles,
    required this.pendingPayments,
    required this.recentTransactions,
  });

  factory DashboardReport.fromApi(Map<String, dynamic> response) {
    final Map<String, dynamic> data = response['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;

    num toNum(v) => v is num ? v : (v is String ? num.tryParse(v) ?? 0 : 0);
    int toInt(v) => v is int
        ? v
        : (v is String ? int.tryParse(v) ?? 0 : (v is num ? v.toInt() : 0));

    return DashboardReport(
      monthlyRevenue: toNum(data['monthly_revenue'] ?? 0).toDouble(),
      weeklyRevenue: toNum(data['weekly_revenue'] ?? 0).toDouble(),
      dailyRevenue: toNum(data['daily_revenue'] ?? 0).toDouble(),
      netProfit: toNum(data['net_profit'] ?? 0).toDouble(),
      activeDrivers: toInt(data['active_drivers'] ?? 0),
      totalDrivers: toInt(data['total_drivers'] ?? 0),
      activeVehicles: toInt(data['active_vehicles'] ?? 0),
      totalVehicles: toInt(data['total_vehicles'] ?? 0),
      pendingPayments: toInt(data['pending_payments'] ?? 0),
      recentTransactions: (data['recent_transactions'] is List)
          ? List<Map<String, dynamic>>.from(
              (data['recent_transactions'] as List)
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from),
            )
          : <Map<String, dynamic>>[],
    );
  }

  final double monthlyRevenue;
  final double weeklyRevenue;
  final double dailyRevenue;
  final double netProfit;
  final int activeDrivers;
  final int totalDrivers;
  final int activeVehicles;
  final int totalVehicles;
  final int pendingPayments;
  final List<Map<String, dynamic>> recentTransactions;
}
