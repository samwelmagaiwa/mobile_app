import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RentalProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Dashboard
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> get dashboardData => _dashboardData;

  // Properties
  List<dynamic> _properties = [];
  List<dynamic> get properties => _properties;

  // Tenants
  List<dynamic> _tenants = [];
  List<dynamic> get tenants => _tenants;

  // Bills
  List<dynamic> _bills = [];
  List<dynamic> get bills => _bills;

  // Payments
  List<dynamic> _payments = [];
  List<dynamic> get payments => _payments;

  // Receipts
  List<dynamic> _receipts = [];
  List<dynamic> get receipts => _receipts;

  // Arrears
  List<dynamic> _arrears = [];
  List<dynamic> get arrears => _arrears;

  // Selected Property for details
  Map<String, dynamic>? _selectedProperty;
  Map<String, dynamic>? get selectedProperty => _selectedProperty;

  // Property Stats
  Map<String, dynamic>? _propertyStats;
  Map<String, dynamic>? get propertyStats => _propertyStats;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;

  // Last payment for showing receipt
  dynamic _lastPayment;
  dynamic get lastPayment => _lastPayment;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalDashboard();
      _dashboardData = response['data'] ?? {};
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProperties() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalProperties();
      _properties = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTenants() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalTenants();
      _tenants = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBills() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalBills();
      _bills = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching bills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalPayments();
      _payments = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReceipts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalReceipts();
      _receipts = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching receipts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArrears() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalArrears();
      _arrears = (response['data']?['arrears'] as List?) ?? [];
    } catch (e) {
      debugPrint('Error fetching arrears: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> onboardTenant(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.onboardTenant(data);
      await fetchProperties();
      await fetchTenants();
      await fetchBills();
      return true;
    } catch (e) {
      debugPrint('Error onboarding tenant: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordPayment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.recordRentalPayment(data);
      _lastPayment = response['data'];
      await fetchBills();
      await fetchPayments();
      await fetchDashboard();
      return true;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProperty(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addRentalProperty(data);
      await fetchProperties();
      return true;
    } catch (e) {
      debugPrint('Error adding property: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHouse(String propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addHouseToProperty(propertyId, data);
      await fetchProperties();
      return true;
    } catch (e) {
      debugPrint('Error adding house: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPropertyDetails(String propertyId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalPropertyDetails(propertyId);
      _selectedProperty = response['data'];
    } catch (e) {
      debugPrint('Error fetching property details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPropertyStats() async {
    try {
      final response = await _api.getRentalPropertyStats();
      _propertyStats = response['data'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching property stats: $e');
    }
  }

  Future<void> fetchPropertiesWithPagination(
      {String? search, String? status, int page = 1}) async {
    if (page > 1 && !_hasMore) return;

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalPropertiesPaginated(
          page: page, search: search, status: status);
      final data = response['data'];

      if (page == 1) {
        _properties = (data['data'] as List?) ?? [];
      } else {
        _properties.addAll((data['data'] as List?) ?? []);
      }

      _currentPage = data['current_page'] ?? 1;
      _totalPages = data['last_page'] ?? 1;
      _hasMore = _currentPage < _totalPages;
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetPagination() {
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _properties = [];
  }

  Future<bool> updateProperty(
      String propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateRentalProperty(propertyId, data);
      await fetchProperties();
      return true;
    } catch (e) {
      debugPrint('Error updating property: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProperty(String propertyId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.deleteRentalProperty(propertyId);
      _properties.removeWhere((p) => p['id'] == propertyId);
      return true;
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
