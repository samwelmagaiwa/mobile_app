import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/inv_product.dart';

class InventoryProvider extends ChangeNotifier {
  // In-memory mock data for MVP
  final List<InvProduct> _products = List.generate(
    12,
    (i) => InvProduct(
      id: i + 1,
      name: 'Product ${i + 1}',
      sku: 'SKU00${i + 1}',
      category: 'General',
      costPrice: 3000 + i * 100,
      sellingPrice: 5000 + i * 150,
      unit: 'pcs',
      quantity: 25 - i,
      minStock: 8,
      status: 'active',
      barcode: '0000${i + 1}',
      createdBy: 1,
    ),
  );

  List<InvProduct> get products => List.unmodifiable(_products);

  List<InvProduct> get lowStockTop5 => _products
      .where((p) => p.quantity < p.minStock)
      .toList()
      ..sort((a, b) => (a.quantity - a.minStock).compareTo(b.quantity - b.minStock))
      ..take(5);

  // Sales KPIs (mock)
  double get totalSalesToday => 125000;
  String get totalSalesTodayFormatted => 'TZS ${totalSalesToday.toStringAsFixed(0)}';
  double get profitToday => 38000;
  String get profitTodayFormatted => 'TZS ${profitToday.toStringAsFixed(0)}';
  String get profitWeekFormatted => 'TZS 210,000';
  String get profitMonthFormatted => 'TZS 920,000';

  // Trend (mock)
  List<FlSpot> get salesTrend => List.generate(12, (i) => FlSpot(i.toDouble(), (i * 2 + (i % 3 == 0 ? 3 : 0)).toDouble()));

  void bootstrap() {
    // Placeholder for loading from API/storage later
  }

  // Basic stock operations (no negative stock)
  bool stockIn(int productId, int qty) {
    final p = _products.firstWhere((e) => e.id == productId);
    p.quantity += qty;
    notifyListeners();
    return true;
  }

  bool stockOut(int productId, int qty) {
    final p = _products.firstWhere((e) => e.id == productId);
    if (p.quantity - qty < 0) return false;
    p.quantity -= qty;
    notifyListeners();
    return true;
  }
}
