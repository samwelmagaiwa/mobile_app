<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ReceiptController;

/*
|--------------------------------------------------------------------------
| Receipt API Routes
|--------------------------------------------------------------------------
|
| Here are the API routes for payment receipt management.
| These routes are protected by authentication middleware.
|
*/

Route::middleware(['auth:sanctum'])->group(function () {
    
    // Get pending receipts (payments without receipts generated)
    Route::get('/receipts/pending', [ReceiptController::class, 'getPendingReceipts']);
    
    // Generate receipt for a payment
    Route::post('/receipts/generate', [ReceiptController::class, 'generateReceipt']);
    
    // Get receipt preview
    Route::get('/receipts/{receiptId}/preview', [ReceiptController::class, 'getReceiptPreview']);
    
    // Send receipt to driver
    Route::post('/receipts/send', [ReceiptController::class, 'sendReceipt']);
    
    // Get all receipts with filtering options
    Route::get('/receipts', [ReceiptController::class, 'getReceipts']);
    
    // Get receipt by ID
    Route::get('/receipts/{receiptId}', [ReceiptController::class, 'getReceiptPreview']);
    
});