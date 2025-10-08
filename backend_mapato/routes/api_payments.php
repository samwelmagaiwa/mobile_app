<?php

use App\Http\Controllers\Api\PaymentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Payment API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for payment management.
| These routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group.
|
*/

Route::middleware(['auth:api'])->prefix('admin/payments')->group(function () {
    // Driver and debt management
    Route::get('/drivers-with-debts', [PaymentController::class, 'getDriversWithDebts']);
    Route::get('/driver-debt-summary/{driverId}', [PaymentController::class, 'getDriverDebtSummary']);
    Route::get('/driver-debts/{driverId}', [PaymentController::class, 'getDriverDebtRecords']);
    
    // Payment operations
    Route::post('/record', [PaymentController::class, 'recordPayment']);
    Route::get('/history', [PaymentController::class, 'getPaymentHistory']);
    Route::put('/{paymentId}', [PaymentController::class, 'updatePayment']);
    Route::delete('/{paymentId}', [PaymentController::class, 'deletePayment']);
    
    // Statistics and summaries
    Route::get('/summary', [PaymentController::class, 'getPaymentSummary']);
    
    // Debt management
    Route::put('/mark-debt-paid/{debtId}', [PaymentController::class, 'markDebtAsPaid']);
});

// Public routes (if needed for testing or webhook)
Route::prefix('payments')->group(function () {
    // Add any public payment routes here if needed
    // Route::post('/webhook', [PaymentController::class, 'handleWebhook']);
});