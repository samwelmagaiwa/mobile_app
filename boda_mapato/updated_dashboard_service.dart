import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_dynamic_calls, avoid_catches_without_on_clauses

class DashboardService {
  static const String baseUrl = 'http://your-laravel-backend.com/api/admin';
  
  // Headers for authenticated requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add your authentication token here
    'Authorization': 'Bearer ${getAuthToken()}', // Replace with actual token logic
  };
  
  static String getAuthToken() {
    // Replace this with your actual token retrieval logic
    // e.g., from SharedPreferences, secure storage, etc.
    return 'your_auth_token_here';
  }

  /// Get comprehensive dashboard data in a single API call (Recommended)
  /// This is the most efficient approach as it fetches all data with one request
  static Future<Map<String, dynamic>> getComprehensiveDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/comprehensive'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          return data['data']; // Returns the complete dashboard data object
        } else {
          throw Exception(data['message'] ?? 'Failed to load dashboard data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Individual endpoint methods (Alternative approach if you prefer separate calls)
  
  static Future<int> getActiveDriversCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/active-drivers-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching active drivers count: $e');
      }
      return 0;
    }
  }

  static Future<int> getActiveDevicesCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/active-devices-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching active devices count: $e');
      }
      return 0;
    }
  }

  static Future<int> getUnpaidDebtsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/unpaid-debts-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching unpaid debts count: $e');
      }
      return 0;
    }
  }

  static Future<int> getGeneratedReceiptsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/generated-receipts-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching generated receipts count: $e');
      }
      return 0;
    }
  }

  static Future<int> getPendingReceiptsCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/pending-receipts-count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching pending receipts count: $e');
      }
      return 0;
    }
  }

  static Future<double> getDailyRevenue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/daily-revenue'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['revenue'] ?? 0.0).toDouble();
        }
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching daily revenue: $e');
      }
      return 0.0;
    }
  }

  static Future<double> getWeeklyRevenue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/weekly-revenue'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['revenue'] ?? 0.0).toDouble();
        }
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching weekly revenue: $e');
      }
      return 0.0;
    }
  }

  static Future<double> getMonthlyRevenue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/monthly-revenue'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['revenue'] ?? 0.0).toDouble();
        }
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching monthly revenue: $e');
      }
      return 0.0;
    }
  }
}

/// Dashboard data model to structure the comprehensive response
class DashboardData {

  DashboardData({
    required this.unpaidDebtsCount,
    required this.activeDevicesCount,
    required this.activeDriversCount,
    required this.generatedReceiptsCount,
    required this.pendingReceiptsCount,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      unpaidDebtsCount: (json['unpaid_debts_count'] ?? 0).toInt(),
      activeDevicesCount: (json['active_devices_count'] ?? 0).toInt(),
      activeDriversCount: (json['active_drivers_count'] ?? 0).toInt(),
      generatedReceiptsCount: (json['generated_receipts_count'] ?? 0).toInt(),
      pendingReceiptsCount: (json['pending_receipts_count'] ?? 0).toInt(),
      dailyRevenue: (json['daily_revenue'] ?? 0.0).toDouble(),
      weeklyRevenue: (json['weekly_revenue'] ?? 0.0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0.0).toDouble(),
    );
  }
  final int unpaidDebtsCount;
  final int activeDevicesCount;
  final int activeDriversCount;
  final int generatedReceiptsCount;
  final int pendingReceiptsCount;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;

  Map<String, dynamic> toJson() {
    return {
      'unpaid_debts_count': unpaidDebtsCount,
      'active_devices_count': activeDevicesCount,
      'active_drivers_count': activeDriversCount,
      'generated_receipts_count': generatedReceiptsCount,
      'pending_receipts_count': pendingReceiptsCount,
      'daily_revenue': dailyRevenue,
      'weekly_revenue': weeklyRevenue,
      'monthly_revenue': monthlyRevenue,
    };
  }
}

/// Usage example for the dashboard screen:
/*

// In your Flutter dashboard widget:

class ModernDashboard extends StatefulWidget {
  @override
  _ModernDashboardState createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> {
  DashboardData? dashboardData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Method 1: Use comprehensive endpoint (Recommended)
      final data = await DashboardService.getComprehensiveDashboardData();
      setState(() {
        dashboardData = DashboardData.fromJson(data);
        isLoading = false;
      });

      // Method 2: Individual calls (Alternative)
      /*
      final activeDrivers = await DashboardService.getActiveDriversCount();
      final activeDevices = await DashboardService.getActiveDevicesCount();
      final unpaidDebts = await DashboardService.getUnpaidDebtsCount();
      final generatedReceipts = await DashboardService.getGeneratedReceiptsCount();
      final pendingReceipts = await DashboardService.getPendingReceiptsCount();
      final dailyRevenue = await DashboardService.getDailyRevenue();
      final weeklyRevenue = await DashboardService.getWeeklyRevenue();
      final monthlyRevenue = await DashboardService.getMonthlyRevenue();

      setState(() {
        dashboardData = DashboardData(
          activeDriversCount: activeDrivers,
          activeDevicesCount: activeDevices,
          unpaidDebtsCount: unpaidDebts,
          generatedReceiptsCount: generatedReceipts,
          pendingReceiptsCount: pendingReceipts,
          dailyRevenue: dailyRevenue,
          weeklyRevenue: weeklyRevenue,
          monthlyRevenue: monthlyRevenue,
        );
        isLoading = false;
      });
      */

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: loadDashboardData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (dashboardData == null) {
      return Center(child: Text('No data available'));
    }

    // Use dashboardData to display your dashboard cards
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Your existing dashboard UI using dashboardData.activeDriversCount, etc.
          DashboardCard(
            title: 'Madereva Hai',
            value: dashboardData!.activeDriversCount.toString(),
            color: Colors.blue,
          ),
          DashboardCard(
            title: 'Vyombo vya Usafiri',
            value: dashboardData!.activeDevicesCount.toString(),
            color: Colors.green,
          ),
          // ... more cards
        ],
      ),
    );
  }
}

*/