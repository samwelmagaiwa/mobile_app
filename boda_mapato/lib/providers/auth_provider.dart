import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/login_response.dart';
import '../services/api_service.dart';
import '../services/app_messenger.dart';
import '../services/auth_events.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Listen for global unauthorized events
    _authSub = AuthEvents.instance.stream.listen((event) async {
      if (event == AuthEvent.unauthorized) {
        await _handleUnauthorized();
      }
    });
  }

  UserData? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _errorMessage;

  late final StreamSubscription<AuthEvent> _authSub;

  // Getters
  UserData? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        final Map<String, dynamic>? userData = await AuthService.getUserData();
        if (userData != null) {
          _user = UserData.fromJson(userData);
        }
        // Validate token (non-destructive: avoid forced logout on transient errors)
        final bool isValid = await AuthService.validateToken();
        if (!isValid) {
          // Keep local session; real 401s from API calls will trigger a global unauthorized event
          // which clears auth safely via AuthEvents listener.
        }
      }
    } on Exception catch (e) {
      _setError("Failed to initialize auth: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Login (direct authentication)
  Future<bool> login({
    required final String email,
    required final String password,
    required final String phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Preflight connectivity check to provide a clear error if backend is unreachable
      final api = ApiService();
      final bool serverUp = await api.testConnectivity();
      if (!serverUp) {
        final String url = ApiService.baseUrl;
        final String msg = 'Seva haipatikani: ' + url + '/health. Hakikisha simu yako na kompyuta yako ziko kwenye mtandao mmoja na bandari 8000 inaruhusiwa.';
        _setError(msg);
        _errorMessage = msg;
        return false;
      }

      final Map<String, dynamic> response = await AuthService.login(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      // Extract token and optimistically save it
      final Map<String, dynamic>? responseData = response["data"] as Map<String, dynamic>?;
      final String? token = responseData != null
          ? responseData["token"] as String?
          : response["token"] as String?;
      if (token != null && token.isNotEmpty) {
        await AuthService.saveToken(token);
      }

      // Fetch fresh user profile from backend using the token we just saved
      final Map<String, dynamic>? freshUser = await AuthService.getCurrentUser();
      if (freshUser == null) {
        throw Exception("Imeshindikana kupata taarifa za mtumiaji baada ya kuingia.");
      }
      _user = UserData.fromJson(freshUser);

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError(e.toString());
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required final String name,
    required final String email,
    required final String password,
    required final String passwordConfirmation,
    final String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final Map<String, dynamic> response = await AuthService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );

      _user = response["user"];
      _isAuthenticated = true;

      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await AuthService.logout();
    } on Exception catch (e) {
      // Continue with logout even if server request fails
      debugPrint("Logout error: $e");
    } finally {
      _user = null;
      _isAuthenticated = false;
      _clearError();
      _setLoading(false);
    }
  }

  Future<void> _handleUnauthorized() async {
    try {
      await AuthService.clearAuthData();
    } on Exception {
      // ignore
    }
    _user = null;
    _isAuthenticated = false;
    _error = null;
    _errorMessage = null;
    notifyListeners();
    // Inform the user globally
    AppMessenger.show('Muda wa kikao umeisha, tafadhali ingia tena.');
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) {
      return;
    }

    try {
      final Map<String, dynamic>? userData = await AuthService.getCurrentUser();
      if (userData != null) {
        _user = UserData.fromJson(userData);
      }
      notifyListeners();
    } on Exception catch (e) {
      _setError("Failed to refresh user data: $e");
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    final String? name,
    final String? email,
    final String? phone,
  }) async {
    if (!_isAuthenticated || _user == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call backend to update profile
      final Map<String, dynamic> res = await AuthService.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );

      final Map<String, dynamic>? updated =
          res['user'] is Map ? Map<String, dynamic>.from(res['user']) : null;
      if (updated != null) {
        _user = UserData.fromJson(updated);
      } else if (_user != null) {
        // Fallback: locally merge
        final Map<String, Object?> updatedUserData = <String, Object?>{
          "id": _user!.id,
          "name": name ?? _user!.name,
          "email": email ?? _user!.email,
          "phone_number": phone ?? _user!.phoneNumber,
          "role": _user!.role,
          "is_active": _user!.isActive,
          if (_user!.avatarUrl != null) 'avatar_url': _user!.avatarUrl,
        };
        await AuthService.saveUserData(updatedUserData);
        _user = UserData.fromJson(updatedUserData);
      }

      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError("Failed to update profile: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile image (avatar)
  Future<bool> uploadProfileImage({
    required List<int> bytes,
    required String filename,
  }) async {
    if (!_isAuthenticated) return false;
    _setLoading(true);
    _clearError();
    try {
      final api = ApiService();
      final res = await api.uploadProfileImage(bytes: Uint8List.fromList(bytes), filename: filename);
      // Try to get updated user from response
      Map<String, dynamic>? updated;
      if (res['data'] is Map && (res['data'] as Map)['user'] is Map) {
        updated = Map<String, dynamic>.from((res['data'] as Map)['user'] as Map);
      } else if (res['user'] is Map) {
        updated = Map<String, dynamic>.from(res['user'] as Map);
      }
      if (updated != null) {
        _user = UserData.fromJson(updated);
        await AuthService.saveUserData(updated);
      }
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _setError("Failed to upload image: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required final String currentPassword,
    required final String newPassword,
    required final String confirmPassword,
  }) async {
    if (!_isAuthenticated) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on Exception catch (e) {
      _setError("Failed to change password: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Forgot password
  Future<bool> forgotPassword(final String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.forgotPassword(email);
      return true;
    } on Exception catch (e) {
      _setError("Failed to send reset email: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required final String email,
    required final String password,
    required final String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return true;
    } on Exception catch (e) {
      _setError("Failed to reset password: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(final bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(final String error) {
    _error = error;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Get user display name
  String get userDisplayName {
    if (_user == null) {
      return "Guest";
    }
    return _user!.name.isNotEmpty ? _user!.name : _user!.email;
  }

  // Get user email
  String get userEmail {
    if (_user == null) {
      return "";
    }
    return _user!.email;
  }

  // Get user phone
  String get userPhone {
    if (_user == null) {
      return "";
    }
    return _user!.phoneNumber ?? "";
  }

  // Check if user has specific role
  bool hasRole(final String role) {
    if (_user == null) {
      return false;
    }
    return _user!.role == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole("admin");

  // Check if user is driver
  bool get isDriver => hasRole("driver");
}
