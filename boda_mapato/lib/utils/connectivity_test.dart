/// Connectivity test utilities for the Boda Mapato app
/// This file helps test API connectivity during development
library;

import "dart:convert";
import "dart:developer" as developer;
import "package:http/http.dart" as http;

class ConnectivityTest {
  // Test endpoints
  static const List<String> testUrls = <String>[
    "http://127.0.1:8000/api/health",
    "http://192.168.1.124:8000/api/health",
    "http://10.2.2:8000/api/health",
  ];

  static const Duration timeout = Duration(seconds: 10);

  /// Test all possible API endpoints
  static Future<Map<String, bool>> testAllEndpoints() async {
    final Map<String, bool> results = <String, bool>{};

    for (final String url in testUrls) {
      results[url] = await _testSingleEndpoint(url);
    }

    return results;
  }

  /// Test a single endpoint
  static Future<bool> _testSingleEndpoint(String url) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log("âœ… $url: ${data["message"] ?? "Connected"}");
        return true;
      } else {
        developer.log("âŒ $url: HTTP ${response.statusCode}");
        return false;
      }
    } on Exception catch (e) {
      developer.log("âŒ $url: Connection failed - $e");
      return false;
    }
  }

  /// Get the best working endpoint
  static Future<String?> getBestEndpoint() async {
    for (final String url in testUrls) {
      if (await _testSingleEndpoint(url)) {
        final String apiUrl = url.replaceAll("/health", "");
        developer.log("ðŸŽ¯ Using API endpoint: $apiUrl");
        return apiUrl;
      }
    }

    developer.log("âš ï¸ No working endpoints found");
    return null;
  }

  /// Test Laravel backend health
  static Future<Map<String, dynamic>?> testBackendHealth() async {
    try {
      final http.Response response = await http.get(
        Uri.parse("http://127.0.1:8000/api/health"),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        developer.log("ðŸ”¥ Backend Status: ${data["status"]}");
        developer.log("ðŸ“¡ API Message: ${data["message"]}");
        developer.log("â° Server Time: ${data["server_time"]}");
        developer.log("ðŸ˜ PHP Version: ${data["php_version"]}");
        return data;
      } else {
        developer
            .log("âŒ Backend health check failed: ${response.statusCode}");
        return null;
      }
    } on Exception catch (e) {
      developer.log("âŒ Backend health check error: $e");
      return null;
    }
  }

  /// Print connectivity report
  static Future<void> printConnectivityReport() async {
    developer.log("ðŸ” Starting Connectivity Test...");
    developer.log(
      "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”",
    );

    // Test backend health
    final Map<String, dynamic>? health = await testBackendHealth();

    if (health != null) {
      developer.log("âœ… Laravel Backend: ONLINE");
      developer.log("   ðŸ“ URL: http://127.0.1:8000");
      developer.log("   ðŸ”— API: http://127.0.1:8000/api");
      developer.log("   âš¡ Status: ${health["status"]}");
    } else {
      developer.log("âŒ Laravel Backend: OFFLINE");
      developer.log("   ðŸ’¡ Make sure to run: php artisan serve");
    }

    developer.log(
      "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”",
    );

    // Test all endpoints
    final Map<String, bool> results = await testAllEndpoints();

    developer.log("ðŸ“Š Endpoint Test Results:");
    results.forEach((String url, bool isWorking) {
      final String status = isWorking ? "âœ… WORKING" : "âŒ FAILED";
      developer.log("   $status: $url");
    });

    // Recommend best endpoint
    final String? bestEndpoint = await getBestEndpoint();
    if (bestEndpoint != null) {
      developer.log(
        "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”",
      );
      developer.log("ðŸŽ¯ RECOMMENDED API URL: $bestEndpoint");
      developer.log("ðŸ’¡ Update your ApiConfig._environment accordingly");
    } else {
      developer.log(
        "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”",
      );
      developer.log("âš ï¸ WARNING: No working endpoints found!");
      developer.log("ðŸ’¡ Please start your Laravel backend:");
      developer.log("   cd ../backend_mapato && php artisan serve");
    }

    developer.log(
      "â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”",
    );
  }
}
