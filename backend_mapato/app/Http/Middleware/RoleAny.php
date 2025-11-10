<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleAny
{
    /**
     * Handle an incoming request.
     * Accepts comma-separated roles, e.g., role_any:admin,manager,sales_officer
     */
    public function handle(Request $request, Closure $next, $roles)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Super Admin bypass
        if (method_exists($user, 'isSuperAdmin') && $user->isSuperAdmin()) {
            return $next($request);
        }

        $allowed = array_map('trim', explode(',', (string) $roles));
        $userRole = strtolower((string)($user->role ?? ''));
        if (!in_array($userRole, array_map('strtolower', $allowed), true)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        return $next($request);
    }
}
