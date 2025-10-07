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

        // Check if user is active
        if (!$user->is_active) {
            return ResponseHelper::error('Account is inactive', 403);
        }

        // Check if user has any of the required roles
        if (!in_array($user->role, $roles)) {
            return ResponseHelper::error('Insufficient permissions', 403);
        }

        return $next($request);
    }
}