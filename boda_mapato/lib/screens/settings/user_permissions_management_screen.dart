import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../models/user_permissions.dart';
import '../../services/api_service.dart';
import '../../services/localization_service.dart';

class UserPermissionsManagementScreen extends StatefulWidget {
  // rental, transport, inventory

  const UserPermissionsManagementScreen({
    required this.user,
    required this.serviceType,
    super.key,
  });
  final Map<String, dynamic> user;
  final String serviceType;

  @override
  State<UserPermissionsManagementScreen> createState() =>
      _UserPermissionsManagementScreenState();
}

class _UserPermissionsManagementScreenState
    extends State<UserPermissionsManagementScreen> {
  final ApiService _api = ApiService();
  final LocalizationService _loc = LocalizationService.instance;

  late List<String> _currentPermissions;
  bool _saving = false;

  /// Permissions that the user's role already includes by default.
  late List<String> _roleDefaults;

  final Map<String, List<Map<String, String>>> _allPermissionGroups = {
    'inventory': [
      // Products & Stock
      {'id': 'inv_view_products',    'name': 'View Products',    'icon': 'inventory_2'},
      {'id': 'inv_manage_products',  'name': 'Manage Products',  'icon': 'edit'},
      {'id': 'inv_manage_stock',     'name': 'Manage Stock',     'icon': 'track_changes'},
      // Sales
      {'id': 'inv_create_sales',     'name': 'Create Sales',     'icon': 'point_of_sale'},
      {'id': 'inv_manage_sales',     'name': 'Manage Sales',     'icon': 'manage_accounts'},
      // Financials
      {'id': 'inv_view_credit',      'name': 'Credit / Debt',    'icon': 'credit_card'},
      {'id': 'inv_view_cash',        'name': 'Daily Cash',       'icon': 'payments'},
      {'id': 'inv_view_crates',      'name': 'Crates / Empties', 'icon': 'inbox'},
      {'id': 'inv_view_expenses',    'name': 'View Expenses',    'icon': 'receipt_long'},
      {'id': 'inv_manage_expenses',  'name': 'Record Expenses',  'icon': 'edit_note'},
      // Supply chain
      {'id': 'inv_view_purchasing',  'name': 'Purchasing',       'icon': 'local_shipping'},
      // Insights
      {'id': 'inv_view_reports',     'name': 'Reports',          'icon': 'bar_chart'},
      // Misc
      {'id': 'inv_view_reminders',   'name': 'Reminders',        'icon': 'notifications'},
      {'id': 'inv_manage_settings',  'name': 'Depot Settings',   'icon': 'settings'},
    ],
    'rental': [
      {'id': 'manage_properties_rental', 'name': 'Properties',  'icon': 'home_work'},
      {'id': 'manage_houses_rental',     'name': 'Houses',       'icon': 'house'},
      {'id': 'onboard_tenants_rental',   'name': 'Onboarding',  'icon': 'person_add'},
      {'id': 'manage_agreements_rental', 'name': 'Agreements',  'icon': 'handshake'},
      {'id': 'manage_billing_rental',    'name': 'Billing',      'icon': 'receipt'},
      {'id': 'view_reports_rental',      'name': 'Reports',      'icon': 'bar_chart'},
      {'id': 'manage_maintenance_rental','name': 'Maintenance',  'icon': 'build'},
    ],
    'transport': [
      {'id': 'manage_vehicles_transport',   'name': 'Vehicles',   'icon': 'directions_car'},
      {'id': 'manage_drivers_transport',    'name': 'Drivers',    'icon': 'person'},
      {'id': 'manage_agreements_transport', 'name': 'Agreements', 'icon': 'handshake'},
      {'id': 'manage_payments_transport',   'name': 'Payments',   'icon': 'payments'},
      {'id': 'manage_debts_transport',      'name': 'Debts',      'icon': 'money_off'},
      {'id': 'view_reports_transport',      'name': 'Reports',    'icon': 'bar_chart'},
      {'id': 'manage_reminders_transport',  'name': 'Reminders',  'icon': 'notifications'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadInitialPermissions();
  }

  void _loadInitialPermissions() {
    // Explicit per-user grants stored in DB
    final rawPerms = widget.user['permissions'];
    if (rawPerms is List) {
      _currentPermissions = List<String>.from(rawPerms.map((e) => e.toString()));
    } else if (rawPerms is String && rawPerms.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(rawPerms);
        _currentPermissions = decoded is List
            ? List<String>.from(decoded.map((e) => e.toString()))
            : [];
      } catch (_) {
        _currentPermissions = [];
      }
    } else {
      _currentPermissions = [];
    }

    // Role default baseline — used for display only (locked green chips)
    final String role = (widget.user['role'] as String?) ?? '';
    _roleDefaults = UserPermissions.fromRole(role).all;
  }

  void _togglePermission(String permId) {
    setState(() {
      if (_currentPermissions.contains(permId)) {
        _currentPermissions.remove(permId);
      } else {
        _currentPermissions.add(permId);
      }
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _saving = true);
    try {
      final res = await _api.updateUserPermissions(
        widget.user['id'].toString(),
        _currentPermissions,
      );

      if (res['success'] == true) {
        if (mounted) {
          ThemeConstants.showSuccessSnackBar(
            context,
            _loc.isSwahili ? 'Mabadiliko yamehifadhiwa' : 'Permissions updated',
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(res['message'] ?? 'Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ThemeConstants.showErrorSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _serviceName {
    if (widget.serviceType == 'rental') return 'All In One';
    if (widget.serviceType == 'transport') return 'Transport Service';
    if (widget.serviceType == 'inventory') return 'Inventory / Depot';
    return '${widget.serviceType.toUpperCase()} Service';
  }

  /// Three-state logic for each permission tile:
  ///  - fromRole  → granted by role, locked (admin can't take it away here)
  ///  - explicit  → extra grant admin gave this specific user
  ///  - denied    → not in role defaults, not explicitly granted
  _PermState _permState(String id) {
    if (_roleDefaults.contains(id)) return _PermState.fromRole;
    if (_currentPermissions.contains(id)) return _PermState.explicit;
    return _PermState.denied;
  }

  @override
  Widget build(BuildContext context) {
    final perms = _allPermissionGroups[widget.serviceType] ?? [];
    final String role = (widget.user['role'] as String?) ?? '';

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: AppBar(
        title: Text(
          _loc.isSwahili ? 'Usimamizi wa Ruhusa' : 'Permissions Management',
          style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeConstants.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: ThemeConstants.primaryOrange)),
              ),
            )
          else
            TextButton(
              onPressed: _savePermissions,
              child: Text(
                _loc.isSwahili ? 'HIFADHI' : 'SAVE',
                style: const TextStyle(
                    color: ThemeConstants.primaryOrange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── User header ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                  child: Text(
                    (widget.user['name'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: ThemeConstants.primaryOrange,
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                              color: ThemeConstants.textPrimary,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _rolePill(role),
                        const SizedBox(width: 6),
                        _pill(widget.serviceType.toUpperCase(),
                            ThemeConstants.primaryOrange),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Legend ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              _legendDot(Colors.green, _loc.isSwahili ? 'Ruhusa ya Nafasi' : 'Role default'),
              const SizedBox(width: 16),
              _legendDot(Colors.cyanAccent, _loc.isSwahili ? 'Ziada' : 'Extra grant'),
              const SizedBox(width: 16),
              _legendDot(Colors.red.shade300, _loc.isSwahili ? 'Hakuna' : 'Not granted'),
            ]),
          ),

          // ── Grid ──────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 112,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: perms.length,
              itemBuilder: (context, index) {
                final perm = perms[index];
                final state = _permState(perm['id']!);
                final isFromRole = state == _PermState.fromRole;
                final isGranted = state != _PermState.denied;

                return InkWell(
                  onTap: isFromRole
                      ? null // role defaults cannot be toggled here
                      : () => _togglePermission(perm['id']!),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFromRole
                            ? [Colors.green.withOpacity(0.18), Colors.green.withOpacity(0.04)]
                            : state == _PermState.explicit
                                ? [Colors.cyanAccent.withOpacity(0.18), Colors.cyanAccent.withOpacity(0.04)]
                                : [Colors.red.withOpacity(0.12), Colors.red.withOpacity(0.03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFromRole
                            ? Colors.green.withOpacity(0.55)
                            : state == _PermState.explicit
                                ? Colors.cyanAccent.withOpacity(0.65)
                                : Colors.red.withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: isGranted
                          ? [BoxShadow(
                              color: (isFromRole ? Colors.green : Colors.cyanAccent)
                                  .withOpacity(0.12),
                              blurRadius: 10, spreadRadius: 1,
                            )]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // State icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            isFromRole
                                ? Icons.lock
                                : isGranted
                                    ? Icons.add_circle
                                    : Icons.remove_circle_outline,
                            key: ValueKey(state),
                            color: isFromRole
                                ? Colors.green
                                : isGranted
                                    ? Colors.cyanAccent
                                    : Colors.red.shade300,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          perm['name']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 12,
                            fontWeight: isGranted ? FontWeight.bold : FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isFromRole) ...[
                          const SizedBox(height: 2),
                          Text('role', style: TextStyle(
                              fontSize: 9,
                              color: Colors.green.withOpacity(0.8),
                              fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolePill(String role) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: ThemeConstants.primaryCyan.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ThemeConstants.primaryCyan.withOpacity(0.4)),
    ),
    child: Text(role.toUpperCase(),
        style: const TextStyle(color: ThemeConstants.primaryCyan, fontSize: 10,
            fontWeight: FontWeight.bold)),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: ThemeConstants.textSecondary.withOpacity(0.8),
          fontSize: 11)),
    ],
  );
}

enum _PermState { fromRole, explicit, denied }
