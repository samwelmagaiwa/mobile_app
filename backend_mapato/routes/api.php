<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\AdminController;
use App\Http\Controllers\API\DriverViewController;
use App\Http\Controllers\API\DeviceController;
use App\Http\Controllers\API\DriverController;
use App\Http\Controllers\API\TransactionController;
use App\Http\Controllers\API\ReceiptController;
use App\Http\Controllers\API\ReportController;
use App\Http\Controllers\API\TestController;
use App\Http\Controllers\API\TestReportController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes (no authentication required)
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('resend-otp', [AuthController::class, 'resendOtp']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);
});

// Temporary development routes (bypass authentication until database is set up)
Route::prefix('admin')->group(function () {
    // Driver management (temporary - no auth required)
    Route::get('drivers', [AdminController::class, 'getDrivers']);
    Route::post('drivers', [AdminController::class, 'createDriver']);
    Route::put('drivers/{id}', [AdminController::class, 'updateDriver']);
    Route::delete('drivers/{id}', [AdminController::class, 'deleteDriver']);
    
    // Payment management (temporary - no auth required)
    Route::post('record-payment', [AdminController::class, 'recordPayment']);
    Route::get('payment-history', [AdminController::class, 'getPaymentHistory']);
    
    // Vehicle management (temporary - no auth required)
    Route::get('vehicles', [AdminController::class, 'getVehicles']);
    Route::post('vehicles', [AdminController::class, 'createVehicle']);
});

// Protected routes (authentication required)
Route::middleware(['auth:sanctum'])->group(function () {
    
    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('user', [AuthController::class, 'user']);
        Route::post('refresh', [AuthController::class, 'refresh']);
    });

    // Admin routes (Vehicle Owner/Admin only)
    Route::middleware(['role:admin'])->group(function () {
        Route::prefix('admin')->group(function () {
            // Dashboard
            Route::get('dashboard', [AdminController::class, 'dashboard']);
            
            // Vehicle management
            Route::get('vehicles', [AdminController::class, 'getVehicles']);
            Route::post('vehicles', [AdminController::class, 'createVehicle']);
            Route::post('assign-driver', [AdminController::class, 'assignDriverToVehicle']);
            
            // Payment management
            Route::post('record-payment', [AdminController::class, 'recordPayment']);
            Route::get('payment-history', [AdminController::class, 'getPaymentHistory']);
            
            // Receipt management
            Route::post('generate-receipt', [AdminController::class, 'generateReceipt']);
            
            // Reminders/Notes
            Route::post('reminders', [AdminController::class, 'addReminder']);
            
            // Reports (admin view)
            Route::prefix('reports')->group(function () {
                Route::get('dashboard', [ReportController::class, 'dashboard']);
                Route::get('revenue', [ReportController::class, 'revenue']);
                Route::get('expenses', [ReportController::class, 'expenses']);
                Route::get('profit-loss', [ReportController::class, 'profitLoss']);
                Route::get('device-performance', [ReportController::class, 'devicePerformance']);
                Route::post('export-pdf', [ReportController::class, 'exportPdf']);
            });
        });
    });

    // Driver routes (Read-only view for drivers)
    Route::middleware(['role:driver'])->group(function () {
        Route::prefix('driver')->group(function () {
            // Driver dashboard (read-only)
            Route::get('dashboard', [DriverViewController::class, 'dashboard']);
            Route::get('profile', [DriverViewController::class, 'getProfile']);
            
            // View payment history
            Route::get('payment-history', [DriverViewController::class, 'getPaymentHistory']);
            
            // View receipts
            Route::get('receipts', [DriverViewController::class, 'getReceipts']);
            
            // Submit payment request (for admin approval)
            Route::post('submit-payment-request', [DriverViewController::class, 'submitPaymentRequest']);
            
            // View reminders from admin
            Route::get('reminders', [DriverViewController::class, 'getReminders']);
        });
    });

    // Common routes (all authenticated users)
    Route::prefix('common')->group(function () {
        // Basic user info
        Route::get('profile', [AuthController::class, 'user']);
    });
});

// Health check route
Route::get('health', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'Boda Mapato API is running',
        'timestamp' => now()->toISOString(),
        'version' => '1.0.0',
        'server_time' => date('Y-m-d H:i:s'),
        'php_version' => PHP_VERSION,
    ]);
});

// Test routes for development
Route::prefix('test')->group(function () {
    Route::get('otp-flow', [TestController::class, 'testOtpFlow']);
    Route::get('otp-status', [TestController::class, 'getOtpStatus']);
    Route::post('cleanup-otps', [TestController::class, 'cleanupOtps']);
    Route::get('system-status', [TestController::class, 'systemStatus']);
    
    // Report testing routes
    Route::get('reports', [TestReportController::class, 'testReports']);
    Route::get('reports/status', [TestReportController::class, 'getTestDataStatus']);
    Route::post('reports/cleanup', [TestReportController::class, 'cleanupTestData']);
    
    // Test report endpoints without authentication
    Route::get('reports/revenue', [TestReportController::class, 'testRevenueReport']);
    Route::get('reports/expenses', [TestReportController::class, 'testExpenseReport']);
    Route::get('reports/profit-loss', [TestReportController::class, 'testProfitLossReport']);
    Route::get('reports/device-performance', [TestReportController::class, 'testDevicePerformanceReport']);
    
    // Test driver creation
    Route::post('create-driver', function (\Illuminate\Http\Request $request) {
        try {
            $adminController = new \App\Http\Controllers\API\AdminController();
            $createDriverRequest = \App\Http\Requests\CreateDriverRequest::createFrom($request);
            return $adminController->createDriver($createDriverRequest);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Test failed: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    });
    
    // Test vehicle creation
    Route::post('create-vehicle', function (\Illuminate\Http\Request $request) {
        try {
            $adminController = new \App\Http\Controllers\API\AdminController();
            $createVehicleRequest = \App\Http\Requests\CreateVehicleRequest::createFrom($request);
            return $adminController->createVehicle($createVehicleRequest);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Test failed: ' . $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine()
            ], 500);
        }
    });
});

// Simple test route
Route::get('test', function () {
    return response()->json([
        'message' => 'Simple test route working',
        'time' => now(),
    ]);
});

// Debug route to check what's happening
Route::get('debug', function () {
    return response()->json([
        'message' => 'Debug endpoint',
        'request_method' => request()->method(),
        'request_url' => request()->fullUrl(),
        'headers' => request()->headers->all(),
        'server_info' => [
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'server_time' => now(),
        ],
    ]);
});

// Fallback route for undefined API endpoints
Route::fallback(function () {
    return response()->json([
        'status' => 'error',
        'message' => 'API endpoint not found',
        'requested_url' => request()->fullUrl(),
        'available_endpoints' => [
            'GET /api/health',
            'GET /api/test', 
            'GET /api/debug',
            'POST /api/auth/login',
            'POST /api/auth/forgot-password',
            'POST /api/auth/reset-password',
        ],
    ], 404);
});