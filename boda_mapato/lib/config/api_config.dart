/// API Configuration for different environments
/// This file manages API endpoints for the Boda Mapato app
library;

import "package:http/http.dart" as http;

mixin ApiConfig {
  // Environment enum
  static const String _environment =
      Environment.network; // Use "network" for mobile device testing

  // Get base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.local:
        return "http://127.0.1:8000/api";
      case Environment.network:
        return "http://192.168.1.124:8000/api";
      case Environment.emulator:
        return "http://10.2.2:8000/api";
      case Environment.production:
        return "https://yourdomain.com/api";
      default:
        return "http://127.0.1:8000/api";
    }
  }

  // Get web base URL (without /api)
  static String get webBaseUrl {
    switch (_environment) {
      case Environment.local:
        return "http://127.0.1:8000";
      case Environment.network:
        return "http://192.168.1.124:8000";
      case Environment.emulator:
        return "http://10.2.2:8000";
      case Environment.production:
        return "https://yourdomain.com";
      default:
        return "http://127.0.1:8000";
    }
  }

  // Connection timeout
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  // Test connectivity
  static Future<bool> testConnectivity() async {
    try {
      final http.Response response = await http
          .get(
            Uri.parse("$baseUrl/health"),
            headers: headers,
          )
          .timeout(timeoutDuration);

      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }
}

// Environment constants
mixin Environment {
  // 127.0.1:8000 - for desktop/web development
  static const String local = "local";
  // 192.168.1.5:8000 - for real device testing
  static const String network = "network";
  // 10.2.2:8000 - for Android emulator
  static const String emulator = "emulator";
  // production server
  static const String production = "production";
}
