import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';

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

  // Blocks
  List<dynamic> _blocks = [];
  List<dynamic> get blocks => _blocks;

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
      debugPrint('Fetch properties RAW keys: ${response.keys}');
      debugPrint('Fetch properties RAW response: $response');
      
      List<dynamic> items = [];
      
      // Greedy extraction: Collect ALL lists that look like they contain property-like objects
      void collectLists(obj) {
        if (obj is List) {
          if (obj.isNotEmpty && obj.first is Map && 
              (obj.first.containsKey('name') || obj.first.containsKey('house_number'))) {
            items.addAll(obj);
          }
        } else if (obj is Map) {
          for (final v in obj.values) {
            collectLists(v);
          }
        }
      }
      
      collectLists(response);
      
      // If nothing found via greedy collection, fallback to standard locations
      if (items.isEmpty) {
        final dynamic data = response['data'] ?? response['properties'] ?? response['result'];
        if (data is List) {
          items = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          items = data['data'];
        }
      }
      
      // Deduplicate by ID if needed
      final seenIds = <String>{};
      _properties = items.where((item) {
        final id = item['id']?.toString();
        if (id == null) return true;
        if (seenIds.contains(id)) return false;
        seenIds.add(id);
        return true;
      }).toList();

      debugPrint('Loaded ${_properties.length} properties via deep greedy fetch');
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

  Future<void> fetchBlocks(String propertyId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalBlocks(propertyId);
      _blocks = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching blocks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBlock(String propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addRentalBlock(propertyId, data);
      await fetchBlocks(propertyId);
      return true;
    } catch (e) {
      debugPrint('Error adding block: $e');
      return false;
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

  Future<bool> addHouse(String propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addHouseToProperty(propertyId, data);
      await fetchProperties(); // Refresh to show new house
      return true;
    } catch (e) {
      debugPrint('Error adding house: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> terminateTenantAgreement(String tenantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.terminateTenant(tenantId);
      await fetchTenants();
      return true;
    } catch (e) {
      debugPrint('Error terminating agreement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendSmsReminder(String billId) async {
    return SmsService.instance.sendBillReminder(billId);
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

  Future<bool> addProperty(Map<String, dynamic> data, {File? image}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.addRentalProperty(data, image: image);
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

  Future<void> fetchPropertyDetails(String propertyId) async {
    if (propertyId.isEmpty) return; // Prevention
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getRentalPropertyDetails(propertyId);
      if (response['data'] is Map<String, dynamic>) {
        _selectedProperty = response['data'];
      } else {
        debugPrint('fetchPropertyDetails: Expected Map but got ${response['data'].runtimeType}');
      }
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
      debugPrint('Fetch properties paginated (page $page) RAW keys: ${response.keys}');
      
      List<dynamic> items = [];
      Map<String, dynamic>? paginationMap;

      // 1. Deeply look for pagination metadata with verification
      void findPagination(obj) {
        if (obj is Map) {
          if (obj.containsKey('data') && obj['data'] is List && obj.containsKey('current_page')) {
            // Verify this list contains property-like objects
            final list = obj['data'] as List;
            if (list.isEmpty || (list.first is Map && 
                (list.first.containsKey('name') || list.first.containsKey('house_number')))) {
              paginationMap = obj as Map<String, dynamic>;
              return;
            }
          }
          for (final v in obj.values) {
            if (v is Map || v is List) findPagination(v);
            if (paginationMap != null) return;
          }
        } else if (obj is List) {
          for (final v in obj) {
            findPagination(v);
            if (paginationMap != null) return;
          }
        }
      }

      findPagination(response);

      if (paginationMap != null) {
        items = paginationMap!['data'];
        _currentPage = paginationMap!['current_page'] ?? page;
        _totalPages = paginationMap!['last_page'] ?? _currentPage;
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }

      // 2. Deeply look for ANY other lists and merge them (Greedy Collection)
      void collectMoreItems(obj) {
        if (obj is List) {
          if (obj.isNotEmpty && obj.first is Map && 
              (obj.first.containsKey('name') || obj.first.containsKey('house_number'))) {
            items.addAll(obj);
          }
        } else if (obj is Map && obj != paginationMap) {
          for (final v in obj.values) {
            collectMoreItems(v);
          }
        }
      }

      collectMoreItems(response);

      // 3. Safeguard: if items is empty, stop paging
      if (items.isEmpty) {
        _hasMore = false;
        if (page == 1) _properties = [];
        return;
      }

      // 4. Deduplicate by ID
      final seenIds = <String>{};
      final uniqueItems = items.where((item) {
        final id = (item is Map) ? (item['id']?.toString() ?? item['name']?.toString() ?? '') : '';
        if (id == '') return true;
        if (seenIds.contains(id)) return false;
        seenIds.add(id);
        return true;
      }).toList();

      if (page == 1) {
        _properties = uniqueItems;
      } else {
        final existingIds = _properties.map((p) => (p is Map) ? (p['id']?.toString() ?? p['name']?.toString() ?? '') : '').toSet();
        int addedCount = 0;
        for (final item in uniqueItems) {
          final id = (item is Map) ? (item['id']?.toString() ?? item['name']?.toString() ?? '') : '';
          if (!existingIds.contains(id)) {
            _properties.add(item);
            addedCount++;
          }
        }
        if (addedCount == 0) _hasMore = false;
      }
      debugPrint('Loaded ${_properties.length} properties. More: $_hasMore');
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      _hasMore = false;
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

  Future<bool> updateProperty(String propertyId, Map<String, dynamic> data,
      {File? image}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateRentalProperty(propertyId, data, image: image);
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

  Future<Map<String, dynamic>?> fetchHouseDetails(String houseId) async {
    try {
      final response = await _api.getHouseDetails(houseId);
      return response['data'];
    } catch (e) {
      debugPrint('Error fetching house details: $e');
      return null;
    }
  }

  Future<bool> createHouse(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.createHouse(data);
      await fetchProperties();
      return true;
    } catch (e) {
      debugPrint('Error creating house: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateHouse(String houseId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateHouse(houseId, data);
      return true;
    } catch (e) {
      debugPrint('Error updating house: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHouse(String houseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.deleteHouse(houseId);
      await fetchProperties();
      return true;
    } catch (e) {
      debugPrint('Error deleting house: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchPropertyHouses(String propertyId) async {
    try {
      final response = await _api.getPropertyHouses(propertyId);
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching property houses: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchOccupancyReport() async {
    try {
      final response = await _api.getOccupancyReport();
      return response['data'];
    } catch (e) {
      debugPrint('Error fetching occupancy: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchRevenueReport(String period) async {
    try {
      final response = await _api.getRevenueReport(period: period);
      return response['data'];
    } catch (e) {
      debugPrint('Error fetching revenue report: $e');
      return null;
    }
  }

  Future<bool> updateTenantStatus(String tenantId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateTenantStatus(tenantId, status);
      await fetchTenants();
      return true;
    } catch (e) {
      debugPrint('Error updating tenant status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> terminateTenant(String tenantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.terminateTenant(tenantId);
      await fetchTenants();
      return true;
    } catch (e) {
      debugPrint('Error terminating tenant: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> searchTenants(String query) {
    if (query.isEmpty) return _tenants;
    return _tenants.where((tenant) {
      final name = (tenant['name'] ?? '').toString().toLowerCase();
      final phone = (tenant['phone_number'] ?? '').toString().toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search) || phone.contains(search);
    }).toList();
  }

  // Agreement methods
  List<dynamic> _agreements = [];
  List<dynamic> get agreements => _agreements;

  Future<void> fetchAgreements({String? status, String? search}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.getAgreements(status: status, search: search);
      _agreements = response['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching agreements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAgreement(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.createAgreement(data);
      await fetchAgreements();
      return true;
    } catch (e) {
      debugPrint('Error creating agreement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> renewAgreement(String id, Map<String, dynamic> data) async {
    try {
      await _api.renewAgreement(id, data);
      await fetchAgreements();
      return true;
    } catch (e) {
      debugPrint('Error renewing agreement: $e');
      return false;
    }
  }

  Future<bool> terminateAgreement(String id, String reason) async {
    try {
      await _api.terminateAgreement(id, reason);
      await fetchAgreements();
      return true;
    } catch (e) {
      debugPrint('Error terminating agreement: $e');
      return false;
    }
  }

  List<dynamic> getExpiringAgreements() {
    return _agreements.where((a) {
      return a['status'] == 'active' && a['end_date'] != null;
    }).toList();
  }
}
