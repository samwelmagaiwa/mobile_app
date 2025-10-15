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
use App\Http\Controllers\API\CommunicationController;
use App\Http\Controllers\DriverAgreementController;
use App\Http\Controllers\API\DashboardController;

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

// Payment Receipt routes - PROTECTED
Route::middleware(['auth:sanctum'])->prefix('payment-receipts')->group(function () {
    Route::get('pending', [PaymentReceiptController::class, 'getPendingReceipts']);
    Route::post('generate', [PaymentReceiptController::class, 'generateReceipt']);
    Route::get('{receiptId}/preview', [PaymentReceiptController::class, 'getReceiptPreview']);
    Route::post('send', [PaymentReceiptController::class, 'sendReceipt']);
    Route::get('', [PaymentReceiptController::class, 'getReceipts']);
    Route::get('{receiptId}', [PaymentReceiptController::class, 'getReceiptPreview']);
});

// PROTECTED ADMIN ROUTES
Route::middleware(['auth:sanctum','role:admin'])->prefix('admin')->group(function () {
    // Dashboard
    Route::get('dashboard', [AdminController::class, 'dashboard']);
    Route::get('dashboard-data', [DashboardController::class, 'index']);
    Route::get('dashboard-stats', [DashboardController::class, 'getStats']);
    
    // Individual Dashboard Card Endpoints
    Route::prefix('dashboard')->group(function () {
        Route::get('active-drivers-count', [DashboardController::class, 'getActiveDriversCount']);
        Route::get('active-devices-count', [DashboardController::class, 'getActiveDevicesCount']);
        Route::get('unpaid-debts-count', [DashboardController::class, 'getUnpaidDebtsCount']);
        Route::get('generated-receipts-count', [DashboardController::class, 'getGeneratedReceiptsCount']);
        Route::get('pending-receipts-count', [DashboardController::class, 'getPendingReceiptsCountApi']);
        Route::get('daily-revenue', [DashboardController::class, 'getDailyRevenueApi']);
        Route::get('weekly-revenue', [DashboardController::class, 'getWeeklyRevenueApi']);
        Route::get('monthly-revenue', [DashboardController::class, 'getMonthlyRevenueApi']);
    });

    // Drivers
    Route::get('drivers', [AdminController::class, 'getDrivers']);
    Route::get('drivers/{id}', [AdminController::class, 'getDriver']);
    Route::get('drivers/{driverId}/prediction', [\App\Http\Controllers\Admin\DriverPredictionController::class, 'show']);
    Route::post('drivers', [AdminController::class, 'createDriver']);
    Route::put('drivers/{id}', [AdminController::class, 'updateDriver']);
    Route::delete('drivers/{id}', [AdminController::class, 'deleteDriver']);
    Route::get('drivers/{driverId}/debt-trends', [AdminController::class, 'getDriverDebtTrends']);
    Route::get('drivers/{driverId}/payment-trends', [AdminController::class, 'getDriverPaymentTrends']);
    Route::get('drivers/{driverId}/prediction', [\App\Http\Controllers\API\PredictionController::class, 'getDriverPrediction']);
    Route::get('drivers/{driverId}/history-pdf', [\App\Http\Controllers\API\DriverReportController::class, 'driverHistoryPdf']);

    // Vehicles
    Route::get('vehicles', [AdminController::class, 'getVehicles']);
    Route::post('vehicles', [AdminController::class, 'createVehicle']);
    Route::put('vehicles/{id}', [AdminController::class, 'updateVehicle']);
    Route::delete('vehicles/{id}', [AdminController::class, 'deleteVehicle']);
    Route::post('vehicles/{id}/unassign', [AdminController::class, 'unassignDriverFromVehicle']);
    Route::post('assign-driver', [AdminController::class, 'assignDriverToVehicle']);

    // Payments (use PaymentController under admin/payments)
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
        Route::post('new', [PaymentController::class, 'storeNewPayment']);
        Route::get('new-payments-map', [PaymentController::class, 'getNewPaymentsMap']);
    });

    // Debts
    Route::prefix('debts')->group(function () {
        Route::get('drivers', [\App\Http\Controllers\API\DebtsController::class, 'listDrivers']);
        Route::get('driver/{driverId}/records', [\App\Http\Controllers\API\DebtsController::class, 'listDriverRecords']);
        Route::post('bulk-create', [\App\Http\Controllers\API\DebtsController::class, 'bulkCreate']);
        Route::put('records/{id}', [\App\Http\Controllers\API\DebtsController::class, 'updateRecord']);
        Route::delete('records/{id}', [\App\Http\Controllers\API\DebtsController::class, 'deleteRecord']);
    });

    // Driver agreements
    Route::prefix('driver-agreements')->group(function () {
        Route::get('', [DriverAgreementController::class, 'index']);
        Route::post('', [DriverAgreementController::class, 'store']);
        Route::get('{id}', [DriverAgreementController::class, 'show']);
        Route::put('{id}', [DriverAgreementController::class, 'update']);
        Route::delete('{id}', [DriverAgreementController::class, 'destroy']);
        Route::get('driver/{driverId}', [DriverAgreementController::class, 'getByDriver']);
        Route::post('calculate-preview', [DriverAgreementController::class, 'calculatePreview']);
    });

    // Reminders
    Route::prefix('reminders')->group(function () {
        Route::get('', [AdminController::class, 'getReminders']);
        Route::post('', [AdminController::class, 'addReminder']);
        Route::put('{id}', [AdminController::class, 'updateReminder']);
        Route::delete('{id}', [AdminController::class, 'deleteReminder']);
    });

    // Receipts Management (admin view)
    Route::prefix('receipts')->group(function () {
        Route::get('pending', [PaymentReceiptController::class, 'getPendingReceipts']);
        Route::post('generate', [PaymentReceiptController::class, 'generateReceipt']);
        Route::get('{receiptId}/preview', [PaymentReceiptController::class, 'getReceiptPreview']);
        Route::post('send', [PaymentReceiptController::class, 'sendReceipt']);
        Route::get('', [PaymentReceiptController::class, 'getReceipts']);
        Route::get('{receiptId}', [PaymentReceiptController::class, 'getReceiptPreview']);
        Route::put('{receiptId}/status', [PaymentReceiptController::class, 'updateReceiptStatus']);
        Route::put('{receiptId}/cancel', [PaymentReceiptController::class, 'cancelReceipt']);
        Route::delete('{receiptId}', [PaymentReceiptController::class, 'deleteReceipt']);
        Route::get('stats', [PaymentReceiptController::class, 'getReceiptStats']);
        Route::post('export', [PaymentReceiptController::class, 'exportReceipts']);
        Route::post('bulk-generate', [PaymentReceiptController::class, 'generateBulkReceipts']);
        Route::get('search', [PaymentReceiptController::class, 'searchReceipts']);
    });

    // Reports
    Route::prefix('reports')->group(function () {
        Route::get('dashboard', [AdminReportController::class, 'getDashboardReport']);
        Route::get('revenue', [AdminReportController::class, 'getRevenueReport']);
        Route::get('expenses', [AdminReportController::class, 'getExpenseReport']);
        Route::get('profit-loss', [AdminReportController::class, 'getProfitLossReport']);
        Route::get('device-performance', [AdminReportController::class, 'getDevicePerformanceReport']);
        Route::post('export-pdf', [AdminReportController::class, 'exportToPdf']);
    });

    // Analytics
    Route::prefix('analytics')->group(function () {
        Route::get('overview', [AdminReportController::class, 'getAnalyticsOverview']);
        Route::get('top-performers', [AdminReportController::class, 'getTopPerformers']);
        Route::get('live', [AdminReportController::class, 'getLiveAnalytics']);
        Route::get('trends', [AdminReportController::class, 'getRevenueReport']);
    });
});

// Protected routes (authentication required)
Route::middleware(['auth:sanctum'])->group(function () {
    
    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('user', [AuthController::class, 'user']);
        Route::post('refresh', [AuthController::class, 'refresh']);
        // Security
        Route::post('change-password', [\App\Http\Controllers\API\SecurityController::class, 'changePassword']);
        Route::get('security', [\App\Http\Controllers\API\SecurityController::class, 'getSecuritySettings']);
        Route::post('two-factor', [\App\Http\Controllers\API\SecurityController::class, 'setTwoFactor']);
        Route::get('login-history', [\App\Http\Controllers\API\SecurityController::class, 'getLoginHistory']);
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

// Removed testing and debug routes for production

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