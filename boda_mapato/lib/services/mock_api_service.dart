import 'dart:async';
import 'dart:math';

/// Mock API service for development without backend server
/// This service provides realistic mock data for the app
class MockApiService {
  // Simulate network delay
  static const Duration _networkDelay = Duration(milliseconds: 500);

  /// Generate mock dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    await Future.delayed(_networkDelay);
    
    final Random random = Random();
    
    return {
      "success": true,
      "data": {
        "active_drivers": 15 + random.nextInt(10),
        "total_drivers": 25 + random.nextInt(5),
        "active_vehicles": 12 + random.nextInt(8),
        "total_vehicles": 20 + random.nextInt(5),
        "monthly_revenue": 2500000 + random.nextInt(1000000),
        "pending_payments": 3 + random.nextInt(5),
        "driver_growth": 12.5 + (random.nextDouble() * 10),
        "vehicle_utilization": 85.0 + (random.nextDouble() * 10),
        "revenue_growth": 15.2 + (random.nextDouble() * 10),
        "recent_transactions": [
          {
            "id": "TXN001",
            "driver_name": "Juma Mwalimu",
            "vehicle_number": "T123ABC",
            "amount": 25000 + random.nextInt(50000),
            "status": "paid",
            "date": DateTime.now().subtract(const Duration(hours: 2)),
            "type": "daily_fee"
          },
          {
            "id": "TXN002", 
            "driver_name": "Fatuma Hassan",
            "vehicle_number": "T456DEF",
            "amount": 30000 + random.nextInt(40000),
            "status": "pending",
            "date": DateTime.now().subtract(const Duration(hours: 5)),
            "type": "daily_fee"
          },
          {
            "id": "TXN003",
            "driver_name": "Mohamed Ali",
            "vehicle_number": "T789GHI",
            "amount": 20000 + random.nextInt(35000),
            "status": "paid",
            "date": DateTime.now().subtract(const Duration(days: 1)),
            "type": "weekly_fee"
          }
        ]
      }
    };
  }

  /// Generate mock dashboard stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    await Future.delayed(_networkDelay);
    
    return {
      "success": true,
      "data": {
        "total_revenue": 15000000,
        "total_drivers": 30,
        "total_vehicles": 25,
        "active_sessions": 18
      }
    };
  }

  /// Generate mock revenue chart data
  static Future<List<dynamic>> getRevenueChart({int days = 30}) async {
    await Future.delayed(_networkDelay);
    
    final List<dynamic> chartData = [];
    final Random random = Random();
    
    for (int i = days; i >= 0; i--) {
      final DateTime date = DateTime.now().subtract(Duration(days: i));
      chartData.add({
        "date": date.toIso8601String(),
        "revenue": 50000 + random.nextInt(200000),
        "transactions": 5 + random.nextInt(15)
      });
    }
    
    return chartData;
  }

  /// Mock login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await Future.delayed(_networkDelay);
    
    // Simulate login validation
    if (email.contains('@') && password.length >= 6) {
      return {
        "success": true,
        "token": "mock_token_${DateTime.now().millisecondsSinceEpoch}",
        "user": {
          "id": 1,
          "name": "Admin Mkuu",
          "email": email,
          "role": "admin",
          "phone": phoneNumber ?? "+255 123 456 789"
        },
        "message": "Umeingia kikamilifu"
      };
    } else {
      throw MockApiException("Barua pepe au neno la siri si sahihi");
    }
  }

  /// Mock current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    await Future.delayed(_networkDelay);
    
    return {
      "success": true,
      "user": {
        "id": 1,
        "name": "Admin Mkuu",
        "email": "admin@bodamapato.com",
        "role": "admin", 
        "phone": "+255 123 456 789"
      }
    };
  }

  /// Mock drivers list
  static Future<Map<String, dynamic>> getDrivers({
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(_networkDelay);
    
    final List<Map<String, dynamic>> drivers = [
      {
        "id": 1,
        "name": "Juma Mwalimu",
        "phone": "+255 123 456 789",
        "license_number": "LIC001",
        "status": "active",
        "vehicle": "T123ABC"
      },
      {
        "id": 2,
        "name": "Fatuma Hassan",
        "phone": "+255 987 654 321", 
        "license_number": "LIC002",
        "status": "active",
        "vehicle": "T456DEF"
      },
      {
        "id": 3,
        "name": "Mohamed Ali",
        "phone": "+255 555 123 456",
        "license_number": "LIC003", 
        "status": "inactive",
        "vehicle": null
      }
    ];
    
    return {
      "success": true,
      "data": drivers,
      "meta": {
        "current_page": page,
        "last_page": 1,
        "per_page": limit,
        "total": drivers.length
      }
    };
  }

  /// Mock vehicles list
  static Future<Map<String, dynamic>> getVehicles({
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(_networkDelay);
    
    final List<Map<String, dynamic>> vehicles = [
      {
        "id": 1,
        "registration_number": "T123ABC",
        "make": "Bajaj",
        "model": "Boxer 150",
        "year": 2022,
        "status": "active",
        "driver": "Juma Mwalimu"
      },
      {
        "id": 2,
        "registration_number": "T456DEF",
        "make": "TVS",
        "model": "Apache 160",
        "year": 2021,
        "status": "active", 
        "driver": "Fatuma Hassan"
      },
      {
        "id": 3,
        "registration_number": "T789GHI",
        "make": "Honda",
        "model": "CB 125",
        "year": 2020,
        "status": "maintenance",
        "driver": null
      }
    ];
    
    return {
      "success": true,
      "data": vehicles,
      "meta": {
        "current_page": page,
        "last_page": 1,
        "per_page": limit,
        "total": vehicles.length
      }
    };
  }

  /// Mock payments list
  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(_networkDelay);
    
    final Random random = Random();
    final List<Map<String, dynamic>> payments = List.generate(10, (index) {
      return {
        "id": "PAY${(index + 1).toString().padLeft(3, '0')}",
        "driver_name": [
          "Juma Mwalimu",
          "Fatuma Hassan", 
          "Mohamed Ali",
          "Amina Juma",
          "Hassan Mwangi"
        ][index % 5],
        "vehicle_number": "T${(123 + index).toString()}ABC",
        "amount": 20000 + random.nextInt(50000),
        "payment_date": DateTime.now().subtract(Duration(days: index)),
        "status": ["paid", "pending", "overdue"][index % 3],
        "type": ["daily_fee", "weekly_fee", "monthly_fee"][index % 3]
      };
    });
    
    return {
      "success": true,
      "data": payments,
      "meta": {
        "current_page": page,
        "last_page": 1,
        "per_page": limit,
        "total": payments.length
      }
    };
  }

  /// Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    await Future.delayed(_networkDelay);
    
    return {
      "success": true,
      "status": "healthy",
      "message": "Mock API is running",
      "timestamp": DateTime.now().toIso8601String()
    };
  }

  /// Test connection
  static Future<Map<String, dynamic>> testConnection() async {
    await Future.delayed(_networkDelay);
    
    return {
      "success": true,
      "message": "Mock connection successful",
      "version": "1.0.0-mock"
    };
  }
}

/// Mock API Exception
class MockApiException implements Exception {
  MockApiException(this.message);
  final String message;

  @override
  String toString() => "MockApiException: $message";
}