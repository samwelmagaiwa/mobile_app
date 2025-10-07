import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Transaction> _transactions = <Transaction>[];
  List<Transaction> _filteredTransactions = <Transaction>[];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'all';

  // Getters
  List<Transaction> get transactions => _transactions;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterType => _filterType;

  // Load transactions from API
  Future<void> loadTransactions() async {
    _setLoading(true);
    _clearError();

    try {
      final resp = await _api.getTransactions();
      final data = resp['data'];
      List list = <dynamic>[];
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'];
      }
      _transactions = list
          .map<Transaction>((final j) => Transaction.fromJson(j as Map<String, dynamic>))
          .toList();
      _applyFilters();
    } catch (e) {
      _setError('Failed to load transactions: $e');
      // Use mock data for development
      _loadMockTransactions();
    } finally {
      _setLoading(false);
    }
  }

  // Add new transaction
  Future<bool> addTransaction(final Transaction transaction) async {
    try {
      final resp = await _api.createTransaction(transaction.toJson());
      final createdJson = (resp['data'] ?? resp) as Map<String, dynamic>;
      final newTransaction = Transaction.fromJson(createdJson);
      _transactions.insert(0, newTransaction);
      _applyFilters();
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      // Add to local list for development
      _transactions.insert(0, transaction);
      _applyFilters();
      return false;
    }
  }

  // Update transaction
  Future<bool> updateTransaction(final Transaction transaction) async {
    try {
      final resp = await _api.updateTransaction(transaction.id, transaction.toJson());
      final updatedJson = (resp['data'] ?? resp) as Map<String, dynamic>;
      final updatedTransaction = Transaction.fromJson(updatedJson);
      final index = _transactions.indexWhere((final Transaction t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _applyFilters();
      }
      return true;
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(final String id) async {
    try {
      await _api.deleteTransaction(id);
      _transactions.removeWhere((final t) => t.id == id);
      _applyFilters();
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    }
  }

  // Filter transactions
  void filterTransactions(final String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Set filter type
  void setFilterType(final String type) {
    _filterType = type;
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    _filteredTransactions = _transactions.where((final transaction) {
      // Apply search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = transaction.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.category
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            transaction.amount.toString().contains(_searchQuery);
      }

      // Apply type filter
      bool matchesType = true;
      switch (_filterType) {
        case 'income':
          matchesType = transaction.type == TransactionType.income;
        case 'expense':
          matchesType = transaction.type == TransactionType.expense;
        case 'today':
          final today = DateTime.now();
          matchesType = transaction.createdAt.day == today.day &&
              transaction.createdAt.month == today.month &&
              transaction.createdAt.year == today.year;
        case 'week':
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          matchesType = transaction.createdAt.isAfter(weekStart);
        case 'month':
          final now = DateTime.now();
          matchesType = transaction.createdAt.month == now.month &&
              transaction.createdAt.year == now.year;
        default:
          matchesType = true;
      }

      return matchesSearch && matchesType;
    }).toList();

    // Sort by date (newest first)
    _filteredTransactions.sort((final Transaction a, final Transaction b) => b.createdAt.compareTo(a.createdAt));
    
    notifyListeners();
  }

  // Get revenue statistics
  Map<String, double> getRevenueStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);

    double todayRevenue = 0;
    double weekRevenue = 0;
    double monthRevenue = 0;
    double totalRevenue = 0;

    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.status == TransactionStatus.completed) {
        totalRevenue += transaction.amount.toDouble();

        if (transaction.createdAt.isAfter(today)) {
          todayRevenue += transaction.amount.toDouble();
        }

        if (transaction.createdAt.isAfter(weekStart)) {
          weekRevenue += transaction.amount.toDouble();
        }

        if (transaction.createdAt.isAfter(monthStart)) {
          monthRevenue += transaction.amount.toDouble();
        }
      }
    }

    return <String, double>{
      'today': todayRevenue.toDouble(),
      'week': weekRevenue.toDouble(),
      'month': monthRevenue.toDouble(),
      'total': totalRevenue.toDouble(),
    };
  }

  // Get recent transactions
  List<Transaction> getRecentTransactions(final int limit) {
    final sortedTransactions = List<Transaction>.from(_transactions);
    sortedTransactions.sort((final Transaction a, final Transaction b) => b.createdAt.compareTo(a.createdAt));
    return sortedTransactions.take(limit).toList();
  }

  // Get device revenue for today
  double getDeviceRevenueToday(final String deviceId) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return _transactions
        .where((final t) =>
            t.deviceId == deviceId &&
            t.type == TransactionType.income &&
            t.status == TransactionStatus.completed &&
            t.createdAt.isAfter(todayStart),)
        .fold(0.0, (final double sum, final t) => sum + t.amount.toDouble());
  }

  // Get transactions by date range
  List<Transaction> getTransactionsByDateRange(
      final DateTime startDate, final DateTime endDate,) => _transactions
        .where((final t) =>
            t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate),)
        .toList();

  // Get transactions by type
  List<Transaction> getTransactionsByType(final TransactionType type) => _transactions.where((final Transaction t) => t.type == type).toList();

  // Get transactions by status
  List<Transaction> getTransactionsByStatus(final TransactionStatus status) => _transactions.where((final Transaction t) => t.status == status).toList();

  // Get monthly revenue data for charts
  Map<String, double> getMonthlyRevenueData() {
    final monthlyData = <String, double>{};
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = '${month.month}/${month.year}';
      monthlyData[monthKey] = 0.0;
    }

    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income &&
          transaction.status == TransactionStatus.completed) {
        final monthKey =
            '${transaction.createdAt.month}/${transaction.createdAt.year}';
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = monthlyData[monthKey]! + transaction.amount.toDouble();
        }
      }
    }

    return monthlyData;
  }

  // Helper methods
  void _setLoading(final bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(final String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Load mock data for development
  void _loadMockTransactions() {
    final now = DateTime.now();
    _transactions = <Transaction>[
      Transaction(
        id: '1',
        amount: 5000,
        type: TransactionType.income,
        status: TransactionStatus.completed,
        description: 'Safari ya Kimbo',
        category: 'Abiria',
        deviceId: 'device1',
        driverId: 'driver1',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        customerName: 'John Doe',
      ),
      Transaction(
        id: '2',
        amount: 3000,
        type: TransactionType.income,
        status: TransactionStatus.completed,
        description: 'Safari ya Mwenge',
        category: 'Abiria',
        deviceId: 'device1',
        driverId: 'driver1',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        customerName: 'Jane Smith',
      ),
      Transaction(
        id: '3',
        amount: 15000,
        type: TransactionType.expense,
        status: TransactionStatus.completed,
        description: 'Mafuta',
        category: 'Matumizi',
        deviceId: 'device1',
        driverId: 'driver1',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      Transaction(
        id: '4',
        amount: 7500,
        type: TransactionType.income,
        status: TransactionStatus.completed,
        description: 'Safari ya Ubungo',
        category: 'Abiria',
        deviceId: 'device1',
        driverId: 'driver1',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        customerName: 'Peter Johnson',
      ),
    ];
    _applyFilters();
  }
}