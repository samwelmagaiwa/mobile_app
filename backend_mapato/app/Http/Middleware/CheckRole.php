<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $role): Response
    {
        // Check if user is authenticated
        if (!$request->user()) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
            return redirect()->guest(route('login'));
        }

        // Check if user has the required role
        if (!$request->user()->hasRole($role)) {
            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'Insufficient permissions.',
                    'required_role' => $role,
                    'user_role' => $request->user()->role
                ], 403);
            }
            
            // For web requests, redirect based on user role
            $userRole = $request->user()->role;
            switch ($userRole) {
                case 'super_admin':
                case 'admin':
                    return redirect()->route('admin.dashboard');
                case 'driver':
                    return redirect()->route('driver.dashboard');
                default:
                    return redirect('/')->with('error', 'Access denied. Insufficient permissions.');
            }
        }

        return $next($request);
    }
}