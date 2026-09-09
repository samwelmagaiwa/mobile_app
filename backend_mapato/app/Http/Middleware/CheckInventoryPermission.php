<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gate inventory routes by granular permission key.
 *
 * Usage in routes:   ->middleware('inv_perm:inv_view_reports')
 *
 * Resolution order (mirrors Flutter UserPermissions.fromUser):
 *   1. super_admin / admin / full_access   → always allowed
 *   2. Explicit per-user grant in users.permissions (JSON column)
 *   3. Role-default permission set (User::hasInventoryPermission)
 *
 * Multiple comma-separated permissions = ANY of them grants access:
 *   ->middleware('inv_perm:inv_view_expenses,inv_manage_expenses')
 */
class CheckInventoryPermission
{
    public function handle(Request $request, Closure $next, string ...$permissions): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // At least one of the required permissions must be satisfied
        foreach ($permissions as $perm) {
            if ($user->hasInventoryPermission(trim($perm))) {
                return $next($request);
            }
        }

        return response()->json([
            'message'             => 'Forbidden. Insufficient inventory permissions.',
            'required_any'        => $permissions,
            'user_role'           => $user->role,
            'user_explicit_perms' => is_array($user->permissions) ? $user->permissions : [],
        ], 403);
    }
}
