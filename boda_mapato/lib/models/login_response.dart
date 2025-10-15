class LoginResponse {
  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(final Map<String, dynamic> json) =>
      LoginResponse(
        status: (json["status"] as String?) ?? "",
        message: (json["message"] as String?) ?? "",
        data: json["data"] != null
            ? LoginData.fromJson(
                json["data"] as Map<String, dynamic>,
              )
            : null,
      );
  final String status;
  final String message;
  final LoginData? data;

  bool get isSuccess => status == "success";
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
        userId: json["user_id"] as String?,
        token: json["token"] as String?,
        user: json["user"] != null
            ? UserData.fromJson(
                json["user"] as Map<String, dynamic>,
              )
            : null,
        role: json["role"] as String?,
        dashboardRoute: json["dashboard_route"] as String?,
        expiresInMinutes: json["expires_in_minutes"] as int?,
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
    required this.role,
    required this.isActive,
    this.phoneNumber,
    this.deviceId,
    this.lastLoginAt,
    this.driver,
    this.assignedDevice,
    this.avatarUrl,
  });

  factory UserData.fromJson(final Map<String, dynamic> json) => UserData(
        id: (json["id"] as String?) ?? "",
        name: (json["name"] as String?) ?? "",
        email: (json["email"] as String?) ?? "",
        phoneNumber: json["phone_number"] as String?,
        role: (json["role"] as String?) ?? "driver",
        isActive: (json["is_active"] as bool?) ?? true,
        deviceId: json["device_id"] as String?,
        lastLoginAt: json["last_login_at"] != null
            ? DateTime.parse(json["last_login_at"] as String)
            : null,
        driver: json["driver"] != null
            ? DriverData.fromJson(
                json["driver"] as Map<String, dynamic>,
              )
            : null,
        assignedDevice: json["assigned_device"] != null
            ? DeviceData.fromJson(
                json["assigned_device"] as Map<String, dynamic>,
              )
            : null,
        // Flexible avatar/profile image keys from backend
        avatarUrl: _pickAvatarUrl(json),
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
  final String? avatarUrl;

  bool get isSuperAdmin => role == "super_admin";
  bool get isAdmin => role == "admin";
  bool get isDriver => role == "driver";
  bool get canManageDrivers => isSuperAdmin || isAdmin;

  static String? _pickAvatarUrl(Map<String, dynamic> json) {
    final List<String> keys = <String>[
      'avatar_url',
      'avatar',
      'profile_image_url',
      'profile_image',
      'profile_photo_url',
      'photo_url',
      'image_url',
    ];
    for (final String k in keys) {
      final dynamic v = json[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

class DriverData {
  DriverData({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.isActive,
    required this.rating,
    required this.totalTrips,
    required this.totalEarnings,
    this.address,
    this.emergencyContact,
  });

  factory DriverData.fromJson(final Map<String, dynamic> json) => DriverData(
        id: (json["id"] as String?) ?? "",
        userId: (json["user_id"] as String?) ?? "",
        licenseNumber: (json["license_number"] as String?) ?? "",
        licenseExpiry: DateTime.parse(
          (json["license_expiry"] as String?) ??
              DateTime.now().toIso8601String(),
        ),
        address: json["address"] as String?,
        emergencyContact: json["emergency_contact"] as String?,
        isActive: (json["is_active"] as bool?) ?? true,
        rating: ((json["rating"] as num?) ?? 0).toDouble(),
        totalTrips: (json["total_trips"] as int?) ?? 0,
        totalEarnings: ((json["total_earnings"] as num?) ?? 0).toDouble(),
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
    required this.isActive,
    this.description,
  });

  factory DeviceData.fromJson(final Map<String, dynamic> json) => DeviceData(
        id: (json["id"] as String?) ?? "",
        name: (json["name"] as String?) ?? "",
        type: (json["type"] as String?) ?? "",
        plateNumber: (json["plate_number"] as String?) ?? "",
        description: json["description"] as String?,
        isActive: (json["is_active"] as bool?) ?? true,
      );
  final String id;
  final String name;
  final String type;
  final String plateNumber;
  final String? description;
  final bool isActive;
}
