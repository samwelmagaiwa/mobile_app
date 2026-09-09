import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/service_selection_screen.dart';

/// Wraps a service home screen. If the authenticated user has explicit service
/// bindings and [service] is NOT one of them, the user is redirected to the
/// service picker instead of seeing the protected screen.
///
/// Users with zero bound services (not yet assigned by admin) still see the
/// full picker — no lockout.
class ServiceGuard extends StatelessWidget {
  const ServiceGuard({
    super.key,
    required this.service,
    required this.child,
  });

  /// The service key this screen belongs to ('inventory', 'transport', 'rental').
  final String service;

  /// The actual service home screen to show when access is granted.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // Not logged in — AuthWrapper handles this; show child and let it be
    // replaced on the next frame.
    if (user == null) return child;

    // Admins and super_admins have full cross-service access by role.
    // Their service bindings are managed by super_admin but never enforced
    // here — they can always navigate anywhere.
    if (user.isAdmin || user.isSuperAdmin) return child;

    final bound = user.serviceTypes;

    // No explicit bindings yet (e.g. freshly created account not yet assigned
    // by admin). Allow through — the picker already handled showing the right
    // tiles; blocking here would create an infinite redirect loop.
    if (bound.isEmpty) return child;

    // Access granted.
    if (bound.contains(service)) return child;

    // Access denied — redirect to the picker filtered to bound services only,
    // with a warning banner explaining why.
    return ServiceSelectionScreen(
      allowedServices: bound,
      deniedService: service,
    );
  }
}
