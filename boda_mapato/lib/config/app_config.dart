/// Application configuration for different environments
/// This file manages the app behavior in different modes
library;

import '../services/api_service.dart';
import '../services/mock_api_service.dart';

mixin AppConfig {
  // Development mode - SET THIS TO FALSE TO USE REAL BACKEND API
  static const bool useMockData = false;

  // Build mode
  static const bool isDebugMode = true;

  // App version
  static const String appVersion = "1.0.0";

  // App name
  static const String appName = "Boda Mapato";

  // Company info
  static const String companyName = "Boda Mapato Ltd";
  static const String companyPhone = "+255 123 456 789";
  static const String companyEmail = "info@bodamapato.com";

  // API configuration based on mode
  static bool get useRealApi => !useMockData;
  static bool get shouldShowMockIndicator => useMockData && isDebugMode;
}

/// Service locator for API services
class ServiceLocator {
  static ApiService? _realApiService;

  /// Get API service based on configuration
  static ApiService getApiService() {
    if (AppConfig.useRealApi) {
      return _realApiService ??= ApiService();
    } else {
      // Return a wrapper that uses mock data
      return _MockApiServiceWrapper();
    }
  }

  /// Reset services (useful for testing)
  static void reset() {
    _realApiService = null;
  }
}

/// Wrapper class to make MockApiService compatible with ApiService interface
class _MockApiServiceWrapper extends ApiService {
  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await MockApiService.getDashboardData();
    return response['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await MockApiService.getDashboardStats();
    return response['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getRevenueChart({int days = 30}) async {
    return MockApiService.getRevenueChart(days: days);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      return await MockApiService.login(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
    } on Exception catch (e) {
      if (e is MockApiException) {
        throw ApiException(e.message);
      }
      rethrow;
    }
  }
  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await MockApiService.getCurrentUser();
    return response;
  }

  @override
  Future<Map<String, dynamic>> getDrivers({
    int page = 1,
    int limit = 20,
  }) async {
    return MockApiService.getDrivers(page: page, limit: limit);
  }

  @override
  Future<Map<String, dynamic>> getVehicles({
    int page = 1,
    int limit = 20,
  }) async {
    return MockApiService.getVehicles(page: page, limit: limit);
  }

  @override
  Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int limit = 20,
  }) async {
    return MockApiService.getPayments(page: page, limit: limit);
  }

  @override
  Future<Map<String, dynamic>> healthCheck() async {
    return MockApiService.healthCheck();
  }

  @override
  Future<Map<String, dynamic>> testConnection() async {
    return MockApiService.testConnection();
  }

  // For other methods that aren't implemented in mock, return empty or throw not implemented
  @override
  Future<Map<String, dynamic>> logout() async {
    await clearAuthToken();
    return {"success": true, "message": "Umetoka kikamilifu"};
  }

  @override
  Future<Map<String, dynamic>> refreshToken() async {
    return {
      "success": true,
      "token": "mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}",
      "message": "Token imebureshwa"
    };
  }

  // Implement other required methods with mock responses
  @override
  Future<Map<String, dynamic>> createDriver(
      Map<String, dynamic> driverData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      "success": true,
      "data": {
        "id": DateTime.now().millisecondsSinceEpoch,
        ...driverData,
        "created_at": DateTime.now().toIso8601String()
      },
      "message": "Dereva ameongezwa kikamilifu"
    };
  }

  @override
  Future<Map<String, dynamic>> updateDriver(
      String driverId, Map<String, dynamic> driverData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      "success": true,
      "data": {
        "id": driverId,
        ...driverData,
        "updated_at": DateTime.now().toIso8601String()
      },
      "message": "Taarifa za dereva zimesasishwa"
    };
  }

  @override
  Future<Map<String, dynamic>> deleteDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {"success": true, "message": "Dereva amefutwa kikamilifu"};
  }

  // Add similar implementations for other methods as needed...
}
