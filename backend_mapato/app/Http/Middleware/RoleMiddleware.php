<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Helpers\ResponseHelper;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        if (!$request->user()) {
            return ResponseHelper::error('Unauthenticated', 401);
        }

        $user = $request->user();

        // Super Admin bypass: can access any route guarded by this middleware
        if (method_exists($user, 'isSuperAdmin') && $user->isSuperAdmin()) {
            return $next($request);
        }

        // Check if user is active
        if (!$user->is_active) {
            return ResponseHelper::error('Account is inactive', 403);
        }

        // Check if user has any of the required roles
        if (!in_array($user->role, $roles) && !$this->hasRouteGrant($request, $user)) {
            return ResponseHelper::error('Insufficient permissions', 403);
        }

        return $next($request);
    }

    /**
     * A role-guarded Rental/Transport route is also open to a user who was
     * explicitly granted the matching feature permission (see
     * config/feature_permissions.php). Routes with no mapping stay role-only.
     */
    private function hasRouteGrant(Request $request, $user): bool
    {
        $route = $request->route();
        if (!$route) {
            return false;
        }

        $uri = preg_replace('#^api/#', '', $route->uri());
        foreach (config('feature_permissions.routes', []) as $pattern => $perms) {
            if (!fnmatch($pattern, $uri)) {
                continue;
            }
            foreach ((array) $perms as $perm) {
                if ($user->hasExplicitGrant($perm)) {
                    return true;
                }
            }
            return false;
        }

        return false;
    }
}
