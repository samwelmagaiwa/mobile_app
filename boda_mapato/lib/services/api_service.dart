import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

class ApiService {
  // API Configuration - Updated for Laravel backend
  // For development on localhost (when running flutter on same machine)
  static const String baseUrl = "http://192.168.1.124:8000/api";
  static const String webBaseUrl = "http://127.0.1:8000";

  // Alternative URLs for different environments:
  // For real device testing: "http://192.168.1.124:8000/api";
  // For Android emulator: "http://10.2.2:8000/api";
  // For iOS simulator: "http://127.0.1:8000/api";

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

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
    } on SocketException {
      throw ApiException("Hakuna muunganisho wa mtandao");
    } on HttpException {
      throw ApiException("Hitilafu ya seva");
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
    } on SocketException {
      throw ApiException("Hakuna muunganisho wa mtandao");
    } on HttpException {
      throw ApiException("Hitilafu ya seva");
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
    } on SocketException {
      throw ApiException("Hakuna muunganisho wa mtandao");
    } on HttpException {
      throw ApiException("Hitilafu ya seva");
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
    } on SocketException {
      throw ApiException("Hakuna muunganisho wa mtandao");
    } on HttpException {
      throw ApiException("Hitilafu ya seva");
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
        throw ApiException("Hitilafu ya seva ya ndani");
      default:
        throw ApiException("Hitilafu isiyojulikana: ${response.statusCode}");
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

  Future<Map<String, dynamic>> createDriver(
    final Map<String, dynamic> driverData,
  ) async =>
      _post("/admin/drivers", driverData);

  Future<Map<String, dynamic>> updateDriver(
    final String driverId,
    final Map<String, dynamic> driverData,
  ) async =>
      _put("/admin/drivers/$driverId", driverData);

  Future<Map<String, dynamic>> deleteDriver(final String driverId) async =>
      _delete("/admin/drivers/$driverId");

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
  Future<Map<String, dynamic>> getPaymentReceiptPreview(String receiptId) async =>
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
