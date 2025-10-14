import "dart:convert";
import "dart:developer" as developer;

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "../config/api_config.dart";

mixin AuthService {
  // API Configuration - Updated for Laravel backend
  // For mobile device testing via USB debugging on this PC (192.168.1.124)
  // Use centralized API configuration for consistency with ApiService
  static String get baseUrl => ApiConfig.baseUrl;

  // Alternative URLs for different environments:
  // For development on localhost: "http://127.0.1:8000/api"
  // For Android emulator: "http://10.2.2:8000/api"
  // For iOS simulator: "http://127.0.1:8000/api"

  static const Duration timeoutDuration = Duration(seconds: 30);
  static const String tokenKey = "auth_token";
  static const String userKey = "user_data";

  // Headers for API requests
  static Map<String, String> get _headers => <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  // Headers with authentication token
  static Future<Map<String, String>> get _authHeaders async {
    final String? token = await getToken();
    return <String, String>{
      ..._headers,
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(final http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(
        data["message"] ?? "Server error: ${response.statusCode}",
      );
    }
  }

  // Login method (direct authentication)
  static Future<Map<String, dynamic>> login({
    required final String email,
    required final String password,
    required final String phoneNumber,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: _headers,
            body: jsonEncode(<String, String>{
              "email": email,
              "password": password,
              "phone_number": phoneNumber,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);

      // Normalize response structure and persist
      final Map<String, dynamic>? dataMap =
          data["data"] is Map ? Map<String, dynamic>.from(data["data"]) : null;
      final String? token = (dataMap?['token'] ?? data['token']) as String?;
      final Map<String, dynamic>? user =
          (dataMap?['user'] ?? data['user']) is Map
              ? Map<String, dynamic>.from(dataMap?['user'] ?? data['user'])
              : null;

      if (token != null) {
        await saveToken(token);
      }
      if (user != null) {
        await saveUserData(user);
      }

      return data;
    } on Exception catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // Register method
  static Future<Map<String, dynamic>> register({
    required final String name,
    required final String email,
    required final String password,
    required final String passwordConfirmation,
    final String? phone,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/register"),
            headers: _headers,
            body: jsonEncode(<String, String>{
              "name": name,
              "email": email,
              "password": password,
              "password_confirmation": passwordConfirmation,
              if (phone != null) "phone": phone,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);

      // Save token and user data
      if (data["token"] != null) {
        await saveToken(data["token"]);
      }
      if (data["user"] != null) {
        await saveUserData(data["user"]);
      }

      return data;
    } on Exception catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  // Logout method
  static Future<void> logout() async {
    try {
      final Map<String, String> headers = await _authHeaders;
      await http
          .post(
            Uri.parse("$baseUrl/auth/logout"),
            headers: headers,
          )
          .timeout(timeoutDuration);
    } on Exception catch (e) {
      // Continue with local logout even if server request fails
      developer.log("Logout request failed: $e");
    } finally {
      // Clear local storage
      await clearAuthData();
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final Map<String, String> headers = await _authHeaders;
      final http.Response response = await http
          .get(
            Uri.parse("$baseUrl/auth/user"),
            headers: headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);

      // Update stored user data
      final Map<String, dynamic>? user =
          data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null;
      if (user != null) {
        await saveUserData(user);
      }

      return user;
    } on Exception catch (e) {
      throw Exception("Failed to get user data: $e");
    }
  }

  // Refresh token
  static Future<String?> refreshToken() async {
    try {
      final Map<String, String> headers = await _authHeaders;
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/refresh"),
            headers: headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);

      if (data["token"] != null) {
        await saveToken(data["token"]);
        return data["token"];
      }

      return null;
    } on Exception catch (e) {
      throw Exception("Token refresh failed: $e");
    }
  }

  // Forgot password
  static Future<Map<String, dynamic>> forgotPassword(final String email) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/forgot-password"),
            headers: _headers,
            body: jsonEncode(<String, String>{"email": email}),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);
      return data;
    } on Exception catch (e) {
      throw Exception("Forgot password request failed: $e");
    }
  }

  // Update profile
  static Future<Map<String, dynamic>> updateProfile({
    final String? name,
    final String? email,
    final String? phone,
  }) async {
    try {
      final Map<String, String> headers = await _authHeaders;
      final http.Response response = await http
          .put(
            Uri.parse("$baseUrl/auth/profile"),
            headers: headers,
            body: jsonEncode(<String, String?>{
              if (name != null) "name": name,
              if (email != null) "email": email,
              if (phone != null) "phone_number": phone,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);

      final Map<String, dynamic>? user =
          data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null;
      if (user != null) {
        await saveUserData(user);
      }

      return data;
    } on Exception catch (e) {
      throw Exception("Profile update failed: $e");
    }
  }

  // Change password
  static Future<void> changePassword({
    required final String currentPassword,
    required final String newPassword,
    required final String confirmPassword,
  }) async {
    try {
      final Map<String, String> headers = await _authHeaders;
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/change-password"),
            headers: headers,
            body: jsonEncode(<String, String>{
              "current_password": currentPassword,
              "password": newPassword,
              "password_confirmation": confirmPassword,
            }),
          )
          .timeout(timeoutDuration);

      _handleResponse(response);
    } on Exception catch (e) {
      throw Exception("Change password failed: $e");
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required final String email,
    required final String password,
    required final String passwordConfirmation,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse("$baseUrl/auth/reset-password"),
            headers: _headers,
            body: jsonEncode(<String, String>{
              "email": email,
              "password": password,
              "password_confirmation": passwordConfirmation,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _handleResponse(response);
      return data;
    } on Exception catch (e) {
      throw Exception("Password reset failed: $e");
    }
  }

  // Token management
  static Future<void> saveToken(final String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // User data management
  static Future<void> saveUserData(final Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  // Clear all auth data
  static Future<void> clearAuthData() async {
    await clearToken();
    await clearUserData();
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Validate token (check if it's still valid)
  static Future<bool> validateToken() async {
    try {
      await getCurrentUser();
      return true;
    } on Exception {
      return false;
    }
  }
}
