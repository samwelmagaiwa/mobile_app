import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../models/dashboard_report.dart";
import "../models/revenue_report.dart";

class ApiService {
  // API Configuration - Updated for Laravel backend
  // For development on localhost (when running flutter on same machine)
  static const String baseUrl =
      "http://127.0.0.1/mobile_app/backend_mapato/public/api";
  static const String webBaseUrl =
      "http://127.0.0.1/mobile_app/backend_mapato/public";

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

      final http.Response response = await http
          .post(
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

  Future<Map<String, dynamic>> _put(
    final String endpoint,
    final Map<String, dynamic> data,
  ) async {
    try {
      final Map<String, String> headers = await _authHeaders;
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
      "email": email,
      "password": password,
    };

    // Only add phone_number if provided
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      requestData["phone_number"] = phoneNumber;
    }

    final Map<String, dynamic> response =
        await _post("/auth/login", requestData, requireAuth: false);

    if (response["token"] != null) {
      await setAuthToken(response["token"]);
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

  // Dashboard endpoints
  Future<Map<String, dynamic>> getDashboardData() async =>
      _get("/admin/dashboard");
  Future<Map<String, dynamic>> getDashboardStats() async =>
      _get("/admin/dashboard/data");

  Future<List<dynamic>> getRevenueChart({final int days = 30}) async {
    final Map<String, dynamic> response =
        await _get("/admin/dashboard/revenue-chart?days=$days");
    return response["data"] ?? <dynamic>[];
  }

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

  Future<Map<String, dynamic>> getReceipts({
    final int page = 1,
    final int limit = 20,
  }) async =>
      _get("/admin/receipts?page=$page&limit=$limit");

  // Reports endpoints
  Future<Map<String, dynamic>> getDashboardReport() async =>
      _get("/admin/reports/dashboard");

  Future<Map<String, dynamic>> getRevenueReport({
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/reports/revenue";
    final List<String> params = <String>[];

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String()}");
    }
    if (endDate != null) params.add("end_date=${endDate.toIso8601String()}");

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

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String()}");
    }
    if (endDate != null) params.add("end_date=${endDate.toIso8601String()}");

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

    if (startDate != null) {
      params.add("start_date=${startDate.toIso8601String()}");
    }
    if (endDate != null) params.add("end_date=${endDate.toIso8601String()}");

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
      _get("/admin/payments/drivers-with-debts?page=$page&limit=$limit");

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
  ) async =>
      _get("/admin/payments/driver-debt-summary/$driverId");

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

  Future<Map<String, dynamic>> getPaymentHistory({
    final int page = 1,
    final int limit = 20,
    final String? driverId,
    final DateTime? startDate,
    final DateTime? endDate,
  }) async {
    String endpoint = "/admin/payments/history?page=$page&limit=$limit";

    if (driverId != null) {
      endpoint += "&driver_id=$driverId";
    }
    if (startDate != null) {
      endpoint += "&start_date=${startDate.toIso8601String()}";
    }
    if (endDate != null) {
      endpoint += "&end_date=${endDate.toIso8601String()}";
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
      _get("/payment-receipts/pending");

  /// Generate receipt for a payment
  Future<Map<String, dynamic>> generatePaymentReceipt(String paymentId) async =>
      _post("/payment-receipts/generate", {
        "payment_id": paymentId,
      });

  /// Get payment receipt preview by receipt ID
  Future<Map<String, dynamic>> getPaymentReceiptPreview(
          String receiptId) async =>
      _get("/payment-receipts/$receiptId/preview");

  /// Send payment receipt to driver via specified method
  Future<Map<String, dynamic>> sendPaymentReceipt({
    required String receiptId,
    required String sendVia, // 'whatsapp', 'email', 'system'
    required String contactInfo, // phone number for WhatsApp, email for email
  }) async =>
      _post("/payment-receipts/send", {
        "receipt_id": receiptId,
        "send_via": sendVia,
        "contact_info": contactInfo,
      });

  /// Get all payment receipts with optional filtering
  Future<Map<String, dynamic>> getPaymentReceipts({
    String? status,
    String? driverId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    String endpoint = "/payment-receipts";
    final List<String> params = <String>[];

    if (status != null) {
      params.add("status=$status");
    }
    if (driverId != null) {
      params.add("driver_id=$driverId");
    }
    if (dateFrom != null) {
      params.add("date_from=${dateFrom.toIso8601String().split('T')[0]}");
    }
    if (dateTo != null) {
      params.add("date_to=${dateTo.toIso8601String().split('T')[0]}");
    }

    if (params.isNotEmpty) {
      endpoint += "?${params.join("&")}";
    }

    return _get(endpoint);
  }

  /// Get payment receipt by ID
  Future<Map<String, dynamic>> getPaymentReceiptById(String receiptId) async =>
      _get("/payment-receipts/$receiptId");

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
