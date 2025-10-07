class LoginResponse {

  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(final Map<String, dynamic> json) => LoginResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  final String status;
  final String message;
  final LoginData? data;

  bool get isSuccess => status == 'success';
}

class LoginData {

  LoginData({
    this.userId,
    this.token,
    this.user,
    this.role,
    this.dashboardRoute,
    this.expiresInMinutes,
  });

  factory LoginData.fromJson(final Map<String, dynamic> json) => LoginData(
      userId: json['user_id'],
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      role: json['role'],
      dashboardRoute: json['dashboard_route'],
      expiresInMinutes: json['expires_in_minutes'],
    );
  final String? userId;
  final String? token;
  final UserData? user;
  final String? role;
  final String? dashboardRoute;
  final int? expiresInMinutes;
}

class UserData {

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role, required this.isActive, this.phoneNumber,
    this.deviceId,
    this.lastLoginAt,
    this.driver,
    this.assignedDevice,
  });

  factory UserData.fromJson(final Map<String, dynamic> json) => UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'driver',
      isActive: json['is_active'] ?? true,
      deviceId: json['device_id'],
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      driver: json['driver'] != null 
          ? DriverData.fromJson(json['driver']) 
          : null,
      assignedDevice: json['assigned_device'] != null 
          ? DeviceData.fromJson(json['assigned_device']) 
          : null,
    );
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final String? deviceId;
  final DateTime? lastLoginAt;
  final DriverData? driver;
  final DeviceData? assignedDevice;

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver';
  bool get canManageDrivers => isSuperAdmin || isAdmin;
}

class DriverData {

  DriverData({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.isActive, required this.rating, required this.totalTrips, required this.totalEarnings, this.address,
    this.emergencyContact,
  });

  factory DriverData.fromJson(final Map<String, dynamic> json) => DriverData(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseExpiry: DateTime.parse(json['license_expiry']),
      address: json['address'],
      emergencyContact: json['emergency_contact'],
      isActive: json['is_active'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['total_trips'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
    );
  final String id;
  final String userId;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String? address;
  final String? emergencyContact;
  final bool isActive;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
}

class DeviceData {

  DeviceData({
    required this.id,
    required this.name,
    required this.type,
    required this.plateNumber,
    required this.isActive, this.description,
  });

  factory DeviceData.fromJson(final Map<String, dynamic> json) => DeviceData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  final String id;
  final String name;
  final String type;
  final String plateNumber;
  final String? description;
  final bool isActive;
}