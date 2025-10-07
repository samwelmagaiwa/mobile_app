<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Helpers\ResponseHelper;

class HandleSanctumAuth
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if user is authenticated via Sanctum
        if (!$request->user()) {
            return ResponseHelper::error('Unauthenticated', 401);
        }

        // Check if user has an active driver profile
        $driver = $request->user()->driver;
        if (!$driver) {
            return ResponseHelper::error('Driver profile not found', 403);
        }

        if (!$driver->is_active) {
            return ResponseHelper::error('Driver account is inactive', 403);
        }

        return $next($request);
    }
}