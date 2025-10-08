<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Helpers\ResponseHelper;
use App\Models\Driver;
use App\Models\DebtRecord;
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

    /**
     * Seed sample unpaid debt records for active drivers (development helper)
     */
    public function seedDebts(Request $request)
    {
        try {
            $days = (int) ($request->get('days', 3));
            $amount = (float) ($request->get('amount', 10000));
            $created = 0;

            $dates = [];
            for ($i = 0; $i < $days; $i++) {
                $dates[] = now()->subDays($i)->toDateString();
            }

            $drivers = Driver::active()->get();
            foreach ($drivers as $driver) {
                foreach ($dates as $date) {
                    $record = DebtRecord::firstOrCreate(
                        [
                            'driver_id' => $driver->id,
                            'earning_date' => $date,
                        ],
                        [
                            'expected_amount' => $amount,
                            'paid_amount' => 0,
                            'is_paid' => false,
                        ]
                    );
                    if ($record->wasRecentlyCreated) {
                        $created++;
                    }
                }
            }

            return ResponseHelper::success([
                'created' => $created,
                'drivers' => $drivers->count(),
                'dates' => $dates,
            ], 'Sample debts seeded');
        } catch (\Exception $e) {
            return ResponseHelper::error('Failed to seed debts: ' . $e->getMessage(), 500);
        }
    }
}
