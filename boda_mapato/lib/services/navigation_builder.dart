import 'package:flutter/material.dart';
import '../config/navigation_config.dart';
import '../models/user_permissions.dart';
import '../services/localization_service.dart';
import '../screens/receipts/receipts_screen.dart';
import '../constants/theme_constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ignore_for_file: directives_ordering
/// Service for building navigation UI components dynamically
class NavigationBuilder {
  
  /// Build drawer navigation items
  static List<Widget> buildDrawerItems({
    required LocalizationService localization,
    required Map<String, dynamic> badges,
    required UserPermissions permissions,
    required BuildContext context,
    required VoidCallback onLogout,
  }) {
    final List<Widget> items = [];
    
    // Get available navigation items based on permissions
    final availableItems = NavigationConfig.drawerItems.where(
      (item) => _hasPermission(item, permissions),
    ).toList();

    // Add main navigation items
    for (final item in availableItems) {
      items.add(_buildDrawerItem(
        item: item,
        localization: localization,
        badges: badges,
        context: context,
      ));
    }

    // Add divider before system items
    if (availableItems.isNotEmpty) {
      items.add(const Divider(color: Color(0xB3FFFFFF)));
    }

    // Add system items (settings, logout)
    for (final item in NavigationConfig.systemItems) {
      if (item.key == 'logout') {
        items.add(_buildLogoutItem(
          localization: localization,
          onLogout: onLogout,
          context: context,
        ));
      } else {
        items.add(_buildDrawerItem(
          item: item,
          localization: localization,
          badges: badges,
          context: context,
        ));
      }
    }

    return items;
  }

  /// Build quick action buttons
  static List<Widget> buildQuickActions({
    required LocalizationService localization,
    required UserPermissions permissions,
    required BuildContext context,
  }) {
    final availableActions = NavigationConfig.quickActions.where(
      (action) => _hasPermissionForAction(action, permissions),
    ).toList();

    return availableActions.map((action) => _buildActionButton(
      action: action,
      localization: localization,
      context: context,
    )).toList();
  }

