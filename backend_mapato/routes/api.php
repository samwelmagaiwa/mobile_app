<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\AdminController;
use App\Http\Controllers\API\AdminReportController;
use App\Http\Controllers\API\DriverViewController;
use App\Http\Controllers\API\DeviceController;
use App\Http\Controllers\API\DriverController;
use App\Http\Controllers\API\PaymentController;
use App\Http\Controllers\API\TransactionController;
use App\Http\Controllers\API\ReceiptController;
use App\Http\Controllers\API\ReportController;
use App\Http\Controllers\API\TestController;
use App\Http\Controllers\API\TestReportController;
use App\Http\Controllers\API\PaymentReceiptController;
use App\Http\Controllers\DriverAgreementController;

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

// Payment Receipt routes (temporary - no auth required for testing)
Route::prefix('payment-receipts')->group(function () {
    Route::get('pending', [PaymentReceiptController::class, 'getPendingReceipts']);
    Route::post('generate', [PaymentReceiptController::class, 'generateReceipt']);
    Route::get('{receiptId}/preview', [PaymentReceiptController::class, 'getReceiptPreview']);
    Route::post('send', [PaymentReceiptController::class, 'sendReceipt']);
    Route::get('', [PaymentReceiptController::class, 'getReceipts']);
    Route::get('{receiptId}', [PaymentReceiptController::class, 'getReceiptPreview']);
});

