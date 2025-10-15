import 'package:flutter/material.dart';

/// Represents a single navigation item with its properties
class NavigationItem {
  final String key;
  final IconData icon;
  final String route;
  final List<String>? requiredPermissions;
  final String? badgeKey; // Key to get badge count from dashboard data
  final Color? badgeColor;
  final bool isSystemItem; // For items like settings, logout that appear in all roles

  const NavigationItem({
    required this.key,
    required this.icon,
    required this.route,
    this.requiredPermissions,
    this.badgeKey,
    this.badgeColor,
    this.isSystemItem = false,
  });
}

/// Represents a quick action item for dashboard
class QuickActionItem {
  final String key;
  final IconData icon;
  final String route;
  final List<String>? requiredPermissions;
  final VoidCallback? customAction;
  final bool isHighlighted; // For special styling

  const QuickActionItem({
    required this.key,
    required this.icon,
    required this.route,
    this.requiredPermissions,
    this.customAction,
    this.isHighlighted = false,
  });
}

/// Central configuration for all navigation items
class NavigationConfig {
  // Main drawer navigation items
  static const List<NavigationItem> drawerItems = [
    NavigationItem(
      key: 'dashboard',
      icon: Icons.dashboard,
      route: '/dashboard',
      isSystemItem: true, // Always visible
    ),
    NavigationItem(
      key: 'drivers',
      icon: Icons.people,
      route: '/admin/drivers',
      requiredPermissions: ['view_drivers'],
      badgeKey: 'drivers',
    ),
    NavigationItem(
      key: 'vehicles',
      icon: Icons.directions_car,
      route: '/admin/vehicles',
      requiredPermissions: ['view_vehicles'],
      badgeKey: 'vehicles',
    ),
    NavigationItem(
      key: 'payments',
      icon: Icons.payment,
      route: '/payments',
      requiredPermissions: ['view_payments'],
      badgeKey: 'payments',
      badgeColor: Colors.red,
    ),
    NavigationItem(
      key: 'debt_records',
      icon: Icons.assignment_turned_in,
      route: '/admin/debts',
      requiredPermissions: ['view_debts'],
    ),
    NavigationItem(
      key: 'analytics',
      icon: Icons.analytics,
      route: '/admin/analytics',
      requiredPermissions: ['view_analytics'],
    ),
    NavigationItem(
      key: 'reports',
      icon: Icons.receipt_long,
      route: '/admin/reports',
      requiredPermissions: ['view_reports'],
    ),
    NavigationItem(
      key: 'reminders',
      icon: Icons.notifications,
      route: '/admin/reminders',
      requiredPermissions: ['view_reminders'],
      badgeKey: 'reminders',
      badgeColor: Colors.orange,
    ),
    NavigationItem(
      key: 'communications',
      icon: Icons.chat,
      route: '/admin/communications',
      requiredPermissions: ['view_communications'],
    ),
  ];

  // System navigation items (always visible)
  static const List<NavigationItem> systemItems = [
    NavigationItem(
      key: 'settings',
      icon: Icons.settings,
      route: '/settings',
      isSystemItem: true,
    ),
    NavigationItem(
      key: 'logout',
      icon: Icons.logout,
      route: '/logout', // Special route handled separately
      isSystemItem: true,
    ),
  ];

  // Quick action items for dashboard
  static const List<QuickActionItem> quickActions = [
    QuickActionItem(
      key: 'analytics',
      icon: Icons.bar_chart,
      route: '/admin/analytics',
      requiredPermissions: ['view_analytics'],
    ),
    QuickActionItem(
      key: 'menu',
      icon: Icons.apps,
      route: '/menu', // Special action to open drawer
      isHighlighted: true,
    ),
    QuickActionItem(
      key: 'receipts',
      icon: Icons.receipt_long,
      route: '/receipts',
      requiredPermissions: ['generate_receipts'],
    ),
    QuickActionItem(
      key: 'reports',
      icon: Icons.receipt,
      route: '/admin/reports',
      requiredPermissions: ['view_reports'],
    ),
    QuickActionItem(
      key: 'settings',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  /// Get all navigation items (drawer + system)
  static List<NavigationItem> get allNavigationItems {
    return [...drawerItems, ...systemItems];
  }

  /// Get navigation items by permission level
  static List<NavigationItem> getItemsByPermissions(List<String> userPermissions) {
    return allNavigationItems.where((item) {
      if (item.isSystemItem) return true;
      if (item.requiredPermissions == null) return true;
      
      return item.requiredPermissions!.every(
        (permission) => userPermissions.contains(permission),
      );
    }).toList();
  }

  /// Get quick actions by permission level
  static List<QuickActionItem> getQuickActionsByPermissions(List<String> userPermissions) {
    return quickActions.where((action) {
      if (action.requiredPermissions == null) return true;
      
      return action.requiredPermissions!.every(
        (permission) => userPermissions.contains(permission),
      );
    }).toList();
  }
}

/// Default permission sets for different user roles
class DefaultPermissions {
  static const List<String> admin = [
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

  static const List<String> manager = [
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

  static const List<String> operator = [
    'view_drivers',
    'view_vehicles',
    'view_payments',
    'view_debts',
    'generate_receipts',
  ];

  static const List<String> viewer = [
    'view_drivers',
    'view_vehicles',
    'view_payments',
    'view_reports',
  ];

  /// Get permissions for a role
  static List<String> getPermissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return admin;
      case 'manager':
        return manager;
      case 'operator':
        return operator;
      case 'viewer':
        return viewer;
      default:
        return viewer; // Default to most restrictive
    }
  }
}