import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/login_response.dart';

class AuthProvider extends ChangeNotifier {
  UserData? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _errorMessage;


  // Getters
  UserData? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage;


  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        final userData = await AuthService.getUserData();
        if (userData != null) {
          _user = UserData.fromJson(userData);
        }
        // Validate token
        final isValid = await AuthService.validateToken();
        if (!isValid) {
          await logout();
        }
      }
    } catch (e) {
      _setError('Failed to initialize auth: $e');
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
      final response = await AuthService.login(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      
      // Extract user data from response
      if (response['data'] != null) {
        if (response['data']['user'] != null) {
          _user = UserData.fromJson(response['data']['user']);
        }
        if (response['data']['token'] != null) {
          await AuthService.saveToken(response['data']['token']);
        }
      } else {
        // Handle different response structure
        if (response['user'] != null) {
          _user = UserData.fromJson(response['user']);
        }
        if (response['token'] != null) {
          await AuthService.saveToken(response['token']);
        }
      }
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
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
      final response = await AuthService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
      
      _user = response['user'];
      _isAuthenticated = true;
      
      notifyListeners();
      return true;
    } catch (e) {
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
    } catch (e) {
      // Continue with logout even if server request fails
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _isAuthenticated = false;
      _clearError();
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;
    
    try {
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        _user = UserData.fromJson(userData);
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    final String? name,
    final String? email,
    final String? phone,
  }) async {
    if (!_isAuthenticated || _user == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement API call to update profile
      // For now, just update local data
      final updatedUserData = <String, Object?>{
        'id': _user!.id,
        'name': name ?? _user!.name,
        'email': email ?? _user!.email,
        'phone_number': phone ?? _user!.phoneNumber,
        'role': _user!.role,
        'is_active': _user!.isActive,
      };
      
      await AuthService.saveUserData(updatedUserData);
      _user = UserData.fromJson(updatedUserData);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
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
    if (!_isAuthenticated) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement API call to change password
      // This would typically involve sending current and new passwords to the server
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      _setError('Failed to change password: $e');
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
    } catch (e) {
      _setError('Failed to send reset email: $e');
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
    } catch (e) {
      _setError('Failed to reset password: $e');
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
    if (_user == null) return 'Guest';
    return _user!.name.isNotEmpty ? _user!.name : _user!.email;
  }

  // Get user email
  String get userEmail {
    if (_user == null) return '';
    return _user!.email;
  }

  // Get user phone
  String get userPhone {
    if (_user == null) return '';
    return _user!.phoneNumber ?? '';
  }

  // Check if user has specific role
  bool hasRole(final String role) {
    if (_user == null) return false;
    return _user!.role == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole("admin");

  // Check if user is driver
  bool get isDriver => hasRole("driver");
}