import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../constants/theme_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/localization_service.dart';
import '../../../../screens/settings/backup_screen.dart';
import '../../../../screens/settings/language_screen.dart';
import '../../../../screens/settings/notifications_screen.dart';
import '../../../../screens/settings/permissions_management_screen.dart';
import '../../../../screens/settings/security_screen.dart';
import '../../../../screens/settings/user_management_screen.dart';
import '../../models/inv_depot_models.dart';
import '../../providers/depot_provider.dart';
import '../widgets/inventory_widgets.dart';
import 'receipt_header_screen.dart';

/// Area 13 — depot settings and the permanent audit trail.
class DepotSettingsScreen extends StatefulWidget {
  const DepotSettingsScreen({super.key});

  @override
  State<DepotSettingsScreen> createState() => _DepotSettingsScreenState();
}

class _DepotSettingsScreenState extends State<DepotSettingsScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Draw whatever is already cached; only show a spinner on a cold start.
    _loading = context.read<DepotProvider>().settings.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final DepotProvider depot = context.read<DepotProvider>();
    await Future.wait<void>(<Future<void>>[
      depot.fetchSettings(),
      depot.fetchAuditLog(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    if (_loading) {
      return const Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        body: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    return InvTabScaffold(
      title: loc.translate('depot_settings'),
      tabs: <String>[
        loc.translate('settings'),
        loc.translate('audit_trail'),
      ],
      views: <Widget>[
        _SettingsTab(onSaved: _load),
        _AuditTab(onRefresh: _load),
      ],
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({required this.onSaved});

  final Future<void> Function() onSaved;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  bool _saving = false;

  /// Grouped so the form reads like the settings it configures, and each
  /// field knows whether it is text or a number.
  static final Map<String, List<_Field>> _groups = <String, List<_Field>>{
    'depot_details': <_Field>[
      const _Field('depot_name', 'depot_name',
          hint: 'e.g. Beverage Depot Dodoma'),
      const _Field('depot_phone', 'phone', hint: 'e.g. +255 700 000 000', phone: true),
      const _Field('depot_address', 'address',
          hint: 'e.g. Main Street, Block B'),
    ],
    'invoicing': <_Field>[
      const _Field('invoice_prefix', 'invoice_prefix', hint: 'e.g. INV'),
      const _Field('invoice_next_number', 'next_invoice_number',
          hint: 'e.g. 1', numeric: true),
      const _Field('tax_percent', 'tax_percent',
          hint: 'e.g. 18.0', numeric: true),
    ],
    'limits_and_thresholds': <_Field>[
      const _Field('max_discount_percent', 'max_discount_percent',
          hint: 'e.g. 10.0', numeric: true),
      const _Field('large_discount_percent', 'large_discount_percent',
          hint: 'e.g. 15.0', numeric: true),
      const _Field('low_stock_threshold', 'low_stock_threshold',
          hint: 'e.g. 5', numeric: true),
      const _Field('expiry_alert_days', 'expiry_alert_days',
          hint: 'e.g. 30', numeric: true),
      const _Field('overdue_alert_days', 'overdue_alert_days',
          hint: 'e.g. 7', numeric: true),
    ],
  };

  @override
  void initState() {
    super.initState();
    final Map<String, String> settings = context.read<DepotProvider>().settings;
    for (final List<_Field> group in _groups.values) {
      for (final _Field f in group) {
        _controllers[f.key] =
            TextEditingController(text: settings[f.key] ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final bool ok = await context.read<DepotProvider>().saveSettings(
          _controllers.map((String k, TextEditingController v) =>
              MapEntry<String, String>(k, v.text.trim())),
        );

    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ThemeConstants.showInfoSnackBar(
      context,
      LocalizationService.instance.translate(ok ? 'saved' : 'operation_failed'),
    );
    if (ok) {
      await widget.onSaved();
    }
  }

  String? _validateField(_Field f, String? value) {
    final v = value?.trim() ?? '';
    if (f.key == 'depot_name' && v.isEmpty) {
      return 'Depot name is required';
    }
    if (f.numeric && v.isNotEmpty) {
      final n = double.tryParse(v);
      if (n == null || n < 0) {
        return 'Enter a valid non-negative number';
      }
      if (f.key.contains('percent') && n > 100) {
        return 'Percentage cannot exceed 100%';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;

    return Form(
      key: _formKey,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
        children: <Widget>[
          ..._groups.entries.map(
            (MapEntry<String, List<_Field>> group) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                decoration: ThemeConstants.glassCardDecoration,
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AutoSizeText(
                      loc.translate(group.key),
                      maxLines: 1,
                      minFontSize: 11,
                      overflow: TextOverflow.ellipsis,
                      style: ThemeConstants.bodyStyle
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.h),
                    ...group.value.map(
                      (_Field f) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: InvTextField(
                          controller: _controllers[f.key]!,
                          label: loc.translate(f.labelKey),
                          hint: f.hint,
                          validator: (v) => _validateField(f, v),
                          keyboardType: f.numeric
                              ? const TextInputType.numberWithOptions(decimal: true)
                              : f.phone
                                  ? TextInputType.phone
                                  : TextInputType.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Quick-link to user management (admin / super_admin only) ──
          // Lets an admin create staff for their own bound service, and a
          // super_admin manage every account across every service.
          Builder(
            builder: (context) {
              final user = context.watch<AuthProvider>().user;
              if (user?.isAdmin != true && user?.isSuperAdmin != true) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryBlue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 20.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('users_management'),
                                style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                loc.translate('users_subtitle'),
                                style: ThemeConstants.captionStyle,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14.sp),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Quick-link to receipt header settings (admin / manager only) ──
          Builder(
            builder: (context) {
              final role = context.watch<AuthProvider>().user?.role ?? '';
              if (role != 'admin' && role != 'manager') return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(ReceiptHeaderScreen.route()),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryBlue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mpangilio wa Risiti',
                                style: ThemeConstants.bodyStyle.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Jina, anwani, TIN, ujumbe wa chini na zaidi',
                                style: ThemeConstants.captionStyle,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14.sp),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // ── General App Settings ──────────────────────────────────────
          // All app-wide settings are accessible here so super_admin and
          // admin don't have to leave the inventory service to reach them.
          _AppSettingsSection(),
          SizedBox(height: 8.h),
          InvPrimaryButton(busy: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// App-wide settings tiles rendered inside the depot settings screen.
/// Mirrors SettingsScreen but scoped to what each role should see.
class _AppSettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final user = context.watch<AuthProvider>().user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isAdmin = user?.isAdmin ?? false;

    void go(Widget screen) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => screen),
        );

    // Personal — all roles
    final personal = <_AppTile>[
      _AppTile(Icons.notifications_outlined, loc.translate('notifications'),
          loc.translate('notifications_subtitle'), () => go(const NotificationsScreen())),
      _AppTile(Icons.language_outlined, loc.translate('language'),
          loc.translate('language_subtitle'), () => go(const LanguageScreen())),
      _AppTile(Icons.shield_outlined, loc.translate('security'),
          loc.translate('security_subtitle'), () => go(const SecurityScreen())),
    ];

    // Admin-level tiles (only shown when user has admin role or above)
    final adminTiles = <_AppTile>[
      _AppTile(
        Icons.people_alt_outlined,
        loc.translate('users'),
        isSuperAdmin
            ? (loc.isSwahili ? 'Dhibiti watumiaji wote kwenye huduma zote' : 'Manage all users across every service')
            : (loc.isSwahili ? 'Dhibiti watumiaji wa huduma yako' : 'Manage users in your service(s)'),
        () => go(const UserManagementScreen()),
      ),
      if (isSuperAdmin)
        _AppTile(
          Icons.admin_panel_settings_outlined,
          loc.isSwahili ? 'Ruhusa' : 'Permissions',
          loc.isSwahili ? 'Dhibiti ruhusa za moduli' : 'Manage service module permissions',
          () => go(const PermissionsScreen()),
        ),
      _AppTile(Icons.cloud_upload_outlined, loc.translate('backup'),
          loc.translate('backup_subtitle'), () => go(const BackupScreen())),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal section
          Container(
            decoration: ThemeConstants.glassCardDecoration,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(loc.isSwahili ? 'Binafsi' : 'Personal'),
                SizedBox(height: 6.h),
                ...personal.map((t) => _buildTile(context, t)),
              ],
            ),
          ),
          // Admin / Super Admin section
          if (isAdmin || isSuperAdmin) ...[
            SizedBox(height: 10.h),
            Container(
              decoration: ThemeConstants.glassCardDecoration,
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(
                    isSuperAdmin
                        ? (loc.isSwahili ? 'Udhibiti wa Super Admin' : 'Super Admin Controls')
                        : (loc.isSwahili ? 'Zana za Msimamizi' : 'Admin Tools'),
                    color: isSuperAdmin ? const Color(0xFFFFD700) : Colors.blueGrey.shade200,
                    icon: isSuperAdmin ? Icons.verified_user_rounded : Icons.manage_accounts_rounded,
                  ),
                  SizedBox(height: 6.h),
                  ...adminTiles.map((t) => _buildTile(context, t)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text, {Color? color, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12.sp, color: color ?? ThemeConstants.textSecondary),
          SizedBox(width: 5.w),
        ],
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: color ?? ThemeConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _AppTile t) {
    return InkWell(
      onTap: t.onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(t.icon, color: Colors.white70, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: ThemeConstants.bodyStyle
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                  SizedBox(height: 2.h),
                  Text(t.subtitle, style: ThemeConstants.captionStyle),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

class _AppTile {
  const _AppTile(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _Field {
  const _Field(this.key, this.labelKey, {this.hint, this.numeric = false, this.phone = false});

  final String key;
  final String labelKey;
  final String? hint;
  final bool numeric;
  final bool phone;
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final LocalizationService loc = LocalizationService.instance;
    final List<InvAuditEntry> rows = context.watch<DepotProvider>().auditLog;

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: Colors.white,
      color: ThemeConstants.primaryBlue,
      child: rows.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                SizedBox(height: 60.h),
                InvEmptyState(
                  icon: Icons.history_outlined,
                  message: loc.translate('no_audit_entries'),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
              itemCount: rows.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (_, int i) {
                final InvAuditEntry e = rows[i];
                final DateTime at = e.createdAt;

                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AutoSizeText(
                              '${e.entityType.replaceAll('_', ' ')} · ${e.action}',
                              maxLines: 1,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeConstants.bodyStyle
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2.h),
                            AutoSizeText(
                              <String>[
                                '${at.day}/${at.month}/${at.year} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
                                if (e.userName.isNotEmpty) e.userName,
                                if (e.summary.isNotEmpty) e.summary,
                              ].join('  •  '),
                              maxLines: 2,
                              minFontSize: 9,
                              overflow: TextOverflow.ellipsis,
                              style: ThemeConstants.captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
