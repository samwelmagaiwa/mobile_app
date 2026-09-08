<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Allow access when the user's role matches any of the listed roles,
 * OR when the user has an explicit permission grant that covers an
 * inventory permission (so admin can grant individuals access beyond
 * their role's default set).
 *
 * Usage:  ->middleware('role_any:admin,manager,sales_officer')
 */
class RoleAny
{
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // super_admin and full_access users bypass every gate
        if ($user->isSuperAdmin() || $user->full_access) {
            return $next($request);
        }

        // Laravel splits 'role_any:admin,manager,sales_officer' into three
        // separate arguments before calling handle() -- $roles must be
        // variadic to receive all of them. A single non-variadic parameter
        // here would silently bind only the first ('admin') and drop the
        // rest, which is exactly what was happening: every route using
        // this middleware with more than one allowed role was 403ing any
        // role past the first, including manager and sales_officer.
        $allowed  = array_map('trim', $roles);
        $userRole = strtolower((string)($user->role ?? ''));

        // Role match
        if (in_array($userRole, array_map('strtolower', $allowed), true)) {
            return $next($request);
        }

        // Fallback: if the user has ANY explicit inventory permission grant
        // and admin/manager is in the allowed list, let them through.
        // This covers the case where an admin grants an individual user
        // extra access beyond their role (e.g. a viewer given inv_view_reports).
        $explicit = is_array($user->permissions) ? $user->permissions : [];
        if (!empty($explicit) && array_intersect(['admin', 'manager'], $allowed)) {
            // Check if they have at least one inv_* explicit grant
            foreach ($explicit as $perm) {
                if (str_starts_with((string)$perm, 'inv_')) {
                    return $next($request);
                }
            }
        }

        return response()->json([
            'message'   => 'Forbidden',
            'allowed'   => $allowed,
            'user_role' => $user->role,
        ], 403);
    }
}
