/// User permissions model for role-based access control
class UserPermissions {
  final List<String> _permissions;
  final String? role;

  const UserPermissions({
    List<String>? permissions,
    this.role,
  }) : _permissions = permissions ?? const [];

  /// Create empty permissions (most restrictive)
  const UserPermissions.empty() : this();

  /// Create permissions from role
  UserPermissions.fromRole(String userRole) 
    : role = userRole,
      _permissions = _getPermissionsForRole(userRole);

  /// Create permissions from explicit list
  const UserPermissions.fromList(List<String> permissions)
    : _permissions = permissions,
      role = null;

  /// Check if user has a specific permission
  bool has(String permission) {
    return _permissions.contains(permission);
  }

  /// Check if user has all of the given permissions
  bool hasAll(List<String> permissions) {
    return permissions.every((permission) => _permissions.contains(permission));
  }

  /// Check if user has any of the given permissions
  bool hasAny(List<String> permissions) {
    return permissions.any((permission) => _permissions.contains(permission));
  }

  /// Get all permissions as a list
  List<String> get all => List.unmodifiable(_permissions);

  /// Check if user is an admin
  bool get isAdmin => role?.toLowerCase() == 'admin' || role?.toLowerCase() == 'administrator';

  /// Check if user is a manager
  bool get isManager => role?.toLowerCase() == 'manager';

  /// Check if user is an operator
  bool get isOperator => role?.toLowerCase() == 'operator';

  /// Check if user is a viewer
  bool get isViewer => role?.toLowerCase() == 'viewer';

  /// Check if permissions are empty
  bool get isEmpty => _permissions.isEmpty;

  /// Check if permissions are not empty
  bool get isNotEmpty => _permissions.isNotEmpty;

  @override
  String toString() {
    return 'UserPermissions(role: $role, permissions: $_permissions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPermissions &&
        other.role == role &&
        _listEquals(other._permissions, _permissions);
  }

  @override
  int get hashCode => role.hashCode ^ _permissions.hashCode;

  /// Helper method to get permissions for a role
  static List<String> _getPermissionsForRole(String userRole) {
    switch (userRole.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const [
          'view_drivers',
          'manage_drivers',
          'view_vehicles',
          'manage_vehicles',
          'view_payments',
          'manage_payments',
          'view_debts',
          'manage_debts',
          'view_analytics',
          'view_reports',
          'generate_reports',
          'view_reminders',
          'manage_reminders',
          'view_communications',
          'manage_communications',
          'generate_receipts',
          'manage_settings',
        ];
      case 'manager':
        return const [
          'view_drivers',
          'view_vehicles',
          'view_payments',
          'manage_payments',
          'view_debts',
          'manage_debts',
          'view_analytics',
          'view_reports',
          'view_reminders',
          'view_communications',
          'generate_receipts',
        ];
      case 'operator':
        return const [
          'view_drivers',
          'view_vehicles',
          'view_payments',
          'view_debts',
          'generate_receipts',
        ];
      case 'viewer':
        return const [
          'view_drivers',
          'view_vehicles',
          'view_payments',
          'view_reports',
        ];
      default:
        return const []; // No permissions for unknown roles
    }
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Extension on UserData to add permissions
extension UserDataPermissions on dynamic {
  /// Get user permissions from user data
  UserPermissions get permissions {
    // Try to get role from user data
    if (this is Map && this['role'] != null) {
      return UserPermissions.fromRole(this['role'].toString());
    }
    
    // Try to get explicit permissions from user data
    if (this is Map && this['permissions'] != null && this['permissions'] is List) {
      return UserPermissions.fromList(
        List<String>.from(this['permissions']),
      );
    }
    
    // Default to admin for now (you can change this based on your needs)
    return UserPermissions.fromRole('admin');
  }
}