class RevenueReport {
  RevenueReport({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.transactionCount,
    required this.averagePerDay,
  });

  factory RevenueReport.fromApi(Map<String, dynamic> response) {
    final Map<String, dynamic> data = response['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;

    num toNum(v) => v is num ? v : (v is String ? num.tryParse(v) ?? 0 : 0);
    int toInt(v) => v is int
        ? v
        : (v is String ? int.tryParse(v) ?? 0 : (v is num ? v.toInt() : 0));

    return RevenueReport(
      totalRevenue: toNum(data['total_revenue'] ?? 0).toDouble(),
      totalExpenses: toNum(data['total_expenses'] ?? 0).toDouble(),
      transactionCount: toInt(data['transaction_count'] ?? 0),
      averagePerDay: toNum(data['average_per_day'] ?? 0).toDouble(),
    );
  }

  final double totalRevenue;
  final double totalExpenses;
  final int transactionCount;
  final double averagePerDay;
}