  /// Build individual drawer item
  static Widget _buildDrawerItem({
    required NavigationItem item,
    required LocalizationService localization,
    required Map<String, dynamic> badges,
    required BuildContext context,
  }) {
    final badgeCount = item.badgeKey != null ? badges[item.badgeKey] as int? ?? 0 : null;
    
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            item.icon,
            color: Colors.white,
            size: 24,
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: item.badgeColor ?? const Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        localization.translate(item.key),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (item.badgeColor ?? const Color(0xFFFF6B9D)).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (item.badgeColor ?? const Color(0xFFFF6B9D)).withOpacity(0.5),
                ),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  color: item.badgeColor ?? const Color(0xFFFF6B9D),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        // Close the drawer first, then navigate
        Navigator.pop(context);
        _navigateTo(item, context);
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );
  }

  /// Build logout item with special handling
  static Widget _buildLogoutItem({
    required LocalizationService localization,
    required VoidCallback onLogout,
    required BuildContext context,
  }) {
    return ListTile(
      leading: const Icon(
        Icons.logout,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        localization.translate('logout'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        // Confirm logout dialog (localized)
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            backgroundColor: ThemeConstants.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              localization.translate('logout'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            content: Text(
              localization.translate('logout_confirm'),
              style: const TextStyle(color: Colors.white70),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              // Cancel button (gray)
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(localization.translate('cancel')),
              ),
              // Yes button (red)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(localization.translate('yes')),
              ),
            ],
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );
  }

  /// Build individual quick action button
  static Widget _buildActionButton({
    required QuickActionItem action,
    required LocalizationService localization,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () => _handleQuickAction(action, context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight.isFinite ? constraints.maxHeight : 72;
          // Responsive sizing to avoid overflow in tight spaces
          double side = h * 0.55; // icon button side
          if (side < 32) side = 32;
          if (side > 44) side = 44;
          double iconSize = side * 0.55;
          if (iconSize < 16) iconSize = 16;
          if (iconSize > 24) iconSize = 24;
          double spacing = (h - side) * 0.25;
          if (spacing < 4) spacing = 4;
          if (spacing > 8) spacing = 8;
          double fontSize = (h - side) * 0.35 + 9.5; // ~10-12
          if (fontSize < 10) fontSize = 10;
          if (fontSize > 12) fontSize = 12;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  color: action.isHighlighted
                      ? const Color(0xFFFF6B9D)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(side / 2),
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(height: spacing),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth - 2),
                child: Text(
                  localization.translate(action.key),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xB3FFFFFF),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to a route represented by a NavigationItem (no popping assumptions)
  static void _navigateTo(NavigationItem item, BuildContext context) {
    if (item.route == '/dashboard') {
      // Already on dashboard, do nothing
      return;
    }
    Navigator.pushNamed(context, item.route);
  }

  /// Handle quick action taps
  static void _handleQuickAction(QuickActionItem action, BuildContext context) {
    if (action.customAction != null) {
      action.customAction!();
      return;
    }
    
    switch (action.route) {
      case '/menu':
        // Show drawer items as a 3-column grid menu on top of the main screen
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final String role = auth.user?.role ?? 'viewer';
        final perms = UserPermissions.fromRole(role);
        _showGridMenu(
          context: context,
          localization: LocalizationService.instance,
          permissions: perms,
        );
        return;
      case '/receipts':
        // Navigate to receipts screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReceiptsScreen(),
          ),
        );
        return;
      default:
        // Standard navigation
        Navigator.pushNamed(context, action.route);
        return;
    }
  }

  /// Present the drawer navigation options in a tabular (grid) format
  static Future<void> _showGridMenu({
    required BuildContext context,
    required LocalizationService localization,
    required UserPermissions permissions,
  }) async {
    // Include both main drawer items and system items (e.g., Settings) in the grid
    final items = <NavigationItem>[
      ...NavigationConfig.drawerItems,
      ...NavigationConfig.systemItems,
    ]
        // Exclude the logout action from the grid
        .where((item) => item.key != 'logout')
        .where((item) => _hasPermission(item, permissions))
        .toList();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localization.translate('menu') ?? 'Menu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MenuGridTile(
                    icon: item.icon,
                    label: localization.translate(item.key),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateTo(item, context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if user has permission for navigation item
  static bool _hasPermission(NavigationItem item, UserPermissions permissions) {
    if (item.isSystemItem) return true;
    if (item.requiredPermissions == null || item.requiredPermissions!.isEmpty) {
      return true;
    }
    return permissions.hasAll(item.requiredPermissions!);
  }

  /// Check if user has permission for quick action
  static bool _hasPermissionForAction(QuickActionItem action, UserPermissions permissions) {
    if (action.requiredPermissions == null || action.requiredPermissions!.isEmpty) {
      return true;
    }
    return permissions.hasAll(action.requiredPermissions!);
  }

  /// Get navigation items for current user
  static List<NavigationItem> getAvailableNavigationItems(UserPermissions permissions) {
    return NavigationConfig.allNavigationItems.where(
      (item) => _hasPermission(item, permissions),
    ).toList();
  }

  /// Get quick actions for current user
  static List<QuickActionItem> getAvailableQuickActions(UserPermissions permissions) {
    return NavigationConfig.quickActions.where(
      (action) => _hasPermissionForAction(action, permissions),
    ).toList();
  }

  /// Get badge counts map from dashboard data
  static Map<String, dynamic> getBadgesFromDashboardData(Map<String, dynamic> dashboardData) {
    return {
      'drivers': _toInt(dashboardData['drivers_count'] ?? dashboardData['total_drivers'] ?? 0),
      'vehicles': _toInt(dashboardData['devices_count'] ?? dashboardData['total_vehicles'] ?? 0),
      'payments': _toInt(dashboardData['unpaid_debts_count'] ?? dashboardData['pending_payments'] ?? 0),
      'reminders': _toInt(dashboardData['reminders_count'] ?? 0),
    };
  }

}

class _MenuGridTile extends StatelessWidget {
  const _MenuGridTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double h = constraints.maxHeight.isFinite ? constraints.maxHeight : 90;
            // Compute sizes responsively to avoid overflows on tight tiles
            double side = h * 0.52; // avatar circle side
            if (side < 36) side = 36;
            if (side > 56) side = 56;
            double iconSize = side * 0.5;
            if (iconSize < 18) iconSize = 18;
            if (iconSize > 28) iconSize = 28;
            double spacing = h * 0.08;
            if (spacing < 4) spacing = 4;
            if (spacing > 8) spacing = 8;
            double fontSize = h * 0.18;
            if (fontSize < 10) fontSize = 10;
            if (fontSize > 12) fontSize = 12;

            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: iconSize),
                  ),
                  SizedBox(height: spacing),
                  // Let the text shrink and ellipsize within the tile
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth - 4),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: fontSize),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

/// Helper method to safely convert dynamic values to int
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
