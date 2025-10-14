/// Application configuration for different environments
/// This file manages the app behavior in different modes
library;

import '../services/api_service.dart';

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

/// Service locator for API services (always returns real ApiService)
class ServiceLocator {
  static ApiService? _realApiService;

  /// Get API service
  static ApiService getApiService() {
    return _realApiService ??= ApiService();
  }

  /// Reset services (useful for testing)
  static void reset() {
    _realApiService = null;
  }
}
