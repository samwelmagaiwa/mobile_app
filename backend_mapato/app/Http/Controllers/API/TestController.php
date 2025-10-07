<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Helpers\ResponseHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class TestController extends Controller
{



    /**
     * Get system status and configuration
     */
    public function systemStatus()
    {
        try {
            return ResponseHelper::success([
                'system' => [
                    'status' => 'operational',
                    'timestamp' => now()->toISOString(),
                    'timezone' => config('app.timezone'),
                    'environment' => config('app.env'),
                    'debug_mode' => config('app.debug'),
                ],
                'database' => [
                    'users_count' => User::count(),
                    'active_users_count' => User::active()->count(),
                    'admins_count' => User::admins()->count(),
                    'drivers_count' => User::drivers()->count(),
                ],
                'api_endpoints' => [
                    'auth' => [
                        'POST /api/auth/login',
                        'POST /api/auth/forgot-password',
                        'POST /api/auth/reset-password',
                        'POST /api/auth/logout',
                    ],
                    'test' => [
                        'GET /api/test/system-status',
                    ],
                ],
            ], 'System status retrieved successfully');

        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to get system status: ' . $e->getMessage(), 500);
        }
    }
}