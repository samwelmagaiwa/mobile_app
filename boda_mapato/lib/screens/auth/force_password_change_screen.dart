import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/theme_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';

/// Shown instead of the app while the signed-in account still uses the
/// default password an admin issued. Changing it signs the user out (the
/// server revokes every token), so they log in again with the new password.
///
/// The change goes straight to [AuthService] rather than through
/// [AuthProvider.changePassword]: that sets the provider-wide loading flag,
/// which makes the root widget swap this screen for the splash screen and
/// dispose it mid-request, losing the result and any error message.
class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({
    super.key,
    this.changePassword = _changePasswordOnServer,
    this.onChanged,
  });

  /// Performs the change; throws on failure. Overridable for tests.
  final Future<void> Function(String current, String next, String confirm)
      changePassword;

  /// Called after a successful change. Defaults to signing out, because the
  /// server revokes every token when a password changes.
  final Future<void> Function()? onChanged;

  static Future<void> _changePasswordOnServer(
          String current, String next, String confirm) =>
      AuthService.changePassword(
        currentPassword: current,
        newPassword: next,
        confirmPassword: confirm,
      );

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(bool sw) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.changePassword(_current.text, _new.text, _confirm.text);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ThemeConstants.showErrorSnackBar(
        context,
        sw
            ? 'Imeshindikana kubadilisha nywila. Hakikisha nywila ya sasa ni sahihi.'
            : 'Could not change the password. Check your current password.',
      );
      return;
    }

    if (!mounted) return;
    await (widget.onChanged ?? context.read<AuthProvider>().logout)();
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ThemeConstants.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool sw = context.watch<LocalizationService>().isSwahili;
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.lock_reset,
                      size: 56, color: ThemeConstants.textPrimary),
                  const SizedBox(height: 16),
                  Text(
                    sw ? 'Weka nywila mpya' : 'Set a new password',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sw
                        ? 'Nywila uliyopewa ni ya muda. Weka yako mwenyewe ili uendelee.'
                        : 'Your password was issued by an admin. Choose your own to continue.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ThemeConstants.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _current,
                    obscureText: true,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration:
                        _decoration(sw ? 'Nywila ya sasa' : 'Current password'),
                    validator: (String? v) => (v == null || v.isEmpty)
                        ? (sw ? 'Inahitajika' : 'Required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _new,
                    obscureText: true,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration:
                        _decoration(sw ? 'Nywila mpya' : 'New password'),
                    validator: (String? v) {
                      if (v == null || v.length < 8) {
                        return sw
                            ? 'Angalau herufi 8'
                            : 'At least 8 characters';
                      }
                      if (v == _current.text) {
                        return sw
                            ? 'Lazima iwe tofauti na ya sasa'
                            : 'Must differ from the current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    style: const TextStyle(color: ThemeConstants.textPrimary),
                    decoration: _decoration(
                        sw ? 'Thibitisha nywila mpya' : 'Confirm new password'),
                    validator: (String? v) => v != _new.text
                        ? (sw ? 'Nywila hazilingani' : 'Passwords do not match')
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : () => _submit(sw),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(sw ? 'Hifadhi' : 'Save password'),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.read<AuthProvider>().logout(),
                    child: Text(sw ? 'Toka' : 'Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
