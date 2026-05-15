import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:boda_mapato/constants/theme_constants.dart';
import 'package:boda_mapato/services/api_service.dart';
import 'package:boda_mapato/services/localization_service.dart';

class UserPermissionsManagementScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String serviceType; // rental, transport, inventory

  const UserPermissionsManagementScreen({
    super.key,
    required this.user,
    required this.serviceType,
  });

  @override
  State<UserPermissionsManagementScreen> createState() => _UserPermissionsManagementScreenState();
}

class _UserPermissionsManagementScreenState extends State<UserPermissionsManagementScreen> {
  final ApiService _api = ApiService();
  final LocalizationService _loc = LocalizationService.instance;

  late List<String> _currentPermissions;
  bool _saving = false;

  final Map<String, List<Map<String, String>>> _allPermissionGroups = {
    'rental': [
      {'id': 'manage_properties_rental', 'name': 'Properties'},
      {'id': 'manage_houses_rental', 'name': 'Houses'},
      {'id': 'onboard_tenants_rental', 'name': 'Onboarding'},
      {'id': 'manage_agreements_rental', 'name': 'Agreements'},
      {'id': 'manage_billing_rental', 'name': 'Billing'},
      {'id': 'view_reports_rental', 'name': 'Reports'},
      {'id': 'manage_maintenance_rental', 'name': 'Maintenance'},
    ],
    'transport': [
      {'id': 'manage_vehicles_transport', 'name': 'Vehicles'},
      {'id': 'manage_drivers_transport', 'name': 'Drivers'},
      {'id': 'manage_agreements_transport', 'name': 'Agreements'},
      {'id': 'manage_payments_transport', 'name': 'Payments'},
      {'id': 'manage_debts_transport', 'name': 'Debts'},
      {'id': 'view_reports_transport', 'name': 'Reports'},
      {'id': 'manage_reminders_transport', 'name': 'Reminders'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadInitialPermissions();
  }

  void _loadInitialPermissions() {
    final rawPerms = widget.user['permissions'];
    if (rawPerms is List) {
      _currentPermissions = List<String>.from(rawPerms.map((e) => e.toString()));
    } else if (rawPerms is String && rawPerms.trim().startsWith('[')) {
      // Handle case where it might be a JSON string
      try {
        final decoded = jsonDecode(rawPerms);
        if (decoded is List) {
          _currentPermissions = List<String>.from(decoded.map((e) => e.toString()));
        } else {
          _currentPermissions = [];
        }
      } catch (_) {
        _currentPermissions = [];
      }
    } else {
      _currentPermissions = [];
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_loc.isSwahili ? 'Mabadiliko yamehifadhiwa' : 'Permissions updated'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(res['message'] ?? 'Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _serviceName {
    if (widget.serviceType == 'rental') return 'Rental Service';
    if (widget.serviceType == 'transport') return 'Transport Service';
    return '${widget.serviceType.toUpperCase()} Service';
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _allPermissionGroups[widget.serviceType] ?? [];

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
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ThemeConstants.primaryOrange),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePermissions,
              child: Text(
                _loc.isSwahili ? 'HIFADHI' : 'SAVE',
                style: const TextStyle(color: ThemeConstants.primaryOrange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // User Sticky Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                  child: Text(
                    widget.user['name']?[0]?.toUpperCase() ?? 'U',
                    style: const TextStyle(color: ThemeConstants.primaryOrange, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user['name'] ?? 'Unknown User',
                        style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${(widget.user['role'] ?? 'N/A').toString().toUpperCase()}',
                        style: TextStyle(color: ThemeConstants.textSecondary.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ThemeConstants.primaryOrange.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.serviceType.toUpperCase(),
                    style: const TextStyle(color: ThemeConstants.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryOrange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceName.toUpperCase(),
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 100,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: permissions.length,
              itemBuilder: (context, index) {
                final perm = permissions[index];
                final isGranted = _currentPermissions.contains(perm['id']);

                return InkWell(
                  onTap: () => _togglePermission(perm['id']!),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isGranted 
                            ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)]
                            : [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isGranted 
                            ? Colors.green.withOpacity(0.6) 
                            : Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: isGranted ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isGranted ? Icons.check_circle : Icons.cancel,
                            key: ValueKey(isGranted),
                            color: isGranted ? Colors.green : Colors.red,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          perm['name']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeConstants.textPrimary,
                            fontSize: 14,
                            fontWeight: isGranted ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}
