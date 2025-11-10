// ignore_for_file: cascade_invocations
import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../models/inv_category.dart';
import '../models/inv_customer.dart';
import '../models/inv_product.dart';
import '../models/inv_reminder.dart';
import '../models/inv_sale.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  // Enable mock data fallback for UI development (no backend needed)
  final bool _mockEnabled = true;
  final Random _rng = Random(42);

  // Data
  final List<InvProduct> _products = <InvProduct>[];
  final List<InvCustomer> _customers = <InvCustomer>[];
  final List<InvSale> _sales = <InvSale>[];
  final List<InvReminder> _reminders = <InvReminder>[];
  final List<InvCategory> _categories = <InvCategory>[];

  // POS cart state
  final List<InvSaleItem> _cart = <InvSaleItem>[];
  String _paymentMode = 'cash'; // cash | debt | partial
  int? _selectedCustomerId;
  double _paidAmount = 0;

  // Accessors
  List<InvProduct> get products => List.unmodifiable(_products);
  List<InvCustomer> get customers => List.unmodifiable(_customers);
  List<InvSale> get sales => List.unmodifiable(_sales);
  List<InvReminder> get reminders => List.unmodifiable(_reminders);
  List<InvCategory> get categories => List.unmodifiable(_categories);
  List<InvSaleItem> get cart => List.unmodifiable(_cart);
  String get paymentMode => _paymentMode;
  int? get selectedCustomerId => _selectedCustomerId;
  double get paidAmount => _paidAmount;

  double get cartSubtotal => _cart.fold(0, (sum, it) => sum + it.total);
  double get cartDiscount => 0; // MVP
  double get cartTax => 0; // MVP
  double get cartTotal => cartSubtotal - cartDiscount + cartTax;
  double get cartProfit => _cart.fold(0, (sum, it) => sum + it.profit);

  List<InvProduct> get lowStockTop5 {
    final list = _products.where((p) => p.quantity < p.minStock).toList()
      ..sort((a, b) =>
          (a.quantity - a.minStock).compareTo(b.quantity - b.minStock));
    return list.take(5).toList();
  }

  // Sales KPIs (mock/derived)
  double get totalSalesToday => _sales.where((s) {
        final now = DateTime.now();
        return s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day;
      }).fold<double>(0, (sum, s) => sum + s.total);
  String get totalSalesTodayFormatted =>
      'TZS ${totalSalesToday.toStringAsFixed(0)}';
  double get profitToday => _sales.fold<double>(0, (sum, s) => sum + s.profit);
  String get profitTodayFormatted => 'TZS ${profitToday.toStringAsFixed(0)}';
  String get profitWeekFormatted => 'TZS 210,000';
  String get profitMonthFormatted => 'TZS 920,000';

  // Trend (derived): last 12 days totals (fallbacks to mock if no data)
  List<FlSpot> get salesTrend {
    final now = DateTime.now();
    final Map<int, double> dayTotals = {};
    for (int i = 11; i >= 0; i--) {
      final d =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = d.millisecondsSinceEpoch;
      dayTotals[key] = 0;
    }
    for (final s in _sales) {
      final d = DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day)
          .millisecondsSinceEpoch;
      if (dayTotals.containsKey(d)) {
        dayTotals[d] = (dayTotals[d] ?? 0) + s.total;
      }
    }
    final bool empty = _sales.isEmpty;
    int x = 0;
    final List<FlSpot> spots = <FlSpot>[];
    for (final v in dayTotals.values) {
      final double y = (v as num).toDouble();
      spots
          .add(FlSpot(x.toDouble(), empty ? (2000 + (x * 700)).toDouble() : y));
      x++;
    }
    return spots;
  }

  // Build a secondary series from a base for mock dual-line chart
  List<FlSpot> _seriesFromBase(List<FlSpot> base,
          {double factor = 0.8, double offset = 1200}) =>
      base.map((e) => FlSpot(e.x, (e.y * factor) + offset)).toList();

  // Weekly trend: last 12 weeks
  List<FlSpot> get salesTrendWeekly {
    final now = DateTime.now();
    final DateTime mondayThisWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final List<DateTime> weeks = List<DateTime>.generate(
        12, (i) => mondayThisWeek.subtract(Duration(days: (11 - i) * 7)));
    final Map<int, double> totals = {
      for (final d in weeks) d.millisecondsSinceEpoch: 0
    };
    for (final s in _sales) {
      final d = s.createdAt;
      final DateTime monday = d.subtract(Duration(days: d.weekday - 1));
      final key = DateTime(monday.year, monday.month, monday.day)
          .millisecondsSinceEpoch;
      if (totals.containsKey(key)) totals[key] = (totals[key] ?? 0) + s.total;
    }
    final bool empty = _sales.isEmpty;
    int x = 0;
    final List<FlSpot> spots = [];
    for (final v in totals.values) {
      final double y = (v as num).toDouble();
      spots.add(FlSpot(x.toDouble(), empty ? (5000 + x * 1500).toDouble() : y));
      x++;
    }
    return spots;
  }

  // Monthly trend: last 12 months
  List<FlSpot> get salesTrendMonthly {
    final now = DateTime.now();
    final List<DateTime> months = List<DateTime>.generate(12, (i) {
      final DateTime d = DateTime(now.year, now.month - (11 - i));
      return DateTime(d.year, d.month);
    });
    final Map<int, double> totals = {
      for (final d in months) d.millisecondsSinceEpoch: 0
    };
    for (final s in _sales) {
      final DateTime m = DateTime(s.createdAt.year, s.createdAt.month);
      final key = m.millisecondsSinceEpoch;
      if (totals.containsKey(key)) totals[key] = (totals[key] ?? 0) + s.total;
    }
    final bool empty = _sales.isEmpty;
    int x = 0;
    final List<FlSpot> spots = [];
    for (final v in totals.values) {
      final double y = (v as num).toDouble();
      spots
          .add(FlSpot(x.toDouble(), empty ? (12000 + x * 2500).toDouble() : y));
      x++;
    }
    return spots;
  }

  int get lowStockCount =>
      _products.where((p) => p.quantity < p.minStock).length;

  // Dual-series for chart (mocked from base series)
  List<FlSpot> get onlineTrendDaily =>
      _seriesFromBase(salesTrend, factor: 1.1, offset: 800);
  List<FlSpot> get posTrendDaily =>
      _seriesFromBase(salesTrend, factor: 0.9, offset: 500);
  List<FlSpot> get onlineTrendWeekly =>
      _seriesFromBase(salesTrendWeekly, factor: 1.05);
  List<FlSpot> get posTrendWeekly =>
      _seriesFromBase(salesTrendWeekly, factor: 0.85, offset: 900);
  List<FlSpot> get onlineTrendMonthly =>
      _seriesFromBase(salesTrendMonthly, factor: 1.08, offset: 2500);
  List<FlSpot> get posTrendMonthly =>
      _seriesFromBase(salesTrendMonthly, factor: 0.88, offset: 1800);

  String get topSellingProductName {
    final Map<int, double> totals = <int, double>{};
    for (final s in _sales) {
      for (final it in s.items) {
        totals[it.productId] = (totals[it.productId] ?? 0) + it.qty.toDouble();
      }
    }
    if (totals.isEmpty) {
      return _products.isNotEmpty ? _products.first.name : '—';
    }
    int bestId = totals.keys.first;
    double best = totals[bestId] ?? 0;
    totals.forEach((id, v) {
      if (v > best) {
        best = v;
        bestId = id;
      }
    });
    final p = _products.firstWhere((e) => e.id == bestId,
        orElse: () => _products.isNotEmpty
            ? _products.first
            : InvProduct(
                id: 0,
                name: '—',
                sku: '',
                category: '',
                costPrice: 0,
                sellingPrice: 0,
                unit: 'pcs',
                quantity: 0,
                minStock: 0,
                status: 'active',
                barcode: '',
                createdBy: 0));
    return p.name;
  }

  Future<void> bootstrap() async {
    await Future.wait([
      fetchProducts(),
      fetchCustomers(),
      fetchSales(),
      fetchCategories(),
    ]);
    if (_mockEnabled) {
      if (_products.isEmpty) _seedMockProducts();
      if (_customers.isEmpty) _seedMockCustomers();
      if (_sales.isEmpty) _seedMockSales();
      if (_categories.isEmpty) _seedMockCategories();
    }
    _recomputeCategoryProductTotals();
    _refreshLowStockReminders();
    _refreshPaymentDueReminders();
    notifyListeners();
  }

  // Stock operations (call backend, then refresh)
  Future<bool> stockIn(int productId, int qty, {String? reference}) async {
    try {
      await _api.post('/stock-movements', {
        'product_id': productId,
        'type': 'in',
        'quantity': qty,
        if (reference != null) 'reference': reference,
      });
      await fetchProducts();
      _refreshLowStockReminders();
      return true;
    } on Exception {
      // Mock fallback: update local product quantity
      final int idx = _products.indexWhere((p) => p.id == productId);
      if (!_mockEnabled || idx == -1) return false;
      _products[idx].quantity += qty.abs();
      _refreshLowStockReminders();
      notifyListeners();
      return true;
    }
  }

  Future<bool> stockOut(int productId, int qty, {String? reference}) async {
    try {
      await _api.post('/stock-movements', {
        'product_id': productId,
        'type': 'out',
        'quantity': qty,
        if (reference != null) 'reference': reference,
      });
      await fetchProducts();
      _refreshLowStockReminders();
      return true;
    } on Exception {
      // Mock fallback: decrease local product quantity (no negatives)
      final int idx = _products.indexWhere((p) => p.id == productId);
      if (!_mockEnabled || idx == -1) return false;
      if (_products[idx].quantity - qty.abs() < 0) return false;
      _products[idx].quantity -= qty.abs();
      _refreshLowStockReminders();
      notifyListeners();
      return true;
    }
  }

  // POS: cart operations
  Future<void> fetchProducts(
      {int page = 1, String? q, String? status, bool? lowStock}) async {
    final List<String> endpoints = [
      '/inventory/products',
      '/products',
    ];
    for (final e in endpoints) {
      try {
        final res = await _api.getOrNull(
            '$e?page=$page${q != null ? '&q=$q' : ''}${status != null ? '&status=$status' : ''}${(lowStock ?? false) ? '&low_stock=1' : ''}');
        if (res == null) continue;
        final List<dynamic> list = (res['data'] is List)
            ? List<dynamic>.from(res['data'] as List)
            : (res['products'] is List)
                ? List<dynamic>.from(res['products'] as List)
                : (res is List)
                    ? List<dynamic>.from(res as List)
                    : <dynamic>[];
        _products
          ..clear()
          ..addAll(
              list.map((j) => _fromProductJson(j as Map<String, dynamic>)));
        notifyListeners();
        return;
      } on Exception {
        // try next endpoint, then fall back to mock below
      }
    }
    if (_mockEnabled && _products.isEmpty) {
      _seedMockProducts();
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    required String name,
    required String sku,
    required double costPrice,
    required double sellingPrice,
    required int quantity,
    required int minStock,
    String? category,
    String unit = 'pcs',
    String status = 'active',
    String? barcode,
  }) async {
    try {
      await _api.post('/inventory/products', {
        'name': name,
        'sku': sku,
        'category': category,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'unit': unit,
        'quantity': quantity,
        'min_stock': minStock,
        'status': status,
        'barcode': barcode,
      });
      await fetchProducts();
      _refreshLowStockReminders();
      return true;
    } on Exception {
      if (!_mockEnabled) return false;
      final int id = _nextProductId();
      _products.add(InvProduct(
        id: id,
        name: name,
        sku: sku,
        category: category ?? '',
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        unit: unit,
        quantity: quantity,
        minStock: minStock,
        status: status,
        barcode: barcode ?? '',
        createdBy: 1,
      ));
      _refreshLowStockReminders();
      notifyListeners();
      return true;
    }
  }

  Future<void> fetchCustomers({String? q}) async {
    final List<String> endpoints = [
      '/inventory/customers',
      '/customers',
    ];
    for (final e in endpoints) {
      try {
        final res = await _api.getOrNull('$e${q != null ? '?q=$q' : ''}');
        if (res == null) continue;
        final List<dynamic> list = (res['data'] is List)
            ? List<dynamic>.from(res['data'] as List)
            : (res['customers'] is List)
                ? List<dynamic>.from(res['customers'] as List)
                : (res is List)
                    ? List<dynamic>.from(res as List)
                    : <dynamic>[];
        _customers
          ..clear()
          ..addAll(
              list.map((j) => _fromCustomerJson(j as Map<String, dynamic>)));
        notifyListeners();
        return;
      } on Exception {
        // try next endpoint, then fall back to mock below
      }
    }
    if (_mockEnabled && _customers.isEmpty) {
      _seedMockCustomers();
      notifyListeners();
    }
  }

  Future<void> fetchSales(
      {String? status, DateTime? from, DateTime? to}) async {
    final params = <String, String>{
      if (status != null && status != 'all') 'status': status,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final List<String> endpoints = [
      '/inventory/sales',
      '/sales',
    ];
    for (final e in endpoints) {
      try {
        final res = await _api.getOrNull(qs.isNotEmpty ? '$e?$qs' : e);
        if (res == null) continue;
        final List<dynamic> list = (res['data'] is List)
            ? List<dynamic>.from(res['data'] as List)
            : (res['sales'] is List)
                ? List<dynamic>.from(res['sales'] as List)
                : (res is List)
                    ? List<dynamic>.from(res as List)
                    : <dynamic>[];
        _sales
          ..clear()
          ..addAll(list.map((j) => _fromSaleJson(j as Map<String, dynamic>)));
        notifyListeners();
        return;
      } on Exception {
        // try next endpoint, then fall back to mock below
      }
    }
    if (_mockEnabled && _sales.isEmpty) {
      _seedMockSales();
      _refreshLowStockReminders();
      _refreshPaymentDueReminders();
      notifyListeners();
    }
  }

  Future<int?> createCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      final res = await _api.post('/inventory/customers', {
        'name': name,
        'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      });
      await fetchCustomers();
      final int? id = (res['data'] is Map<String, dynamic>)
          ? (res['data'] as Map<String, dynamic>)['id'] as int?
          : null;
      return id;
    } on Exception {
      if (!_mockEnabled) return null;
      final int id = _nextCustomerId();
      _customers.add(InvCustomer(id: id, name: name, phone: phone));
      notifyListeners();
      return id;
    }
  }

  Future<void> fetchReminders({String? type, String? status}) async {
    final params = <String, String>{
      if (type != null) 'type': type,
      if (status != null) 'status': status,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    try {
      final res = await _api.getOrNull(
          qs.isNotEmpty ? '/inventory/reminders?$qs' : '/inventory/reminders');
      if (res == null) {
        if (_mockEnabled) {
          _reminders.clear();
          _refreshLowStockReminders();
          _refreshPaymentDueReminders();
          notifyListeners();
        }
        return;
      }
      final List<dynamic> list = (res['data'] is List)
          ? List<dynamic>.from(res['data'] as List)
          : (res is List)
              ? List<dynamic>.from(res as List)
              : <dynamic>[];
      _reminders
        ..clear()
        ..addAll(list.map((j) => _fromReminderJson(j as Map<String, dynamic>)));
      notifyListeners();
    } on Exception {
      if (_mockEnabled) {
        // Rebuild local reminders from current products/sales
        _reminders.clear();
        _refreshLowStockReminders();
        _refreshPaymentDueReminders();
        notifyListeners();
      }
    }
  }

  void addProductToCart(InvProduct product) {
    final idx = _cart.indexWhere((it) => it.productId == product.id);
    if (idx >= 0) {
      _cart[idx].qty += 1;
    } else {
      _cart.add(InvSaleItem(
        productId: product.id,
        name: product.name,
        qty: 1,
        unitPrice: product.sellingPrice,
        unitCostSnapshot: product.costPrice,
      ));
    }
    notifyListeners();
  }

  void setCartQty(int productId, int qty) {
    final it = _cart.firstWhere((e) => e.productId == productId);
    it.qty = qty < 1 ? 1 : qty;
    notifyListeners();
  }

  void setCartUnitPrice(int productId, double price) {
    final it = _cart.firstWhere((e) => e.productId == productId);
    it.unitPrice = price < 0 ? 0 : price;
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  void setPaymentMode(String mode) {
    _paymentMode = mode; // cash | debt | partial
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  // Checkout with business rules
  // Returns (success, message)
  Future<(bool, String)> checkout({required int createdBy}) async {
    if (_cart.isEmpty) return (false, 'Cart is empty');

    if ((_paymentMode == 'debt' || _paymentMode == 'partial') &&
        _selectedCustomerId == null) {
      return (false, 'customer_required');
    }

    final subtotal = cartSubtotal;
    final total = cartTotal;
    double paidTotal = 0;
    String status = 'paid';
    List<Map<String, dynamic>> payments = [];

    if (_paymentMode == 'cash') {
      paidTotal = total;
      payments = [
        {
          'amount': total,
          'method': 'cash',
          'reference': null,
          'paid_at': DateTime.now().toIso8601String(),
        }
      ];
      status = 'paid';
    } else if (_paymentMode == 'partial') {
      paidTotal = _paidAmount.clamp(0, total);
      status =
          paidTotal <= 0 ? 'debt' : (paidTotal < total ? 'partial' : 'paid');
      if (paidTotal > 0) {
        payments = [
          {
            'amount': paidTotal,
            'method': 'cash',
            'reference': null,
            'paid_at': DateTime.now().toIso8601String(),
          }
        ];
      }
    } else if (_paymentMode == 'debt') {
      status = 'debt';
      paidTotal = 0;
    }

    final payload = {
      'customer_id': _selectedCustomerId,
      'payment_status': status,
      'subtotal': subtotal,
      'discount': cartDiscount,
      'tax': cartTax,
      'total': total,
      'paid_total': paidTotal,
      'due_date': status == 'paid'
          ? null
          : DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'items': _cart
          .map((e) => {
                'product_id': e.productId,
                'quantity': e.qty,
                'unit_price': e.unitPrice,
                'unit_cost_snapshot': e.unitCostSnapshot,
              })
          .toList(),
      if (payments.isNotEmpty) 'payments': payments,
    };

    try {
      // Try /inventory/sales then /sales
      try {
        await _api.post('/inventory/sales', payload);
      } on Exception {
        await _api.post('/sales', payload);
      }

      await Future.wait([
        fetchSales(),
        fetchProducts(),
        fetchReminders(),
      ]);
      // Regenerate local low-stock to complement server-side payment_due reminders
      _refreshLowStockReminders();

      _cart.clear();
      _paymentMode = 'cash';
      _selectedCustomerId = null;
      _paidAmount = 0;
      notifyListeners();
      return (true, 'success');
    } on Exception catch (_) {
      if (!_mockEnabled) return (false, 'checkout_failed');
      // Local mock checkout: create sale, update stocks, generate reminders
      final newId = _nextSaleId();
      final number = _mockSaleNumber(newId);
      final due =
          status == 'paid' ? null : DateTime.now().add(const Duration(days: 7));
      final items = _cart
          .map((e) => InvSaleItem(
                productId: e.productId,
                name: e.name,
                qty: e.qty,
                unitPrice: e.unitPrice,
                unitCostSnapshot: e.unitCostSnapshot,
              ))
          .toList();
      // Update stocks (prevent negative)
      for (final it in items) {
        final idx = _products.indexWhere((p) => p.id == it.productId);
        if (idx != -1) {
          final newQty = _products[idx].quantity - it.qty;
          _products[idx].quantity = newQty < 0 ? 0 : newQty;
        }
      }
      _sales.add(InvSale(
        id: newId,
        number: number,
        customerId: _selectedCustomerId,
        paymentStatus: status,
        items: items,
        subtotal: subtotal,
        discount: cartDiscount,
        tax: cartTax,
        total: total,
        paidTotal: paidTotal,
        dueDate: due,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      ));
      _refreshLowStockReminders();
      _refreshPaymentDueReminders();
      _cart.clear();
      _paymentMode = 'cash';
      _selectedCustomerId = null;
      _paidAmount = 0;
      notifyListeners();
      return (true, 'success');
    }
  }

  void _refreshLowStockReminders() {
    // Remove existing low_stock reminders and regenerate
    _reminders.removeWhere((r) => r.type == 'low_stock');
    int id = _reminders.length + 1;
    for (final p in _products.where((p) => p.quantity < p.minStock)) {
      _reminders.add(InvReminder(
        id: id++,
        type: 'low_stock',
        title: 'Low Stock',
        description: '${p.name} is below minimum stock.',
        dueAt: DateTime.now(),
        relatedId: p.id,
      ));
    }
  }

  void _refreshPaymentDueReminders() {
    _reminders.removeWhere((r) => r.type == 'payment_due');
    int id =
        _reminders.isEmpty ? 1 : (_reminders.map((e) => e.id).reduce(max) + 1);
    for (final s in _sales.where((s) => s.paymentStatus != 'paid')) {
      _reminders.add(InvReminder(
        id: id++,
        type: 'payment_due',
        title: 'Payment Due',
        description: 'Sale #${s.number} has outstanding balance.',
        dueAt: s.dueDate ?? DateTime.now().add(const Duration(days: 3)),
        relatedId: s.id,
      ));
    }
  }

  Future<void> markReminderDone(int reminderId) async {
    try {
      await _api.put('/inventory/reminders/$reminderId/done', {});
      await fetchReminders();
    } on Exception {
      // fallback local change (no null gymnastics)
      final int idx = _reminders.indexWhere((e) => e.id == reminderId);
      if (idx != -1) {
        _reminders[idx].status = InvReminderStatus.done;
        notifyListeners();
      }
    }
  }

  Future<void> snoozeReminder(int reminderId, {int minutes = 60}) async {
    try {
      await _api
          .put('/inventory/reminders/$reminderId/snooze', {'minutes': minutes});
      await fetchReminders();
    } on Exception {
      final int idx = _reminders.indexWhere((e) => e.id == reminderId);
      if (idx != -1) {
        _reminders[idx].status = InvReminderStatus.snoozed;
        _reminders[idx].snoozeUntil =
            DateTime.now().add(Duration(minutes: minutes));
        notifyListeners();
      }
    }
  }

  // Mock seeding helpers
  void _seedMockProducts() {
    if (_products.isNotEmpty) return;
    final data = <InvProduct>[
      InvProduct(
          id: 1,
          name: 'Dog Kibble 2.5KG',
          sku: 'DK-25',
          category: 'Food & treats',
          costPrice: 18000,
          sellingPrice: 25000,
          unit: 'kg',
          quantity: 12,
          minStock: 5,
          status: 'active',
          barcode: '000111222333',
          createdBy: 1),
      InvProduct(
          id: 2,
          name: 'Wet Food Can 400g',
          sku: 'WF-400',
          category: 'Food & treats',
          costPrice: 3200,
          sellingPrice: 5000,
          unit: 'pcs',
          quantity: 60,
          minStock: 20,
          status: 'active',
          barcode: '000111222334',
          createdBy: 1),
      InvProduct(
          id: 3,
          name: 'Grooming Brush',
          sku: 'GR-BR',
          category: 'Grooming',
          costPrice: 7000,
          sellingPrice: 12000,
          unit: 'pcs',
          quantity: 8,
          minStock: 10,
          status: 'active',
          barcode: '000111222335',
          createdBy: 1),
      InvProduct(
          id: 4,
          name: 'Cat Litter 10KG',
          sku: 'CL-10',
          category: 'Hygiene',
          costPrice: 19000,
          sellingPrice: 28000,
          unit: 'kg',
          quantity: 14,
          minStock: 6,
          status: 'active',
          barcode: '000111222336',
          createdBy: 1),
      InvProduct(
          id: 5,
          name: 'Leash & Collar Set',
          sku: 'LC-SET',
          category: 'Toys collar & Leads',
          costPrice: 8000,
          sellingPrice: 15000,
          unit: 'pcs',
          quantity: 5,
          minStock: 6,
          status: 'active',
          barcode: '000111222337',
          createdBy: 1),
      InvProduct(
          id: 6,
          name: 'Pet Shampoo 500ml',
          sku: 'PS-500',
          category: 'Grooming',
          costPrice: 6000,
          sellingPrice: 10000,
          unit: 'litre',
          quantity: 25,
          minStock: 10,
          status: 'active',
          barcode: '000111222338',
          createdBy: 1),
      InvProduct(
          id: 7,
          name: 'Chew Toy - Bone',
          sku: 'CT-BONE',
          category: 'Toys',
          costPrice: 2000,
          sellingPrice: 4500,
          unit: 'pcs',
          quantity: 35,
          minStock: 10,
          status: 'active',
          barcode: '000111222339',
          createdBy: 1),
      InvProduct(
          id: 8,
          name: 'Dental Treats (Box)',
          sku: 'DT-BOX',
          category: 'Food & treats',
          costPrice: 15000,
          sellingPrice: 22000,
          unit: 'box',
          quantity: 9,
          minStock: 8,
          status: 'active',
          barcode: '000111222340',
          createdBy: 1),
      InvProduct(
          id: 9,
          name: 'Catnip 50g',
          sku: 'CN-50',
          category: 'Toys',
          costPrice: 2500,
          sellingPrice: 4000,
          unit: 'pcs',
          quantity: 16,
          minStock: 5,
          status: 'active',
          barcode: '000111222341',
          createdBy: 1),
      InvProduct(
          id: 10,
          name: 'Dog Jacket - M',
          sku: 'DJ-M',
          category: 'Feeding & clothing',
          costPrice: 22000,
          sellingPrice: 35000,
          unit: 'pcs',
          quantity: 3,
          minStock: 5,
          status: 'active',
          barcode: '000111222342',
          createdBy: 1),
      InvProduct(
          id: 11,
          name: 'Stainless Bowl 1L',
          sku: 'SB-1L',
          category: 'Feeding & clothing',
          costPrice: 5000,
          sellingPrice: 9000,
          unit: 'pcs',
          quantity: 22,
          minStock: 8,
          status: 'active',
          barcode: '000111222343',
          createdBy: 1),
      InvProduct(
          id: 12,
          name: 'Fish Snacks 100g',
          sku: 'FS-100',
          category: 'Treats',
          costPrice: 1500,
          sellingPrice: 3000,
          unit: 'pcs',
          quantity: 0,
          minStock: 10,
          status: 'active',
          barcode: '000111222344',
          createdBy: 1),
    ];
    _products
      ..clear()
      ..addAll(data);
  }

  void _seedMockCustomers() {
    if (_customers.isNotEmpty) return;
    _customers
      ..clear()
      ..addAll([
        InvCustomer(id: 1, name: 'John Doe', phone: '+255700111222'),
        InvCustomer(id: 2, name: 'Jane Smith', phone: '+255710333444'),
        InvCustomer(id: 3, name: 'Pet Palace Ltd', phone: '+255784555666'),
        InvCustomer(id: 4, name: 'Happy Tails', phone: '+255713777888'),
      ]);
  }

  void _seedMockSales() {
    if (_sales.isNotEmpty) return;
    if (_products.isEmpty) _seedMockProducts();
    if (_customers.isEmpty) _seedMockCustomers();
    final now = DateTime.now();
    final List<InvSale> seeded = [];
    int id = 1;
    for (int i = 0; i < 24; i++) {
      final date = now.subtract(Duration(days: _rng.nextInt(28)));
      final int itemsCount = 1 + _rng.nextInt(3);
      final items = <InvSaleItem>[];
      double subtotal = 0;
      for (int j = 0; j < itemsCount; j++) {
        final p = _products[_rng.nextInt(_products.length)];
        final qty = 1 + _rng.nextInt(4);
        items.add(InvSaleItem(
            productId: p.id,
            name: p.name,
            qty: qty,
            unitPrice: p.sellingPrice,
            unitCostSnapshot: p.costPrice));
        subtotal += qty * p.sellingPrice;
      }
      const discount = 0.0;
      const tax = 0.0;
      final total = subtotal - discount + tax;
      final r = _rng.nextDouble();
      String status;
      double paid = 0;
      DateTime? due;
      if (r < 0.7) {
        status = 'paid';
        paid = total;
      } else if (r < 0.85) {
        status = 'partial';
        paid = total * 0.5;
        due = date.add(const Duration(days: 7));
      } else {
        status = 'debt';
        paid = 0;
        due = date.add(const Duration(days: 7));
      }
      seeded.add(InvSale(
        id: id,
        number: _mockSaleNumber(id),
        customerId: _customers[_rng.nextInt(_customers.length)].id,
        paymentStatus: status,
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paidTotal: paid,
        dueDate: due,
        createdBy: 1,
        createdAt: date,
      ));
      id++;
    }
    _sales
      ..clear()
      ..addAll(seeded);
  }

  String _mockSaleNumber(int id) {
    final d = DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'S-$y$m$day-$id';
  }

  int _nextProductId() =>
      _products.isEmpty ? 1 : (_products.map((p) => p.id).reduce(max) + 1);
  int _nextCustomerId() =>
      _customers.isEmpty ? 1 : (_customers.map((c) => c.id).reduce(max) + 1);
  int _nextSaleId() =>
      _sales.isEmpty ? 1 : (_sales.map((s) => s.id).reduce(max) + 1);
  int _nextCategoryId() =>
      _categories.isEmpty ? 1 : (_categories.map((c) => c.id).reduce(max) + 1);

  // Categories API + mock
  Future<void> fetchCategories({String? q, String? status}) async {
    final params = <String, String>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null && status.isNotEmpty && status != 'all')
        'status': status,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final List<String> endpoints = <String>[
      '/inventory/categories',
      '/categories',
    ];
    for (final e in endpoints) {
      try {
        final res = await _api.getOrNull(qs.isNotEmpty ? '$e?$qs' : e);
        if (res == null) continue;
        final List<dynamic> list = (res['data'] is List)
            ? List<dynamic>.from(res['data'] as List)
            : (res['categories'] is List)
                ? List<dynamic>.from(res['categories'] as List)
                : (res is List)
                    ? List<dynamic>.from(res as List)
                    : <dynamic>[];
        _categories
          ..clear()
          ..addAll(list.map((j) => _fromCategoryJson(j as Map<String, dynamic>)));
        _recomputeCategoryProductTotals();
        _ensureCategoryCodes();
        notifyListeners();
        return;
      } on Exception {
        // try next endpoint, then fall back to mock below
      }
    }
    if (_mockEnabled && _categories.isEmpty) {
      _seedMockCategories();
      _recomputeCategoryProductTotals();
      _ensureCategoryCodes();
      notifyListeners();
    }
  }

  Future<int?> createCategory({
    required String name,
    String code = '',
    String description = '',
    int? parentId,
    String? imagePath,
    String status = 'active',
    int createdBy = 1,
  }) async {
    final String newCode = code.isNotEmpty ? code : _genCategoryCode(name);
    final payload = {
      'name': name,
      'code': newCode,
      if (description.isNotEmpty) 'description': description,
      'parent_id': parentId,
      'status': status,
      if (imagePath != null) 'image': imagePath,
    };
    try {
      final res = await _api.post('/inventory/categories', payload);
      await fetchCategories();
      final int? id = (res['data'] is Map<String, dynamic>) ? (res['data'] as Map<String, dynamic>)['id'] as int? : null;
      return id;
    } on Exception {
      if (!_mockEnabled) return null;
      final id = _nextCategoryId();
      _categories.add(InvCategory(
        id: id,
        name: name,
        code: newCode,
        description: description,
        parentId: parentId,
        imagePath: imagePath,
        status: status,
        totalProducts: 0,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _recomputeCategoryProductTotals();
      _ensureCategoryCodes();
      notifyListeners();
      return id;
    }

  }

  Future<bool> updateCategory({
    required int id,
    String? name,
    String? code,
    String? description,
    int? parentId,
    String? imagePath,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      'parent_id': parentId,
      if (status != null) 'status': status,
      if (imagePath != null) 'image': imagePath,
    };
    try {
      await _api.put('/inventory/categories/$id', payload);
      await fetchCategories();
      return true;
    } on Exception {
      if (!_mockEnabled) return false;
      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx == -1) return false;
      final c = _categories[idx];
      _categories[idx] = c.copyWith(
        name: name ?? c.name,
        code: code ?? c.code,
        description: description ?? c.description,
        parentId: payload.containsKey('parent_id') ? parentId : c.parentId,
        imagePath: imagePath ?? c.imagePath,
        status: status ?? c.status,
        updatedAt: DateTime.now(),
      );
      _recomputeCategoryProductTotals();
      notifyListeners();
      return true;
    }
  }

  Future<void> toggleCategoryStatus(int id) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final newStatus =
        _categories[idx].status == 'active' ? 'inactive' : 'active';
    final ok = await updateCategory(id: id, status: newStatus);
    if (!ok && _mockEnabled) {
      // already toggled by updateCategory in mock path
    }
  }

  void _recomputeCategoryProductTotals() {
    // crude mapping by category name (since product has only name category)
    final Map<String, int> countByName = <String, int>{};
    for (final p in _products) {
      final key = p.category.trim();
      countByName[key] = (countByName[key] ?? 0) + 1;
    }
    for (int i = 0; i < _categories.length; i++) {
      final c = _categories[i];
      final count = countByName[c.name.trim()] ?? 0;
      _categories[i] = c.copyWith(totalProducts: count);
    }
  }

  void _seedMockCategories() {
    if (_categories.isNotEmpty) return;
    final now = DateTime.now();
    final data = <InvCategory>[
      InvCategory(
          id: 1,
          name: 'Food & treats',
          code: 'CAT001',
          description: 'Edibles and treats for pets',
          parentId: null,
          imagePath: null,
          status: 'active',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
      InvCategory(
          id: 2,
          name: 'Feeding & clothing',
          code: 'CAT002',
          description: 'Bowls, feeders and clothing',
          parentId: null,
          imagePath: null,
          status: 'active',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
      InvCategory(
          id: 3,
          name: 'Grooming',
          code: 'CAT003',
          description: 'Shampoos and grooming tools',
          parentId: null,
          imagePath: null,
          status: 'active',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
      InvCategory(
          id: 4,
          name: 'Toys collar & Leads',
          code: 'CAT004',
          description: 'Toys and accessories',
          parentId: null,
          imagePath: null,
          status: 'active',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
      InvCategory(
          id: 5,
          name: 'Hygiene',
          code: 'CAT005',
          description: 'Litter and hygiene',
          parentId: null,
          imagePath: null,
          status: 'inactive',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
      InvCategory(
          id: 6,
          name: 'Treats',
          code: 'CAT006',
          description: 'Snacks and rewards',
          parentId: 1,
          imagePath: null,
          status: 'active',
          totalProducts: 0,
          createdBy: 1,
          createdAt: now,
          updatedAt: now),
    ];
    _categories..clear()..addAll(data);
  }

  // Generate category code like ABC001 from name
  String _genCategoryCode(String name) {
    String prefix = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(3)
        .join()
        .toUpperCase();
    if (prefix.isEmpty) prefix = 'CAT';
    final int seq = (_categories.isEmpty ? 1 : (_categories.map((c) => c.id).fold<int>(0, (p, e) => e > p ? e : p) + 1));
    final String num = seq.toString().padLeft(3, '0');
    return '$prefix$num';
  }

  // Ensure every category has a code; auto-generate if missing
  void _ensureCategoryCodes() {
    final Set<String> used = _categories.map((c) => c.code).where((c) => c.isNotEmpty).toSet();
    for (int i = 0; i < _categories.length; i++) {
      final c = _categories[i];
      if (c.code.isEmpty) {
        String candidate = _genCategoryCode(c.name);
        int k = 1;
        while (used.contains(candidate)) {
          candidate = _genCategoryCode(c.name + k.toString());
          k++;
        }
        used.add(candidate);
        _categories[i] = c.copyWith(code: candidate);
      }
    }
  }
}

// JSON mappers (minimal, defensive)
InvProduct _fromProductJson(Map<String, dynamic> j) => InvProduct(
      id: (j['id'] ?? j['product_id']) as int,
      name: (j['name'] ?? j['product_name'] ?? '') as String,
      sku: (j['SKU'] ?? j['sku'] ?? j['code'] ?? '') as String,
      category: (j['category'] ?? '') as String,
      costPrice: ((j['cost_price'] ?? j['cost'] ?? 0) as num).toDouble(),
      sellingPrice: ((j['selling_price'] ?? j['price'] ?? 0) as num).toDouble(),
      unit: (j['unit'] ?? 'pcs') as String,
      quantity: (j['quantity'] ?? j['qty'] ?? 0) as int,
      minStock: (j['min_stock'] ?? j['min'] ?? 0) as int,
      status: (j['status'] ?? 'active') as String,
      barcode: (j['barcode'] ?? j['bar_code'] ?? '') as String,
      createdBy: (j['created_by'] ?? 0) as int,
    );

InvCustomer _fromCustomerJson(Map<String, dynamic> j) => InvCustomer(
      id: (j['id'] ?? j['customer_id']) as int,
      name: (j['name'] ?? j['customer_name'] ?? '') as String,
      phone: (j['phone'] ?? j['phone_number'] ?? '') as String,
    );

InvSale _fromSaleJson(Map<String, dynamic> j) {
  final items = (j['items'] is List)
      ? (j['items'] as List)
          .map((it) => it is Map<String, dynamic>
              ? InvSaleItem(
                  productId: (it['product_id'] ?? 0) as int,
                  name: (it['product_name'] ?? '') as String,
                  qty: (it['quantity'] ?? it['qty'] ?? 0) as int,
                  unitPrice: ((it['unit_price'] ?? 0) as num).toDouble(),
                  unitCostSnapshot: ((it['unit_cost_snapshot'] ??
                          it['unit_cost'] ??
                          0) as num)
                      .toDouble(),
                )
              : null)
          .whereType<InvSaleItem>()
          .toList()
      : <InvSaleItem>[];
  final double subtotal = ((j['subtotal'] ?? 0) as num).toDouble();
  final double total = ((j['total'] ?? 0) as num).toDouble();
  final double discount = ((j['discount'] ?? 0) as num).toDouble();
  final double tax = ((j['tax'] ?? 0) as num).toDouble();
  final double paidTotal = ((j['paid_total'] ?? 0) as num).toDouble();
  final createdAtStr = j['created_at']?.toString();
  final createdAt = createdAtStr != null
      ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
      : DateTime.now();
  return InvSale(
    id: (j['id'] ?? 0) as int,
    number: (j['number'] ?? j['sale_number'] ?? '') as String,
    customerId: j['customer_id'] as int?,
    paymentStatus: (j['payment_status'] ?? j['status'] ?? '') as String,
    items: items,
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: total,
    paidTotal: paidTotal,
    dueDate: j['due_date'] != null
        ? DateTime.tryParse(j['due_date'].toString())
        : null,
    createdBy: (j['created_by'] ?? 0) as int,
    createdAt: createdAt,
  );
}

InvReminder _fromReminderJson(Map<String, dynamic> j) {
  InvReminderStatus statusFrom(s) {
    final v = (s ?? 'open').toString();
    switch (v) {
      case 'done':
        return InvReminderStatus.done;
      case 'snoozed':
        return InvReminderStatus.snoozed;
      default:
        return InvReminderStatus.open;
    }
  }

  return InvReminder(
    id: (j['id'] ?? 0) as int,
    type: (j['type'] ?? 'payment_due') as String,
    title: (j['title'] ?? '') as String,
    description: (j['description'] ?? '') as String,
    dueAt: j['due_at'] != null
        ? (DateTime.tryParse(j['due_at'].toString()) ?? DateTime.now())
        : DateTime.now(),
    status: statusFrom(j['status']),
    snoozeUntil: j['snooze_until'] != null
        ? DateTime.tryParse(j['snooze_until'].toString())
        : null,
    relatedId: (j['related_id'] ?? j['sale_id'] ?? j['product_id']) as int?,
  );
}

InvCategory _fromCategoryJson(Map<String, dynamic> j) {
  final createdAtStr = j['created_at']?.toString();
  final updatedAtStr = j['updated_at']?.toString();
  final DateTime createdAt = createdAtStr != null
      ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
      : DateTime.now();
  final DateTime updatedAt = updatedAtStr != null
      ? (DateTime.tryParse(updatedAtStr) ?? createdAt)
      : createdAt;
  return InvCategory(
    id: (j['id'] ?? j['category_id'] ?? 0) as int,
    name: (j['name'] ?? j['category_name'] ?? '') as String,
    code: (j['code'] ?? j['category_code'] ?? '') as String,
    description: (j['description'] ?? '') as String,
    parentId: j['parent_id'] as int?,
    imagePath: (j['image'] ?? j['icon'] ?? j['image_url']) as String?,
    status: (j['status'] ?? 'active') as String,
    totalProducts: (j['total_products'] ?? 0) as int,
    createdBy: (j['created_by'] ?? 0) as int,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