// Temporary development routes (bypass authentication until database is set up)
Route::prefix('admin')->group(function () {
    // Dashboard (temporary - no auth required for testing)
    Route::get('dashboard', [AdminController::class, 'publicDashboard']);
    
    // Driver management (temporary - no auth required)
    Route::get('drivers', [AdminController::class, 'getDrivers']);
    Route::get('drivers/{id}', [AdminController::class, 'getDriver']);
    Route::post('drivers', [AdminController::class, 'createDriver']);
    Route::put('drivers/{id}', [AdminController::class, 'updateDriver']);
    Route::delete('drivers/{id}', [AdminController::class, 'deleteDriver']);
    
    // Driver trends and analytics
    Route::get('drivers/{driverId}/debt-trends', [AdminController::class, 'getDriverDebtTrends']);
    Route::get('drivers/{driverId}/payment-trends', [AdminController::class, 'getDriverPaymentTrends']);
    
    // Payment management (temporary - no auth required)
    Route::post('record-payment', [AdminController::class, 'recordPayment']);
    Route::get('payment-history', [AdminController::class, 'getPaymentHistory']);
    
    // Vehicle management (temporary - no auth required)
    Route::get('vehicles', [AdminController::class, 'getVehicles']);
    Route::post('vehicles', [AdminController::class, 'createVehicle']);
    
    // Reminders management (temporary - no auth required)
    Route::get('reminders', [AdminController::class, 'getReminders']);
    Route::post('reminders', [AdminController::class, 'addReminder']);
    Route::put('reminders/{id}', [AdminController::class, 'updateReminder']);
    Route::delete('reminders/{id}', [AdminController::class, 'deleteReminder']);
    
    // Receipts management (temporary - no auth required) 
    Route::get('receipts', [AdminController::class, 'getReceipts']);
    
    // Reports management (temporary - no auth required for testing)
    Route::prefix('reports')->group(function () {
        Route::get('dashboard', [AdminReportController::class, 'getDashboardReport']);
        Route::get('revenue', [AdminReportController::class, 'getRevenueReport']);
        Route::get('expenses', [AdminReportController::class, 'getExpenseReport']);
        Route::get('profit-loss', [AdminReportController::class, 'getProfitLossReport']);
        Route::get('device-performance', [AdminReportController::class, 'getDevicePerformanceReport']);
        Route::post('export-pdf', [AdminReportController::class, 'exportToPdf']);
    });
    
    // Analytics management (mobile-focused - no auth required for testing)
    Route::prefix('analytics')->group(function () {
        Route::get('overview', [AdminReportController::class, 'getAnalyticsOverview']);
        Route::get('top-performers', [AdminReportController::class, 'getTopPerformers']);
        Route::get('live', [AdminReportController::class, 'getLiveAnalytics']);
        Route::get('trends', [AdminReportController::class, 'getRevenueReport']); // Reuse revenue for trends
    });
    
    // Payment management (temporary - no auth required for testing)
    Route::prefix('payments')->group(function () {
        Route::get('drivers-with-debts', [PaymentController::class, 'getDriversWithDebts']);
        Route::get('driver-debt-summary/{driverId}', [PaymentController::class, 'getDriverDebtSummary']);
        Route::get('driver-debts/{driverId}', [PaymentController::class, 'getDriverDebtRecords']);
        Route::post('record', [PaymentController::class, 'recordPayment']);
        Route::get('history', [PaymentController::class, 'getPaymentHistory']);
        Route::put('{paymentId}', [PaymentController::class, 'updatePayment']);
        Route::delete('{paymentId}', [PaymentController::class, 'deletePayment']);
        Route::get('summary', [PaymentController::class, 'getPaymentSummary']);
        Route::put('mark-debt-paid/{debtId}', [PaymentController::class, 'markDebtAsPaid']);
    });

    // Debts management (temporary - no auth required for testing)
    Route::prefix('debts')->group(function () {
        Route::get('drivers', [\App\Http\Controllers\API\DebtsController::class, 'listDrivers']);
        Route::get('driver/{driverId}/records', [\App\Http\Controllers\API\DebtsController::class, 'listDriverRecords']);
        Route::post('bulk-create', [\App\Http\Controllers\API\DebtsController::class, 'bulkCreate']);
        Route::put('records/{id}', [\App\Http\Controllers\API\DebtsController::class, 'updateRecord']);
        Route::delete('records/{id}', [\App\Http\Controllers\API\DebtsController::class, 'deleteRecord']);
    });
    
    // Driver agreements management (temporary - no auth required for testing)
    Route::prefix('driver-agreements')->group(function () {
        Route::get('', [DriverAgreementController::class, 'index']);
        Route::post('', [DriverAgreementController::class, 'store']);
        Route::get('{id}', [DriverAgreementController::class, 'show']);
        Route::put('{id}', [DriverAgreementController::class, 'update']);
        Route::delete('{id}', [DriverAgreementController::class, 'destroy']);
        Route::get('driver/{driverId}', [DriverAgreementController::class, 'getByDriver']);
        Route::post('calculate-preview', [DriverAgreementController::class, 'calculatePreview']);
    });
    
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
            
            // Reports (admin view) - DISABLED - Using temporary routes instead
            // Route::prefix('reports')->group(function () {
            //     Route::get('dashboard', [ReportController::class, 'dashboard']);
            //     Route::get('revenue', [ReportController::class, 'revenue']);
            //     Route::get('expenses', [ReportController::class, 'expenses']);
            //     Route::get('profit-loss', [ReportController::class, 'profitLoss']);
            //     Route::get('device-performance', [ReportController::class, 'devicePerformance']);
            //     Route::post('export-pdf', [ReportController::class, 'exportPdf']);
            // });
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
    Route::post('seed-debts', [TestController::class, 'seedDebts']);
    // Test AdminReportController directly
    Route::get('admin-reports/dashboard', [AdminReportController::class, 'getDashboardReport']);
    Route::get('admin-reports/revenue', [AdminReportController::class, 'getRevenueReport']);
    Route::get('admin-reports/expenses', [AdminReportController::class, 'getExpenseReport']);
    Route::get('admin-reports/profit-loss', [AdminReportController::class, 'getProfitLossReport']);
    Route::get('admin-reports/device-performance', [AdminReportController::class, 'getDevicePerformanceReport']);
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

// Test payment receipt route
Route::post('test-receipt', function () {
    return response()->json([
        'success' => true,
        'message' => 'Test receipt endpoint working!',
        'data' => ['test' => true],
        'time' => now(),
    ]);
});

// Test payment receipt controller directly
Route::post('test-payment-receipt-generate', [PaymentReceiptController::class, 'generateReceipt']);

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