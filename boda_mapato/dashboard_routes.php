<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\DashboardController;

/*
|--------------------------------------------------------------------------
| Dashboard API Routes
|--------------------------------------------------------------------------
|
| These routes handle the dashboard endpoints that the modern Flutter app
| will call to retrieve real-time data for the admin dashboard.
| All endpoints return precise data from the actual database tables.
|
*/

Route::group(['prefix' => 'api/admin', 'middleware' => ['auth:api', 'admin']], function () {
    
    // Main comprehensive dashboard endpoint - returns all data in one response
    Route::get('dashboard/comprehensive', [DashboardController::class, 'getComprehensiveData']);
    
    // Existing dashboard endpoint (for compatibility)
    Route::get('dashboard', [DashboardController::class, 'getDashboardData']);
    
    // Individual count endpoints
    Route::get('dashboard/active-drivers-count', [DashboardController::class, 'getActiveDriversCount']);
    Route::get('dashboard/active-devices-count', [DashboardController::class, 'getActiveDevicesCount']);
    Route::get('dashboard/unpaid-debts-count', [DashboardController::class, 'getUnpaidDebtsCount']);
    Route::get('dashboard/generated-receipts-count', [DashboardController::class, 'getGeneratedReceiptsCount']);
    Route::get('dashboard/pending-receipts-count', [DashboardController::class, 'getPendingReceiptsCount']);
    
    // Revenue endpoints by time period
    Route::get('dashboard/daily-revenue', [DashboardController::class, 'getDailyRevenue']);
    Route::get('dashboard/weekly-revenue', [DashboardController::class, 'getWeeklyRevenue']);
    Route::get('dashboard/monthly-revenue', [DashboardController::class, 'getMonthlyRevenue']);
    
});

/*
|--------------------------------------------------------------------------
| Alternative Route Structure (if not using middleware groups)
|--------------------------------------------------------------------------
|
| If your Laravel app doesn't use middleware groups or has different auth,
| you can use these individual route definitions instead:
|

// Main comprehensive dashboard endpoint
Route::get('api/admin/dashboard/comprehensive', [DashboardController::class, 'getComprehensiveData']);

// Existing dashboard endpoint (for compatibility)
Route::get('api/admin/dashboard', [DashboardController::class, 'getDashboardData']);

// Individual count endpoints
Route::get('api/admin/dashboard/active-drivers-count', [DashboardController::class, 'getActiveDriversCount']);
Route::get('api/admin/dashboard/active-devices-count', [DashboardController::class, 'getActiveDevicesCount']);
Route::get('api/admin/dashboard/unpaid-debts-count', [DashboardController::class, 'getUnpaidDebtsCount']);
Route::get('api/admin/dashboard/generated-receipts-count', [DashboardController::class, 'getGeneratedReceiptsCount']);
Route::get('api/admin/dashboard/pending-receipts-count', [DashboardController::class, 'getPendingReceiptsCount']);

// Revenue endpoints by time period
Route::get('api/admin/dashboard/daily-revenue', [DashboardController::class, 'getDailyRevenue']);
Route::get('api/admin/dashboard/weekly-revenue', [DashboardController::class, 'getWeeklyRevenue']);
Route::get('api/admin/dashboard/monthly-revenue', [DashboardController::class, 'getMonthlyRevenue']);

*/