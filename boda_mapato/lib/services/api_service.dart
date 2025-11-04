import 'dart:convert';
import 'dart:io';
// ignore_for_file: avoid_dynamic_calls, avoid_positional_boolean_parameters, cascade_invocations, avoid_catches_without_on_clauses
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/dashboard_report.dart';
import '../models/revenue_report.dart';
import 'auth_events.dart';
import 'auth_service.dart';

class ApiService {
  // API Configuration - Updated for Laravel backend
  // For development on localhost (when running flutter on same machine)
  // Use centralized API configuration
  // See lib/config/api_config.dart
  static String get baseUrl => ApiConfig.baseUrl;
  static String get webBaseUrl => ApiConfig.webBaseUrl;

  // Alternative URLs for different environments:
  // For real device testing: "http://192.168.1.124:8000/api";
  // For Android emulator: "http://10.2.2:8000/api";
  // For iOS simulator: "http://127.0.1:8000/api";

  // Timeout duration - reduced for better UX
  static const Duration timeoutDuration = Duration(seconds: 15);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Headers
  Map<String, String> get _headers => <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Future<Map<String, String>> get _authHeaders async {
    final String? token = await _getStoredToken();
    return <String, String>{
      ..._headers,
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Get token from SharedPreferences (same key as AuthService)
  Future<String?> _getStoredToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // Initialize with stored token (for backward compatibility)
  Future<void> initialize() async {
    // Token is now fetched dynamically from SharedPreferences
    // No need to store it in instance variable
  }

  // Quick connectivity test with shorter timeout
  Future<bool> testConnectivity() async {
    try {
      final http.Response response = await http
          .get(
            Uri.parse("$baseUrl/health"),
            headers: _headers,
          )
          .timeout(connectionTimeout);
      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  // Set auth token
  Future<void> setAuthToken(final String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  // Clear auth token
  Future<void> clearAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }

  // Generic HTTP methods
  Future<Map<String, dynamic>> get(
    final String endpoint, {
    final bool requireAuth = true,
  }) async {
    return _get(endpoint, requireAuth: requireAuth);
  }

  // Helper: try multiple endpoints sequentially (useful when backend routes differ)
  Future<Map<String, dynamic>> _getFirst(List<String> endpoints, {bool requireAuth = true}) async {
    ApiException? last404;
    for (final String e in endpoints) {
      try {
        return await _get(e, requireAuth: requireAuth);
      } on ApiException catch (err) {
        final String m = err.message.toLowerCase();
        if (m.contains('404') || m.contains('haipatikani') || m.contains('not found')) {
          last404 = err;
          continue;
        }
        rethrow;
      }
    }
    throw last404 ?? ApiException('Rasilimali haipatikani');
  }

  Future<Map<String, dynamic>> _postFirst(List<String> endpoints, Map<String, dynamic> data, {bool requireAuth = true}) async {
    ApiException? last404;
    for (final String e in endpoints) {
      try {
        if (kDebugMode && ApiConfig.enableHttpLogs) {
          debugPrint('HTTP POST try -> $e');
        }
        return await _post(e, data, requireAuth: requireAuth);
      } on ApiException catch (err) {
        final String m = err.message.toLowerCase();
        if (m.contains('404') || m.contains('haipatikani') || m.contains('not found')) {
          last404 = err;
          continue;
        }
        rethrow;
      }
    }
    throw last404 ?? ApiException('Rasilimali haipatikani');
  }

  Future<Map<String, dynamic>> _putFirst(List<String> endpoints, Map<String, dynamic> data) async {
    ApiException? last404;
    for (final String e in endpoints) {
      try {
        return await _put(e, data);
      } on ApiException catch (err) {
        final String m = err.message.toLowerCase();
        if (m.contains('404') || m.contains('haipatikani') || m.contains('not found')) {
          last404 = err;
          continue;
        }
        rethrow;
      }
    }
    throw last404 ?? ApiException('Rasilimali haipatikani');
  }

  Future<Map<String, dynamic>> _deleteFirst(List<String> endpoints) async {
    ApiException? last404;
    for (final String e in endpoints) {
      try {
        return await _delete(e);
      } on ApiException catch (err) {
        final String m = err.message.toLowerCase();
        if (m.contains('404') || m.contains('haipatikani') || m.contains('not found')) {
          last404 = err;
          continue;
        }
        rethrow;
      }
    }
    throw last404 ?? ApiException('Rasilimali haipatikani');
  }

  // Fetch raw PDF bytes from API (application/pdf)
  Future<Uint8List> getPdf(
    final String endpoint, {
    final bool requireAuth = true,
  }) async {
    try {
      final Map<String, String> headers =
          requireAuth ? await _authHeaders : _headers;
      final http.Response response = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: {
          ...headers,
          "Accept": "application/pdf",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.contains('application/pdf') ??
              false)) {
        return response.bodyBytes;
      }
      throw ApiException("Server returned status ${response.statusCode}");
    } on SocketException catch (e) {
      throw ApiException("Hakuna muunganisho wa mtandao: ${e.message}");
    } on Exception catch (e) {
      throw ApiException("Hitilafu ya kupata PDF: $e");
    }
  }

  Future<Map<String, dynamic>> post(
    final String endpoint,
    final Map<String, dynamic> data, {
    final bool requireAuth = true,
  }) async {
    return _post(endpoint, data, requireAuth: requireAuth);
  }

  Future<Map<String, dynamic>> put(
    final String endpoint,
    final Map<String, dynamic> data,
  ) async {
    return _put(endpoint, data);
  }

  Future<Map<String, dynamic>> _get(
    final String endpoint, {
    final bool requireAuth = true,
  }) async {
    try {
      final Map<String, String> headers =
          requireAuth ? await _authHeaders : _headers;
      
      // If auth is required but no token present, avoid hitting the server at all
      if (requireAuth && !headers.containsKey("Authorization")) {
        throw ApiException("Hauruhusiwi - tafadhali ingia tena");
      }
      final http.Response response = await http
          .get(
            Uri.parse("$baseUrl$endpoint"),
            headers: headers,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException("Hakuna muunganisho wa mtandao: ${e.message}");
    } on HttpException catch (e) {
      throw ApiException("Hitilafu ya seva: ${e.message}");
    } on FormatException catch (e) {
      throw ApiException("Jibu la seva halieleweki: ${e.message}");
    } on Exception catch (e) {
      throw ApiException("Hitilafu isiyojulikana: $e");
    }
  }

  Future<Map<String, dynamic>> _post(
    final String endpoint,
    final Map<String, dynamic> data, {
    final bool requireAuth = true,
  }) async {
    try {
      final Map<String, String> headers =
          requireAuth ? await _authHeaders : _headers;
      if (requireAuth && !headers.containsKey("Authorization")) {
        throw ApiException("Hauruhusiwi - tafadhali ingia tena");
      }

      final String fullUrl = "$baseUrl$endpoint";
      if (kDebugMode && ApiConfig.enableHttpLogs) {
        debugPrint('HTTP POST -> $fullUrl');
      }
      final http.Response response = await http
          .post(
            Uri.parse(fullUrl),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException("Hakuna muunganisho wa mtandao: ${e.message}");
    } on HttpException catch (e) {
      throw ApiException("Hitilafu ya seva: ${e.message}");
    } on FormatException catch (e) {
      throw ApiException("Jibu la seva halieleweki: ${e.message}");
    } on Exception catch (e) {
      throw ApiException("Hitilafu isiyojulikana: $e");
    }
  }

  Future<Map<String, dynamic>> _put(
    final String endpoint,
    final Map<String, dynamic> data,
  ) async {
    try {
      final Map<String, String> headers = await _authHeaders;
      if (!headers.containsKey("Authorization")) {
        throw ApiException("Hauruhusiwi - tafadhali ingia tena");
      }
      final http.Response response = await http
          .put(
            Uri.parse("$baseUrl$endpoint"),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException("Hakuna muunganisho wa mtandao: ${e.message}");
    } on HttpException catch (e) {
      throw ApiException("Hitilafu ya seva: ${e.message}");
    } on FormatException catch (e) {
      throw ApiException("Jibu la seva halieleweki: ${e.message}");
    } on Exception catch (e) {
      throw ApiException("Hitilafu isiyojulikana: $e");
    }
  }

  Future<Map<String, dynamic>> _delete(final String endpoint) async {
    try {
      final Map<String, String> headers = await _authHeaders;
      if (!headers.containsKey("Authorization")) {
        throw ApiException("Hauruhusiwi - tafadhali ingia tena");
      }
      final http.Response response = await http
          .delete(
            Uri.parse("$baseUrl$endpoint"),
            headers: headers,
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException("Hakuna muunganisho wa mtandao: ${e.message}");
    } on HttpException catch (e) {
      throw ApiException("Hitilafu ya seva: ${e.message}");
    } on FormatException catch (e) {
      throw ApiException("Jibu la seva halieleweki: ${e.message}");
    } on Exception catch (e) {
      throw ApiException("Hitilafu isiyojulikana: $e");
    }
  }

  // Payments APIs
  Future<void> markPaymentAsPaid(final String paymentId) async {
    await _post("/admin/payments/$paymentId/mark-paid", <String, dynamic>{});
  }




  // Drivers APIs for import/create

  // Vehicles APIs for import/create

  // Driver payment requests (driver app)
  Future<void> createPaymentRequest(final Map<String, dynamic> data) async {
    await _post("/driver/payment-requests", data);
  }

  Map<String, dynamic> _handleResponse(final http.Response response) {
    Map<String, dynamic> data;

    try {
      data = json.decode(response.body);
    } on Exception {
      throw ApiException("Jibu la seva halieleweki");
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return data;
      case 400:
        throw ApiException(data["message"] ?? "Ombi si sahihi");
      case 401:
        // Clear auth data so UI can return to login
        try {
          // fire-and-forget
          AuthService.clearAuthData();
        } on Exception {
          // ignore
        }
        // Broadcast unauthorized so UI can react immediately
        AuthEvents.instance.emit(AuthEvent.unauthorized);
        throw ApiException("Hauruhusiwi - tafadhali ingia tena");
      case 403:
        throw ApiException("Hauruhusiwi kufikia rasilimali hii");
      case 404:
        throw ApiException("Rasilimali haipatikani");
      case 422:
        final Map<String, dynamic>? errors =
            data["errors"] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw ApiException(firstError.first.toString());
          }
        }
        throw ApiException(data["message"] ?? "Data si sahihi");
      case 500:
        throw ApiException(data["message"] ?? "Hitilafu ya seva ya ndani");
      default:
        throw ApiException(data["message"] ??
            "Hitilafu isiyojulikana: ${response.statusCode}");
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login({
    required final String email,
    required final String password,
    final String? phoneNumber,
  }) async {
    final Map<String, dynamic> requestData = <String, dynamic>{
      if (email.isNotEmpty) "email": email,
      "password": password,
    };

    // Add phone_number if provided (drivers often login via phone)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      requestData["phone_number"] = phoneNumber;
    }

    // Try multiple possible auth endpoints (admin and driver guards)
    final List<String> endpoints = <String>[
      "/auth/login",                  // default (admin/user)
      "/driver/login",               // driver guard variant A
      "/driver/auth/login",          // driver guard variant B
      "/auth/driver/login",          // driver under auth namespace
    ];

    final Map<String, dynamic> response =
        await _postFirst(endpoints, requestData, requireAuth: false);

    // Handle nested response structure: response.data.token or response.token
    String? token;
    if (response["data"] is Map && response["data"]["token"] != null) {
      token = response["data"]["token"];
    } else if (response["token"] != null) {
      token = response["token"];
    }

    if (token != null) {
      await setAuthToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final Map<String, dynamic> response =
          await _post("/auth/logout", <String, dynamic>{});
      await clearAuthToken();
      return response;
    } on Exception {
      // Clear token even if logout fails
      await clearAuthToken();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async => _get("/auth/user");

  Future<Map<String, dynamic>> refreshToken() async {
    final Map<String, dynamic> response =
        await _post("/auth/refresh", <String, dynamic>{});

    if (response["token"] != null) {
      await setAuthToken(response["token"]);
    }

    return response;
  }

  // Security endpoints
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      _post("/auth/change-password", <String, dynamic>{
        "current_password": currentPassword,
        "new_password": newPassword,
      });

  Future<Map<String, dynamic>> getSecuritySettings() async =>
      _get("/auth/security");

  Future<Map<String, dynamic>> setTwoFactor(bool enabled) async =>
      _post("/auth/two-factor", <String, dynamic>{"enabled": enabled});

  Future<Map<String, dynamic>> getLoginHistory({int page = 1, int limit = 20}) async =>
      _get("/auth/login-history?page=$page&limit=$limit");

  // Dashboard endpoints
  // Summary dashboard (AdminController::dashboard)
  Future<Map<String, dynamic>> getDashboardData() async =>
      _get("/admin/dashboard");
  // Detailed dashboard data (DashboardController::index)
  Future<Map<String, dynamic>> getDashboardDataDetailed() async =>
      _get("/admin/dashboard-data");
  
  // Driver dashboard (read-only for driver role)
  Future<Map<String, dynamic>> getDriverDashboard() async =>
      _get("/driver/dashboard");
  
  // Driver self resources
  Future<Map<String, dynamic>> getDriverReceipts({int page = 1, int limit = 20}) async =>
      _get("/driver/receipts?per_page=$limit&page=$page");
  
  Future<Map<String, dynamic>> getDriverPayments({int page = 1, int limit = 50, DateTime? startDate, DateTime? endDate}) async {
    final List<String> params = <String>["per_page=$limit", "page=$page"];
    if (startDate != null) params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    if (endDate != null) params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    final String qs = params.join("&");
    return _get("/driver/payments?$qs");
  }

  Future<Map<String, dynamic>> getDriverDebtRecordsSelf({int page = 1, int limit = 50, bool onlyPaid = false, bool onlyUnpaid = false, DateTime? startDate, DateTime? endDate}) async {
    final List<String> params = <String>["per_page=$limit", "page=$page"];
    if (onlyPaid) params.add("only_paid=true");
    if (onlyUnpaid) params.add("only_unpaid=true");
    if (startDate != null) params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    if (endDate != null) params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    final String qs = params.join("&");
    return _get("/driver/debts/records?$qs");
  }
  
  Future<Map<String, dynamic>> getDriverPaymentHistory({int page = 1, int limit = 200, DateTime? startDate, DateTime? endDate}) async {
    final List<String> params = <String>["per_page=$limit", "page=$page"];
    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    }
    if (endDate != null) {
      params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    }
    final String qs = params.join("&");
    return _get("/driver/payment-history?$qs");
  }

  Future<Map<String, dynamic>> getDriverPaymentsSummary({DateTime? startDate, DateTime? endDate}) async {
    final List<String> params = <String>[];
    if (startDate != null) params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    if (endDate != null) params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    final String qs = params.isEmpty ? '' : '?${params.join('&')}';
    return _get("/driver/payments/summary$qs");
  }
  // Aggregated stats (DashboardController::getStats)
  Future<Map<String, dynamic>> getDashboardStats() async =>
      _get("/admin/dashboard-stats");

  // Token verification helper (wraps /auth/user)
  Future<bool> verifyToken() async {
    try {
      await _get("/auth/user");
      return true;
    } catch (_) {
      return false;
    }
  }

  // Specific dashboard counts from database tables with exact column filtering
  
  /// Get unpaid debts count from debt_records table WHERE is_paid = 0
  Future<Map<String, dynamic>> getUnpaidDebtsCount() async =>
      _get("/admin/dashboard/unpaid-debts-count");

  /// Get active devices count from devices table WHERE is_active = 1
  Future<Map<String, dynamic>> getActiveDevicesCount() async =>
      _get("/admin/dashboard/active-devices-count");

  /// Get active drivers count from drivers table WHERE is_active = 1
  Future<Map<String, dynamic>> getActiveDriversCount() async =>
      _get("/admin/dashboard/active-drivers-count");

  /// Get generated receipts count from payment_receipts table WHERE receipt_status = 'generated'
  Future<Map<String, dynamic>> getGeneratedReceiptsCount() async =>
      _get("/admin/dashboard/generated-receipts-count");

  /// Get pending receipts count from payments table WHERE receipt_status = 'pending'
  Future<Map<String, dynamic>> getPendingReceiptsCount() async =>
      _get("/admin/dashboard/pending-receipts-count");

  /// Get daily revenue from debt_records (is_paid=1) + payments tables for today
  Future<Map<String, dynamic>> getDailyRevenue() async =>
      _get("/admin/dashboard/daily-revenue");

  /// Get weekly revenue from debt_records (is_paid=1) + payments tables for current week
  Future<Map<String, dynamic>> getWeeklyRevenue() async =>
      _get("/admin/dashboard/weekly-revenue");

  /// Get monthly revenue from debt_records (is_paid=1) + payments tables for current month
  Future<Map<String, dynamic>> getMonthlyRevenue() async =>
      _get("/admin/dashboard/monthly-revenue");

  /// Get comprehensive dashboard data with all database table counts and exact column filtering
  Future<Map<String, dynamic>> getComprehensiveDashboardData() async =>
      _get("/admin/dashboard/comprehensive");

  Future<List<dynamic>> getRevenueChart({final int days = 30, DateTime? startDate, DateTime? endDate}) async {
    // Build date window (defaults to last N days)
    final DateTime end = endDate ?? DateTime.now();
    final DateTime start = startDate ?? end.subtract(Duration(days: days - 1));
    final String startStr = start.toIso8601String().split('T')[0];
    final String endStr = end.toIso8601String().split('T')[0];

    // Try multiple parameter conventions
    final List<String> endpoints = <String>[
      "/admin/reports/revenue?start_date=$startStr&end_date=$endStr",
      "/admin/reports/revenue?date_from=$startStr&date_to=$endStr",
    ];

    final Map<String, dynamic> response = await _getFirst(endpoints);

    // Expected shape: { data: { daily_data: [ {date, amount|total|total_amount|paid}, ... ] } }
    final dynamic data = response["data"];
    if (data is Map<String, dynamic>) {
      final dynamic daily = data["daily_data"] ?? data["daily"] ?? data["series"];
      if (daily is List) return daily.cast<dynamic>();
    }

    if (response["daily_data"] is List) {
      return (response["daily_data"] as List).cast<dynamic>();
    }

    return <dynamic>[];
  }

  // Upload profile image (avatar)
  Future<Map<String, dynamic>> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final Map<String, String> headers = await _authHeaders;
    if (!headers.containsKey("Authorization")) {
      throw ApiException("Hauruhusiwi - tafadhali ingia tena");
    }

    Future<Map<String, dynamic>> send(String endpoint, String fieldName) async {
      final uri = Uri.parse("$baseUrl$endpoint");
      final request = http.MultipartRequest('POST', uri);
      final Map<String, String> h = Map.of(headers);
      // Let MultipartRequest set the correct boundary header
      h.remove('Content-Type');
      request.headers.addAll(h);
      request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
      final streamed = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    }

    // Try common endpoints/field names
    try {
      return await send('/auth/profile/avatar', 'avatar');
    } on Exception {
      try {
        return await send('/auth/profile/photo', 'photo');
      } on Exception {
        return send('/auth/profile/image', 'image');
      }
    }
  }

  // Users management endpoints
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 50, String? query}) async {
    final String q = (query != null && query.isNotEmpty) ? "&q=${Uri.encodeComponent(query)}" : "";
    final List<String> endpoints = <String>[
      "/admin/users?page=$page&limit=$limit$q",
      "/users?page=$page&limit=$limit$q",
      "/admin/user-management/users?page=$page&limit=$limit$q",
    ];
    return _getFirst(endpoints);
  }

  /// Get users created by the currently authenticated admin
  Future<Map<String, dynamic>> getMyUsers({int page = 1, int limit = 50, String? query}) async {
    final String q = (query != null && query.isNotEmpty) ? "&q=${Uri.encodeComponent(query)}" : "";
    final List<String> endpoints = <String>[
      "/admin/users?created_by=me&page=$page&limit=$limit$q",
      "/admin/users/mine?page=$page&limit=$limit$q",
      "/users?created_by=me&page=$page&limit=$limit$q",
      "/admin/user-management/users/mine?page=$page&limit=$limit$q",
    ];
    return _getFirst(endpoints);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    if (kDebugMode) {
      debugPrint('DEBUG ApiService.createUser: Trying endpoints for user creation');
    }
    return _postFirst(<String>["/admin/users", "/users", "/admin/user-management/users"], userData);
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async =>
      _putFirst(<String>["/admin/users/$userId", "/users/$userId", "/admin/user-management/users/$userId"], userData);

  Future<Map<String, dynamic>> deleteUser(String userId) async =>
      _deleteFirst(<String>["/admin/users/$userId", "/users/$userId", "/admin/user-management/users/$userId"]);

  Future<Map<String, dynamic>> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async => _postFirst(<String>[
        "/admin/users/$userId/reset-password",
        "/admin/users/$userId/password/reset",
        "/users/$userId/reset-password",
        "/users/$userId/password/reset",
      ], {
        "password": newPassword,
        "password_confirmation": newPassword,
      });

  // Driver management endpoints
  Future<Map<String, dynamic>> getDrivers({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/drivers?page=$page&limit=$limit");

  /// Get a single driver by ID
  Future<Map<String, dynamic>> getDriverById(final String driverId) async =>
      _get("/admin/drivers/$driverId");

  Future<Map<String, dynamic>> createDriver(
    final Map<String, dynamic> driverData,
  ) async =>
      _post("/admin/drivers", driverData, requireAuth: false);

  Future<Map<String, dynamic>> updateDriver(
    final String driverId,
    final Map<String, dynamic> driverData,
  ) async =>
      _put("/admin/drivers/$driverId", driverData);

  Future<Map<String, dynamic>> deleteDriver(final String driverId) async =>
      _delete("/admin/drivers/$driverId");

  // Driver History endpoints
  Future<Map<String, dynamic>> getDriverHistory({
    required final String driverId,
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/drivers/$driverId/history";
    final List<String> params = <String>[];

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    }
    if (endDate != null) {
      params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    }

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getDriverFinancialSummary(
    final String driverId, {
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/drivers/$driverId/financial-summary";
    final List<String> params = <String>[];

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    }
    if (endDate != null) {
      params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    }

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getDriverPerformanceMetrics(
    final String driverId,
  ) async =>
      _get("/admin/drivers/$driverId/performance-metrics");

  Future<Map<String, dynamic>> getDriverTripsHistory({
    required final String driverId,
    final int page = 1,
    final int limit = 50,
    final DateTime? startDate,
    final DateTime? endDate,
    final String? status,
  }) async {
    String endpoint = "/admin/drivers/$driverId/trips?page=$page&limit=$limit";

    if (startDate != null) {
      endpoint += "&start_date=${startDate.toIso8601String().split('T')[0]}";
    }
    if (endDate != null) {
      endpoint += "&end_date=${endDate.toIso8601String().split('T')[0]}";
    }
    if (status != null) {
      endpoint += "&status=$status";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getDriverStatusHistory({
    required final String driverId,
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/drivers/$driverId/status-history?page=$page&limit=$limit");

  Future<Map<String, dynamic>> getDriverPaymentTrends({
    required final String driverId,
    final String period = "monthly", // daily, weekly, monthly, yearly
    final int months = 12,
  }) async =>
      _get(
          "/admin/drivers/$driverId/payment-trends?period=$period&months=$months");

  // Driver prediction analytics (server-side)
  Future<Map<String, dynamic>> getDriverPrediction(final String driverId) async =>
      _get("/admin/drivers/$driverId/prediction");

  Future<Map<String, dynamic>> getDriverDebtTrends({
    required final String driverId,
    final String period = "monthly",
    final int months = 12,
  }) async =>
      _get(
          "/admin/drivers/$driverId/debt-trends?period=$period&months=$months");

  Future<Map<String, dynamic>> updateDriverPerformanceMetrics(
    final String driverId,
  ) async =>
      _put("/admin/drivers/$driverId/recalculate-metrics", <String, dynamic>{});

  // Driver Agreement endpoints
  Future<Map<String, dynamic>> getDriverAgreements({
    final int page = 1,
    final int limit = 20,
    final String? status,
    final String? agreementType,
  }) async {
    String endpoint = "/admin/driver-agreements?page=$page&limit=$limit";
    if (status != null) endpoint += "&status=$status";
    if (agreementType != null) endpoint += "&agreement_type=$agreementType";
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> createDriverAgreement(
    final Map<String, dynamic> agreementData,
  ) async =>
      _post("/admin/driver-agreements", agreementData);

  Future<Map<String, dynamic>> getDriverAgreement(
          final String agreementId) async =>
      _get("/admin/driver-agreements/$agreementId");

  Future<Map<String, dynamic>> updateDriverAgreement(
    final String agreementId,
    final Map<String, dynamic> agreementData,
  ) async =>
      _put("/admin/driver-agreements/$agreementId", agreementData);

  Future<Map<String, dynamic>> deleteDriverAgreement(
    final String agreementId,
  ) async =>
      _delete("/admin/driver-agreements/$agreementId");

  Future<Map<String, dynamic>> getDriverAgreementByDriverId(
    final String driverId,
  ) async =>
      _get("/admin/driver-agreements/driver/$driverId");

  Future<Map<String, dynamic>> terminateDriverAgreement(
    final String agreementId,
    final Map<String, dynamic> terminationData,
  ) async =>
      _put("/admin/driver-agreements/$agreementId/terminate", terminationData);

  Future<Map<String, dynamic>> previewDriverAgreementCalculation(
    final Map<String, dynamic> calculationData,
  ) async =>
      _post("/admin/driver-agreements/calculate-preview", calculationData);

  /// Check if a driver has completed their agreement
  /// Returns true if driver has an active/completed agreement, false otherwise
  Future<bool> hasDriverCompletedAgreement(final String driverId) async {
    try {
      final Map<String, dynamic> response =
          await getDriverAgreementByDriverId(driverId);

      final Map<String, dynamic>? data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : null;
      final String? status = data?['status']?.toString();
      return status == 'active' || status == 'completed';
    } on Exception {
      // If no agreement found or error occurred, consider as not completed
      return false;
    }
  }

  // Vehicle management endpoints
  Future<Map<String, dynamic>> getVehicles({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/vehicles?page=$page&limit=$limit");

  Future<Map<String, dynamic>> createVehicle(
    final Map<String, dynamic> vehicleData,
  ) async =>
      _post("/admin/vehicles", vehicleData);

  Future<Map<String, dynamic>> updateVehicle(
    final String vehicleId,
    final Map<String, dynamic> vehicleData,
  ) async =>
      _put("/admin/vehicles/$vehicleId", vehicleData);

  Future<Map<String, dynamic>> unassignDriverFromVehicle(
          final String vehicleId) async =>
      _post("/admin/vehicles/$vehicleId/unassign", <String, dynamic>{});

  Future<Map<String, dynamic>> deleteVehicle(final String vehicleId) async =>
      _delete("/admin/vehicles/$vehicleId");

  Future<Map<String, dynamic>> assignDriverToVehicle({
    required final String vehicleId,
    required final String driverId,
  }) async =>
      _post("/admin/assign-driver", <String, dynamic>{
        "vehicle_id": vehicleId,
        "driver_id": driverId,
      });

  // Payment management endpoints
  Future<Map<String, dynamic>> getPayments({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/payment-history?page=$page&limit=$limit");

  // Receipt management endpoints
  Future<Map<String, dynamic>> generateReceipt(
    final Map<String, dynamic> receiptData,
  ) async =>
      _post("/admin/generate-receipt", receiptData);

  // Reports endpoints
  Future<Map<String, dynamic>> getDashboardReport() async =>
      _get("/admin/reports/dashboard");

  Future<Map<String, dynamic>> getRevenueReport({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/reports/revenue";
    final List<String> params = <String>[];

    String _d(DateTime d) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      return "${d.year}-${two(d.month)}-${two(d.day)}"; // send date-only to avoid TZ issues
    }

    if (startDate != null) {
      params.add("start_date=${_d(startDate)}");
    }
    if (endDate != null) params.add("end_date=${_d(endDate)}");

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  // Typed helpers (non-breaking): parse API maps into DTOs
  // Consumers can migrate to these methods incrementally for type safety.
  Future<DashboardReport> getDashboardReportTyped() async {
    final Map<String, dynamic> map = await getDashboardReport();
    return DashboardReport.fromApi(map);
  }

  Future<DashboardReport> getDashboardDataTyped() async {
    final Map<String, dynamic> map = await getDashboardData();
    return DashboardReport.fromApi(map);
  }

  Future<RevenueReport> getRevenueReportTyped({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    final Map<String, dynamic> map = await getRevenueReport(
      startDate: startDate,
      endDate: endDate,
    );
    return RevenueReport.fromApi(map);
  }

  Future<Map<String, dynamic>> getExpenseReport({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/reports/expenses";
    final List<String> params = <String>[];

    String _d(DateTime d) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      return "${d.year}-${two(d.month)}-${two(d.day)}";
    }

    if (startDate != null) {
      params.add("start_date=${_d(startDate)}");
    }
    if (endDate != null) params.add("end_date=${_d(endDate)}");

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getProfitLossReport({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/reports/profit-loss";
    final List<String> params = <String>[];

    String _d(DateTime d) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      return "${d.year}-${two(d.month)}-${two(d.day)}";
    }

    if (startDate != null) {
      params.add("start_date=${_d(startDate)}");
    }
    if (endDate != null) params.add("end_date=${_d(endDate)}");

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getDevicePerformanceReport() async =>
      _get("/admin/reports/device-performance");

  Future<Map<String, dynamic>> exportReportToPdf(
    final Map<String, dynamic> reportData,
  ) async =>
      _post("/admin/reports/export-pdf", reportData);

  // Reminder endpoints
  Future<Map<String, dynamic>> addReminder(
    final Map<String, dynamic> reminderData,
  ) async =>
      _post("/admin/reminders", reminderData);

  Future<Map<String, dynamic>> getReminders({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/reminders?page=$page&limit=$limit");

  // Driver reminders (read-only)
  Future<Map<String, dynamic>> getDriverReminders({int page = 1, int limit = 50}) async =>
      _get("/driver/reminders?page=$page&limit=$limit");

  Future<Map<String, dynamic>> updateReminder(
    final String reminderId,
    final Map<String, dynamic> reminderData,
  ) async =>
      _put("/admin/reminders/$reminderId", reminderData);

  Future<Map<String, dynamic>> deleteReminder(final String reminderId) async =>
      _delete("/admin/reminders/$reminderId");

  // Device management endpoints
  Future<Map<String, dynamic>> getDevices({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/devices?page=$page&limit=$limit");

  Future<Map<String, dynamic>> createDevice(
    final Map<String, dynamic> deviceData,
  ) async =>
      _post("/admin/devices", deviceData);

  Future<Map<String, dynamic>> updateDevice(
    final String deviceId,
    final Map<String, dynamic> deviceData,
  ) async =>
      _put("/admin/devices/$deviceId", deviceData);

  Future<Map<String, dynamic>> deleteDevice(final String deviceId) async =>
      _delete("/admin/devices/$deviceId");

  // Transaction endpoints
  Future<Map<String, dynamic>> getTransactions({
    final int page = 1,
    final int limit = 20,
    final String? status,
    final String? type,
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/transactions?page=$page&limit=$limit";

    if (status != null) endpoint += "&status=$status";
    if (type != null) endpoint += "&type=$type";
    if (startDate != null) {
      endpoint += "&start_date=${startDate.toIso8601String()}";
    }
    if (endDate != null) endpoint += "&end_date=${endDate.toIso8601String()}";

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> createTransaction(
    final Map<String, dynamic> transactionData,
  ) async =>
      _post("/admin/transactions", transactionData);

  Future<Map<String, dynamic>> updateTransaction(
    final String transactionId,
    final Map<String, dynamic> transactionData,
  ) async =>
      _put("/admin/transactions/$transactionId", transactionData);

  Future<Map<String, dynamic>> deleteTransaction(
    final String transactionId,
  ) async =>
      _delete("/admin/transactions/$transactionId");

  // Payment management endpoints
  Future<Map<String, dynamic>> getDriversWithDebts({
    final int page = 1,
    final int limit = 50,
  }) async =>
      // Updated to new debts route (payments routes removed on backend)
      _get("/admin/debts/drivers?page=$page&limit=$limit");

  // Debts management endpoints
  Future<Map<String, dynamic>> getDebtDrivers({
    final int page = 1,
    final int limit = 50,
    final String? query,
  }) async {
    String endpoint = "/admin/debts/drivers?page=$page&limit=$limit";
    if (query != null && query.isNotEmpty) {
      endpoint += "&q=${Uri.encodeComponent(query)}";
    }
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> createDebts({
    required String driverId,
    List<String>? dates, // YYYY-MM-DD (legacy mode)
    double? amount, // legacy mode
    List<Map<String, dynamic>>? items, // [{date: YYYY-MM-DD, amount: 10000}]
    String? notes,
    bool promisedToPay = false,
    DateTime? promiseToPayAt,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      "driver_id": driverId,
      if (items != null) "items": items,
      if (dates != null) "dates": dates,
      if (amount != null) "amount": amount,
      if (notes != null && notes.isNotEmpty) "notes": notes,
      if (promisedToPay) "promised_to_pay": true,
      if (promiseToPayAt != null)
        "promise_to_pay_at": promiseToPayAt.toIso8601String(),
    };
    return _post("/admin/debts/bulk-create", payload);
  }

  Future<Map<String, dynamic>> updateDebtRecord({
    required String debtId,
    String? earningDate,
    double? expectedAmount,
    String? notes,
    bool? promisedToPay,
    DateTime? promiseToPayAt,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      if (earningDate != null) "earning_date": earningDate,
      if (expectedAmount != null) "expected_amount": expectedAmount,
      if (notes != null) "notes": notes,
      if (promisedToPay != null) "promised_to_pay": promisedToPay,
      if (promiseToPayAt != null)
        "promise_to_pay_at": promiseToPayAt.toIso8601String(),
    };
    return _put("/admin/debts/records/$debtId", payload);
  }

  Future<Map<String, dynamic>> deleteDebtRecord(String debtId) async =>
      _delete("/admin/debts/records/$debtId");

  Future<Map<String, dynamic>> getDriverDebtSummary(
    final String driverId,
  ) async {
    // Backend no longer exposes /admin/payments/driver-debt-summary.
    // Fetch records and compute a summary compatible with existing UI models.
    final Map<String, dynamic> resp =
        await _get("/admin/debts/driver/$driverId/records");

    final dynamic data = resp["data"];
    final List<dynamic> records = (data is Map && data["debt_records"] is List)
        ? (data["debt_records"] as List).cast<dynamic>()
        : (resp["debt_records"] is List)
            ? (resp["debt_records"] as List).cast<dynamic>()
            : <dynamic>[];

    double toDouble(Object? v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    double totalDebt = 0;
    int unpaidDays = 0;
    DateTime? lastPaidAt;
    String driverName = "";

    for (final dynamic r in records) {
      final Map<String, dynamic> m = (r as Map).cast<String, dynamic>();
      driverName = driverName.isEmpty
          ? (m['driver_name']?.toString() ?? driverName)
          : driverName;
      final bool isPaid = m['is_paid'] == true || m['is_paid'] == 1;
      if (!isPaid) {
        unpaidDays += 1;
        totalDebt += toDouble(m['remaining_amount']);
      } else {
        final String? paidAtStr = m['paid_at']?.toString();
        final DateTime? dt =
            paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;
        if (dt != null) {
          if (lastPaidAt == null || dt.isAfter(lastPaidAt)) {
            lastPaidAt = dt;
          }
        }
      }
    }

    return <String, dynamic>{
      'success': true,
      'message': 'Driver debt summary computed',
      'data': <String, dynamic>{
        'driver_id': driverId,
        'driver_name': driverName,
        'total_debt': totalDebt,
        'unpaid_days': unpaidDays,
        'debt_records': records,
        'last_payment_date': lastPaidAt?.toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> getDriverDebtRecords(
    final String driverId, {
    final bool unpaidOnly = true,
    final int limit = 100,
  }) async {
    String endpoint = "/admin/payments/driver-debts/$driverId?limit=$limit";
    if (unpaidOnly) {
      endpoint += "&unpaid_only=true";
    }
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> recordPayment(
    final Map<String, dynamic> paymentData,
  ) async =>
      _post("/admin/payments/record", paymentData);

  // Store new monthly payment (not tied to debt clearance)
  Future<Map<String, dynamic>> storeNewPayment(
    final Map<String, dynamic> paymentData,
  ) async =>
      _post("/admin/payments/new", paymentData);

  Future<Map<String, dynamic>> getNewPaymentsMap({String? month}) async {
    String endpoint = "/admin/payments/new-payments-map";
    if (month != null && month.isNotEmpty) {
      endpoint += "?month=$month";
    }
    return _get(endpoint);
  }

  Future<Map<String, dynamic>> getPaymentHistory({
    final int page = 1,
    final int limit = 20,
    final String? driverId,
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/payments/history?page=$page&limit=$limit";

    String _d(DateTime d) {
      String two(int n) => n < 10 ? '0$n' : '$n';
      return "${d.year}-${two(d.month)}-${two(d.day)}";
    }

    if (driverId != null) {
      endpoint += "&driver_id=$driverId";
    }
    if (startDate != null) {
      endpoint += "&start_date=${_d(startDate)}";
    }
    if (endDate != null) {
      endpoint += "&end_date=${_d(endDate)}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> updatePayment(
    final String paymentId,
    final Map<String, dynamic> paymentData,
  ) async =>
      _put("/admin/payments/$paymentId", paymentData);

  Future<Map<String, dynamic>> deletePayment(
    final String paymentId,
  ) async =>
      _delete("/admin/payments/$paymentId");

  Future<Map<String, dynamic>> getPaymentSummary({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/payments/summary";
    final List<String> params = <String>[];

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String()}");
    }
    if (endDate != null) {
      params.add("end_date=${endDate.toIso8601String()}");
    }

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  Future<Map<String, dynamic>> markDebtAsPaid(
    final String debtId,
    final String paymentId,
  ) async =>
      _put("/admin/payments/mark-debt-paid/$debtId", {
        "payment_id": paymentId,
        "paid_at": DateTime.now().toIso8601String(),
      });

  // Receipt Management Methods

  /// Get pending receipts (payments without receipts generated)
  Future<Map<String, dynamic>> getPendingReceipts() async =>
      _get("/admin/receipts/pending");

  /// Generate receipt for a payment
  Future<Map<String, dynamic>> generatePaymentReceipt(String paymentId) async =>
      _post("/admin/receipts/generate", {
        "payment_id": paymentId,
      });

  /// Generate bulk receipts for multiple payments
  Future<Map<String, dynamic>> generateBulkReceipts(
    List<String> paymentIds,
  ) async =>
      _post("/admin/receipts/bulk-generate", {
        "payment_ids": paymentIds,
      });

  /// Get receipt by ID
  Future<Map<String, dynamic>> getReceipt(String receiptId) async =>
      _get("/admin/receipts/$receiptId");

  /// Get all receipts with optional filtering and pagination
  Future<Map<String, dynamic>> getReceipts({
    int page = 1,
    int limit = 20,
    String? status,
    String? driverId,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    String endpoint = "/admin/receipts?page=$page&limit=$limit";
    final List<String> params = <String>[];

    if (status != null && status.isNotEmpty) {
      params.add("status=$status");
    }
    if (driverId != null && driverId.isNotEmpty) {
      params.add("driver_id=$driverId");
    }
    if (query != null && query.isNotEmpty) {
      params.add("q=${Uri.encodeComponent(query)}");
    }
    if (dateFrom != null) {
      params.add("date_from=${dateFrom.toIso8601String().split('T')[0]}");
    }
    if (dateTo != null) {
      params.add("date_to=${dateTo.toIso8601String().split('T')[0]}");
    }

    if (params.isNotEmpty) {
      endpoint += "&${params.join("&")}";
    }

    return _get(endpoint);
  }

  /// Search receipts
  Future<Map<String, dynamic>> searchReceipts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async =>
      _get("/admin/receipts/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit");

  /// Get payment receipt preview by receipt ID
  Future<Map<String, dynamic>> getPaymentReceiptPreview(
          String receiptId) async =>
      _get("/admin/receipts/$receiptId/preview");

  /// Send payment receipt to driver via specified method
  Future<Map<String, dynamic>> sendPaymentReceipt({
    required String receiptId,
    required String sendVia, // 'whatsapp', 'email', 'sms'
    required String contactInfo, // phone number for WhatsApp/SMS, email for email
    String? message,
  }) async =>
      _post("/admin/receipts/send", {
        "receipt_id": receiptId,
        "send_via": sendVia,
        "contact_info": contactInfo,
        if (message != null && message.isNotEmpty) "message": message,
      });

  /// Update receipt status
  Future<Map<String, dynamic>> updateReceiptStatus(
    String receiptId,
    String status,
  ) async =>
      _put("/admin/receipts/$receiptId/status", {
        "status": status,
      });

  /// Cancel receipt
  Future<Map<String, dynamic>> cancelReceipt(String receiptId) async =>
      _put("/admin/receipts/$receiptId/cancel", <String, dynamic>{});

  /// Delete receipt
  Future<Map<String, dynamic>> deleteReceipt(String receiptId) async =>
      _delete("/admin/receipts/$receiptId");

  /// Get receipt statistics
  Future<Map<String, dynamic>> getReceiptStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = "/admin/receipts/stats";
    final List<String> params = <String>[];

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String().split('T')[0]}");
    }
    if (endDate != null) {
      params.add("end_date=${endDate.toIso8601String().split('T')[0]}");
    }

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  /// Export receipts to PDF or Excel
  Future<Map<String, dynamic>> exportReceipts({
    required String format, // 'pdf' or 'excel'
    String? status,
    String? driverId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      "format": format,
    };

    if (status != null) data["status"] = status;
    if (driverId != null) data["driver_id"] = driverId;
    if (dateFrom != null) {
      data["date_from"] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      data["date_to"] = dateTo.toIso8601String().split('T')[0];
    }

    return _post("/admin/receipts/export", data);
  }

  /// Get payment receipt by ID (alias for getReceipt)
  Future<Map<String, dynamic>> getPaymentReceiptById(String receiptId) async =>
      getReceipt(receiptId);

  /// Get all payment receipts (alias for getReceipts)
  Future<Map<String, dynamic>> getPaymentReceipts({
    String? status,
    String? driverId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async =>
      getReceipts(
        status: status,
        driverId: driverId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  // Health check
  Future<Map<String, dynamic>> healthCheck() async =>
      _get("/health", requireAuth: false);

  // Test endpoints
  Future<Map<String, dynamic>> testConnection() async =>
      _get("/test", requireAuth: false);

  Future<Map<String, dynamic>> getSystemStatus() async =>
      _get("/test/system-status", requireAuth: false);
}

// Custom exception class for API errors
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => "ApiException: $message";
}

// Response wrapper class
class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(
    final Map<String, dynamic> json,
    final T Function()? fromJson,
  ) =>
      ApiResponse<T>(
        success: json["success"] ?? true,
        data: json["data"] != null && fromJson != null
            ? fromJson()
            : json["data"],
        message: json["message"],
        errors: json["errors"],
      );
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;
}

// Network connectivity helper
class NetworkHelper {
  static Future<bool> isConnected() async {
    try {
      final List<InternetAddress> result =
          await InternetAddress.lookup("google.com");
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
