import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/localization_service.dart';
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final LocalizationService _loc = LocalizationService.instance;
  final ApiService _api = ApiService();

  bool _loading = true;
  bool _creating = false;
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _api.initialize();
    _loadMyUsers();
  }

  Future<void> _loadMyUsers() async {
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> res = await _api.getMyUsers(page: 1, limit: 100);
      final List<Map<String, dynamic>> items = _extractUsers(res);
      setState(() {
        _users = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ThemeConstants.showErrorSnackBar(context, e.toString());
    }
  }

  List<Map<String, dynamic>> _extractUsers(Map<String, dynamic> resp) {
    final dynamic data = resp['data'];
    List<dynamic> raw;
    if (data is Map && data['users'] is List) {
      raw = data['users'] as List;
    } else if (resp['users'] is List) {
      raw = resp['users'] as List;
    } else if (data is List) {
      raw = data;
    } else {
      raw = const <dynamic>[];
    }
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _defaultPasswordFromName(String fullName) {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'PASSWORD';
    final List<String> parts = trimmed.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    final String base = (parts.isNotEmpty ? parts.last : trimmed).toUpperCase();
    // Ensure backend validation (min 6 chars). If surname is shorter, repeat it until length >= 6.
    String pwd = base;
    while (pwd.length < 6) {
      pwd += base;
    }
    return pwd.substring(0, 6);
  }

  Future<void> _openCreateDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController name = TextEditingController();
    final TextEditingController email = TextEditingController();
    final TextEditingController phone = TextEditingController();
    String role = 'admin';
    bool isActive = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _loc.translate('create_user'),
          style: const TextStyle(color: ThemeConstants.textPrimary),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: InputDecoration(
                      labelText: _loc.translate('full_name'),
                      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
                      prefixIcon: const Icon(Icons.person, color: ThemeConstants.textSecondary),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (_loc.isSwahili ? 'Ingiza jina kamili' : 'Enter full name')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: InputDecoration(
                      labelText: _loc.translate('email'),
                      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
                      prefixIcon: const Icon(Icons.email, color: ThemeConstants.textSecondary),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (_loc.isSwahili ? 'Ingiza barua pepe' : 'Enter email')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: InputDecoration(
                      labelText: _loc.translate('phone_number'),
                      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
                      prefixIcon: const Icon(Icons.phone, color: ThemeConstants.textSecondary),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    dropdownColor: ThemeConstants.primaryBlue,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: InputDecoration(
                      labelText: _loc.translate('role'),
                      labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
                      prefixIcon: const Icon(Icons.verified_user, color: ThemeConstants.textSecondary),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'operator', child: Text('Operator')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                      DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    ],
                    onChanged: (v) => role = v ?? 'admin',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isActive,
                    onChanged: (v) => isActive = v,
                    title: Text(
                      _loc.translate('active'),
                      style: const TextStyle(color: ThemeConstants.textPrimary),
                    ),
                    activeColor: ThemeConstants.primaryOrange,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _loc.translate('default_password_note'),
                      style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_loc.translate('cancel'), style: const TextStyle(color: ThemeConstants.textSecondary)),
          ),
          FilledButton(
            onPressed: _creating
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => _creating = true);
                    try {
                      final String password = _defaultPasswordFromName(name.text);
                      final Map<String, dynamic> payload = <String, dynamic>{
                        'name': name.text.trim(),
                        'email': email.text.trim(),
                        'phone_number': phone.text.trim().isEmpty ? null : phone.text.trim(),
                        'role': role,
                        'is_active': isActive,
                        'password': password,
                        'password_confirmation': password,
                      }..removeWhere((key, value) => value == null);
                      // Use backend's existing registration endpoint
                      final Map<String, dynamic> res = await AuthService.register(
                        name: payload['name'] as String,
                        email: payload['email'] as String,
                        password: password,
                        passwordConfirmation: password,
                        phone: payload['phone_number'] as String?,
                      );
                      if (mounted) {
                        ThemeConstants.showSuccessSnackBar(context, _loc.translate('user_created_successfully'));
                      }
                      Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        ThemeConstants.showErrorSnackBar(context, e.toString());
                      }
                    } finally {
                      if (mounted) setState(() => _creating = false);
                      await _loadMyUsers();
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange, foregroundColor: Colors.white),
            child: _creating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_loc.translate('create_user')),
          ),
        ],
      ),
    );
  }

  void _showUserActions(Map<String, dynamic> user) {
    final bool active = user['is_active'] == true || user['is_active'] == 1;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.white70),
                title: Text(
                  _loc.translate('reset_password'),
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _resetUserPassword(user);
                },
              ),
              const Divider(height: 1, color: Colors.white24),
              ListTile(
                leading: Icon(active ? Icons.block : Icons.check_circle, color: Colors.white70),
                title: Text(
                  active ? (_loc.isSwahili ? 'Lemaza mtumiaji' : 'Deactivate user') : (_loc.isSwahili ? 'Wezesha mtumiaji' : 'Activate user'),
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _setUserActive(user, !active);
                },
              ),
              const Divider(height: 1, color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text(
                  _loc.isSwahili ? 'Futa mtumiaji' : 'Delete user',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteUser(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetUserPassword(Map<String, dynamic> user) async {
    final String name = (user['name'] ?? '').toString();
    final String defaultPassword = _defaultPasswordFromName(name);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_loc.translate('reset_password'), style: const TextStyle(color: ThemeConstants.textPrimary)),
        content: Text(
          _loc.isSwahili
              ? 'Utarejesha nywila ya ${user['name']} kuwa "$defaultPassword"?'
              : "Reset ${user['name']}'s password to \"$defaultPassword\"?",
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.translate('no'), style: const TextStyle(color: ThemeConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_loc.translate('yes'), style: const TextStyle(color: ThemeConstants.primaryOrange)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final String id = (user['id'] ?? user['user_id'] ?? '').toString();
      final Map<String, dynamic> res = await _api.resetUserPassword(userId: id, newPassword: defaultPassword);
      if (mounted) ThemeConstants.showSuccessSnackBar(context, _loc.translate('password_reset_successfully'));
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _setUserActive(Map<String, dynamic> user, bool active) async {
    try {
      final String id = (user['id'] ?? user['user_id'] ?? '').toString();
      await _api.updateUser(id, <String, dynamic>{'is_active': active});
      await _loadMyUsers();
      if (mounted) ThemeConstants.showSuccessSnackBar(context, _loc.isSwahili ? 'Imesasishwa' : 'Updated');
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_loc.isSwahili ? 'Thibitisha' : 'Confirm', style: const TextStyle(color: ThemeConstants.textPrimary)),
        content: Text(
          _loc.isSwahili ? 'Una uhakika unataka kufuta mtumiaji huyu?' : 'Are you sure you want to delete this user?',
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.translate('no'), style: const TextStyle(color: ThemeConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_loc.translate('yes'), style: const TextStyle(color: ThemeConstants.primaryOrange)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final String id = (user['id'] ?? user['user_id'] ?? '').toString();
      await _api.deleteUser(id);
      await _loadMyUsers();
      if (mounted) ThemeConstants.showSuccessSnackBar(context, _loc.isSwahili ? 'Imefutwa' : 'Deleted');
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _resetPasswordForCurrentUser() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final String name = user.name;
    final String defaultPassword = _defaultPasswordFromName(name);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_loc.translate('reset_password'), style: const TextStyle(color: ThemeConstants.textPrimary)),
        content: Text(
          _loc.isSwahili
              ? 'Utarejesha nywila yako kuwa "$defaultPassword"?'
              : "Reset your password to \"$defaultPassword\"?",
          style: const TextStyle(color: ThemeConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.translate('no'), style: const TextStyle(color: ThemeConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_loc.translate('yes'), style: const TextStyle(color: ThemeConstants.primaryOrange)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await AuthService.resetPassword(
        email: user.email,
        password: defaultPassword,
        passwordConfirmation: defaultPassword,
      );
      if (mounted) {
        ThemeConstants.showSuccessSnackBar(context, _loc.translate('password_reset_successfully'));
      }
    } catch (e) {
      if (mounted) ThemeConstants.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar(_loc.translate('users_management')),
      floatingActionButton: (user?.isAdmin == true || user?.isSuperAdmin == true)
          ? FloatingActionButton(
              backgroundColor: ThemeConstants.primaryOrange,
              foregroundColor: Colors.white,
              onPressed: _openCreateDialog,
              child: const Icon(Icons.person_add_alt_1),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemeConstants.buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: ThemeConstants.primaryOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _loc.translate('users_subtitle'),
                          style: const TextStyle(color: ThemeConstants.textSecondary),
                        ),
                      ),
                      if (user?.isAdmin == true || user?.isSuperAdmin == true)
                        FilledButton.icon(
                          onPressed: _openCreateDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: ThemeConstants.primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(_loc.translate('create_user')),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                ThemeConstants.buildLoadingWidget()
              else
                Expanded(
                  child: _users.isEmpty
                      ? Center(
                          child: Text(
                            _loc.isSwahili ? 'Hakuna watumiaji wako bado' : 'No users created by you yet',
                            style: const TextStyle(color: ThemeConstants.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = _users[index];
                            final String name = (m['name'] ?? '').toString();
                            final String email = (m['email'] ?? '').toString();
                            final String role = (m['role'] ?? '').toString();
                            final bool active = m['is_active'] == true || m['is_active'] == 1;
                            return ThemeConstants.buildGlassCard(
                              onTap: () => _showUserActions(m),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: ThemeConstants.primaryOrange,
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(color: ThemeConstants.textPrimary, fontWeight: FontWeight.w600)),
                                subtitle: Text('$email • ${role.toUpperCase()}${active ? '' : ' • INACTIVE'}',
                                    style: const TextStyle(color: ThemeConstants.textSecondary)),
                                trailing: const Icon(Icons.more_vert, color: Colors.white70),
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
